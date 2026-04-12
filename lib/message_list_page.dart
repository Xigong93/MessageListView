import 'package:flutter/material.dart';
import 'package:message_list_view/message_list_view.dart';

import 'capsule_button.dart';
import 'message_content_view.dart';

class MessageListPage extends StatefulWidget {
  final int? startMsgId;

  const MessageListPage({super.key, this.startMsgId});

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

  void _onAnnouncementChanged(bool value) {
    final controller = _contentKey.currentState?.controller;
    final wasAtBottom = controller?.atBottom ?? false;
    setState(() => _showAnnouncement = value);
    if (wasAtBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller?.scrollToBottom(anim: false);
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
          if (_showAnnouncement) _buildAnnouncementBanner(),
          Expanded(
            child: MessageContentView(
              key: _contentKey,
              startMsgId: widget.startMsgId,
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildAnnouncementBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF8E1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: const Row(
        children: [
          Icon(Icons.campaign_outlined, size: 18, color: Color(0xFFE65100)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '群公告：欢迎加入本群，请遵守群规，文明交流，禁止发布广告和违规内容。',
              style: TextStyle(fontSize: 13, color: Color(0xFF5D4037)),
            ),
          ),
        ],
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
                  value: _showAnnouncement,
                  onChanged: _onAnnouncementChanged),
            ],
          ),
          if (controller != null) ListenableBuilder(
              listenable: Listenable.merge([
                controller.initialLoadStatus,
                controller.loadNewStatus,
              ]),
              builder: (_, __) {
                final isLoadingInitial = controller.initialLoadStatus.value ==
                    InitialLoadStatus.loading;
                final loadNewStatus = controller.loadNewStatus.value;
                return Row(
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
                );
              },
            ),
        ],
      ),
    );
  }
}
