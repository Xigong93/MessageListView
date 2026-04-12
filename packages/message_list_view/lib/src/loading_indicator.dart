import 'package:flutter/material.dart';

import 'load_more_status.dart';

/// 顶部加载指示器（历史消息方向）。
/// 三种状态均显示 40px 高的指示器。
class TopLoadingIndicator extends StatelessWidget {
  final LoadMoreStatus status;
  final VoidCallback onRetry;

  const TopLoadingIndicator({
    super.key,
    required this.status,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return _LoadingIndicatorCell(
      status: status,
      idleText: '下拉加载更多消息',
      noMoreText: '没有更多历史消息',
      onRetry: onRetry,
    );
  }
}

/// 底部加载指示器（新消息方向）。
/// [LoadMoreStatus.noMore] 时通过 [AnimatedSize] 收缩至 0 高度。
class BottomLoadingIndicator extends StatelessWidget {
  final LoadMoreStatus status;
  final VoidCallback onRetry;

  const BottomLoadingIndicator({
    super.key,
    required this.status,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: status == LoadMoreStatus.noMore
          ? const SizedBox(width: double.infinity, height: 0)
          : _LoadingIndicatorCell(
              status: status,
              idleText: '上拉加载更多消息',
              noMoreText: '',
              onRetry: onRetry,
            ),
    );
  }
}

// ───────────────────────────── 共用组件 ─────────────────────────────

const _textStyle = TextStyle(color: Colors.grey, fontSize: 13);

class _LoadingIndicatorCell extends StatelessWidget {
  final LoadMoreStatus status;
  final String idleText;
  final String noMoreText;
  final VoidCallback onRetry;

  const _LoadingIndicatorCell({
    required this.status,
    required this.idleText,
    required this.noMoreText,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      width: double.infinity,
      child: Center(
        child: switch (status) {
          LoadMoreStatus.loading => _buildLoading(),
          LoadMoreStatus.idle => Text(idleText, style: _textStyle),
          LoadMoreStatus.noMore => Text(noMoreText, style: _textStyle),
          LoadMoreStatus.error => _buildError(),
        },
      ),
    );
  }

  SizedBox _buildLoading() {
    return SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildError() {
    return GestureDetector(
      onTap: onRetry,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
        child: const Text('加载失败，点击重试', style: _textStyle),
      ),
    );
  }
}
