# 数据模型使用说明

## 目录结构

```
models/
├── User.ets           # 用户相关实体
├── Request.ets        # 求助请求相关实体
├── Message.ets        # 聊天消息相关实体
├── Order.ets          # 志愿者订单相关实体
├── Community.ets      # 社区管理相关实体
├── Common.ets         # 通用类型定义
├── index.ets          # 统一导出
└── README.md          # 使用说明
```

## 使用方式

### 1. 导入模型

```typescript
// 导入单个模型
import { User } from '../models/User';

// 导入多个模型（推荐）
import { User, HelpRequest, ChatMessage } from '../models';
```

### 2. 在页面中使用

```typescript
@Entry
@Component
struct MyPage {
  // 使用模型定义状态
  @State requests: HelpRequest[] = [];
  @State currentUser: User | null = null;
  
  async loadData() {
    // 从 API 获取数据
    const response = await RequestApi.getRequests();
    this.requests = response.items;
  }
}
```

### 3. API 调用示例

```typescript
import { RequestApi, MessageApi } from '../services/ApiService';

// 获取求助列表
const requests = await RequestApi.getRequests(1, 10);

// 创建求助
const newRequest = await RequestApi.createRequest({
  type: 'medical',
  title: '需要陪同就医',
  description: '明天上午需要去医院',
  location: '北京市朝阳区',
  urgency: 'high'
});

// 发送消息
const message = await MessageApi.sendMessage({
  requestId: '123',
  text: '你好',
  type: 'text'
});
```

## 数据模型说明

### User（用户）
- 基础用户信息
- 用户资料（UserProfile）包含更详细的信息

### HelpRequest（求助请求）
- 求助类型：medical（就医）、shopping（购物）、repair（维修）、companion（陪伴）、emergency（紧急）
- 紧急程度：low、medium、high、emergency
- 状态：pending、assigned、in-progress、completed、cancelled

### ChatMessage（聊天消息）
- 消息类型：text（文字）、voice（语音）、image（图片）、location（位置）
- 支持 WebSocket 实时通信

### VolunteerOrder（志愿者订单）
- 志愿者接单后的订单信息
- 包含进度跟踪（OrderProgress）

### CommunityRequest（社区管理）
- 社区管理员视角的请求信息
- 志愿者信息（VolunteerInfo）
- 分配记录（AssignmentRecord）
- 统计数据（CommunityStatistics）

## 后端对接说明

### JSON 数据格式

后端返回的 JSON 数据应该符合以下格式：

```json
{
  "code": 200,
  "message": "success",
  "data": {
    // 实际数据，对应模型定义
  },
  "timestamp": "2024-01-01T00:00:00Z"
}
```

### 分页数据格式

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "items": [...],
    "total": 100,
    "page": 1,
    "pageSize": 10,
    "totalPages": 10
  },
  "timestamp": "2024-01-01T00:00:00Z"
}
```

## WebSocket 消息格式

聊天消息通过 WebSocket 实时推送，格式如下：

```json
{
  "type": "message",
  "data": {
    "id": 1,
    "requestId": "123",
    "senderId": "user1",
    "senderName": "张三",
    "text": "你好",
    "time": "14:30",
    "type": "text",
    "createdAt": "2024-01-01T14:30:00Z"
  }
}
```

## 注意事项

1. 所有模型都使用 TypeScript interface 定义
2. 可选字段使用 `?` 标记
3. 时间字段统一使用 ISO 8601 格式字符串
4. 枚举类型使用字符串字面量联合类型
5. 所有 API 调用都应该有错误处理
6. 敏感信息（如密码）不应该包含在模型中

## TODO

- [ ] 实现 HTTP 请求封装
- [ ] 添加请求拦截器（token、错误处理）
- [ ] 实现 WebSocket 连接管理
- [ ] 添加数据缓存机制
- [ ] 实现离线数据同步
