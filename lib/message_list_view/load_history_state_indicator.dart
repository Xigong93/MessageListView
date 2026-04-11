import 'package:flutter/material.dart';

/// 历史消息加载状态指示器。
/// [visible] 为 false 时不占空间。
/// [isLoading] 为 true 时显示加载中，为 false 时显示无更多历史。
/// 两种状态的整体高度保持一致。
class LoadHistoryStateIndicator extends StatelessWidget {
  final bool isLoading;
  final bool visible;

  const LoadHistoryStateIndicator({
    super.key,
    required this.isLoading,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading) ...[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              isLoading ? '加载更多消息...' : '没有更多消息了',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
