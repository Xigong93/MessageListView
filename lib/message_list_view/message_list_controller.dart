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

  /// 当前已加载的所有消息（不可变视图）。
  final ValueNotifier<List<Message>> messages = ValueNotifier([]);

  /// 是否正在进行首次加载。
  final ValueNotifier<bool> isLoadingInitial = ValueNotifier(true);

  /// 加载历史消息的状态。
  final ValueNotifier<LoadMoreStatus> loadHistoryStatus =
      ValueNotifier(LoadMoreStatus.idle);

  /// 加载新消息的状态。
  final ValueNotifier<LoadMoreStatus> loadNewStatus =
      ValueNotifier(LoadMoreStatus.idle);

  /// 头部插入内容后发出通知，供滚动组件补偿位置。
  final ValueNotifier<int> prependNotifier = ValueNotifier(0);

  // ───────────────────────────── 公开方法 ─────────────────────────────

  /// 首次加载消息，[startMsgId] 为展示的第一条消息 ID，为空时使用默认值。
  Future<void> loadMessage({int? startMsgId}) async {
    /// 设置是否可以加载更多
    loadNewStatus.value =
        startMsgId != null ? LoadMoreStatus.idle : LoadMoreStatus.noMore;
    isLoadingInitial.value = true;
    final list = await _service.fetchInitialMessages(startMsgId: startMsgId);
    messages.value = list;
    isLoadingInitial.value = false;
  }

  /// 加载更多历史消息，插入列表头部。
  Future<void> loadMoreHistory() async {
    if (loadHistoryStatus.value != LoadMoreStatus.idle) return;
    final oldestMsgId = messages.value.firstOrNull?.id;
    if (oldestMsgId == null) return;
    loadHistoryStatus.value = LoadMoreStatus.loading;

    final list = await _service.fetchHistoryMessages(oldestMsgId);
    messages.value = [...list, ...messages.value];
    if (list.isNotEmpty) {
      prependNotifier.value++;
    }
    loadHistoryStatus.value =
        list.isEmpty ? LoadMoreStatus.noMore : LoadMoreStatus.idle;
  }

  /// 拉取新消息，追加到列表末尾。
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
    loadHistoryStatus.value = LoadMoreStatus.idle;
    loadNewStatus.value = LoadMoreStatus.idle;
    await loadMessage();
  }

  /// 释放资源。
  void dispose() {
    messages.dispose();
    isLoadingInitial.dispose();
    loadHistoryStatus.dispose();
    loadNewStatus.dispose();
    prependNotifier.dispose();
  }
}
