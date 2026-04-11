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
    _controller.addListener(_onChanged);
    _controller.loadMessage(startMsgId: widget.startMsgId);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        title: Text(
          widget.startMsgId == null ? '消息页面' : '历史消息页面',
          style: const TextStyle(fontSize: 17),
        ),
        actions: [
          IconButton(
            tooltip: '收到新消息',
            icon: const Icon(Icons.mark_chat_unread_outlined),
            onPressed:
                _controller.isLoadingInitial || _controller.isLoadingNewMessage
                    ? null
                    : _controller.addNewMessage,
          ),
          IconButton(
            tooltip: '重置页面',
            icon: const Icon(Icons.refresh),
            onPressed: _controller.isLoadingInitial ? null : _controller.reset,
          ),
        ],
      ),
      body: _controller.isLoadingInitial
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.grey[400],
              ),
            )
          : MessageListView(
              controller: _controller,
              scrollToBottomOnLoad: widget.startMsgId == null,
            ),
    );
  }
}
