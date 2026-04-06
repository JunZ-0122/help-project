# 项目结构说明

## 目录结构

```
entry/src/main/ets/
├── models/                 # 数据模型层
│   ├── User.ets           # 用户实体
│   ├── Auth.ets           # 认证实体
│   ├── Request.ets        # 求助请求实体
│   ├── Emergency.ets      # 紧急求助实体
│   ├── Message.ets        # 聊天消息实体
│   ├── Order.ets          # 志愿者订单实体
│   ├── Review.ets         # 评价实体
│   ├── Community.ets      # 社区管理实体
│   ├── Settings.ets       # 设置实体
│   ├── Common.ets         # 通用类型
│   ├── index.ets          # 统一导出
│   └── README.md          # 使用说明
│
├── services/              # 服务层（API 调用）
│   ├── ApiService.ets     # API 服务基类
│   ├── AuthService.ets    # 认证服务
│   ├── WebSocketService.ets # WebSocket 服务
│   └── index.ets          # 统一导出
│
├── utils/                 # 工具类
│   ├── StorageUtil.ets    # 本地存储工具
│   ├── DateUtil.ets       # 日期时间工具
│   └── index.ets          # 统一导出
│
├── pages/                 # 页面组件
│   ├── community/         # 社区管理页面
│   │   ├── CommunityHomePage.ets    # 社区首页
│   │   ├── AssignPage.ets           # 分配页面
│   │   ├── ManagePage.ets           # 管理页面
│   │   ├── RequestDetailPage.ets    # 请求详情
│   │   └── StatisticsPage.ets       # 统计页面
│   │
│   ├── help-seeker/       # 求助者页面
│   │   ├── HelpSeekerHomePage.ets   # 求助者首页
│   │   ├── EmergencyRequestPage.ets # 紧急求助
│   │   ├── RequestTypePage.ets      # 选择求助类型
│   │   ├── MyRequestsPage.ets       # 我的求助
│   │   ├── RequestDetailPage.ets    # 求助详情
│   │   └── ProfilePage.ets          # 个人中心
│   │
│   ├── volunteer/         # 志愿者页面
│   │   ├── VolunteerHomePage.ets    # 志愿者首页
│   │   ├── RequestDetailPage.ets    # 请求详情
│   │   ├── MyOrdersPage.ets         # 我的订单
│   │   ├── OrderDetailPage.ets      # 订单详情
│   │   ├── ProgressPage.ets         # 进度跟踪
│   │   ├── ChatPage.ets             # 聊天页面
│   │   ├── ReviewPage.ets           # 评价页面
│   │   └── ProfilePage.ets          # 个人中心
│   │
│   ├── LoginPage.ets      # 登录页面
│   ├── RoleSelectPage.ets # 角色选择
│   ├── SplashPage.ets     # 启动页
│   ├── Index.ets          # 主页
│   └── ErrorPage.ets      # 错误页面
│
├── entryability/          # 应用入口
│   └── EntryAbility.ets
│
└── entrybackupability/    # 备份能力
    └── EntryBackupAbility.ets
```

## 分层架构

### 1. 数据模型层 (models/)
- 定义所有数据实体的 TypeScript 接口
- 与后端 JSON 数据格式一一对应
- 提供类型安全和代码提示

### 2. 服务层 (services/)
- 封装所有后端 API 调用
- 处理 HTTP 请求和响应
- 管理 WebSocket 连接
- 统一错误处理

### 3. 工具层 (utils/)
- 提供通用工具函数
- 本地存储管理
- 日期时间处理
- 其他辅助功能

### 4. 页面层 (pages/)
- UI 组件和页面逻辑
- 使用 @State 管理页面状态
- 调用服务层获取数据
- 渲染用户界面

## 数据流向

```
用户操作 → 页面组件 → 服务层 → 后端 API
                ↓
            数据模型
                ↓
            页面渲染
```

## 命名规范

### 文件命名
- 模型文件：大驼峰，如 `User.ets`
- 服务文件：大驼峰 + Service，如 `AuthService.ets`
- 工具文件：大驼峰 + Util，如 `StorageUtil.ets`
- 页面文件：大驼峰 + Page，如 `LoginPage.ets`

### 变量命名
- 接口/类型：大驼峰，如 `UserProfile`
- 变量/函数：小驼峰，如 `getUserInfo`
- 常量：全大写下划线，如 `API_BASE_URL`

### 接口命名
- 实体接口：名词，如 `User`, `HelpRequest`
- 请求接口：名词 + Request，如 `LoginRequest`
- 响应接口：名词 + Response，如 `LoginResponse`

## 使用示例

### 1. 在页面中使用模型和服务

```typescript
import { HelpRequest, PageResponse } from '../models';
import { RequestApi } from '../services';

@Entry
@Component
struct MyRequestsPage {
  @State requests: HelpRequest[] = [];
  @State loading: boolean = false;

  async aboutToAppear() {
    await this.loadRequests();
  }

  async loadRequests() {
    this.loading = true;
    try {
      const response: PageResponse<HelpRequest> = await RequestApi.getRequests(1, 10);
      this.requests = response.items;
    } catch (err) {
      console.error('加载失败:', err);
    } finally {
      this.loading = false;
    }
  }

  build() {
    Column() {
      ForEach(this.requests, (request: HelpRequest) => {
        Text(request.title)
      })
    }
  }
}
```

### 2. 使用工具类

```typescript
import { StorageUtil, DateUtil } from '../utils';

// 保存 token
await StorageUtil.saveToken('token', 'refresh-token');

// 格式化日期
const formattedDate = DateUtil.format(new Date(), 'YYYY-MM-DD HH:mm');

// 获取相对时间
const relativeTime = DateUtil.getRelativeTime('2024-01-01T10:00:00Z');
```

### 3. WebSocket 实时通信

```typescript
import { WebSocketService } from '../services';
import { ChatMessage } from '../models';

// 连接 WebSocket
const ws = WebSocketService.getInstance();
await ws.connect('your-token');

// 监听消息
ws.onMessage('request-id', (message: ChatMessage) => {
  console.log('收到消息:', message);
});

// 发送消息
ws.sendMessage({
  requestId: 'request-id',
  text: 'Hello',
  type: 'text'
});
```

## 后端对接清单

### 需要实现的 API 接口

#### 认证相关
- [ ] POST /api/auth/login - 用户登录
- [ ] POST /api/auth/register - 用户注册
- [ ] POST /api/auth/send-code - 发送验证码
- [ ] POST /api/auth/reset-password - 重置密码
- [ ] POST /api/auth/refresh-token - 刷新 Token
- [ ] POST /api/auth/logout - 退出登录

#### 求助请求相关
- [ ] GET /api/requests - 获取求助列表
- [ ] POST /api/requests - 创建求助
- [ ] GET /api/requests/:id - 获取求助详情
- [ ] PUT /api/requests/:id - 更新求助
- [ ] DELETE /api/requests/:id - 取消求助

#### 聊天消息相关
- [ ] GET /api/messages/:requestId - 获取聊天历史
- [ ] POST /api/messages - 发送消息
- [ ] PUT /api/messages/read - 标记已读
- [ ] WebSocket /ws - 实时消息推送

#### 志愿者订单相关
- [ ] GET /api/orders/my - 获取我的订单
- [ ] POST /api/orders/accept - 接受订单
- [ ] PUT /api/orders/:id/status - 更新订单状态
- [ ] POST /api/orders/:id/complete - 完成订单

#### 评价相关
- [ ] POST /api/reviews - 创建评价
- [ ] GET /api/reviews/:orderId - 获取评价详情

#### 社区管理相关
- [ ] GET /api/community/requests/pending - 获取待分配请求
- [ ] GET /api/community/volunteers/available - 获取可用志愿者
- [ ] POST /api/community/assign - 分配志愿者
- [ ] GET /api/community/statistics - 获取统计数据

#### 用户相关
- [ ] GET /api/users/:id - 获取用户资料
- [ ] PUT /api/users/profile - 更新用户资料
- [ ] GET /api/users/settings - 获取用户设置
- [ ] PUT /api/users/settings - 更新用户设置

## 注意事项

1. 所有 API 调用都应该有错误处理
2. 敏感数据（token）应该加密存储
3. 网络请求应该有超时设置
4. 大数据列表应该实现分页加载
5. 图片上传应该压缩处理
6. WebSocket 断线应该自动重连
7. 所有用户输入都应该验证
8. 日期时间应该统一使用 ISO 8601 格式

## 开发流程

1. 后端提供 API 文档
2. 前端根据文档定义数据模型
3. 实现服务层 API 调用
4. 页面组件调用服务层
5. 测试和调试
6. 优化和重构
