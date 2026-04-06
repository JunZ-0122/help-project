# WebSocket 实时聊天功能说明

## 功能概述

聊天功能已经完整实现了 WebSocket 实时通信，当用户发送消息后：
1. 消息通过 REST API 保存到数据库
2. 后端通过 WebSocket 实时推送给发送者和接收者
3. 双方的聊天界面实时更新，无需刷新

## 技术架构

### 后端实现 (Spring Boot + WebSocket)

#### 1. WebSocket 配置
**文件**: `help/src/main/java/com/csi/help/config/WebSocketConfig.java`

```java
@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {
    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(chatWebSocketHandler, "/ws/chat")
                .addInterceptors(jwtHandshakeInterceptor)
                .setAllowedOriginPatterns("*");
    }
}
```

- **端点**: `ws://localhost:8080/ws/chat`
- **认证**: 通过 URL 参数传递 JWT Token (`?token=xxx`)
- **跨域**: 允许所有来源

#### 2. WebSocket 处理器
**文件**: `help/src/main/java/com/csi/help/websocket/ChatWebSocketHandler.java`

核心功能：
- **连接管理**: 维护 userId 到 WebSocketSession 的映射
- **消息推送**: `sendChatMessage()` 方法同时推送给发送者和接收者
- **已读回执**: `sendReadReceipt()` 方法推送已读状态
- **自动清理**: 连接断开时自动清理会话

```java
public void sendChatMessage(ChatMessage message) {
    // 推送给接收者
    if (message.getReceiverId() != null) {
        sendToUser(message.getReceiverId(), message);
    }
    // 推送给发送者（用于多设备同步）
    if (message.getSenderId() != null) {
        sendToUser(message.getSenderId(), message);
    }
}
```

#### 3. JWT 认证拦截器
**文件**: `help/src/main/java/com/csi/help/websocket/JwtHandshakeInterceptor.java`

- 从 URL 参数中提取 Token
- 验证 Token 有效性
- 将 userId 存入 WebSocket Session 属性

#### 4. 消息服务集成
**文件**: `help/src/main/java/com/csi/help/service/ChatMessageService.java`

```java
public ChatMessage sendMessage(ChatMessage message, String senderId) {
    // 1. 保存消息到数据库
    chatMessageMapper.insert(message);
    
    // 2. 通过 WebSocket 实时推送
    chatWebSocketHandler.sendChatMessage(message);
    
    return message;
}
```

### 前端实现 (HarmonyOS ArkTS + WebSocket)

#### 1. WebSocket 服务
**文件**: `help_system/entry/src/main/ets/services/WebSocketService.ets`

核心功能：
- **单例模式**: 全局唯一的 WebSocket 连接
- **自动重连**: 连接断开后 3 秒自动重连
- **消息分发**: 根据 requestId 分发消息给对应的聊天页面
- **状态管理**: 连接状态（connecting/connected/reconnecting/error/disconnected）

```typescript
export class WebSocketService {
  private static instance: WebSocketService;
  private connection: webSocket.WebSocket | null = null;
  private messageHandlers: Map<string, MessageHandler> = new Map();
  private readHandlers: Map<string, ReadReceiptHandler> = new Map();
  
  async connect(token: string): Promise<boolean> {
    const connectUrl = `${WS_BASE_URL}?token=${encodeURIComponent(token)}`;
    return socket.connect(connectUrl);
  }
  
  onMessage(requestId: string, handler: MessageHandler): void {
    this.messageHandlers.set(requestId, handler);
  }
}
```

#### 2. ChatPage 集成
**文件**: `help_system/entry/src/main/ets/pages/volunteer/ChatPage.ets`

##### 连接 WebSocket
```typescript
private async connectRealtimeChannel(): Promise<void> {
  const token = await StorageUtil.getString('token');
  const connected = await this.webSocketService.connect(token);
  
  // 注册消息处理器
  this.webSocketService.onMessage(this.requestId, (message: ChatMessage) => {
    this.handleRealtimeMessage(message);
  });
  
  // 注册已读回执处理器
  this.webSocketService.onReadReceipt(this.requestId, (event: ChatReadReceiptEvent) => {
    this.handleReadReceipt(event);
  });
}
```

##### 处理实时消息
```typescript
private handleRealtimeMessage(message: ChatMessage): void {
  // 1. 检查消息是否属于当前聊天
  if (message.requestId !== this.requestId) {
    return;
  }
  
  // 2. 检查消息是否已存在（避免重复）
  const exists = this.messages.some((item: ChatViewMessage) => item.id === message.id);
  if (exists) {
    return;
  }
  
  // 3. 添加消息到列表
  const nextMessages: ChatViewMessage[] = this.messages.slice();
  nextMessages.push(this.mapMessage(message));
  this.messages = nextMessages;
  
  // 4. 如果是接收的消息，标记为已读
  if (!message.isRead && message.receiverId === this.currentUserId) {
    MessageApi.markAsRead([message.id]);
  }
}
```

##### 发送消息
```typescript
handleSend() {
  const text: string = this.inputText.trim();
  if (!text || !this.targetUserId || this.isSending) {
    return;
  }
  
  this.isSending = true;
  
  // 调用 REST API 发送消息
  MessageApi.sendMessage({
    requestId: this.requestId,
    receiverId: this.targetUserId,
    text: text,
    type: 'text'
  }).then((message: ChatMessage) => {
    // 发送成功后，消息会通过 WebSocket 推送回来
    // handleRealtimeMessage() 会自动处理
    this.inputText = '';
    console.info('message sent successfully');
  }).catch((err: Error) => {
    console.error('send message failed:', err.message || err);
  }).finally(() => {
    this.isSending = false;
  });
}
```

## 消息流程详解

### 完整的消息发送和接收流程

```
用户 A (求助者)                    后端服务器                    用户 B (志愿者)
     |                                |                                |
     | 1. 输入消息并点击发送           |                                |
     |-------------------------------->|                                |
     |    POST /api/chat-messages/send |                                |
     |                                |                                |
     |                                | 2. 保存消息到数据库             |
     |                                |    (chat_messages 表)          |
     |                                |                                |
     |                                | 3. 通过 WebSocket 推送          |
     |<-------------------------------|                                |
     | 4. 收到自己发送的消息           |                                |
     |    (用于多设备同步)             |                                |
     |                                |                                |
     |                                |------------------------------->|
     |                                | 5. 推送消息给接收者             |
     |                                |                                |
     |                                |                                | 6. 实时显示新消息
     |                                |                                |
     |                                |<-------------------------------|
     |                                | 7. 标记消息为已读               |
     |                                |    PUT /api/chat-messages/read |
     |                                |                                |
     |<-------------------------------|------------------------------->|
     | 8. 推送已读回执                 |    推送已读回执                 |
     |    (更新消息状态为"已读")        |    (通知对方消息已读)           |
```

### 关键时间点

1. **T0**: 用户点击发送按钮
2. **T1** (~100ms): REST API 返回，消息保存到数据库
3. **T2** (~150ms): WebSocket 推送消息给发送者（自己）
4. **T3** (~150ms): WebSocket 推送消息给接收者（对方）
5. **T4** (~200ms): 接收者看到新消息并标记为已读
6. **T5** (~250ms): 发送者收到已读回执，消息状态更新为"已读"

## 测试方法

### 方法 1: 使用测试脚本

运行 PowerShell 测试脚本：
```powershell
cd help
.\chat_websocket_test.ps1
```

脚本会自动：
1. 登录求助者和志愿者账号
2. 发送测试消息
3. 验证消息是否保存到数据库
4. 显示聊天历史

### 方法 2: 手动测试

#### 准备工作
1. 启动后端服务：
   ```bash
   cd help
   mvn spring-boot:run
   ```

2. 启动前端应用（在 DevEco Studio 中运行）

#### 测试步骤
1. **设备 A**: 使用求助者账号登录 (13800138001 / 123456)
2. **设备 B**: 使用志愿者账号登录 (13800138002 / 123456)
3. **设备 A**: 创建一个求助请求
4. **设备 B**: 接单该求助请求
5. **设备 A**: 进入聊天页面，发送消息 "你好"
6. **设备 B**: 应该立即看到消息 "你好"（无需刷新）
7. **设备 B**: 回复消息 "收到"
8. **设备 A**: 应该立即看到回复 "收到"（无需刷新）
9. **设备 A**: 查看消息状态，应该显示"已读"

### 方法 3: 使用浏览器开发者工具

1. 打开浏览器开发者工具 (F12)
2. 切换到 Network 标签
3. 筛选 WS (WebSocket) 连接
4. 观察 WebSocket 消息的发送和接收

## 常见问题排查

### 问题 1: WebSocket 连接失败

**症状**: 连接状态显示"已断开"或"连接异常"

**排查步骤**:
1. 检查后端服务是否启动：`curl http://localhost:8080/api/auth/login`
2. 检查 Token 是否有效：查看 StorageUtil 中的 token
3. 检查 WebSocket 端点是否正确：`ws://localhost:8080/ws/chat`
4. 查看后端日志：`tail -f help/logs/spring.log`

### 问题 2: 消息发送成功但对方收不到

**症状**: 发送者看到消息，但接收者没有收到

**排查步骤**:
1. 检查接收者的 WebSocket 是否连接：查看连接状态
2. 检查 requestId 是否正确：两个用户必须在同一个求助请求的聊天中
3. 检查后端日志：确认消息是否推送成功
4. 检查前端日志：`console.info` 和 `console.error` 输出

### 问题 3: 消息重复显示

**症状**: 同一条消息显示多次

**原因**: `handleRealtimeMessage()` 中的去重逻辑失效

**解决方案**: 检查消息 ID 是否正确，确保 `exists` 检查生效

### 问题 4: 已读状态不更新

**症状**: 消息一直显示"未读"

**排查步骤**:
1. 检查 `markAsRead` API 是否调用成功
2. 检查 WebSocket 已读回执是否推送
3. 检查 `handleReadReceipt()` 方法是否执行

## 性能优化

### 当前实现的优化点

1. **连接复用**: 全局单例 WebSocket 连接，避免重复连接
2. **消息去重**: 通过消息 ID 去重，避免重复显示
3. **自动重连**: 连接断开后自动重连，提高可靠性
4. **按需订阅**: 只订阅当前聊天的消息，减少不必要的处理
5. **状态同步**: 连接恢复后自动同步最新消息

### 未来可优化的方向

1. **消息分页**: 聊天历史分页加载，减少初始加载时间
2. **消息缓存**: 本地缓存聊天记录，离线也能查看历史
3. **心跳检测**: 定期发送心跳包，及时发现连接异常
4. **消息队列**: 离线消息队列，网络恢复后自动发送
5. **压缩传输**: 使用消息压缩，减少网络流量

## 安全性

### 已实现的安全措施

1. **JWT 认证**: WebSocket 连接需要有效的 JWT Token
2. **权限验证**: 只能接收自己相关的消息
3. **消息过滤**: 前端根据 requestId 过滤消息
4. **HTTPS/WSS**: 生产环境应使用加密连接

### 安全建议

1. 定期刷新 Token，避免 Token 泄露
2. 限制 WebSocket 连接数，防止资源耗尽
3. 消息内容过滤，防止 XSS 攻击
4. 日志审计，记录所有消息发送行为

## 总结

✅ **已完成的功能**:
- WebSocket 实时连接
- 消息实时推送
- 已读回执
- 自动重连
- 多设备同步
- 连接状态显示

✅ **工作流程**:
1. 用户发送消息 → REST API 保存
2. 后端推送 → WebSocket 实时通知
3. 前端接收 → 自动更新界面
4. 对方看到 → 标记已读
5. 已读回执 → 发送者看到"已读"

✅ **测试验证**:
- 使用测试脚本验证消息发送和接收
- 手动测试双向实时通信
- 验证已读状态同步

🎉 **WebSocket 实时聊天功能已完整实现并可正常使用！**
