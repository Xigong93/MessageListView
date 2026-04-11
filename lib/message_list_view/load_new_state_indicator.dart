import 'package:flutter/material.dart';

import 'load_more_status.dart';

/// 新消息加载状态指示器，根据 [status] 显示三种 UI：
/// - [LoadMoreStatus.idle]：提示文字"上拉加载更多消息"
/// - [LoadMoreStatus.loading]：加载动画
/// - [LoadMoreStatus.noMore]：高度动画收缩至 0
class LoadNewStateIndicator extends StatelessWidget {
  final LoadMoreStatus status;

  const LoadNewStateIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: status == LoadMoreStatus.noMore
          ? const SizedBox(width: double.infinity, height: 0)
          : SizedBox(
              height: 40,
              width: double.infinity,
              child: Center(
                child: status == LoadMoreStatus.loading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.grey[400],
                        ),
                      )
                    : const Text(
                        '上拉加载更多消息',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
              ),
            ),
    );
  }
}
