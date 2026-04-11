import 'package:flutter/material.dart';

import '../message_bubble.dart';
import 'load_history_state_indicator.dart';
import 'load_more_status.dart';
import 'load_new_state_indicator.dart';
import 'message_list_controller.dart';
import 'prepend_aware_scroll_view.dart';

/// 消息列表视图，负责消息展示、滚动管理和加载触发。
/// 页面只需传入 [MessageListController]，不处理列表相关的业务逻辑。
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

    // 滚到顶部附近时拉取历史
    if (_scrollController.offset <= 80 &&
        _controller.loadHistoryStatus.value == LoadMoreStatus.idle &&
        !_controller.isLoadingInitial.value) {
      _controller.loadMoreHistory();
    }

    // 滚到底部附近时拉取新消息
    final maxExtent = _scrollController.position.maxScrollExtent;
    if (_scrollController.offset >= maxExtent - 80 &&
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
    return PrependAwareScrollView(
      controller: _scrollController,
      prependNotifier: _controller.prependNotifier,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        _buildTopLoadingBar(),
        _buildMessageList(),
        _buildBottomLoadingBar(),
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

  Widget _buildTopLoadingBar() {
    return ValueListenableBuilder(
      valueListenable: _controller.loadHistoryStatus,
      builder: (_, state, __) {
        return SliverToBoxAdapter(
          child: LoadHistoryStateIndicator(status: state),
        );
      },
    );
  }

  Widget _buildBottomLoadingBar() {
    return ValueListenableBuilder(
      valueListenable: _controller.loadNewStatus,
      builder: (_, state, __) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              LoadNewStateIndicator(status: state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageList() {
    return ValueListenableBuilder(
      valueListenable: _controller.messages,
      builder: (_, messages, __) {
        return SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          sliver: SliverList.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) =>
                MessageBubble(message: messages[index]),
          ),
        );
      },
    );
  }
}
