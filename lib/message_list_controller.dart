import 'dart:async';

import 'package:flutter/foundation.dart';

import 'message.dart';
import 'mock_message_service.dart';

/// 负责消息列表的数据加载与状态管理。
/// 视图通过 [addListener] 订阅变化，并从只读属性中读取最新状态。
class MessageListController extends ChangeNotifier {
  final MockMessageService _service;

  MessageListController(this._service);

  // ───────────────────────────── 状态 ─────────────────────────────

  List<Message> _messages = [];
  bool _isLoadingInitial = true;
  bool _isLoadingHistory = false;
  bool _hasMoreHistory = true;

  List<Message> get messages => List.unmodifiable(_messages);
  bool get isLoadingInitial => _isLoadingInitial;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get hasMoreHistory => _hasMoreHistory;

  StreamSubscription<Message>? _newMessageSub;

  // ───────────────────────────── 公开方法 ─────────────────────────────

  /// 首次加载，完成后开始监听新消息流。
  Future<void> initialize() async {
    final msgs = await _service.fetchInitialMessages();
    _messages = msgs;
    _isLoadingInitial = false;
    notifyListeners();

    _newMessageSub = _service.newMessageStream().listen(_appendMessage);
  }

  /// 加载更多历史消息，插入列表头部。
  Future<void> loadMoreHistory() async {
    if (_isLoadingHistory || !_hasMoreHistory) return;

    _isLoadingHistory = true;
    notifyListeners(); // 通知视图：历史加载开始

    final result = await _service.fetchHistoryMessages();
    _messages.insertAll(0, result.messages);
    _isLoadingHistory = false;
    _hasMoreHistory = result.hasMore;
    notifyListeners(); // 通知视图：历史加载完成，数据已更新
  }

  /// 发送一条自己的消息，追加到列表末尾。
  void sendMessage(String content) {
    _appendMessage(_service.createMyMessage(content));
  }

  // ───────────────────────────── 内部 ─────────────────────────────

  void _appendMessage(Message message) {
    _messages.add(message);
    notifyListeners();
  }

  @override
  void dispose() {
    _newMessageSub?.cancel();
    super.dispose();
  }
}
