import 'package:flutter/material.dart';

import 'message_list_controller.dart';
import 'message_list_view/message_list_view.dart';
import 'mock_message_service.dart';

class MessageListPage extends StatefulWidget {
  final int? startMsgId;

  const MessageListPage({super.key, this.startMsgId});

  @override
  State<MessageListPage> createState() => _MessageListPageState();
}

class _MessageListPageState extends State<MessageListPage> {
  late final MessageListController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MessageListController(MockMessageService());
    _controller.loadMessage(startMsgId: widget.startMsgId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: _controller.isLoadingInitial,
              builder: (_, isLoadingInitial, __) => isLoadingInitial
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Colors.grey[400],
                      ),
                    )
                  : MessageListView(
                      controller: _controller,
                      scrollToBottomOnLoad: widget.startMsgId == null,
                    ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
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
      child: ValueListenableBuilder<bool>(
        valueListenable: _controller.isLoadingInitial,
        builder: (_, isLoadingInitial, __) => ValueListenableBuilder<bool>(
          valueListenable: _controller.isLoadingNewMessage,
          builder: (_, isLoadingNewMessage, __) => Row(
            children: [
              Expanded(
                child: _CapsuleButton(
                  text: '收到新消息',
                  enabled: !isLoadingInitial && !isLoadingNewMessage,
                  onTap: _controller.addNewMessage,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CapsuleButton(
                  text: '重置页面',
                  enabled: !isLoadingInitial,
                  onTap: _controller.reset,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CapsuleButton extends StatelessWidget {
  final String text;
  final bool enabled;
  final VoidCallback onTap;

  const _CapsuleButton({
    required this.text,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFF2196F3) : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: enabled ? Colors.white : Colors.grey[500],
          ),
        ),
      ),
    );
  }
}
