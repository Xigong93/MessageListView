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

  /// 初始滚动定位完成后置为 true，防止定位前触发加载。
  final ValueNotifier<bool> isReady = ValueNotifier(false);

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
    isReady.value = false;
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
      if (!result.hasMoreNew) await scrollToBottom(anim: false);
      isReady.value = true;
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

  /// 删除消息
  void deleteMessage(T t) {
    final msgIdx = messages.value.indexOf(t);
    if (msgIdx != -1) {
      final list = [...messages.value];
      list.removeAt(msgIdx);
      messages.value = list;
      return;
    }
    final histIdx = historyMessages.value.indexOf(t);
    if (histIdx != -1) {
      final list = [...historyMessages.value];
      list.removeAt(histIdx);
      historyMessages.value = list;
    }
  }

  /// 刷新消息
  void refreshMessage(T t) {
    replaceMessage((ele) => ele == t, t);
  }

  /// 替换消息
  /// [isMatch] 匹配器
  void replaceMessage(bool Function(T t) isMatch, T newMsg) {
    final msgIdx = messages.value.indexWhere(isMatch);
    if (msgIdx != -1) {
      final list = [...messages.value];
      list[msgIdx] = newMsg;
      messages.value = list;
      return;
    }
    final histIdx = historyMessages.value.indexWhere(isMatch);
    if (histIdx != -1) {
      final list = [...historyMessages.value];
      list[histIdx] = newMsg;
      historyMessages.value = list;
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
    if (anim) {
      await WidgetsBinding.instance.endOfFrame;
      await scrollController.animateTo(
        getTarget(),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      // 动画期间 maxScrollExtent 可能增长，动画结束后迭代修正剩余偏差
      var last = double.nan;
      for (int i = 0; i < 5; i++) {
        await WidgetsBinding.instance.endOfFrame;
        final current = getTarget();
        if (current == last) break;
        last = current;
        scrollController.jumpTo(current);
      }
    } else {
      // 迭代跳转：每帧跳到当前目标，直到目标不再增长
      var last = double.nan;
      for (int i = 0; i < 10; i++) {
        await WidgetsBinding.instance.endOfFrame;
        final current = getTarget();
        if (current == last) break;
        last = current;
        scrollController.jumpTo(current);
      }
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
    isReady.dispose();
    scrollController.dispose();
    _provider.dispose();
  }
}
