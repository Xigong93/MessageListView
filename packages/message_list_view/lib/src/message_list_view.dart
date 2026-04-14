import 'package:flutter/material.dart';

import 'initial_load_overlay.dart';
import 'initial_load_status.dart';
import 'load_more_status.dart';
import 'loading_indicator.dart';
import 'message_list_controller.dart';

/// 构建列表项的回调。
///
/// [prevItem] 为时间上紧邻的上一条消息，可据此决定是否显示时间戳等分隔信息。
/// 列表最旧一条消息的 [prevItem] 为 null。
typedef MessageItemBuilder<T> = MessageItemView Function(
    BuildContext context, T item, T? prevItem, int index);

/// 双向消息列表视图，负责消息展示、滚动管理和加载触发。
///
/// 使用 [CustomScrollView] 的 center 机制实现双向滚动：
/// - center 之前：历史消息（向上增长，不影响正方向滚动位置）
/// - center 之后：当前消息 + 新消息（向下增长）
///
/// 列表项通过 [itemBuilder] 回调构建，与具体业务类型解耦。
class MessageListView<T> extends StatefulWidget {
  final MessageListController<T> controller;
  final MessageItemBuilder<T> itemBuilder;

  const MessageListView(
    this.controller, {
    super.key,
    required this.itemBuilder,
  });

  @override
  State<MessageListView<T>> createState() => _MessageListViewState<T>();
}

class _MessageListViewState<T> extends State<MessageListView<T>> {
  final _centerKey = UniqueKey();

  /// 初始滚动定位完成后置为 true，防止定位前触发加载。
  bool _isReady = false;

  MessageListController<T> get _controller => widget.controller;

  // ───────────────────────────── 生命周期 ─────────────────────────────

  @override
  void initState() {
    super.initState();
    _controller.scrollController.addListener(_onScroll);
    _controller.initialLoadStatus.addListener(_onInitialLoadChanged);
  }

  @override
  void dispose() {
    _controller.initialLoadStatus.removeListener(_onInitialLoadChanged);
    super.dispose();
  }

  // ───────────────────────────── 初始加载完成处理 ─────────────────────────────

  void _onInitialLoadChanged() {
    switch (_controller.initialLoadStatus.value) {
      case InitialLoadStatus.loading:
        // 重新加载（如 reload），隐藏列表
        setState(() => _isReady = false);
      case InitialLoadStatus.success:
        // 加载成功，等待布局后显示列表
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _isReady = true);
        });
      case InitialLoadStatus.error:
        // 保持 _isReady = false，由 overlay 显示错误 UI
        break;
    }
  }

  // ───────────────────────────── 滚动事件 ─────────────────────────────

  void _onScroll() {
    if (!_isReady || !_controller.scrollController.hasClients) return;
    final position = _controller.scrollController.position;

    final initialDone =
        _controller.initialLoadStatus.value == InitialLoadStatus.success;

    // 接近反方向顶端 → 加载更多历史
    if (position.pixels - position.minScrollExtent <= 80 &&
        _controller.loadHistoryStatus.value == LoadMoreStatus.idle &&
        initialDone) {
      _controller.loadMoreHistory();
    }

    // 接近正方向底端 → 加载更多新消息
    if (position.maxScrollExtent - position.pixels <= 80 &&
        _controller.loadNewStatus.value == LoadMoreStatus.idle &&
        initialDone) {
      _controller.loadNewMessage();
    }
  }

  // ───────────────────────────── UI ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildScrollView(),
        _buildLoadingState(),
      ],
    );
  }

  Widget _buildScrollView() {
    return Opacity(
      opacity: _isReady ? 1.0 : 0.0,
      child: CustomScrollView(
        controller: _controller.scrollController,
        center: _centerKey,
        anchor: 0.0,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // ← 反方向（向上增长）
          _buildTopLoadingIndicator(),
          _buildHistoryMessageList(),

          // 锚点（offset = 0）
          SliverToBoxAdapter(key: _centerKey, child: const SizedBox.shrink()),

          // → 正方向（向下增长）
          _buildMessageList(),
          _buildBottomLoadingIndicator(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ValueListenableBuilder(
      valueListenable: _controller.initialLoadStatus,
      builder: (_, status, __) => InitialLoadOverlay(
        status: status,
        onRetry: _controller.loadMessage,
      ),
    );
  }

  // ───────────── 反方向 slivers ─────────────

  Widget _buildHistoryMessageList() {
    return ValueListenableBuilder(
      valueListenable: _controller.historyMessages,
      builder: (_, historyMessages, __) {
        return SliverList.builder(
          itemCount: historyMessages.length,
          // historyMessages 降序存储（index 0 最新），视觉上向上增长。
          // index+1 处是时间更早的消息，即当前消息的"上一条"。
          itemBuilder: (context, index) {
            final prevItem = index + 1 < historyMessages.length
                ? historyMessages[index + 1]
                : null;
            return widget.itemBuilder(
                context, historyMessages[index], prevItem, index);
          },
        );
      },
    );
  }

  // ───────────── 正方向 slivers ─────────────

  Widget _buildMessageList() {
    return ValueListenableBuilder(
      valueListenable: _controller.messages,
      builder: (_, messages, __) {
        return SliverList.builder(
          itemCount: messages.length,
          // messages 升序存储（index 0 最旧），index-1 是时间更早的上一条。
          itemBuilder: (context, index) {
            final prevItem = index > 0 ? messages[index - 1] : null;
            return widget.itemBuilder(
                context, messages[index], prevItem, index);
          },
        );
      },
    );
  }

  Widget _buildTopLoadingIndicator() {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _controller.initialLoadStatus,
        _controller.loadHistoryStatus,
      ]),
      builder: (_, __) {
        if (_controller.initialLoadStatus.value != InitialLoadStatus.success) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverToBoxAdapter(
          child: TopLoadingIndicator(
            status: _controller.loadHistoryStatus.value,
            onRetry: _controller.loadMoreHistory,
          ),
        );
      },
    );
  }

  Widget _buildBottomLoadingIndicator() {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _controller.initialLoadStatus,
        _controller.loadNewStatus,
      ]),
      builder: (_, __) {
        if (_controller.initialLoadStatus.value != InitialLoadStatus.success) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverToBoxAdapter(
          child: BottomLoadingIndicator(
            status: _controller.loadNewStatus.value,
            onRetry: _controller.loadNewMessage,
          ),
        );
      },
    );
  }
}

class MessageItemView extends StatelessWidget {
  final Widget child;

  // 将 key 设置为 required
  const MessageItemView({required Key key, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: child,
    );
  }
}
