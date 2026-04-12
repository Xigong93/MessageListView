import 'package:flutter/material.dart';
import 'package:message_list_view/message_list_view.dart';

import 'capsule_button.dart';
import 'im_message_provider.dart';
import 'message.dart';
import 'message_bubble.dart';

class MessageListPage extends StatefulWidget {
  final int? startMsgId;

  const MessageListPage({super.key, this.startMsgId});

  @override
  State<MessageListPage> createState() => _MessageListPageState();
}

class _MessageListPageState extends State<MessageListPage> {
  late final _provider = ImMessageProvider(startMsgId: widget.startMsgId);
  late final _controller = MessageListController<Message>(_provider);

  @override
  void initState() {
    super.initState();
    _controller.loadMessage();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onReceiveNewMessage() {
    final id = _controller.messages.value.lastOrNull?.id;
    if (id == null) return;
    _controller.appendMessages([_provider.createMessage(id)]);
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
            child: MessageListView<Message>(
              _controller,
              itemBuilder: (context, message, index) =>
                  MessageBubble(message: message),
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
      child: ListenableBuilder(
        listenable: Listenable.merge([
          _controller.isLoadingInitial,
          _controller.loadNewStatus,
        ]),
        builder: (_, __) {
          final isLoadingInitial = _controller.isLoadingInitial.value;
          final loadNewStatus = _controller.loadNewStatus.value;
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
                  onTap: () => _controller.reload(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
