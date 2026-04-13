import 'package:flutter/widgets.dart';

import 'initial_load_status.dart';
import 'load_more_status.dart';
import 'message_provider.dart';

/// 加载异常的处理回调。
///
/// - [error]：捕获到的异常对象。
/// - [stack]：对应的堆栈信息。
/// - [operation]：发生异常的操作名称（`loadMessage` / `loadMoreHistory` / `loadNewMessage`）。
typedef MessageErrorHandler = void Function(
  Object error,
  StackTrace stack,
  String operation,
);

/// 消息列表的统一控制器，持有全部状态、协调加载逻辑，并管理 [ScrollController]。
///
/// 外部通过此对象完成数据加载和滚动控制；[MessageProvider] 只负责纯数据获取。
///
/// 可通过 [onError] 将加载异常转发到业务日志系统（Sentry、Crashlytics 等）。
/// 未传时回退到 [FlutterError.reportError]。
class MessageListController<T> {
  final MessageProvider<T> _provider;
  final MessageErrorHandler? onError;
  final scrollController = ScrollController();

  // ───────────────────────────── 状态 ─────────────────────────────

  /// 正方向列表项（初始加载 + 新增），按时间升序排列。
  final ValueNotifier<List<T>> messages = ValueNotifier([]);

  /// 反方向列表项（历史），按时间降序排列（最新在前，最旧在后）。
  final ValueNotifier<List<T>> historyMessages = ValueNotifier([]);

  /// 首次加载的状态。
  final ValueNotifier<InitialLoadStatus> initialLoadStatus =
      ValueNotifier(InitialLoadStatus.loading);

  /// 加载历史消息的状态。
  final ValueNotifier<LoadMoreStatus> loadHistoryStatus =
      ValueNotifier(LoadMoreStatus.idle);

  /// 加载新消息的状态。
  final ValueNotifier<LoadMoreStatus> loadNewStatus =
      ValueNotifier(LoadMoreStatus.idle);

  MessageListController(this._provider, {this.onError});

  // ───────────────────────────── 错误上报 ─────────────────────────────

  void _reportError(Object e, StackTrace s, String operation) {
    if (onError != null) {
      onError!(e, s, operation);
    } else {
      FlutterError.reportError(FlutterErrorDetails(
        exception: e,
        stack: s,
        library: 'message_list_view',
        context: ErrorDescription(operation),
      ));
    }
  }

  // ───────────────────────────── 加载协调 ─────────────────────────────

  /// 首次加载消息并在布局就绪后自动滚动到目标位置。
  ///
  /// - [startMsgId] 为空：加载最新消息，完成后滚动到底部。
  /// - [startMsgId] 不为空：加载指定位置消息，完成后保持顶部。
  Future<void> loadMessage() async {
    loadHistoryStatus.value = LoadMoreStatus.idle;
    loadNewStatus.value = LoadMoreStatus.idle;
    initialLoadStatus.value = InitialLoadStatus.loading;
    try {
      final result = await _provider.fetchInitial();
      messages.value = result.messages;
      historyMessages.value = [];
      loadNewStatus.value =
          result.hasMoreNew ? LoadMoreStatus.idle : LoadMoreStatus.noMore;
      initialLoadStatus.value = InitialLoadStatus.success;
      // hasMoreNew 为 false 意味着已加载最新消息，滚到底部
      if (!result.hasMoreNew) scrollToBottom(anim: false);
    } catch (e, s) {
      _reportError(e, s, 'loadMessage');
      initialLoadStatus.value = InitialLoadStatus.error;
    }
  }

  /// 加载更多历史数据（向上方向）。由视图在滚动接近顶部时调用。
  Future<void> loadMoreHistory() async {
    if (loadHistoryStatus.value == LoadMoreStatus.loading) return;
    if (loadHistoryStatus.value == LoadMoreStatus.noMore) return;
    final oldestItem = historyMessages.value.isNotEmpty
        ? historyMessages.value.last
        : messages.value.firstOrNull;
    if (oldestItem == null) return;
    loadHistoryStatus.value = LoadMoreStatus.loading;
    try {
      final list = await _provider.fetchHistory(oldestItem);
      // provider 返回升序列表，反转为降序后追加到历史列表末尾
      historyMessages.value = [...historyMessages.value, ...list.reversed];
      loadHistoryStatus.value =
          list.isEmpty ? LoadMoreStatus.noMore : LoadMoreStatus.idle;
    } catch (e, s) {
      _reportError(e, s, 'loadMoreHistory');
      loadHistoryStatus.value = LoadMoreStatus.error;
    }
  }

  /// 加载更多新数据（向下方向）。由视图在滚动接近底部时调用。
  Future<void> loadNewMessage() async {
    if (loadNewStatus.value == LoadMoreStatus.loading) return;
    if (loadNewStatus.value == LoadMoreStatus.noMore) return;
    final newestItem = messages.value.lastOrNull;
    if (newestItem == null) return;
    loadNewStatus.value = LoadMoreStatus.loading;
    try {
      final list = await _provider.fetchNew(newestItem);
      messages.value = [...messages.value, ...list];
      loadNewStatus.value =
          list.isEmpty ? LoadMoreStatus.noMore : LoadMoreStatus.idle;
    } catch (e, s) {
      _reportError(e, s, 'loadNewMessage');
      loadNewStatus.value = LoadMoreStatus.error;
    }
  }

  /// 追加消息到正方向列表末尾。用于实时推送或 demo 模拟收到新消息。
  void appendMessages(List<T> items) {
    messages.value = [...messages.value, ...items];
  }

  /// 重连后从最新消息开始拉取新消息，返回获取到的列表（空表示断线期间无新消息）。
  ///
  /// 若当前正在加载新消息，直接返回空列表。
  /// 拉到数据后会将 [loadNewStatus] 重置为 [LoadMoreStatus.idle]，
  /// 允许后续继续向下滚动加载。
  Future<List<T>> reconnectAndFetch() async {
    if (loadNewStatus.value == LoadMoreStatus.loading) return [];
    final newestItem = messages.value.lastOrNull;
    if (newestItem == null) return [];
    // 重置，以防之前已到达末尾（noMore）
    loadNewStatus.value = LoadMoreStatus.idle;
    try {
      final list = await _provider.fetchNew(newestItem);
      if (list.isNotEmpty) {
        messages.value = [...messages.value, ...list];
        // 保持 idle，允许继续向下加载更多
      }
      return list;
    } catch (e, s) {
      _reportError(e, s, 'reconnect');
      return [];
    }
  }

  /// 重置并重新加载，原子操作（等同于清空数据后调用 [loadMessage]）。
  Future<void> reload() async {
    messages.value = [];
    historyMessages.value = [];
    await loadMessage();
  }

  // ───────────────────────────── 滚动 ─────────────────────────────

  /// 滚动到顶部。
  /// 无需等待布局完成，内部已处理
  Future<void> scrollToTop({bool anim = true}) =>
      _scrollTo(() => scrollController.position.minScrollExtent, anim: anim);

  /// 滚动到底部。
  /// 无需等待布局完成，内部已处理
  Future<void> scrollToBottom({bool anim = true}) =>
      _scrollTo(() => scrollController.position.maxScrollExtent, anim: anim);

  Future<void> _scrollTo(double Function() getTarget,
      {required bool anim}) async {
    if (!scrollController.hasClients) return;
    await WidgetsBinding.instance.endOfFrame;
    final target = getTarget();
    if (anim) {
      await scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      scrollController.jumpTo(target);
    }
  }

  /// 列表当前是否处于底部。
  bool get atBottom {
    if (!scrollController.hasClients) return false;
    final position = scrollController.position;
    return position.pixels >= position.maxScrollExtent - 1;
  }

  // ───────────────────────────── 资源释放 ─────────────────────────────

  void dispose() {
    messages.dispose();
    historyMessages.dispose();
    initialLoadStatus.dispose();
    loadHistoryStatus.dispose();
    loadNewStatus.dispose();
    scrollController.dispose();
    _provider.dispose();
  }
}
