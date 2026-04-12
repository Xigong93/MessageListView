# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter analyze          # 静态分析（lint）
flutter test             # 运行所有测试
flutter test test/widget_test.dart   # 运行单个测试文件
flutter run              # 启动应用
```

## Architecture

这是一个 IM 消息列表的 Flutter 示例，分为两层：

- **`lib/`**：应用层，所有源文件平级放置，不分子目录。
- **`packages/message_list_view/`**：本地包，封装可复用的消息列表组件，通过 `path` 依赖引入。

### 数据流

```
MockMessageService
       ↓
ImMessageProvider  (MessageProvider<Message> 子类，只做数据获取)
       ↓
MessageListController<T>  (持有状态 + 协调加载逻辑 + ScrollController)
       ↓
MessageListView<T>  (包内视图，负责展示与滚动触发)
```

### 核心类职责

**包内（`packages/message_list_view/`）：**

- **`MessageProvider<T>`**（抽象类）：纯数据获取接口，无任何状态。子类实现 `fetchInitial()`、`fetchHistory(T oldestItem)`、`fetchNew(T newestItem)`，返回数据即可，不涉及状态管理。
- **`InitialResult<T>`**：`fetchInitial()` 的返回类型，携带 `messages` 列表和 `hasMoreNew` 标志。
- **`MessageListController<T>`**：持有全部 `ValueNotifier` 状态字段（`messages`、`historyMessages`、`isLoadingInitial`、`loadHistoryStatus`、`loadNewStatus`）和 `ScrollController`。统一实现加载协调逻辑（状态机切换 `loading/idle/noMore`）。对外提供 `loadMessage()`、`loadMoreHistory()`、`loadNewMessage()`、`appendMessages()`、`reload()`、`scrollToBottom()` 等接口。
- **`MessageListView<T>`**：视图层，接收 `MessageListController` 和 `itemBuilder`，直接从 controller 读取状态。

**应用层（`lib/`）：**

- **`ImMessageProvider`**：`MessageProvider<Message>` 的具体实现，调用 `MockMessageService`，额外提供 `createMessage(newestId)` 用于 demo 模拟推送。
- **`MessageListPage`**：持有 `ImMessageProvider` 和 `MessageListController`，组合 `MessageListView` 和底部操作栏。`_onReceiveNewMessage()` 通过 `_controller.appendMessages([_provider.createMessage(id)])` 模拟收到消息；重置通过 `_controller.reload()` 完成。支持两种模式：`startMsgId=null`（加载最新消息）、`startMsgId=60`（从指定位置加载历史消息）。

### 双向滚动机制

`MessageListView` 使用 `CustomScrollView` 的 `center` 锚点实现双向滚动：

- **center 之前**（反方向，向上增长）：`historyMessages` + 顶部加载指示器
- **center（offset = 0）**：`SliverToBoxAdapter(key: _centerKey)`，不可见占位
- **center 之后**（正方向，向下增长）：`messages` + 底部加载指示器

`historyMessages` 必须保持**降序**存储：index 0 是最新的历史消息（紧邻 center），最后一项是最旧的。`fetchHistory()` 返回升序列表，controller 负责反转后追加。

### 关键滚动逻辑

`MessageListView._onScroll()` 受 `_isReady` 标志保护（初始加载完成并布局后才置为 `true`）：

| 条件 | 行为 |
|---|---|
| `pixels - minScrollExtent ≤ 80` | 调用 `controller.loadMoreHistory()` |
| `maxScrollExtent - pixels ≤ 80` | 调用 `controller.loadNewMessage()` |

初始加载期间列表用 `Opacity(0)` 隐藏，加载完成后在 `addPostFrameCallback` 中显示，防止跳屏。
