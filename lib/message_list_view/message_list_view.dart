import 'package:flutter/material.dart';

import '../message_bubble.dart';
import '../message_list_controller.dart';
import 'history_aware_scroll_physics.dart';
import 'load_history_state_indicator.dart';
import 'load_new_state_indicator.dart';
import 'scroll_to_bottom_button.dart';

/// 消息列表视图，负责消息展示、滚动管理和加载触发。
/// 页面只需传入 [MessageListController]，不处理列表相关的业务逻辑。
class MessageListView extends StatefulWidget {
  final MessageListController controller;

  /// 首次加载完成后是否滚动到底部，false 则停留在顶部。
  final bool scrollToBottomOnLoad;

  const MessageListView({
    super.key,
    required this.controller,
    this.scrollToBottomOnLoad = true,
  });

  @override
  State<MessageListView> createState() => _MessageListViewState();
}

class _MessageListViewState extends State<MessageListView> {
  final _scrollController = ScrollController();

  // 滚动 UI 状态
  bool _showScrollToBottom = false;
  int _unreadCount = 0;

  // 控制器状态转换快照
  bool _wasLoadingInitial = true;
  bool _wasLoadingHistory = false;
  int _previousMessageCount = 0;

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
    _controller.addListener(_onControllerChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant MessageListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _scrollController.dispose();
    super.dispose();
  }

  // ───────────────────────────── 控制器变化响应 ─────────────────────────────

  void _onControllerChanged() {
    final c = _controller;

    // 控制器重置（重新进入初始加载）→ 清空视图状态
    if (c.isLoadingInitial) {
      _showScrollToBottom = false;
      _unreadCount = 0;
      _wasLoadingInitial = true;
      _wasLoadingHistory = false;
      _previousMessageCount = 0;
      if (mounted) setState(() {});
      return;
    }

    if (_wasLoadingInitial && !c.isLoadingInitial) {
      // ① 首次加载完成 → 根据配置跳到底部或顶部
      if (widget.scrollToBottomOnLoad) {
        _scheduleScrollToBottom(animate: false);
      }
    } else if (_wasLoadingHistory && !c.isLoadingHistory) {
      // ② 历史加载完成 → 设置标记，布局阶段由 physics 自动补偿
      _needsHistoryCorrection = true;
    } else if (!c.isLoadingInitial &&
        !c.isLoadingHistory &&
        c.messages.length > _previousMessageCount) {
      // ③ 新消息追加 → 在底部则跟随，否则累积未读
      _handleMessageAppended();
    }

    _wasLoadingInitial = c.isLoadingInitial;
    _wasLoadingHistory = c.isLoadingHistory;
    _previousMessageCount = c.messages.length;

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

  void _handleMessageAppended() {
    final isAtBottom = _scrollController.hasClients &&
        _scrollController.offset >=
            _scrollController.position.maxScrollExtent - 100;
    if (isAtBottom) {
      _scheduleScrollToBottom();
    } else {
      _unreadCount++;
    }
  }

  // ───────────────────────────── 滚动事件 ─────────────────────────────

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    // 滚到顶部附近时拉取历史
    if (_scrollController.offset <= 80 &&
        !_controller.isLoadingHistory &&
        _controller.hasMoreHistory &&
        !_controller.isLoadingInitial) {
      _controller.loadMoreHistory();
    }

    // 更新"滚到底部"按钮
    final isNearBottom = _scrollController.offset >=
        _scrollController.position.maxScrollExtent - 100;
    final shouldShow = !isNearBottom && _controller.messages.isNotEmpty;

    if (_showScrollToBottom != shouldShow ||
        (isNearBottom && _unreadCount > 0)) {
      setState(() {
        _showScrollToBottom = shouldShow;
        if (isNearBottom) _unreadCount = 0;
      });
    }
  }

  void _scrollToBottom() {
    setState(() => _unreadCount = 0);
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
        NotificationListener<OverscrollNotification>(
          onNotification: (n) {
            if (n.overscroll > 0 && !_controller.isLoadingNewMessage) {
              _controller.loadNewMessage();
            }
            return false;
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: HistoryAwareScrollPhysics(
              needsCorrection: _consumeHistoryCorrection,
              parent: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
            ),
            slivers: [
              // 顶部：历史消息加载状态
              SliverToBoxAdapter(
                child: LoadHistoryStateIndicator(
                  isLoading: _controller.isLoadingHistory,
                  visible: true,
                ),
              ),
              // 中间：消息列表
              SliverPadding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                sliver: SliverList.builder(
                  itemCount: _controller.messages.length,
                  itemBuilder: (context, index) =>
                      MessageBubble(message: _controller.messages[index]),
                ),
              ),
              // 底部：新消息加载状态
              SliverToBoxAdapter(
                child: LoadNewStateIndicator(
                  isLoading: _controller.isLoadingNewMessage,
                ),
              ),
            ],
          ),
        ),
        if (_showScrollToBottom)
          Positioned(
            bottom: 12,
            right: 12,
            child: ScrollToBottomButton(
              unreadCount: _unreadCount,
              onTap: _scrollToBottom,
            ),
          ),
      ],
    );
  }
}
