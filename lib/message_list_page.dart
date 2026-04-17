import 'package:flutter/material.dart';
import 'package:message_list_view/message_list_view.dart';

import 'announcement_banner.dart';
import 'capsule_button.dart';
import 'message_content_view.dart';

class MessageListPage extends StatefulWidget {
  final int? startMsgId;
  final bool showLastReadButton;

  const MessageListPage({
    super.key,
    this.startMsgId,
    this.showLastReadButton = false,
  });

  @override
  State<MessageListPage> createState() => _MessageListPageState();
}

class _MessageListPageState extends State<MessageListPage> {
  final _contentKey = GlobalKey<MessageContentViewState>();
  bool _simulateError = false;
  bool _showAnnouncement = false;

  @override
  void initState() {
    super.initState();
    // 第一帧渲染后 _contentKey.currentState 才可用，触发一次重建以显示底栏按钮
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _onSimulateErrorChanged(bool value) {
    setState(() => _simulateError = value);
    _contentKey.currentState?.provider.shouldFail = value;
  }

  static const _announcementAnimDuration = Duration(milliseconds: 300);

  void _onAnnouncementChanged(bool value) {
    final controller = _contentKey.currentState?.controller;
    final wasAtBottom = controller?.atBottom ?? false;
    setState(() => _showAnnouncement = value);
    if (wasAtBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _stickToBottomDuring(_announcementAnimDuration);
      });
    }
  }

  /// 在动画期间每帧将列表固定在底部，解决视口高度渐变导致的位置漂移。
  void _stickToBottomDuring(Duration remaining) {
    final scrollController =
        _contentKey.currentState?.controller.scrollController;
    if (scrollController == null || !scrollController.hasClients) return;
    scrollController.jumpTo(scrollController.position.maxScrollExtent);
    if (remaining > Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _stickToBottomDuring(remaining - const Duration(milliseconds: 16));
      });
    }
  }

  void _onReceiveNewMessage() {
    final state = _contentKey.currentState!;
    final id = state.controller.messages.value.lastOrNull?.id;
    if (id == null) return;
    state.appendMessages([state.provider.createMessage(id)]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          widget.startMsgId == null ? '消息页面' : '历史消息页面',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.5),
          child: Divider(height: 0.5, thickness: 0.5, color: Color(0xFFDDDDDD)),
        ),
      ),
      body: Column(
        children: [
          _buildAnnouncementBanner(),
          Expanded(
            child: MessageContentView(
              key: _contentKey,
              startMsgId: widget.startMsgId,
              showLastReadButton: widget.showLastReadButton,
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildAnnouncementBanner() {
    return ClipRect(
      child: AnimatedAlign(
        alignment: Alignment.topCenter,
        heightFactor: _showAnnouncement ? 1.0 : 0.0,
        duration: _announcementAnimDuration,
        curve: Curves.easeInOut,
        child: AnimatedOpacity(
          opacity: _showAnnouncement ? 1.0 : 0.0,
          duration: _announcementAnimDuration,
          curve: Curves.easeInOut,
          child: const AnnouncementBanner(
            text: '群公告：欢迎加入本群，请遵守群规，文明交流，禁止发布广告和违规内容。',
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final state = _contentKey.currentState;
    final controller = state?.controller;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFDDDDDD), width: 0.5),
        ),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: 10 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('模拟加载失败', style: TextStyle(fontSize: 14)),
              const Spacer(),
              Switch(value: _simulateError, onChanged: _onSimulateErrorChanged),
            ],
          ),
          Row(
            children: [
              const Text('显示群公告', style: TextStyle(fontSize: 14)),
              const Spacer(),
              Switch(
                  value: _showAnnouncement, onChanged: _onAnnouncementChanged),
            ],
          ),
          if (controller != null)
            ListenableBuilder(
              listenable: Listenable.merge([
                controller.initialLoadStatus,
                controller.loadNewStatus,
                state!.isReconnecting,
              ]),
              builder: (_, __) {
                final isLoadingInitial = controller.initialLoadStatus.value ==
                    InitialLoadStatus.loading;
                final loadNewStatus = controller.loadNewStatus.value;
                final isReconnecting = state.isReconnecting.value;
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CapsuleButton(
                            text: '收到新消息',
                            enabled: !isLoadingInitial &&
                                loadNewStatus != LoadMoreStatus.loading,
                            onTap: _onReceiveNewMessage,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CapsuleButton(
                            text: '重置页面',
                            enabled: !isLoadingInitial,
                            onTap: () => controller.reload(),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
