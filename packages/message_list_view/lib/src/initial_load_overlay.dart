import 'package:flutter/material.dart';

import 'initial_load_status.dart';

/// 首次加载的全屏覆盖层。
///
/// - [InitialLoadStatus.loading]：显示居中加载圈。
/// - [InitialLoadStatus.error]：显示"加载失败 + 点击重试"。
/// - [InitialLoadStatus.success]：不渲染任何内容。
class InitialLoadOverlay extends StatelessWidget {
  final InitialLoadStatus status;
  final VoidCallback onRetry;

  const InitialLoadOverlay({
    super.key,
    required this.status,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      InitialLoadStatus.loading => _buildLoading(),
      InitialLoadStatus.error => _buildError(),
      InitialLoadStatus.success => const SizedBox.shrink(),
    };
  }

  Center _buildLoading() {
    return Center(
      child: CircularProgressIndicator(color: Colors.grey[400]),
    );
  }

  Center _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '加载失败',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text('点击重试'),
          ),
        ],
      ),
    );
  }
}
