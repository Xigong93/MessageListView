# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 包概述

`message_list_view` 是一个可复用的双向消息列表组件包，所有源文件在 `lib/src/` 下，通过 `lib/message_list_view.dart` 统一导出。

## Architecture

### 对外公开的类

| 类 / 枚举 | 职责 |
|---|---|
| `MessageProvider<T>` | 抽象基类，定义纯数据获取接口，无状态 |
| `InitialResult<T>` | `fetchInitial()` 的返回类型 |
| `MessageListController<T>` | 持有全部状态 + 协调加载逻辑 + ScrollController |
| `MessageListView<T>` | 视图 Widget，消费 Controller，负责渲染和触发加载 |
| `LoadMoreStatus` | 枚举：`idle` / `loading` / `noMore` |

### 职责分离原则

- **`MessageProvider`**：只做数据获取，返回 `List<T>` 或 `InitialResult<T>`，不碰任何状态字段。
- **`MessageListController`**：是唯一的状态持有者和加载协调者。子类无需（也无法）直接操作状态，加载逻辑（`loading/idle/noMore` 状态机）在 controller 内统一实现。
- **`MessageListView`**：直接从 `controller` 读取所有状态，不访问 `MessageProvider`。

### 状态模型（`MessageListController`）

| 字段 | 类型 | 说明 |
|---|---|---|
| `messages` | `ValueNotifier<List<T>>` | 正方向列表项，时间升序 |
| `historyMessages` | `ValueNotifier<List<T>>` | 反方向历史，时间**降序**（index 0 紧邻 center）|
| `isLoadingInitial` | `ValueNotifier<bool>` | 首次加载中 |
| `loadHistoryStatus` | `ValueNotifier<LoadMoreStatus>` | 历史加载状态 |
| `loadNewStatus` | `ValueNotifier<LoadMoreStatus>` | 新消息加载状态 |

### 双向滚动实现

`MessageListView` 使用 `CustomScrollView` 的 `center` 锚点实现双向滚动：

```
┌─────────────────────────────────┐  ← minScrollExtent（反方向顶部）
│  TopLoadingIndicator            │
│  historyMessages（降序向上增长） │
├─────────────────────────────────┤  ← offset = 0（center 锚点）
│  messages（升序向下增长）        │
│  BottomLoadingIndicator         │
└─────────────────────────────────┘  ← maxScrollExtent（正方向底部）
```

- `historyMessages` 必须保持**降序**存储：`fetchHistory()` 返回升序，controller 内部负责反转后追加。
- `_isReady` 标志在初始加载完成并布局后才置为 `true`，防止定位前误触发加载。

### 加载触发阈值

`_onScroll()` 检测：
- `pixels - minScrollExtent ≤ 80` → 调用 `controller.loadMoreHistory()`
- `maxScrollExtent - pixels ≤ 80` → 调用 `controller.loadNewMessage()`

### 初始可见性处理

初始加载期间列表用 `Opacity(opacity: 0)` 隐藏（保证布局尺寸存在）。加载完成后在 `addPostFrameCallback` 中将 `_isReady` 置为 `true` 并触发 `setState`，防止跳屏。

## 扩展指南

实现自定义数据源时，继承 `MessageProvider<T>`，实现三个抽象方法：

```dart
class MyProvider extends MessageProvider<MyMessage> {
  @override
  Future<InitialResult<MyMessage>> fetchInitial({int? startMsgId}) async {
    final list = await myApi.fetchInitial(startMsgId: startMsgId);
    return InitialResult(messages: list, hasMoreNew: startMsgId != null);
  }

  @override
  Future<List<MyMessage>> fetchHistory(MyMessage oldestItem) =>
      myApi.fetchHistory(oldestItem.id);

  @override
  Future<List<MyMessage>> fetchNew(MyMessage newestItem) =>
      myApi.fetchNew(newestItem.id);
}
```

在页面中使用：

```dart
final _provider = MyProvider();
final _controller = MessageListController<MyMessage>(_provider);

// initState
_controller.loadMessage();

// build
MessageListView<MyMessage>(_controller, itemBuilder: ...)

// dispose
_controller.dispose();  // 内部会调用 _provider.dispose()
```

`dispose()` 时 controller 会自动调用 `provider.dispose()` 并释放所有 `ValueNotifier`，无需手动清理。
