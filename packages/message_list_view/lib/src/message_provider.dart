/// 消息数据提供者抽象类，应用层继承此类。
///
/// 只负责数据获取，不持有任何状态。加载协调（状态机管理）由
/// [MessageListController] 统一完成。
abstract class MessageProvider<T> {
  /// 首次加载。初始位置等业务参数由子类构造时自行持有，框架无需感知。
  Future<InitialResult<T>> fetchInitial();

  /// 加载历史消息（向上方向）。[oldestItem] 为当前最旧的一条消息。
  /// 返回列表按升序排列，框架负责反转后插入历史列表。
  Future<List<T>> fetchHistory(T oldestItem);

  /// 加载新消息（向下方向）。[newestItem] 为当前最新的一条消息。
  Future<List<T>> fetchNew(T newestItem);

  /// 释放资源。默认为空实现，子类按需重写。
  void dispose() {}
}

/// 首次加载的结果。
class InitialResult<T> {
  /// 正方向消息列表，按时间升序排列。
  final List<T> messages;

  /// 是否还有更新方向的消息可以加载。
  /// 加载最新消息时为 false，从历史位置加载时为 true。
  final bool hasMoreNew;

  const InitialResult({required this.messages, this.hasMoreNew = true});
}
