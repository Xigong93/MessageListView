import 'package:flutter/material.dart';

/// 在内容顶部插入历史消息后，通过 [adjustPositionForNewDimensions] 自动补偿
/// 滚动偏移，使已有内容保持视觉位置不变。
class HistoryAwareScrollPhysics extends ScrollPhysics {
  final double Function() getCorrection;

  const HistoryAwareScrollPhysics({
    required this.getCorrection,
    super.parent,
  });

  @override
  HistoryAwareScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return HistoryAwareScrollPhysics(
      getCorrection: getCorrection,
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
    final contentGrew =
        newPosition.maxScrollExtent > oldPosition.maxScrollExtent;
    if (contentGrew) {
      final correction = getCorrection();
      if (correction != 0) return newPosition.pixels + correction;
    }
    return super.adjustPositionForNewDimensions(
      oldPosition: oldPosition,
      newPosition: newPosition,
      isScrolling: isScrolling,
      velocity: velocity,
    );
  }
}
