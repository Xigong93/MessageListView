import 'package:flutter/widgets.dart';

import 'load_more_status.dart';
import 'message_provider.dart';

/// 消息列表的统一控制器，持有全部状态、协调加载逻辑，并管理 [ScrollController]。
///
/// 外部通过此对象完成数据加载和滚动控制；[MessageProvider] 只负责纯数据获取。
class MessageListController<T> {
  final MessageProvider<T> _provider;
  final scrollController = ScrollController();

  // ───────────────────────────── 状态 ─────────────────────────────

  /// 正方向列表项（初始加载 + 新增），按时间升序排列。
  final ValueNotifier<List<T>> messages = ValueNotifier([]);

  /// 反方向列表项（历史），按时间降序排列（最新在前，最旧在后）。
  final ValueNotifier<List<T>> historyMessages = ValueNotifier([]);

  /// 是否正在进行首次加载。
  final ValueNotifier<bool> isLoadingInitial = ValueNotifier(true);

  /// 加载历史消息的状态。
  final ValueNotifier<LoadMoreStatus> loadHistoryStatus =
      ValueNotifier(LoadMoreStatus.idle);

  /// 加载新消息的状态。
  final ValueNotifier<LoadMoreStatus> loadNewStatus =
      ValueNotifier(LoadMoreStatus.idle);

  MessageListController(this._provider);

  // ───────────────────────────── 加载协调 ─────────────────────────────

  /// 首次加载消息并在布局就绪后自动滚动到目标位置。
  ///
  /// - [startMsgId] 为空：加载最新消息，完成后滚动到底部。
  /// - [startMsgId] 不为空：加载指定位置消息，完成后保持顶部。
  Future<void> loadMessage() async {
    loadHistoryStatus.value = LoadMoreStatus.idle;
    loadNewStatus.value = LoadMoreStatus.idle;
    isLoadingInitial.value = true;
    final result = await _provider.fetchInitial();
    messages.value = result.messages;
    historyMessages.value = [];
    loadNewStatus.value =
        result.hasMoreNew ? LoadMoreStatus.idle : LoadMoreStatus.noMore;
    isLoadingInitial.value = false;
    // hasMoreNew 为 false 意味着已加载最新消息，滚到底部
    if (!result.hasMoreNew) scrollToBottom(anim: false);
  }

  /// 加载更多历史数据（向上方向）。由视图在滚动接近顶部时调用。
  Future<void> loadMoreHistory() async {
    if (loadHistoryStatus.value != LoadMoreStatus.idle) return;
    final oldestItem = historyMessages.value.isNotEmpty
        ? historyMessages.value.last
        : messages.value.firstOrNull;
    if (oldestItem == null) return;
    loadHistoryStatus.value = LoadMoreStatus.loading;
    final list = await _provider.fetchHistory(oldestItem);
    // provider 返回升序列表，反转为降序后追加到历史列表末尾
    historyMessages.value = [...historyMessages.value, ...list.reversed];
    loadHistoryStatus.value =
        list.isEmpty ? LoadMoreStatus.noMore : LoadMoreStatus.idle;
  }

  /// 加载更多新数据（向下方向）。由视图在滚动接近底部时调用。
  Future<void> loadNewMessage() async {
    if (loadNewStatus.value != LoadMoreStatus.idle) return;
    final newestItem = messages.value.lastOrNull;
    if (newestItem == null) return;
    loadNewStatus.value = LoadMoreStatus.loading;
    final list = await _provider.fetchNew(newestItem);
    messages.value = [...messages.value, ...list];
    loadNewStatus.value =
        list.isEmpty ? LoadMoreStatus.noMore : LoadMoreStatus.idle;
  }

  /// 追加消息到正方向列表末尾。用于实时推送或 demo 模拟收到新消息。
  void appendMessages(List<T> items) {
    messages.value = [...messages.value, ...items];
  }

  /// 重置并重新加载，原子操作（等同于清空数据后调用 [loadMessage]）。
  Future<void> reload() async {
    messages.value = [];
    historyMessages.value = [];
    await loadMessage();
  }

  // ───────────────────────────── 滚动 ─────────────────────────────

  /// 滚动到顶部。
  Future<void> scrollToTop({bool anim = true}) =>
      _scrollTo(() => scrollController.position.minScrollExtent, anim: anim);

  /// 滚动到底部。
  Future<void> scrollToBottom({bool anim = true}) =>
      _scrollTo(() => scrollController.position.maxScrollExtent, anim: anim);

  Future<void> _scrollTo(double Function() getTarget, {required bool anim}) async {
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
    isLoadingInitial.dispose();
    loadHistoryStatus.dispose();
    loadNewStatus.dispose();
    scrollController.dispose();
    _provider.dispose();
  }
}
