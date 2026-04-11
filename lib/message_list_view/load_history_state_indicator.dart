import 'package:flutter/material.dart';

/// 历史消息加载状态指示器。
/// [visible] 为 false 时不占空间。
/// [isLoading] 为 true 时显示加载中，为 false 时显示无更多历史。
/// 两种状态的整体高度保持一致。
class LoadHistoryStateIndicator extends StatelessWidget {
  final bool isLoading;

  const LoadHistoryStateIndicator({super.key, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: double.infinity,
      child: Stack(
        children: [
          Center(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.grey[400],
                  ),
                ),
              const SizedBox(width: 8),
              if (!isLoading)
                Text(
                  '没有更多消息了',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                )
            ]),
          )
        ],
      ),
    );
  }
}
