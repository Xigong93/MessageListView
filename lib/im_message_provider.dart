import 'package:message_list_view/message_list_view.dart';

import 'message.dart';
import 'mock_message_service.dart';

/// IM 场景的消息数据提供者，实现 [MessageProvider] 抽象。
///
/// 只负责纯数据获取，不持有任何状态。加载协调逻辑由
/// [MessageListController] 统一处理。
class ImMessageProvider extends MessageProvider<Message> {
  final _service = MockMessageService();
  final int? _startMsgId;

  ImMessageProvider({int? startMsgId}) : _startMsgId = startMsgId;

  @override
  Future<InitialResult<Message>> fetchInitial() async {
    final list = await _service.fetchInitialMessages(startMsgId: _startMsgId);
    return InitialResult(
      messages: list,
      // 加载最新消息时不存在更新方向的数据；从历史位置加载时可能有
      hasMoreNew: _startMsgId != null,
    );
  }

  @override
  Future<List<Message>> fetchHistory(Message oldestItem) =>
      _service.fetchHistoryMessages(oldestItem.id);

  @override
  Future<List<Message>> fetchNew(Message newestItem) =>
      _service.fetchNewMessage(newestItem.id);

  /// demo 特有：同步生成一条紧随 [newestId] 之后的新消息。
  Message createMessage(int newestId) => _service.newMessage(newestId);
}
