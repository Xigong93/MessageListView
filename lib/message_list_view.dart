import 'package:flutter/material.dart';

import 'message_bubble.dart';
import 'message_list_controller.dart';

/// 消息列表视图，负责消息展示、滚动管理和加载触发。
/// 页面只需传入 [MessageListController]，不处理列表相关的业务逻辑。
class MessageListView extends StatefulWidget {
  final MessageListController controller;

  const MessageListView({super.key, required this.controller});

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

  // HistoryAwareScrollPhysics 所需的待补偿高度
  double _pendingCorrection = 0;

  MessageListController get _controller => widget.controller;

  double _getCorrection() {
    final v = _pendingCorrection;
    _pendingCorrection = 0;
    return v;
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
      // ① 首次加载完成 → 跳到底部
      _scheduleScrollToBottom(animate: false);
    } else if (_wasLoadingHistory && !c.isLoadingHistory) {
      // ② 历史加载完成 → 下一帧计算 delta 并补偿
      final preMaxExtent = _scrollController.position.maxScrollExtent;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        final delta =
            _scrollController.position.maxScrollExtent - preMaxExtent;
        if (delta > 0) {
          _pendingCorrection = delta;
          _scrollController.jumpTo(_scrollController.position.pixels + delta);
        }
      });
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
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
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

  // ───────────────────────────── 列表构建辅助 ─────────────────────────────

  bool get _showTopIndicator =>
      _controller.isLoadingHistory || !_controller.hasMoreHistory;

  bool get _showBottomIndicator => _controller.isLoadingNewMessage;

  int get _itemCount =>
      _controller.messages.length +
      (_showTopIndicator ? 1 : 0) +
      (_showBottomIndicator ? 1 : 0);

  Widget _buildListItem(BuildContext context, int index) {
    final topOffset = _showTopIndicator ? 1 : 0;

    if (_showTopIndicator && index == 0) {
      return _controller.isLoadingHistory
          ? const _TopLoadingIndicator()
          : const _NoMoreHistoryHint();
    }

    if (_showBottomIndicator && index == _itemCount - 1) {
      return const _BottomLoadingIndicator();
    }

    return MessageBubble(message: _controller.messages[index - topOffset]);
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
          child: ListView.builder(
            controller: _scrollController,
            physics: HistoryAwareScrollPhysics(
              getCorrection: _getCorrection,
              parent: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _itemCount,
            itemBuilder: _buildListItem,
          ),
        ),
        if (_showScrollToBottom)
          Positioned(
            bottom: 12,
            right: 12,
            child: _ScrollToBottomButton(
              unreadCount: _unreadCount,
              onTap: _scrollToBottom,
            ),
          ),
      ],
    );
  }
}

// ───────────────────────────── ScrollPhysics ─────────────────────────────

/// 在内容顶部插入历史消息后，通过 [adjustPositionForNewDimensions] 自动补偿
/// 滚动偏移，使已有内容保持视觉位置不变。
class HistoryAwareScrollPhysics extends ScrollPhysics {
  final double Function() getCorrection;

  const HistoryAwareScrollPhysics({
    required this.getCorrection,
    super.parent,
  });

  @override
  HistoryAwareScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return HistoryAwareScrollPhysics(
      getCorrection: getCorrection,
      parent: buildParent(ancestor),
    );
  }

  @override
  double adjustPositionForNewDimensions({
    required ScrollMetrics oldPosition,
    required ScrollMetrics newPosition,
    required bool isScrolling,
    required double velocity,
  }) {
    final contentGrew =
        newPosition.maxScrollExtent > oldPosition.maxScrollExtent;
    if (contentGrew) {
      final correction = getCorrection();
      if (correction != 0) return newPosition.pixels + correction;
    }
    return super.adjustPositionForNewDimensions(
      oldPosition: oldPosition,
      newPosition: newPosition,
      isScrolling: isScrolling,
      velocity: velocity,
    );
  }
}

// ───────────────────────────── 辅助小组件 ─────────────────────────────

class _TopLoadingIndicator extends StatelessWidget {
  const _TopLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('加载更多消息...',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _NoMoreHistoryHint extends StatelessWidget {
  const _NoMoreHistoryHint();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text('没有更多消息了',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
      ),
    );
  }
}

class _BottomLoadingIndicator extends StatelessWidget {
  const _BottomLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('正在获取新消息...',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _ScrollToBottomButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const _ScrollToBottomButton(
      {required this.unreadCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              blurRadius: 6,
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.12),
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (unreadCount > 0) ...[
              Text(
                '$unreadCount 条新消息',
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF2196F3)),
              ),
              const SizedBox(width: 4),
            ],
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 20, color: Color(0xFF2196F3)),
          ],
        ),
      ),
    );
  }
}
