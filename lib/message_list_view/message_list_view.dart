import 'package:flutter/material.dart';

import '../message_bubble.dart';
import 'history_aware_scroll_physics.dart';
import 'load_history_state_indicator.dart';
import 'load_more_status.dart';
import 'load_new_state_indicator.dart';
import 'message_list_controller.dart';
import 'scroll_to_bottom_button.dart';

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

  // HistoryAwareScrollPhysics 所需的补偿标记
  bool _needsHistoryCorrection = false;

  MessageListController get _controller => widget.controller;

  bool _consumeHistoryCorrection() {
    if (_needsHistoryCorrection) {
      _needsHistoryCorrection = false;
      return true;
    }
    return false;
  }

  // ───────────────────────────── 生命周期 ─────────────────────────────

  @override
  void initState() {
    super.initState();
    _addControllerListeners();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant MessageListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _removeControllerListeners(oldWidget.controller);
      _addControllerListeners();
    }
  }

  @override
  void dispose() {
    _removeControllerListeners(_controller);
    _scrollController.dispose();
    super.dispose();
  }

  void _addControllerListeners() {}

  void _removeControllerListeners(MessageListController c) {}

  // ───────────────────────────── 控制器变化响应 ─────────────────────────────

  void triggerRebuild() {
    if (mounted) setState(() {});
  }

  // ───────────────────────────── 滚动动作 ─────────────────────────────

  void _scheduleScrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animate) {
        _scrollController.animateTo(target,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      } else {
        _scrollController.jumpTo(target);
      }
    });
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

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  // ───────────────────────────── UI ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        buildScrollView(),
        _centerLoading(),
      ],
    );
  }

  CustomScrollView buildScrollView() {
    return CustomScrollView(
      controller: _scrollController,
      physics: HistoryAwareScrollPhysics(
        needsCorrection: _consumeHistoryCorrection,
        parent: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
      ),
      slivers: [
        // 顶部：历史消息加载状态
        _topLoadingBar(),
        // 中间：消息列表
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          sliver: _buildMessageList(),
        ),
        // 底部：新消息加载状态
        _bottomLoadingBar(),
      ],
    );
  }

  Widget _centerLoading() {
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
        });
  }

  ValueListenableBuilder<LoadMoreStatus> _topLoadingBar() {
    return ValueListenableBuilder(
        valueListenable: _controller.loadHistoryStatus,
        builder: (_, state, __) {
          return SliverToBoxAdapter(
            child: LoadHistoryStateIndicator(
              status: state,
            ),
          );
        });
  }

  ValueListenableBuilder<LoadMoreStatus> _bottomLoadingBar() {
    return ValueListenableBuilder(
        valueListenable: _controller.loadNewStatus,
        builder: (_, state, __) {
          return SliverToBoxAdapter(
            child: LoadNewStateIndicator(
              status: state,
            ),
          );
        });
  }

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
}
