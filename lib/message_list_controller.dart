import 'package:flutter/foundation.dart';

import 'message.dart';
import 'mock_message_service.dart';

/// 负责消息列表的数据加载与状态管理。
/// 各状态字段为 [ValueNotifier]，视图可按需订阅单个字段的变化。
class MessageListController {
  MockMessageService _service;

  MessageListController(this._service);

  // ───────────────────────────── 状态 ─────────────────────────────

  /// 当前已加载的所有消息（不可变视图）。
  final ValueNotifier<List<Message>> messages = ValueNotifier([]);

  /// 是否正在进行首次加载。
  final ValueNotifier<bool> isLoadingInitial = ValueNotifier(true);

  /// 是否正在加载历史消息。
  final ValueNotifier<bool> isLoadingHistory = ValueNotifier(false);

  /// 是否还有更多历史消息可加载。
  final ValueNotifier<bool> hasMoreHistory = ValueNotifier(true);

  /// 是否正在加载新消息。
  final ValueNotifier<bool> isLoadingNewMessage = ValueNotifier(false);

  // ───────────────────────────── 公开方法 ─────────────────────────────

  /// 首次加载消息，[startMsgId] 为展示的第一条消息 ID，为空时使用默认值。
  Future<void> loadMessage({int? startMsgId}) async {
    final msgs = await _service.fetchInitialMessages(startMsgId: startMsgId);
    messages.value = msgs;
    isLoadingInitial.value = false;
  }

  /// 加载更多历史消息，插入列表头部。
  Future<void> loadMoreHistory() async {
    if (isLoadingHistory.value || !hasMoreHistory.value) return;
    final oldestMsgId = messages.value.firstOrNull?.id;
    if (oldestMsgId == null) return;
    isLoadingHistory.value = true;

    final list = await _service.fetchHistoryMessages(oldestMsgId);
    messages.value = [...list, ...messages.value];
    isLoadingHistory.value = false;
    hasMoreHistory.value = list.isNotEmpty;
  }

  /// 拉取新消息，追加到列表末尾。
  Future<void> loadNewMessage() async {
    if (isLoadingNewMessage.value) return;
    final newestMsgId = messages.value.lastOrNull?.id;
    if (newestMsgId == null) return;
    isLoadingNewMessage.value = true;

    final list = await _service.fetchNewMessage(newestMsgId);
    messages.value = [...messages.value, ...list];
    isLoadingNewMessage.value = false;
  }

  /// 同步追加一条新消息到列表末尾。
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
    isLoadingInitial.value = true;
    isLoadingHistory.value = false;
    hasMoreHistory.value = true;
    isLoadingNewMessage.value = false;
    await loadMessage();
  }

  /// 释放资源。
  void dispose() {
    messages.dispose();
    isLoadingInitial.dispose();
    isLoadingHistory.dispose();
    hasMoreHistory.dispose();
    isLoadingNewMessage.dispose();
  }
}
