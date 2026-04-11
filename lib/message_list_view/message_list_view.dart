import 'package:flutter/material.dart';

import '../message_bubble.dart';
import 'load_history_state_indicator.dart';
import 'load_more_status.dart';
import 'load_new_state_indicator.dart';
import 'message_list_controller.dart';

/// 消息列表视图，负责消息展示、滚动管理和加载触发。
/// 使用 [CustomScrollView] 的 center 机制实现双向滚动：
/// - center 之前：历史消息（向上增长，不影响正方向滚动位置）
/// - center 之后：当前消息 + 新消息（向下增长）
class MessageListView extends StatefulWidget {
  final MessageListController controller;

  const MessageListView({
    super.key,
    required this.controller,
  });

  @override
  State<MessageListView> createState() => _MessageListViewState();
}

class _MessageListViewState extends State<MessageListView> {
  final _scrollController = ScrollController();
  final _centerKey = UniqueKey();

  MessageListController get _controller => widget.controller;

  // ───────────────────────────── 生命周期 ─────────────────────────────

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ───────────────────────────── 滚动事件 ─────────────────────────────

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;

    // 接近反方向顶端 → 加载更多历史
    if (position.pixels - position.minScrollExtent <= 80 &&
        _controller.loadHistoryStatus.value == LoadMoreStatus.idle &&
        !_controller.isLoadingInitial.value) {
      _controller.loadMoreHistory();
    }

    // 接近正方向底端 → 加载更多新消息
    if (position.maxScrollExtent - position.pixels <= 80 &&
        _controller.loadNewStatus.value == LoadMoreStatus.idle &&
        !_controller.isLoadingInitial.value) {
      _controller.loadNewMessage();
    }
  }

  // ───────────────────────────── UI ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildScrollView(),
        _buildCenterLoading(),
      ],
    );
  }

  Widget _buildScrollView() {
    return CustomScrollView(
      controller: _scrollController,
      center: _centerKey,
      anchor: 0.0,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        // ← 反方向（向上增长）
        _buildHistoryLoadingBar(),
        _buildHistoryMessageList(),

        // 锚点（offset = 0）
        SliverToBoxAdapter(key: _centerKey, child: const SizedBox.shrink()),

        // → 正方向（向下增长）
        _buildMessageList(),
        _buildNewLoadingBar(),
      ],
    );
  }

  Widget _buildCenterLoading() {
    return ValueListenableBuilder(
      valueListenable: _controller.isLoadingInitial,
      builder: (_, visible, __) {
        return Visibility(
          visible: visible,
          child: Center(
            child: CircularProgressIndicator(
              color: Colors.grey[400],
            ),
          ),
        );
      },
    );
  }

  // ───────────── 反方向 slivers ─────────────

  Widget _buildHistoryLoadingBar() {
    return ValueListenableBuilder(
      valueListenable: _controller.loadHistoryStatus,
      builder: (_, state, __) {
        return SliverToBoxAdapter(
          child: LoadHistoryStateIndicator(status: state),
        );
      },
    );
  }

  Widget _buildHistoryMessageList() {
    return ValueListenableBuilder(
      valueListenable: _controller.historyMessages,
      builder: (_, historyMessages, __) {
        return SliverList.builder(
          itemCount: historyMessages.length,
          itemBuilder: (context, index) =>
              MessageBubble(message: historyMessages[index]),
        );
      },
    );
  }

  // ───────────── 正方向 slivers ─────────────

  Widget _buildMessageList() {
    return ValueListenableBuilder(
      valueListenable: _controller.messages,
      builder: (_, messages, __) {
        return SliverList.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) =>
              MessageBubble(message: messages[index]),
        );
      },
    );
  }

  Widget _buildNewLoadingBar() {
    return ValueListenableBuilder(
      valueListenable: _controller.loadNewStatus,
      builder: (_, state, __) {
        return SliverToBoxAdapter(
          child: LoadNewStateIndicator(status: state),
        );
      },
    );
  }
}
