import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:message_list_view/message_list_view.dart';

import 'im_message_provider.dart';
import 'message.dart';
import 'message_bubble.dart';
import 'scroll_to_bottom_button.dart';
import 'scroll_to_last_read_button.dart';

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

  /// 不在底部时收到的新消息计数。
  final ValueNotifier<int> _unreadCount = ValueNotifier(0);

  /// 当前列表是否在底部。
  final ValueNotifier<bool> _isAtBottom = ValueNotifier(true);

  /// 是否显示"上次阅读位置"按钮。
  final ValueNotifier<bool> _showLastRead = ValueNotifier(true);

  static const int _lastReadMessageId = 60;

  @override
  void initState() {
    super.initState();
    controller.loadMessage();
    controller.scrollController.addListener(_onScrollChanged);
  }

  @override
  void dispose() {
    controller.scrollController.removeListener(_onScrollChanged);
    _unreadCount.dispose();
    _isAtBottom.dispose();
    _showLastRead.dispose();
    controller.dispose();
    super.dispose();
  }

  void _onScrollChanged() {
    final atBottom = controller.atBottom;
    _isAtBottom.value = atBottom;
    if (atBottom) _unreadCount.value = 0;
  }

  /// 追加新消息。在底部时自动滚动到底部，否则仅追加不滚动。
  void appendMessages(List<Message> items) {
    final wasAtBottom = controller.atBottom;
    controller.appendMessages(items);
    if (wasAtBottom) {
      controller.scrollToBottom(anim: true);
    } else {
      _unreadCount.value += items.length;
    }
  }

  void _scrollToBottomAndClearUnread() {
    controller.scrollToBottom(anim: true);
    _unreadCount.value = 0;
  }

  /// 滚动到指定消息。先估算偏移量跳转，再用 ensureVisible 精确定位。
  void _scrollToMessage(int messageId) {
    provider.startMsgId = messageId;
    controller.reload();
  }

  int? _indexWhere(List<Message> list, int messageId) {
    final i = list.indexWhere((m) => m.id == messageId);
    return i >= 0 ? i : null;
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
              child: Stack(
                children: [
                  MessageListView<Message>(
                    controller,
                    itemBuilder: (context, message, index) => KeyedSubtree(
                      key: GlobalObjectKey(message.id),
                      child: MessageBubble(message: message),
                    ),
                  ),
                  _buildScrollToBottomButton(),
                  _buildScrollToLastReadButton(),
                ],
              ),
            ),
            _buildInputBar(),
          ],
        );
      },
    );
  }

  Widget _buildScrollToBottomButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isAtBottom,
      builder: (_, isAtBottom, __) {
        if (isAtBottom) return const SizedBox.shrink();
        return Positioned(
          right: 16,
          bottom: 16,
          child: ValueListenableBuilder<int>(
            valueListenable: _unreadCount,
            builder: (_, unread, __) {
              return ScrollToBottomButton(
                unreadCount: unread,
                onTap: _scrollToBottomAndClearUnread,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildScrollToLastReadButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: _showLastRead,
      builder: (_, show, __) {
        if (!show) return const SizedBox.shrink();
        return Positioned(
          right: 16,
          top: 16,
          child: ScrollToLastReadButton(
            onTap: () {
              _showLastRead.value = false;
              _scrollToMessage(_lastReadMessageId);
            },
          ),
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
