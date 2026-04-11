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

  /// 当前已加载的所有消息（不可变视图）。
  List<Message> get messages => List.unmodifiable(_messages);

  /// 是否正在进行首次加载。
  bool get isLoadingInitial => _isLoadingInitial;

  /// 是否正在加载历史消息。
  bool get isLoadingHistory => _isLoadingHistory;

  /// 是否还有更多历史消息可加载。
  bool get hasMoreHistory => _hasMoreHistory;

  /// 是否正在加载新消息。
  bool get isLoadingNewMessage => _isLoadingNewMessage;

  // ───────────────────────────── 公开方法 ─────────────────────────────

  /// 首次加载消息，[startMsgId] 为展示的第一条消息 ID，为空时使用默认值。
  Future<void> loadMessage({int? startMsgId}) async {
    final msgs = await _service.fetchInitialMessages(startMsgId: startMsgId);
    _messages = msgs;
    _isLoadingInitial = false;
    notifyListeners();
  }

  /// 加载更多历史消息，插入列表头部。
  Future<void> loadMoreHistory() async {
    if (_isLoadingHistory || !_hasMoreHistory) return;
    final oldestMsgId = messages.firstOrNull?.id;
    if (oldestMsgId == null) return;
    _isLoadingHistory = true;
    notifyListeners();

    final list = await _service.fetchHistoryMessages(oldestMsgId);
    _messages.insertAll(0, list);
    _isLoadingHistory = false;
    _hasMoreHistory = list.isNotEmpty;
    notifyListeners();
  }

  /// 拉取新消息，追加到列表末尾。
  Future<void> loadNewMessage() async {
    if (_isLoadingNewMessage) return;
    final newestMsgId = messages.lastOrNull?.id;
    if (newestMsgId == null) return;
    _isLoadingNewMessage = true;
    notifyListeners();

    final list = await _service.fetchNewMessage(newestMsgId);
    _messages.addAll(list);
    _isLoadingNewMessage = false;
    notifyListeners();
  }

  /// 同步追加一条新消息到列表末尾。
  void addNewMessage() {
    final newestMsgId = messages.lastOrNull?.id;
    if (newestMsgId == null) return;
    final message = _service.newMessage(newestMsgId);
    _messages.add(message);
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
    await loadMessage();
  }
}
