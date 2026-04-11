import 'message.dart';

class MockMessageService {
  static int _idCounter = 0;

  static String _nextId() => 'msg_${++_idCounter}';

  static const _aliceLines = [
    '你好！最近怎么样？',
    '昨天看了部很棒的电影',
    '周末有空一起吃饭吗？',
    '好的，你来定地方吧',
    '我刚买了新手机，拍照超棒',
    '今天天气真好，适合出去走走',
    '工作忙吗？最近很少见你',
    '有空来我这边玩啊',
    '刚刚吃了顿超棒的火锅',
    '你有没有推荐的电影？',
    '我最近在学一门新技术，感觉挺难的',
    '终于到周末了！',
    '下午打算去逛逛，要一起吗？',
    '你最近在看什么书？',
    '昨晚睡得很晚，今天好困',
    '哈哈，是的',
    '好久不见了呢',
    '要不要一起去爬山？',
    '我发现了一家很好吃的餐厅',
    '最近有什么新鲜事吗？',
  ];

  static const _myLines = [
    '还不错，你呢？',
    '哦，什么电影？',
    '好啊，周六下午怎么样？',
    '可以，我来找地方',
    '羡慕，我也想换了',
    '对啊，要不要出去走走？',
    '还行，项目有点多',
    '好，下次约',
    '哇，在哪里吃的？',
    '最近在看科幻的',
    '慢慢来，坚持就好',
    '太好了！',
    '可以啊，下午几点？',
    '在看《三体》，非常推荐',
    '早点休息啊',
    '有啊，下周要出差',
    '好久不见！',
    '好啊，周末去',
    '在哪家？',
    '没什么特别的，你呢？',
  ];

  int _aliceIdx = 0;
  int _myIdx = 0;
  int _historyBatchCount = 0;
  DateTime _historyAnchorTime = DateTime.now().subtract(const Duration(hours: 1));

  static const _maxHistoryBatches = 10;

  Message _makeAliceMessage(DateTime time) {
    final content = _aliceLines[_aliceIdx % _aliceLines.length];
    _aliceIdx++;
    return Message(
      id: _nextId(),
      content: content,
      senderId: 'alice',
      senderName: 'Alice',
      isMe: false,
      timestamp: time,
    );
  }

  Message _makeMyMessage(DateTime time) {
    final content = _myLines[_myIdx % _myLines.length];
    _myIdx++;
    return Message(
      id: _nextId(),
      content: content,
      senderId: 'me',
      senderName: '我',
      isMe: true,
      timestamp: time,
    );
  }

  /// 生成 count 条消息，最新一条时间约为 endTime
  List<Message> _generateConversation(int count, DateTime endTime) {
    final messages = <Message>[];
    var time = endTime.subtract(Duration(minutes: count * 3));
    for (int i = 0; i < count; i++) {
      time = time.add(const Duration(minutes: 3));
      // 对话节奏：Alice 说、我回、Alice 说两条、我回…
      final isMe = i % 3 == 1;
      messages.add(isMe ? _makeMyMessage(time) : _makeAliceMessage(time));
    }
    return messages;
  }

  /// 首次加载：模拟 1.5s 网络延迟，返回 20 条最近消息
  Future<List<Message>> fetchInitialMessages() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    final now = DateTime.now();
    return _generateConversation(20, now.subtract(const Duration(minutes: 5)));
  }

  /// 加载历史消息：模拟 1s 延迟，每次返回 15 条，最多加载 3 批
  Future<({List<Message> messages, bool hasMore})> fetchHistoryMessages() async {
    if (_historyBatchCount >= _maxHistoryBatches) {
      return (messages: <Message>[], hasMore: false);
    }

    await Future.delayed(const Duration(milliseconds: 1000));

    final endTime = _historyAnchorTime;
    _historyAnchorTime = endTime.subtract(const Duration(hours: 1));
    _historyBatchCount++;

    final messages = _generateConversation(15, endTime);
    final hasMore = _historyBatchCount < _maxHistoryBatches;
    return (messages: messages, hasMore: hasMore);
  }

  /// 拉取一条新消息：模拟 800ms 网络延迟
  Future<Message> fetchNewMessage() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _makeAliceMessage(DateTime.now());
  }
}
