import 'package:flutter/material.dart';

import 'load_more_status.dart';

/// 历史消息加载状态指示器，根据 [status] 显示三种 UI：
/// - [LoadMoreStatus.idle]：提示文字"下拉加载更多消息"
/// - [LoadMoreStatus.loading]：加载动画
/// - [LoadMoreStatus.noMore]：提示文字"没有更多历史消息"
class LoadHistoryStateIndicator extends StatelessWidget {
  final LoadMoreStatus status;

  const LoadHistoryStateIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: double.infinity,
      child: Center(
        child: switch (status) {
          LoadMoreStatus.loading => SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey[400],
              ),
            ),
          LoadMoreStatus.idle => const Text(
              '下拉加载更多消息',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          LoadMoreStatus.noMore => const Text(
              '没有更多历史消息',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
        },
      ),
    );
  }
}
