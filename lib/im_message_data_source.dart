import 'package:message_list_view/message_list_view.dart';

import 'message.dart';
import 'mock_message_service.dart';

/// IM 场景的消息列表控制器，实现 [MessageDataSource] 抽象。
class ImMessageDataSource extends MessageDataSource<Message> {
  final _service = MockMessageService();

  ImMessageDataSource();

  bool _shouldScrollToBottom = true;

  @override
  bool get shouldScrollToBottom => _shouldScrollToBottom;

  // ───────────────────────────── 公开方法 ─────────────────────────────

  /// 首次加载消息，[startMsgId] 为展示的第一条消息 ID，为空时使用默认值。
  ///
  /// - startMsgId == null：加载最新消息，完成后视图应滚动到底部。
  /// - startMsgId != null：加载指定位置消息，完成后视图应滚动到顶部。
  Future<void> loadMessage({int? startMsgId}) async {
    _shouldScrollToBottom = startMsgId == null;
    loadHistoryStatus.value = LoadMoreStatus.idle;
    loadNewStatus.value =
        startMsgId != null ? LoadMoreStatus.idle : LoadMoreStatus.noMore;
    isLoadingInitial.value = true;
    final list = await _service.fetchInitialMessages(startMsgId: startMsgId);
    messages.value = list;
    isLoadingInitial.value = false;
  }

  @override
  Future<void> loadMoreHistory() async {
    if (loadHistoryStatus.value != LoadMoreStatus.idle) return;
    // 最旧的消息：优先从 historyMessages 末尾取，否则从 messages 首条取
    final oldestMsgId = historyMessages.value.isNotEmpty
        ? historyMessages.value.last.id
        : messages.value.firstOrNull?.id;
    if (oldestMsgId == null) return;
    loadHistoryStatus.value = LoadMoreStatus.loading;

    final list = await _service.fetchHistoryMessages(oldestMsgId);
    // 服务返回升序 [80,81,...,99]，反转为降序 [99,98,...,80] 后追加
    historyMessages.value = [...historyMessages.value, ...list.reversed];
    loadHistoryStatus.value =
        list.isEmpty ? LoadMoreStatus.noMore : LoadMoreStatus.idle;
  }

  @override
  Future<void> loadNewMessage() async {
    if (loadNewStatus.value != LoadMoreStatus.idle) return;
    final newestMsgId = messages.value.lastOrNull?.id;
    if (newestMsgId == null) return;
    loadNewStatus.value = LoadMoreStatus.loading;

    final list = await _service.fetchNewMessage(newestMsgId);
    messages.value = [...messages.value, ...list];
    loadNewStatus.value =
        list.isEmpty ? LoadMoreStatus.noMore : LoadMoreStatus.idle;
  }

  /// 同步追加一条新消息到 [messages] 末尾。
  void addNewMessage() {
    final newestMsgId = messages.value.lastOrNull?.id;
    if (newestMsgId == null) return;
    final message = _service.newMessage(newestMsgId);
    messages.value = [...messages.value, message];
  }

  /// 重置为初始状态，重新加载。
  Future<void> reset() async {
    messages.value = [];
    historyMessages.value = [];
    isLoadingInitial.value = true;
    loadHistoryStatus.value = LoadMoreStatus.idle;
    loadNewStatus.value = LoadMoreStatus.idle;
    await loadMessage();
  }
}
