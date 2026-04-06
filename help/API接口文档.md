# Help System - API 接口文档

## 基础信息

- **Base URL**: `http://localhost:8080/api`
- **认证方式**: JWT Bearer Token
- **Content-Type**: `application/json`

## 认证说明

除了以下接口外，所有接口都需要在 Header 中携带 Token：

```
Authorization: Bearer {token}
```

**无需认证的接口**：
- POST /api/auth/login
- POST /api/auth/register
- POST /api/auth/send-code
- POST /api/auth/refresh

---

## 1. 认证模块 (AuthController)

### 1.1 用户登录

**接口**: `POST /api/auth/login`

**请求参数**:
```json
{
  "phone": "13800138000",
  "password": "123456"
}
```

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "user123",
      "name": "张三",
      "phone": "13800138000",
      "role": "help-seeker",
      "avatar": null
    }
  },
  "timestamp": "2024-03-07T10:00:00"
}
```

### 1.2 用户注册

**接口**: `POST /api/auth/register`

**请求参数**:
```json
{
  "phone": "13800138000",
  "password": "123456",
  "verificationCode": "123456",
  "name": "张三",
  "role": "help-seeker"
}
```

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "user123",
      "name": "张三",
      "phone": "13800138000",
      "role": "help-seeker"
    }
  }
}
```

### 1.3 发送验证码

**接口**: `POST /api/auth/send-code`

**请求参数**:
```json
{
  "phone": "13800138000"
}
```

**响应示例**:
```json
{
  "code": 200,
  "message": "验证码已发送",
  "data": null
}
```

### 1.4 刷新 Token

**接口**: `POST /api/auth/refresh`

**请求参数**:
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

### 1.5 退出登录

**接口**: `POST /api/auth/logout`

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": null
}
```

---

## 2. 求助请求模块 (HelpRequestController)

### 2.1 创建求助请求

**接口**: `POST /api/help-requests/`

**请求参数**:
```json
{
  "title": "需要帮助购买日用品",
  "description": "因行动不便，需要帮忙购买一些日用品",
  "type": "daily-care",
  "urgency": "normal",
  "location": "北京市朝阳区XX小区",
  "contactPhone": "13800138000"
}
```

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": "req123",
    "title": "需要帮助购买日用品",
    "status": "pending",
    "createdAt": "2024-03-07T10:00:00"
  }
}
```

### 2.2 获取求助请求列表（分页）

**接口**: `GET /api/help-requests/`

**查询参数**:
- `page`: 页码（默认 1）
- `pageSize`: 每页数量（默认 10）
- `status`: 状态筛选（可选）

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "total": 100,
    "items": [
      {
        "id": "req123",
        "title": "需要帮助购买日用品",
        "type": "daily-care",
        "urgency": "normal",
        "status": "pending",
        "createdAt": "2024-03-07T10:00:00"
      }
    ]
  }
}
```

### 2.3 获取我的求助请求

**接口**: `GET /api/help-requests/my`

**查询参数**:
- `status`: 状态筛选（可选）

**响应示例**: 同 2.2

### 2.4 获取求助请求详情

**接口**: `GET /api/help-requests/{id}`

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": "req123",
    "userId": "user123",
    "title": "需要帮助购买日用品",
    "description": "因行动不便，需要帮忙购买一些日用品",
    "type": "daily-care",
    "urgency": "normal",
    "status": "pending",
    "location": "北京市朝阳区XX小区",
    "contactPhone": "13800138000",
    "createdAt": "2024-03-07T10:00:00",
    "updatedAt": "2024-03-07T10:00:00"
  }
}
```

### 2.5 更新求助请求

**接口**: `PUT /api/help-requests/{id}`

**请求参数**:
```json
{
  "title": "需要帮助购买日用品（更新）",
  "description": "更新后的描述",
  "urgency": "urgent"
}
```

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": null
}
```

### 2.6 删除求助请求

**接口**: `DELETE /api/help-requests/{id}`

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": null
}
```

---

## 3. 志愿者订单模块 (VolunteerOrderController)

### 3.1 接受求助请求

**接口**: `POST /api/volunteer/orders/accept`

**请求参数**:
```json
{
  "requestId": "req123"
}
```

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": "order123",
    "requestId": "req123",
    "volunteerId": "volunteer123",
    "status": "accepted",
    "acceptedAt": "2024-03-07T10:00:00"
  }
}
```

### 3.2 获取我的订单列表

**接口**: `GET /api/volunteer/orders/my`

**查询参数**:
- `status`: 状态筛选（可选）

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": [
    {
      "id": "order123",
      "requestId": "req123",
      "volunteerId": "volunteer123",
      "status": "accepted",
      "acceptedAt": "2024-03-07T10:00:00"
    }
  ]
}
```

### 3.3 获取订单详情

**接口**: `GET /api/volunteer/orders/{id}`

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": "order123",
    "requestId": "req123",
    "volunteerId": "volunteer123",
    "status": "in-progress",
    "acceptedAt": "2024-03-07T10:00:00",
    "completedAt": null,
    "feedback": null
  }
}
```

### 3.4 更新订单状态

**接口**: `PUT /api/volunteer/orders/{id}/status`

**请求参数**:
```json
{
  "status": "in-progress"
}
```

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": null
}
```

### 3.5 完成订单

**接口**: `POST /api/volunteer/orders/{id}/complete`

**请求参数**:
```json
{
  "feedback": "已完成购买并送达"
}
```

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": null
}
```

### 3.6 获取订单进度

**接口**: `GET /api/volunteer/orders/{id}/progress`

**响应示例**: 同 3.3

---

## 4. 聊天消息模块 (ChatMessageController)

### 4.1 发送消息

**接口**: `POST /api/chat/`

**请求参数**:
```json
{
  "requestId": "req123",
  "receiverId": "user456",
  "content": "你好，我可以帮你"
}
```

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": 1,
    "requestId": "req123",
    "senderId": "user123",
    "receiverId": "user456",
    "content": "你好，我可以帮你",
    "isRead": false,
    "createdAt": "2024-03-07T10:00:00"
  }
}
```

### 4.2 获取聊天历史

**接口**: `GET /api/chat/{requestId}`

**查询参数**:
- `page`: 页码（默认 1）
- `pageSize`: 每页数量（默认 50）

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "total": 100,
    "items": [
      {
        "id": 1,
        "requestId": "req123",
        "senderId": "user123",
        "receiverId": "user456",
        "content": "你好",
        "isRead": true,
        "createdAt": "2024-03-07T10:00:00"
      }
    ]
  }
}
```

### 4.3 标记消息为已读

**接口**: `PUT /api/chat/read`

**请求参数**:
```json
{
  "messageIds": [1, 2, 3]
}
```

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": null
}
```

### 4.4 获取未读消息数量

**接口**: `GET /api/chat/{requestId}/unread`

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": 5
}
```

---

## 5. 评价模块 (ReviewController)

### 5.1 创建评价

**接口**: `POST /api/reviews/`

**请求参数**:
```json
{
  "orderId": "order123",
  "revieweeId": "volunteer123",
  "rating": 5,
  "content": "服务很好，非常感谢"
}
```

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": "review123",
    "orderId": "order123",
    "reviewerId": "user123",
    "revieweeId": "volunteer123",
    "rating": 5,
    "content": "服务很好，非常感谢",
    "createdAt": "2024-03-07T10:00:00"
  }
}
```

### 5.2 根据订单 ID 获取评价

**接口**: `GET /api/reviews/order/{orderId}`

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": "review123",
    "orderId": "order123",
    "reviewerId": "user123",
    "revieweeId": "volunteer123",
    "rating": 5,
    "content": "服务很好，非常感谢",
    "replyContent": "谢谢您的认可",
    "createdAt": "2024-03-07T10:00:00"
  }
}
```

### 5.3 回复评价

**接口**: `POST /api/reviews/{id}/reply`

**请求参数**:
```json
{
  "replyContent": "谢谢您的认可"
}
```

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": null
}
```

---

## 6. 用户模块 (UserController)

### 6.1 获取用户信息

**接口**: `GET /api/users/{id}`

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": "user123",
    "name": "张三",
    "phone": "13800138000",
    "avatar": "https://example.com/avatar.jpg",
    "role": "help-seeker",
    "age": 65,
    "gender": "male",
    "address": "北京市朝阳区XX小区",
    "emergencyContact": "李四",
    "emergencyPhone": "13900139000"
  }
}
```

### 6.2 获取当前用户信息

**接口**: `GET /api/users/me`

**响应示例**: 同 6.1

### 6.3 更新用户信息

**接口**: `PUT /api/users/me`

**请求参数**:
```json
{
  "name": "张三",
  "age": 66,
  "address": "北京市朝阳区XX小区2号楼"
}
```

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": null
}
```

### 6.4 更新头像

**接口**: `PUT /api/users/me/avatar`

**请求参数**:
```json
{
  "avatarUrl": "https://example.com/new-avatar.jpg"
}
```

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": null
}
```

---

## 7. 社区管理模块 (CommunityController)

### 7.1 获取所有求助请求（分页）

**接口**: `GET /api/community/requests`

**查询参数**:
- `page`: 页码（默认 1）
- `pageSize`: 每页数量（默认 10）
- `status`: 状态筛选（可选）

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "total": 100,
    "items": [
      {
        "id": "req123",
        "userId": "user123",
        "title": "需要帮助购买日用品",
        "type": "daily-care",
        "urgency": "normal",
        "status": "pending",
        "createdAt": "2024-03-07T10:00:00"
      }
    ]
  }
}
```

### 7.2 分配志愿者

**接口**: `POST /api/community/assign`

**请求参数**:
```json
{
  "requestId": "req123",
  "volunteerId": "volunteer123"
}
```

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": "order123",
    "requestId": "req123",
    "volunteerId": "volunteer123",
    "status": "assigned"
  }
}
```

### 7.3 获取统计数据

**接口**: `GET /api/community/statistics`

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "pendingRequests": 10,
    "assignedRequests": 20,
    "completedRequests": 50,
    "totalRequests": 80
  }
}
```

### 7.4 审核求助请求

**接口**: `POST /api/community/requests/{id}/review`

**请求参数**:
```json
{
  "status": "approved"
}
```

**响应示例**:
```json
{
  "code": 200,
  "message": "success",
  "data": null
}
```

---

## 错误码说明

| 错误码 | 说明 |
|--------|------|
| 200 | 成功 |
| 400 | 请求参数错误 |
| 401 | 未认证或 Token 无效 |
| 403 | 无权限访问 |
| 404 | 资源不存在 |
| 500 | 服务器内部错误 |

## 测试账号

### 求助者账号
- 手机号: 13800138001
- 密码: 123456
- 角色: help-seeker

### 志愿者账号
- 手机号: 13800138002
- 密码: 123456
- 角色: volunteer

### 社区管理员账号
- 手机号: 13800138003
- 密码: 123456
- 角色: community

---

**文档版本**: v1.0  
**最后更新**: 2024-03-07
