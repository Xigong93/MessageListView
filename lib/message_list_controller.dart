import 'package:flutter/foundation.dart';

import 'message.dart';
import 'mock_message_service.dart';

/// 负责消息列表的数据加载与状态管理。
/// 视图通过 [addListener] 订阅变化，并从只读属性中读取最新状态。
class MessageListController extends ChangeNotifier {
  MockMessageService _service;

  MessageListController(this._service);

  // ───────────────────────────── 状态 ─────────────────────────────

  List<Message> _messages = [];
  bool _isLoadingInitial = true;
  bool _isLoadingHistory = false;
  bool _hasMoreHistory = true;
  bool _isLoadingNewMessage = false;

  List<Message> get messages => List.unmodifiable(_messages);
  bool get isLoadingInitial => _isLoadingInitial;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get hasMoreHistory => _hasMoreHistory;
  bool get isLoadingNewMessage => _isLoadingNewMessage;

  // ───────────────────────────── 公开方法 ─────────────────────────────

  /// 首次加载。
  Future<void> initialize() async {
    final msgs = await _service.fetchInitialMessages();
    _messages = msgs;
    _isLoadingInitial = false;
    notifyListeners();
  }

  /// 加载更多历史消息，插入列表头部。
  Future<void> loadMoreHistory() async {
    if (_isLoadingHistory || !_hasMoreHistory) return;

    _isLoadingHistory = true;
    notifyListeners();

    final result = await _service.fetchHistoryMessages();
    _messages.insertAll(0, result.messages);
    _isLoadingHistory = false;
    _hasMoreHistory = result.hasMore;
    notifyListeners();
  }

  /// 拉取一条新消息，追加到列表末尾。
  Future<void> loadNewMessage() async {
    if (_isLoadingNewMessage) return;

    _isLoadingNewMessage = true;
    notifyListeners();

    final message = await _service.fetchNewMessage();
    _messages.add(message);
    _isLoadingNewMessage = false;
    notifyListeners();
  }

  /// 重置为初始状态，重新加载。
  Future<void> reset() async {
    _service = MockMessageService();
    _messages = [];
    _isLoadingInitial = true;
    _isLoadingHistory = false;
    _hasMoreHistory = true;
    _isLoadingNewMessage = false;
    notifyListeners();
    await initialize();
  }

}
