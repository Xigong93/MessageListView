# message_list_sample
消息列表组件示例

这个是一个IM应用消息列表组件示例。
## 一、功能说明
包含以下功能：
1. 首次加载消息
2. 顶部插入历史消息
3. 底部插入新消息


特性：
1. 插入新消息后，保持内容的位置不变
2. 有加载状态




## 二、如何引入
```yaml
dependencies:
  message_list_view:
    git:
      url: https://github.com/Xigong93/MessageListView
      ref: main
      path: packages/message_list_view
```

### 三、Api说明
#### 1.`MessageListView`
消息加载组件，封装了消息加载逻辑和UI展示
#### 2. `MessageContentView` 
消息页面业务组件，这个是Demo,演示了如何展示新消息，显示上次浏览位置，处理键盘弹出等功能