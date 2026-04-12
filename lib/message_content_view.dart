import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:message_list_view/message_list_view.dart';

import 'im_message_provider.dart';
import 'message.dart';
import 'message_bubble.dart';

/// 封装消息列表的完整逻辑：数据加载、列表展示、键盘弹出自动滚底。
///
/// 对外暴露 [controller] 和 [provider] 供页面调用命令式操作
/// （如模拟收消息、重置等）。
class MessageContentView extends StatefulWidget {
  final int? startMsgId;

  const MessageContentView({super.key, this.startMsgId});

  @override
  State<MessageContentView> createState() => MessageContentViewState();
}

class MessageContentViewState extends State<MessageContentView> {
  late final provider = ImMessageProvider(startMsgId: widget.startMsgId);
  late final controller = MessageListController<Message>(provider);

  @override
  void initState() {
    super.initState();
    controller.loadMessage();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardVisibilityBuilder(
      builder: (context, isKeyboardVisible) {
        if (isKeyboardVisible) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) controller.scrollToBottom(anim: false);
          });
        }
        return Column(
          children: [
            Expanded(
              child: MessageListView<Message>(
                controller,
                itemBuilder: (context, message, index) =>
                    MessageBubble(message: message),
              ),
            ),
            _buildInputBar(),
          ],
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFDDDDDD), width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: '输入消息...',
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
