import 'package:flutter/material.dart';

import 'history_aware_scroll_physics.dart';

/// 支持头部插入内容后自动保持滚动位置的 CustomScrollView。
///
/// 当 [prependNotifier] 发出通知时，视为「头部有新内容插入」，
/// 下一次布局会自动补偿滚动偏移，使已有内容保持视觉位置不变。
class PrependAwareScrollView extends StatefulWidget {
  final ScrollController controller;

  /// 每次通知时触发一次滚动位置补偿。
  final Listenable prependNotifier;

  /// 额外的滚动物理效果，会作为 parent 传入内部 physics。
  final ScrollPhysics? physics;

  final List<Widget> slivers;

  const PrependAwareScrollView({
    super.key,
    required this.controller,
    required this.prependNotifier,
    this.physics,
    required this.slivers,
  });

  @override
  State<PrependAwareScrollView> createState() =>
      _PrependAwareScrollViewState();
}

class _PrependAwareScrollViewState extends State<PrependAwareScrollView> {
  bool _needsCorrection = false;

  bool _consumeCorrection() {
    if (_needsCorrection) {
      _needsCorrection = false;
      return true;
    }
    return false;
  }

  void _onPrepend() {
    _needsCorrection = true;
  }

  @override
  void initState() {
    super.initState();
    widget.prependNotifier.addListener(_onPrepend);
  }

  @override
  void didUpdateWidget(covariant PrependAwareScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prependNotifier != widget.prependNotifier) {
      oldWidget.prependNotifier.removeListener(_onPrepend);
      widget.prependNotifier.addListener(_onPrepend);
    }
  }

  @override
  void dispose() {
    widget.prependNotifier.removeListener(_onPrepend);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: widget.controller,
      physics: HistoryAwareScrollPhysics(
        needsCorrection: _consumeCorrection,
        parent: widget.physics,
      ),
      slivers: widget.slivers,
    );
  }
}
