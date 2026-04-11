import 'package:flutter/widgets.dart';

import 'message_data_source.dart';

/// 消息列表的统一控制器，作为对外门面持有 [MessageDataSource] 和 [ScrollController]。
///
/// 外部通过此对象完成数据加载和滚动控制，无需直接接触 [MessageDataSource]。
class MessageListController<T> {
  final MessageDataSource<T> dataSource;
  final scrollController = ScrollController();

  MessageListController(this.dataSource);

  /// 首次加载消息并在布局就绪后自动滚动到目标位置。
  ///
  /// - [startMsgId] 为空：加载最新消息，完成后滚动到底部。
  /// - [startMsgId] 不为空：加载指定位置消息，完成后保持顶部。
  Future<void> loadMessage({int? startMsgId}) async {
    await dataSource.loadMessage(startMsgId: startMsgId);
    // 等待当前帧或下一帧完成
    await WidgetsBinding.instance.endOfFrame;
    if (startMsgId == null) {
      scrollToBottom(anim: false);
    }
  }

  /// 滚动到顶部。
  Future<void> scrollToTop({bool anim = true}) async {
    if (!scrollController.hasClients) return;
    // 等待当前帧或下一帧完成
    await WidgetsBinding.instance.endOfFrame;
    final target = scrollController.position.minScrollExtent;
    if (anim) {
      await _animateTo(target);
    } else {
      scrollController.jumpTo(target);
    }
  }

  /// 滚动到底部。
  Future<void> scrollToBottom({bool anim = true}) async {
    if (!scrollController.hasClients) return;
    // 等待当前帧或下一帧完成
    await WidgetsBinding.instance.endOfFrame;
    final target = scrollController.position.maxScrollExtent;
    if (anim) {
      await _animateTo(target);
    } else {
      scrollController.jumpTo(target);
    }
  }

  Future<void> _animateTo(double target) async {
    await scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  /// 列表当前是否处于底部。
  bool get atBottom {
    if (!scrollController.hasClients) return false;
    final position = scrollController.position;
    return position.pixels >= position.maxScrollExtent - 1;
  }

  void dispose() {
    dataSource.dispose();
    scrollController.dispose();
  }
}
