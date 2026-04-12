import 'package:message_list_view/message_list_view.dart';

import 'message.dart';
import 'mock_message_service.dart';

/// IM 场景的消息数据提供者，实现 [MessageProvider] 抽象。
///
/// 只负责纯数据获取，不持有任何状态。加载协调逻辑由
/// [MessageListController] 统一处理。
class ImMessageProvider extends MessageProvider<Message> {
  final _service = MockMessageService();
  int? startMsgId;

  /// 为 true 时所有 fetch 方法均抛出异常，用于模拟加载失败。
  bool shouldFail = false;

  ImMessageProvider({this.startMsgId});

  Future<void> _checkFail() async {
    if (shouldFail) {
      await Future.delayed(Duration(milliseconds: 400));
      throw Exception('模拟加载失败');
    }
  }

  @override
  Future<InitialResult<Message>> fetchInitial() async {
    await _checkFail();
    final list = await _service.fetchInitialMessages(startMsgId: startMsgId);
    return InitialResult(
      messages: list,
      // 加载最新消息时不存在更新方向的数据；从历史位置加载时可能有
      hasMoreNew: startMsgId != null,
    );
  }

  @override
  Future<List<Message>> fetchHistory(Message oldestItem) async {
    await _checkFail();
    return _service.fetchHistoryMessages(oldestItem.id);
  }

  @override
  Future<List<Message>> fetchNew(Message newestItem) async {
    await _checkFail();
    return _service.fetchNewMessage(newestItem.id);
  }

  /// demo 特有：同步生成一条紧随 [newestId] 之后的新消息。
  Message createMessage(int newestId) => _service.newMessage(newestId);
}
