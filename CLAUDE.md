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

这是一个 IM 消息列表的 Flutter 示例，所有源文件平级放在 `lib/` 下，不分子目录。

### 数据流

```
MockMessageService  ──→  MessageListController  ──→  MessageListPage
   (模拟数据)              (ChangeNotifier)             (视图 + 滚动)
```

- **`MockMessageService`**：纯数据源，提供三个接口：`fetchInitialMessages()`、`fetchHistoryMessages()`（含 `hasMore` 标志，最多 3 批）、`newMessageStream()`（每 8 秒推一条）。
- **`MessageListController`**（`ChangeNotifier`）：持有 `messages`、`isLoadingInitial`、`isLoadingHistory`、`hasMoreHistory`，通过 `notifyListeners()` 广播所有状态变化。内部订阅 `newMessageStream`，`dispose()` 时取消。
- **`MessageListPage`**：视图层，通过 `addListener(_onControllerChanged)` 订阅控制器。滚动相关的 UI 状态（`_unreadCount`、`_showScrollToBottom`）保留在视图层，因为它们依赖 `ScrollController`。

### 关键滚动逻辑

`_onControllerChanged` 通过对比**前后帧状态快照**（`_wasLoadingHistory` 等字段）驱动四种滚动行为：

| 状态转换 | 行为 |
|---|---|
| `wasLoadingInitial → false` | 跳到底部 |
| `!wasLoadingHistory → isLoadingHistory` | 快照 `preOffset` / `preMaxExtent` |
| `wasLoadingHistory → !isLoadingHistory` | `postFrameCallback` 还原位置（`jumpTo(preOffset + heightAdded)`） |
| 消息数量增加（非以上情况） | 在底部则自动跟随，否则累积未读数 |

> 快照必须在 `notifyListeners()` 同步回调中读取，此时 Widget 尚未重建，`maxScrollExtent` 仍反映旧布局。还原动作放在 `addPostFrameCallback` 中读取新布局。
