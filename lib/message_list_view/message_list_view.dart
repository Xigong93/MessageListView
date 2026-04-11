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

  void _addControllerListeners() {
    _controller.isLoadingInitial.addListener(_onLoadingInitialChanged);
    _controller.isLoadingHistory.addListener(_onLoadingHistoryChanged);
    _controller.messages.addListener(_onMessagesChanged);
    _controller.isLoadingNewMessage.addListener(_onStateChanged);
    _controller.hasMoreHistory.addListener(_onStateChanged);
  }

  void _removeControllerListeners(MessageListController c) {
    c.isLoadingInitial.removeListener(_onLoadingInitialChanged);
    c.isLoadingHistory.removeListener(_onLoadingHistoryChanged);
    c.messages.removeListener(_onMessagesChanged);
    c.isLoadingNewMessage.removeListener(_onStateChanged);
    c.hasMoreHistory.removeListener(_onStateChanged);
  }

  // ───────────────────────────── 控制器变化响应 ─────────────────────────────

  /// isLoadingInitial 变化时的回调。
  void _onLoadingInitialChanged() {
    final isLoading = _controller.isLoadingInitial.value;

    if (isLoading) {
      // 控制器重置 → 清空视图状态
      _showScrollToBottom = false;
      _unreadCount = 0;
      _wasLoadingInitial = true;
      _wasLoadingHistory = false;
      _previousMessageCount = 0;
      if (mounted) setState(() {});
      return;
    }

    if (_wasLoadingInitial && !isLoading) {
      // 首次加载完成 → 根据配置跳到底部或顶部
      if (widget.scrollToBottomOnLoad) {
        _scheduleScrollToBottom(animate: false);
      }
      _previousMessageCount = _controller.messages.value.length;
    }

    _wasLoadingInitial = isLoading;
    if (mounted) setState(() {});
  }

  /// isLoadingHistory 变化时的回调。
  void _onLoadingHistoryChanged() {
    final isLoading = _controller.isLoadingHistory.value;

    if (_wasLoadingHistory && !isLoading) {
      // 历史加载完成 → 设置标记，布局阶段由 physics 自动补偿
      _needsHistoryCorrection = true;
      _previousMessageCount = _controller.messages.value.length;
    }

    _wasLoadingHistory = isLoading;
    if (mounted) setState(() {});
  }

  /// messages 变化时的回调（新消息追加等场景）。
  void _onMessagesChanged() {
    final currentCount = _controller.messages.value.length;

    // 排除首次加载和历史加载（由各自的回调处理）
    if (!_controller.isLoadingInitial.value &&
        !_controller.isLoadingHistory.value &&
        currentCount > _previousMessageCount) {
      _handleMessageAppended();
    }

    _previousMessageCount = currentCount;
    if (mounted) setState(() {});
  }

  /// 其他状态变化（isLoadingNewMessage、hasMoreHistory）仅触发重建。
  void _onStateChanged() {
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
        !_controller.isLoadingHistory.value &&
        _controller.hasMoreHistory.value &&
        !_controller.isLoadingInitial.value) {
      _controller.loadMoreHistory();
    }

    // 更新"滚到底部"按钮
    final isNearBottom = _scrollController.offset >=
        _scrollController.position.maxScrollExtent - 100;
    final shouldShow =
        !isNearBottom && _controller.messages.value.isNotEmpty;

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
    final messages = _controller.messages.value;

    return Stack(
      children: [
        NotificationListener<OverscrollNotification>(
          onNotification: (n) {
            if (n.overscroll > 0 && !_controller.isLoadingNewMessage.value) {
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
                  isLoading: _controller.isLoadingHistory.value,
                ),
              ),
              // 中间：消息列表
              SliverPadding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                sliver: SliverList.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) =>
                      MessageBubble(message: messages[index]),
                ),
              ),
              // 底部：新消息加载状态
              SliverToBoxAdapter(
                child: LoadNewStateIndicator(
                  isLoading: _controller.isLoadingNewMessage.value,
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
