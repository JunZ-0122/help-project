# Apifox 自动化测试接入指南

> 以 `help` 后端导出的 `OpenAPI` 文档和真实 controller 路径为准，不再以旧版 markdown 接口清单作为导入基线。

## 1. OpenAPI 导入地址

- JSON: `http://localhost:8080/v3/api-docs`
- Swagger UI: `http://localhost:8080/swagger-ui/index.html`

## 2. 推荐分组

- 认证
- 求助请求
- 紧急求助
- 聊天
- 社区管理
- 用户
- 志愿者概览
- 志愿者订单
- 评价
- 地理编码

## 3. 本地联调环境变量

- `baseUrl=http://localhost:8080`
- `seekerPhone`
- `seekerPassword`
- `volunteerPhone`
- `volunteerPassword`
- `communityPhone`
- `communityPassword`
- `seekerToken`
- `volunteerToken`
- `communityToken`
- `refreshToken`
- `requestId`
- `orderId`
- `chatRequestId`

## 4. 推荐自动化集合

- `Smoke-P0`
- `Auth`
- `Request`
- `Volunteer Flow`
- `Community`
- `Chat`

## 5. 建议的执行顺序

1. 导入 `OpenAPI` 文档到 `Apifox`。
2. 创建 `本地联调` 环境并填充 `baseUrl` 和账号变量。
3. 先跑三个登录接口，分别回填 `seekerToken`、`volunteerToken`、`communityToken`。
4. 以求助者身份创建求助，提取 `requestId`。
5. 以志愿者身份接单，提取 `orderId`。
6. 再跑聊天、进度、完成订单和评价类接口。

## 6. 后置脚本示例

登录后置脚本：

```javascript
const body = pm.response.json();
pm.environment.set('seekerToken', body.data.token);
pm.environment.set('refreshToken', body.data.refreshToken);
```

创建求助后置脚本：

```javascript
const body = pm.response.json();
pm.environment.set('requestId', body.data.id);
```

接单后置脚本：

```javascript
const body = pm.response.json();
pm.environment.set('orderId', body.data.id);
```

## 7. 通用断言建议

```javascript
const body = pm.response.json();
pm.test('HTTP 200', () => pm.response.to.have.status(200));
pm.test('业务成功', () => pm.expect(body.code).to.eql(200));
pm.test('message success', () => pm.expect(body.message).to.eql('success'));
pm.test('timestamp exists', () => pm.expect(body.timestamp).to.be.ok);
```

## 8. 鉴权说明

- 除以下公开接口外，其余 `/api/**` 默认都需要 `Authorization: Bearer <token>`：
  - `/api/auth/login`
  - `/api/auth/register`
  - `/api/auth/send-code`
  - `/api/auth/refresh-token`
  - `/api/geocode/regeo`
- `logout` 在 auth 分组里，但仍需要带 token。

## 9. 关键真实路径提醒

- 聊天接口真实路径前缀是 `/api/chat`
- 志愿者订单真实路径前缀是 `/api/volunteer/orders`
- 志愿者概览真实路径前缀是 `/api/volunteer`
- 求助请求真实路径前缀是 `/api/requests`

## 10. 自动化链路最小闭环

建议优先串通这条闭环：

1. 求助者登录
2. 创建求助
3. 志愿者登录
4. 志愿者接单
5. 查询订单详情
6. 发送聊天消息
7. 完成订单

## 11. 导入后抽样检查

导入完成后，优先确认以下路径已经出现在 `Apifox` 中：

- `/api/auth/login`
- `/api/requests`
- `/api/chat/{requestId}`
- `/api/volunteer/orders/accept`
- `/api/community/statistics`
