import 'package:flutter/material.dart';
import 'package:message_list_view/src/message_list_controller.dart';

import 'load_more_status.dart';
import 'loading_indicator.dart';
import 'message_data_source.dart';

/// 构建列表项的回调。
typedef MessageItemBuilder<T> = Widget Function(
    BuildContext context, T item, int index);

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

  MessageDataSource<T> get _dataSource => _controller.dataSource;

  ScrollController get _scrollController => _controller.scrollController;

  // ───────────────────────────── 生命周期 ─────────────────────────────

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _dataSource.isLoadingInitial.addListener(_onInitialLoadChanged);
  }

  @override
  void dispose() {
    _dataSource.isLoadingInitial.removeListener(_onInitialLoadChanged);
    super.dispose();
  }

  // ───────────────────────────── 初始加载完成处理 ─────────────────────────────

  void _onInitialLoadChanged() {
    if (_dataSource.isLoadingInitial.value) {
      // 重新加载（如 reset），隐藏列表
      setState(() => _isReady = false);
    } else {
      // 加载完成，等待布局后显示列表
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _isReady = true);
      });
    }
  }

  // ───────────────────────────── 滚动事件 ─────────────────────────────

  void _onScroll() {
    if (!_isReady || !_scrollController.hasClients) return;
    final position = _scrollController.position;

    // 接近反方向顶端 → 加载更多历史
    if (position.pixels - position.minScrollExtent <= 80 &&
        _dataSource.loadHistoryStatus.value == LoadMoreStatus.idle &&
        !_dataSource.isLoadingInitial.value) {
      _dataSource.loadMoreHistory();
    }

    // 接近正方向底端 → 加载更多新消息
    if (position.maxScrollExtent - position.pixels <= 80 &&
        _dataSource.loadNewStatus.value == LoadMoreStatus.idle &&
        !_dataSource.isLoadingInitial.value) {
      _dataSource.loadNewMessage();
    }
  }

  // ───────────────────────────── UI ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildScrollView(),
        _buildCenterLoading(),
      ],
    );
  }

  Widget _buildScrollView() {
    return Opacity(
      opacity: _isReady ? 1.0 : 0.0,
      child: CustomScrollView(
        controller: _scrollController,
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

  Widget _buildCenterLoading() {
    return ValueListenableBuilder(
      valueListenable: _dataSource.isLoadingInitial,
      builder: (_, visible, __) {
        return Visibility(
          visible: visible,
          child: Center(
            child: CircularProgressIndicator(
              color: Colors.grey[400],
            ),
          ),
        );
      },
    );
  }

  // ───────────── 反方向 slivers ─────────────

  Widget _buildHistoryMessageList() {
    return ValueListenableBuilder(
      valueListenable: _dataSource.historyMessages,
      builder: (_, historyMessages, __) {
        return SliverList.builder(
          itemCount: historyMessages.length,
          itemBuilder: (context, index) =>
              widget.itemBuilder(context, historyMessages[index], index),
        );
      },
    );
  }

  // ───────────── 正方向 slivers ─────────────

  Widget _buildMessageList() {
    return ValueListenableBuilder(
      valueListenable: _dataSource.messages,
      builder: (_, messages, __) {
        return SliverList.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) =>
              widget.itemBuilder(context, messages[index], index),
        );
      },
    );
  }

  Widget _buildTopLoadingIndicator() {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _dataSource.isLoadingInitial,
        _dataSource.loadHistoryStatus,
      ]),
      builder: (_, __) {
        if (_dataSource.isLoadingInitial.value) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverToBoxAdapter(
          child: TopLoadingIndicator(
            status: _dataSource.loadHistoryStatus.value,
          ),
        );
      },
    );
  }

  Widget _buildBottomLoadingIndicator() {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _dataSource.isLoadingInitial,
        _dataSource.loadNewStatus,
      ]),
      builder: (_, __) {
        if (_dataSource.isLoadingInitial.value) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverToBoxAdapter(
          child: BottomLoadingIndicator(
            status: _dataSource.loadNewStatus.value,
          ),
        );
      },
    );
  }
}
