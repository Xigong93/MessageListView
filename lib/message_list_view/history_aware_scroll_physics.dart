import 'package:flutter/material.dart';

/// 在内容顶部插入历史消息后，通过 [adjustPositionForNewDimensions] 自动补偿
/// 滚动偏移，使已有内容保持视觉位置不变。
///
/// 工作原理：历史消息插入后，视图层将 [needsCorrection] 置为返回 true。
/// 下一次布局时 [adjustPositionForNewDimensions] 检测到内容增长，
/// 直接在布局阶段将 pixels 增加 delta，避免任何闪烁。
class HistoryAwareScrollPhysics extends ScrollPhysics {
  /// 返回 true 表示本次布局需要补偿（调用后自动消费，下次返回 false）。
  final bool Function() needsCorrection;

  const HistoryAwareScrollPhysics({
    required this.needsCorrection,
    super.parent,
  });

  @override
  HistoryAwareScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return HistoryAwareScrollPhysics(
      needsCorrection: needsCorrection,
      parent: buildParent(ancestor),
    );
  }

  @override
  double adjustPositionForNewDimensions({
    required ScrollMetrics oldPosition,
    required ScrollMetrics newPosition,
    required bool isScrolling,
    required double velocity,
  }) {
    final delta = newPosition.maxScrollExtent - oldPosition.maxScrollExtent;
    if (delta > 0 && needsCorrection()) {
      return newPosition.pixels + delta;
    }
    return super.adjustPositionForNewDimensions(
      oldPosition: oldPosition,
      newPosition: newPosition,
      isScrolling: isScrolling,
      velocity: velocity,
    );
  }
}
