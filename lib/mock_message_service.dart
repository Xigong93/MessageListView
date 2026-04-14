import 'message.dart';

class MockMessageService {
  static const _pageSize = 20;

  /// 最新一条初始消息的 ID
  static const _newestId = 100;

  // 基准时间：2025-01-01 08:00
  static final _baseTime = DateTime(2025, 1, 1, 8, 0);

  Message _makeMessage(int id) {
    // text 50%, image/video/voice 各约 16.7%
    const types = [
      MessageType.text,
      MessageType.text,
      MessageType.text,
      MessageType.image,
      MessageType.video,
      MessageType.voice,
    ];
    final type = types[id % types.length];
    // 每组 5 条消息间隔 30s，组间额外加 5 分钟，使时间戳效果可见
    final offsetSeconds = (id ~/ 5) * 5 * 60 + (id % 5) * 30;
    return Message(
      id: id,
      content: '第${id + 1}条消息',
      type: type,
      sendTime: _baseTime.add(Duration(seconds: offsetSeconds)),
    );
  }

  /// 首次加载，[startMsgId] 为展示的第一条消息 ID，为空时使用默认值。
  Future<List<Message>> fetchInitialMessages({int? startMsgId}) async {
    await delay();
    final start = startMsgId ?? _newestId;
    return _batch((index) => start + index);
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
