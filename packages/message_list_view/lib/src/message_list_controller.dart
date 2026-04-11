import 'package:flutter/foundation.dart';

import 'load_more_status.dart';

/// 双向消息列表的数据控制器抽象。
///
/// 泛型 [T] 为列表项的数据类型。子类负责实现具体的加载逻辑，
/// 视图层通过 [ValueNotifier] 订阅状态变化。
abstract class MessageListController<T> {
  // ───────────────────────────── 状态 ─────────────────────────────

  /// 正方向列表项（初始加载 + 新增），按时间升序排列。
  final ValueNotifier<List<T>> messages = ValueNotifier([]);

  /// 反方向列表项（历史），按时间降序排列（最新在前，最旧在后）。
  /// 在双向 ScrollView 中，index 0 紧邻 center，向上增长。
  final ValueNotifier<List<T>> historyMessages = ValueNotifier([]);

  /// 是否正在进行首次加载。
  final ValueNotifier<bool> isLoadingInitial = ValueNotifier(true);

  /// 加载历史消息的状态。
  final ValueNotifier<LoadMoreStatus> loadHistoryStatus =
      ValueNotifier(LoadMoreStatus.idle);

  /// 加载新消息的状态。
  final ValueNotifier<LoadMoreStatus> loadNewStatus =
      ValueNotifier(LoadMoreStatus.idle);

  /// 首次加载完成后是否应滚动到底部。
  bool get shouldScrollToBottom;

  // ───────────────────────────── 加载方法 ─────────────────────────────

  /// 加载更多历史数据（向上方向）。由视图在滚动接近顶部时调用。
  Future<void> loadMoreHistory();

  /// 加载更多新数据（向下方向）。由视图在滚动接近底部时调用。
  Future<void> loadNewMessage();

  // ───────────────────────────── 资源释放 ─────────────────────────────

  /// 释放资源。子类重写时应调用 super.dispose()。
  @mustCallSuper
  void dispose() {
    messages.dispose();
    historyMessages.dispose();
    isLoadingInitial.dispose();
    loadHistoryStatus.dispose();
    loadNewStatus.dispose();
  }
}
