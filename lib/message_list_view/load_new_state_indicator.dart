import 'package:flutter/material.dart';

/// 新消息加载状态指示器。
/// [isLoading] 为 true 时显示加载中，为 false 时高度为 0（不占空间）。
class LoadNewStateIndicator extends StatelessWidget {
  final bool isLoading;

  const LoadNewStateIndicator({super.key, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('正在获取新消息...',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
