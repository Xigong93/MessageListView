import 'package:flutter/foundation.dart';

import '../message.dart';
import '../mock_message_service.dart';
import 'load_more_status.dart';

/// 负责消息列表的数据加载与状态管理。
/// 各状态字段为 [ValueNotifier]，视图可按需订阅单个字段的变化。
class MessageListController {
  MockMessageService _service;

  MessageListController(this._service);

  // ───────────────────────────── 状态 ─────────────────────────────

  /// 正方向消息（初始加载 + 新消息），按时间升序排列。
  final ValueNotifier<List<Message>> messages = ValueNotifier([]);

  /// 反方向消息（历史消息），按时间降序排列（最新在前，最旧在后）。
  /// 在双向 ScrollView 中，index 0 紧邻 center，向上增长。
  final ValueNotifier<List<Message>> historyMessages = ValueNotifier([]);

  /// 是否正在进行首次加载。
  final ValueNotifier<bool> isLoadingInitial = ValueNotifier(true);

  /// 加载历史消息的状态。
  final ValueNotifier<LoadMoreStatus> loadHistoryStatus =
      ValueNotifier(LoadMoreStatus.idle);

  /// 加载新消息的状态。
  final ValueNotifier<LoadMoreStatus> loadNewStatus =
      ValueNotifier(LoadMoreStatus.idle);

  /// 首次加载完成后是否应滚动到底部（由 [loadMessage] 的 startMsgId 决定）。
  bool get shouldScrollToBottom => _shouldScrollToBottom;
  bool _shouldScrollToBottom = true;

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

  /// 加载更多历史消息，追加到 [historyMessages] 末尾（向上增长）。
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

  /// 拉取新消息，追加到 [messages] 末尾。
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
    _service = MockMessageService();
    messages.value = [];
    historyMessages.value = [];
    isLoadingInitial.value = true;
    loadHistoryStatus.value = LoadMoreStatus.idle;
    loadNewStatus.value = LoadMoreStatus.idle;
    await loadMessage();
  }

  /// 释放资源。
  void dispose() {
    messages.dispose();
    historyMessages.dispose();
    isLoadingInitial.dispose();
    loadHistoryStatus.dispose();
    loadNewStatus.dispose();
  }
}
