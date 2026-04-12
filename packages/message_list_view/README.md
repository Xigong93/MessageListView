# message_list_view

适用于 IM 场景的双向消息列表 Flutter 组件，支持历史消息（向上加载）和新消息（向下加载）的双向无限滚动。

## 核心特性

- 基于 `CustomScrollView` center 锚点实现双向滚动，加载历史消息不影响当前阅读位置
- 职责分离：应用层只实现纯数据获取，框架统一管理所有状态和加载协调逻辑
- 泛型设计，消息数据类型由业务方决定
- 内置顶部/底部加载指示器，底部 `noMore` 状态平滑收缩

## 快速接入

**第一步：实现数据提供者**

继承 `MessageProvider<T>`，只需实现三个纯数据获取方法，无需操作任何状态：

```dart
class MyProvider extends MessageProvider<MyMessage> {
  @override
  Future<InitialResult<MyMessage>> fetchInitial({int? startMsgId}) async {
    final list = await myApi.fetchInitial(startMsgId: startMsgId);
    return InitialResult(
      messages: list,
      hasMoreNew: startMsgId != null, // 从历史位置加载时可能有新消息
    );
  }

  @override
  Future<List<MyMessage>> fetchHistory(MyMessage oldestItem) =>
      myApi.fetchHistory(oldestItem.id);

  @override
  Future<List<MyMessage>> fetchNew(MyMessage newestItem) =>
      myApi.fetchNew(newestItem.id);
}
```

**第二步：在页面中使用**

```dart
class _MyPageState extends State<MyPage> {
  final _provider = MyProvider();
  late final _controller = MessageListController<MyMessage>(_provider);

  @override
  void initState() {
    super.initState();
    _controller.loadMessage(); // 加载最新消息并自动滚动到底部
  }

  @override
  void dispose() {
    _controller.dispose(); // 同时释放 provider 和所有状态
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MessageListView<MyMessage>(
      _controller,
      itemBuilder: (context, message, index) => MyMessageBubble(message: message),
    );
  }
}
```

## API 概览

### `MessageListController<T>`

| 方法 / 属性 | 说明 |
|---|---|
| `loadMessage({int? startMsgId})` | 首次加载；`startMsgId` 为空时加载最新消息并滚到底部 |
| `loadMoreHistory()` | 加载更多历史（由视图自动调用，也可手动触发）|
| `loadNewMessage()` | 加载更多新消息（由视图自动调用，也可手动触发）|
| `appendMessages(List<T>)` | 追加消息到列表末尾，用于实时推送 |
| `reload({int? startMsgId})` | 清空数据并重新加载，原子操作 |
| `scrollToBottom({bool anim})` | 滚动到底部，默认有动画 |
| `scrollToTop({bool anim})` | 滚动到顶部，默认有动画 |
| `atBottom` | 当前是否处于底部（误差 1px）|
| `messages` | `ValueNotifier<List<T>>`，正方向消息列表 |
| `isLoadingInitial` | `ValueNotifier<bool>`，首次加载中标志 |
| `loadHistoryStatus` | `ValueNotifier<LoadMoreStatus>` |
| `loadNewStatus` | `ValueNotifier<LoadMoreStatus>` |
| `dispose()` | 释放所有资源（含 provider）|

### `MessageProvider<T>`

| 方法 | 说明 |
|---|---|
| `fetchInitial({int? startMsgId})` | 首次加载，返回 `InitialResult<T>` |
| `fetchHistory(T oldestItem)` | 加载历史，返回升序列表（框架负责反转）|
| `fetchNew(T newestItem)` | 加载新消息 |
| `dispose()` | 默认空实现，按需重写 |

### `InitialResult<T>`

```dart
class InitialResult<T> {
  final List<T> messages;   // 正方向消息列表（升序）
  final bool hasMoreNew;    // false 时新消息方向直接标记为 noMore
}
```

### `LoadMoreStatus`

```dart
enum LoadMoreStatus { idle, loading, noMore }
```

## 注意事项

- `fetchHistory` 返回**升序**列表即可，框架内部会反转后存入 `historyMessages`（降序）。
- `dispose()` 调用后 controller 会自动调用 `provider.dispose()`，不需要单独释放 provider。
- 若需要实时推送，使用 `controller.appendMessages([newMessage])` 追加，而非直接操作 `messages.value`。
