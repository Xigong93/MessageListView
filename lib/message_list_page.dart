import 'package:flutter/material.dart';

import 'message_list_controller.dart';
import 'mock_message_service.dart';
import 'message_bubble.dart';

class MessageListPage extends StatefulWidget {
  const MessageListPage({super.key});

  @override
  State<MessageListPage> createState() => _MessageListPageState();
}

class _MessageListPageState extends State<MessageListPage> {
  // 控制器：负责数据加载
  late final MessageListController _controller;

  // 视图专属：滚动控制 & 输入
  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();

  // 滚动 UI 状态（依赖 ScrollController，属于视图关注点）
  bool _showScrollToBottom = false;
  int _unreadCount = 0;

  // 用于检测控制器状态转换的"前一帧快照"
  bool _wasLoadingInitial = true;
  bool _wasLoadingHistory = false;
  int _previousMessageCount = 0;

  // 历史加载前记录的滚动位置，用于加载完成后还原
  double _preHistoryOffset = 0;
  double _preHistoryMaxExtent = 0;

  // ───────────────────────────── 生命周期 ─────────────────────────────

  @override
  void initState() {
    super.initState();
    _controller = MessageListController(MockMessageService());
    // 先订阅控制器，再调 initialize，保证首次通知不会漏掉
    _controller.addListener(_onControllerChanged);
    _scrollController.addListener(_onScroll);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _scrollController.dispose();
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  // ───────────────────────────── 控制器变化响应 ─────────────────────────────

  /// 每次控制器 notifyListeners() 都会同步调用此方法（在 Widget 重建之前）。
  /// 通过对比前后状态的转换，决定执行哪种滚动行为。
  void _onControllerChanged() {
    final c = _controller;

    if (_wasLoadingInitial && !c.isLoadingInitial) {
      // ① 首次加载完成 → 跳到底部
      _scheduleScrollToBottom(animate: false);
    } else if (!_wasLoadingHistory && c.isLoadingHistory) {
      // ② 历史加载开始 → 快照当前滚动位置
      //    此时 Widget 尚未重建，maxScrollExtent 反映的是旧布局
      _preHistoryOffset = _scrollController.offset;
      _preHistoryMaxExtent = _scrollController.position.maxScrollExtent;
    } else if (_wasLoadingHistory && !c.isLoadingHistory) {
      // ③ 历史加载完成 → 下一帧恢复位置，消除跳动
      _scheduleHistoryScrollRestore();
    } else if (!c.isLoadingInitial &&
        !c.isLoadingHistory &&
        c.messages.length > _previousMessageCount) {
      // ④ 新消息追加（收到推送 or 自己发送）
      //    此刻 maxScrollExtent 仍是旧值，可安全判断"是否在底部"
      _handleMessageAppended();
    }

    _wasLoadingInitial = c.isLoadingInitial;
    _wasLoadingHistory = c.isLoadingHistory;
    _previousMessageCount = c.messages.length;

    // 触发视图层重建
    if (mounted) setState(() {});
  }

  // ───────────────────────────── 滚动动作 ─────────────────────────────

  void _scheduleScrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animate) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  void _scheduleHistoryScrollRestore() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      // heightAdded = 新内容高度 − 旧内容高度（自然包含了 loading 指示器的影响）
      final heightAdded =
          _scrollController.position.maxScrollExtent - _preHistoryMaxExtent;
      final target = (_preHistoryOffset + heightAdded).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.jumpTo(target);
    });
  }

  void _handleMessageAppended() {
    final isAtBottom = _scrollController.hasClients &&
        _scrollController.offset >=
            _scrollController.position.maxScrollExtent - 100;

    if (isAtBottom) {
      _scheduleScrollToBottom();
    } else {
      // 用户正在查看历史，保持位置不动，仅增加未读计数
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

    // 更新"滚到底部"按钮状态
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

  // ───────────────────────────── 用户操作 ─────────────────────────────

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    _controller.sendMessage(text);
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

  int get _itemCount =>
      _controller.messages.length + (_showTopIndicator ? 1 : 0);

  Widget _buildListItem(BuildContext context, int index) {
    if (_showTopIndicator && index == 0) {
      return _controller.isLoadingHistory
          ? const _TopLoadingIndicator()
          : const _NoMoreHistoryHint();
    }
    final msgIndex = _showTopIndicator ? index - 1 : index;
    return MessageBubble(message: _controller.messages[msgIndex]);
  }

  // ───────────────────────────── UI ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alice', style: TextStyle(fontSize: 17)),
            Text(
              '在线',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: _controller.isLoadingInitial
          ? _buildInitialLoading()
          : _buildBody(),
    );
  }

  Widget _buildInitialLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('加载消息中...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _itemCount,
                itemBuilder: _buildListItem,
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
          ),
        ),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                focusNode: _inputFocusNode,
                decoration: InputDecoration(
                  hintText: '输入消息...',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send_rounded),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
              ),
            ),
          ],
        ),
      ),
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
            Text(
              '加载更多消息...',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
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
        child: Text(
          '没有更多消息了',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }
}

class _ScrollToBottomButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const _ScrollToBottomButton({
    required this.unreadCount,
    required this.onTap,
  });

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
                style:
                    const TextStyle(fontSize: 13, color: Color(0xFF2196F3)),
              ),
              const SizedBox(width: 4),
            ],
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: Color(0xFF2196F3),
            ),
          ],
        ),
      ),
    );
  }
}
