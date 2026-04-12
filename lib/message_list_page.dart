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
      child: controller == null
          ? const SizedBox.shrink()
          : ListenableBuilder(
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
    );
  }
}
