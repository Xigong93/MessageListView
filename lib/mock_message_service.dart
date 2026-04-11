import 'message.dart';

class MockMessageService {
  static const _pageSize = 20;

  /// 最新一条初始消息的 ID
  static const _newestId = 100;

  Message _makeMessage(int id) {
    return Message(
      id: id,
      content: '第$id条消息',
    );
  }

  /// 首次加载
  Future<List<Message>> fetchInitialMessages() async {
    await delay();
    return _batch((index) => index + _newestId);
  }

  Future<void> delay() => Future.delayed(const Duration(milliseconds: 1000));

  /// 加载历史消息
  Future<List<Message>> fetchHistoryMessages(int startMsgId) async {
    await delay();
    if (startMsgId <= 0) {
      return [];
    } else {
      return _batch((index) => startMsgId - index - 1).reversed.toList();
    }
  }

  /// 拉取一条新消息：模拟 800ms 网络延迟
  Future<List<Message>> fetchNewMessage(int startMsgId) async {
    await delay();
    if (startMsgId >= 200) {
      return [];
    } else {
      return _batch((index) => index + startMsgId + 1);
    }
  }

  List<Message> _batch(int Function(int index) idCreator) {
    return List.generate(_pageSize, (index) => _makeMessage(idCreator(index)));
  }

  Message newMessage(int startMsgId) {
    return _makeMessage(startMsgId + 1);
  }
}
