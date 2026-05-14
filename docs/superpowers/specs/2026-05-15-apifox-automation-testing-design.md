# Apifox 自动化测试接入设计说明

**日期**: 2026-05-15

## 范围
- 为 `help` 后端补齐可导入 `Apifox` 的 `OpenAPI` 文档输出能力。
- 以真实后端 controller 为准，重建 `Apifox` 接口分组与导入基线。
- 设计 `Apifox` 本地联调环境变量、鉴权传递方式、自动化测试集合分层和关键数据流。
- 输出一套可持续维护的“后端改动 -> OpenAPI 更新 -> Apifox 重新导入 -> 自动化回归”路径。

## 背景
- 当前仓库包含 `help` 后端和 `help_system` 前端，后端使用 Spring Boot 3.5.11。
- 后端已经可以启动，但 `pom.xml` 中尚未接入 `Swagger/OpenAPI` 相关依赖。
- 仓库内已有接口文档，但文档与代码已经出现偏差，不能再直接作为 `Apifox` 的唯一数据源。
- 实际接口应以 controller 为准，例如：
  - 聊天接口实际位于 `/api/chat/*`
  - 志愿者订单接口实际位于 `/api/volunteer/orders/*`
  - 求助请求接口实际位于 `/api/requests/*`

## 目标
- 让 `help` 后端成为 `Apifox` 的唯一接口真相源。
- 让 `Apifox` 可以通过 URL 直接导入 `OpenAPI` 文档，而不是依赖手工录入。
- 让后续接口变更时，团队只需要维护后端注解和代码，不再重复维护多份易漂移文档。
- 为后续自动化测试准备统一的环境变量、前后置脚本和测试集合结构。

## 非目标
- 本轮不直接操作或修改用户在线 `Apifox` 项目。
- 本轮不集成 CI/CD 平台或远程定时回归执行。
- 本轮不重构现有业务返回结构，也不统一所有异常返回格式。
- 本轮不补齐所有业务测试数据初始化脚本，只使用现有本地运行数据和测试账号能力。

## 备选方案

### 方案 A：后端补 OpenAPI，Apifox 从 URL 导入
- 做法：在 `help` 后端增加 `springdoc-openapi`，输出 `/v3/api-docs` 与 `swagger-ui`。
- 优点：
  - 后续维护成本最低。
  - 可以直接消除“文档和 controller 漂移”的问题。
  - 适合后续继续扩展自动化测试和多人协作。
- 缺点：
  - 需要改少量后端配置与注解。

### 方案 B：完全手工维护 Apifox
- 做法：根据现有 controller 和 markdown 文档手工在 `Apifox` 建接口。
- 优点：
  - 今天就能开始，不改后端。
- 缺点：
  - 最容易继续漂移。
  - 接口变更后需要重复维护。

### 方案 C：先手工导入核心接口，后续再切 OpenAPI
- 做法：短期先录入核心接口，后续再让后端补文档输出。
- 优点：
  - 能快速看到 `Apifox` 项目雏形。
- 缺点：
  - 整理工作会重复两遍。

## 推荐方案
- 采用方案 A。
- 原因：
  - 后端当前已经可以正常启动，具备落地前提。
  - 当前接口文档已与真实代码不完全一致，继续走手工模式会持续累积维护债务。
  - 方案 A 能兼顾“现在继续自动化测试”和“后续稳定维护”两个目标。

## 现状约束

### 鉴权现状
- `WebConfig` 当前通过 `AuthInterceptor` 拦截 `/api/**`。
- 当前明确不需要 Token 的公开接口有：
  - `/api/auth/login`
  - `/api/auth/register`
  - `/api/auth/send-code`
  - `/api/auth/refresh-token`
  - `/api/geocode/regeo`
- 其余 `/api/**` 接口默认需要 `Authorization: Bearer <token>`。

### 响应结构现状
- 后端大部分接口统一返回 `Result<T>`，核心字段为：
  - `code`
  - `message`
  - `data`
  - `timestamp`
- 业务失败时，HTTP 状态码不一定变化，`body.code` 才是主要判断依据。
- `AuthInterceptor` 直接拦截失败时可能只返回 HTTP 401，而不是完整 `Result<T>`。

### 数据源约束
- 旧接口文档可以作为补充参考，但不能作为导入基线。
- 导入基线必须以 `help/src/main/java/com/csi/help/controller` 下的真实 controller 和 DTO 为准。

## 最终方案设计

### 1. 后端文档输出层
- 在 `help` 后端接入 `springdoc-openapi-starter-webmvc-ui`。
- 默认暴露：
  - `GET /v3/api-docs`
  - `GET /swagger-ui/index.html`
- 新增一个 OpenAPI 配置类，负责：
  - 设置项目标题、版本、描述。
  - 定义 `Bearer Token` 安全方案。
  - 为公开接口与受保护接口提供一致的文档语义。
  - 为 `Apifox` 导入提供稳定结构。

### 2. Controller 文档增强层
- 为 controller 和关键接口补充注解，至少包括：
  - `@Tag`
  - `@Operation`
  - 必要时为请求体、响应体、参数补说明
- 不要求本轮把所有 DTO 示例都写得极其完整，但至少要保证：
  - 分组正确
  - 摘要明确
  - 鉴权要求明确
  - 关键请求字段可识别

### 3. 文档访问与拦截兼容
- 当前 `AuthInterceptor` 只拦 `/api/**`，理论上不会拦 `/v3/api-docs` 与 `/swagger-ui/**`。
- 本轮仍建议在 `WebConfig` 中显式放行以下路径，降低未来改动风险：
  - `/v3/api-docs/**`
  - `/swagger-ui/**`
  - `/swagger-ui.html`
- 这样即使后续团队调整路径、代理规则或静态资源策略，也不容易误伤文档访问。

### 4. Apifox 导入基线
- `Apifox` 项目不再通过手工新建接口起步，而是通过 `OpenAPI URL` 导入。
- 导入 URL 使用本地开发地址：
  - `http://localhost:8080/v3/api-docs`
- 导入后以真实接口路径为准，不再参考旧文档中的过时命名。

### 5. Apifox 分组设计
- 认证
  - `/api/auth/*`
- 求助请求
  - `/api/requests/*`
- 紧急求助
  - `/api/emergency/*`
- 聊天
  - `/api/chat/*`
- 社区管理
  - `/api/community/*`
- 用户
  - `/api/users/*`
- 志愿者概览
  - `/api/volunteer/statistics`
  - `/api/volunteer/nearby-requests`
- 志愿者订单
  - `/api/volunteer/orders/*`
- 评价
  - `/api/reviews/*`
- 地理编码
  - `/api/geocode/regeo`

### 6. Apifox 环境变量设计
- 至少建立一个 `本地联调` 环境。
- 基础变量：
  - `baseUrl = http://localhost:8080`
  - `seekerPhone`
  - `seekerPassword`
  - `volunteerPhone`
  - `volunteerPassword`
  - `communityPhone`
  - `communityPassword`
- 登录态变量：
  - `seekerToken`
  - `volunteerToken`
  - `communityToken`
  - `refreshToken`
- 业务链路变量：
  - `requestId`
  - `orderId`
  - `chatRequestId`
- 可选调试变量：
  - `lastResponseCode`
  - `lastResponseMessage`

### 7. Token 传递策略
- 三个角色分别登录，分别保存各自 token。
- 受保护接口统一使用环境变量拼接请求头：
  - `Authorization: Bearer {{seekerToken}}`
  - `Authorization: Bearer {{volunteerToken}}`
  - `Authorization: Bearer {{communityToken}}`
- 不同测试集合按角色区分默认 token，避免角色串用导致误测。

### 8. 自动化测试集合分层

#### 冒烟集合 `Smoke-P0`
- 登录成功
- 获取求助列表
- 创建求助
- 获取我的求助
- 志愿者接单
- 获取我的订单
- 完成订单

#### 鉴权集合 `Auth`
- 登录成功
- 登录失败
- 刷新 Token
- 无 Token 访问受保护接口
- 错 Token 访问受保护接口

#### 求助集合 `Request`
- 创建求助
- 查询求助详情
- 更新求助
- 取消求助
- 查询我的求助
- 查询最近求助
- 查询手表状态相关接口

#### 志愿者集合 `Volunteer Flow`
- 查询附近求助
- 接单
- 查询订单详情
- 更新订单状态
- 查询订单进度
- 完成订单

#### 社区集合 `Community`
- 获取待处理请求
- 获取可用志愿者
- 分配志愿者
- 获取统计数据
- 获取志愿者管理数据

#### 聊天集合 `Chat`
- 发送消息
- 获取聊天历史
- 标记已读
- 获取未读数

## 自动化数据流设计
- 求助者登录，保存 `seekerToken`
- 求助者创建求助，保存 `requestId`
- 志愿者登录，保存 `volunteerToken`
- 志愿者接单，保存 `orderId`
- 聊天相关接口复用 `requestId`
- 订单详情、进度、完成接口复用 `orderId`
- 社区相关测试可根据需要复用新创建的 `requestId`

## Apifox 脚本设计

### 登录后置脚本
- 从响应体提取：
  - `data.token`
  - `data.refreshToken`
  - `data.user.role`
- 根据当前登录用例把 token 写回对应环境变量。

### 创建求助后置脚本
- 从响应体提取：
  - `data.id -> requestId`

### 接单后置脚本
- 从响应体提取：
  - `data.id -> orderId`

### 通用断言脚本
- 成功接口断言：
  - HTTP 状态码为 `200`
  - `body.code === 200`
  - `body.message === "success"`
  - `body.timestamp` 存在
- 鉴权失败接口断言：
  - HTTP 状态码为 `401`

## 错误处理设计
- 业务接口测试不以“只有 HTTP 200 才算成功”为唯一判断标准。
- 对统一返回的业务接口，以 `body.code` 作为主要断言依据。
- 对拦截器拦截类异常，以 HTTP 401 作为主要断言依据。
- 对不存在资源、越权访问等接口，允许根据当前实现断言 `body.code` 为 `403/404/500` 中的真实值，但文档中要明确这一点，避免误判为自动化失败。

## 文档与代码的一致性策略
- 以后新增接口时，先补 controller 和 OpenAPI 注解，再重新导入 `Apifox`。
- 不再把 markdown 接口清单当作主数据源。
- 如需保留 markdown 文档，仅作为面向人阅读的辅助说明，而非工具导入源。

## 涉及文件
- `C:\Users\22789\Desktop\endProject\help\pom.xml`
- `C:\Users\22789\Desktop\endProject\help\src\main\java\com\csi\help\config\WebConfig.java`
- `C:\Users\22789\Desktop\endProject\help\src\main\java\com\csi\help\config\` 下新增 OpenAPI 配置类
- `C:\Users\22789\Desktop\endProject\help\src\main\java\com\csi\help\controller\*.java`
- `C:\Users\22789\Desktop\endProject\help_system\API接口清单.md`
- `C:\Users\22789\Desktop\endProject\docs\superpowers\specs\2026-05-15-apifox-automation-testing-design.md`

## 验证方案
- 后端启动后能正常访问 `http://localhost:8080/v3/api-docs`
- 后端启动后能正常访问 `http://localhost:8080/swagger-ui/index.html`
- `Apifox` 能通过 URL 成功导入接口定义
- 导入结果中的核心分组和路径与 controller 一致
- 登录接口可自动提取 token
- 创建求助和接单接口可自动提取 `requestId`、`orderId`
- `Smoke-P0` 集合至少可以串通一条完整核心链路

## 风险
- 部分 DTO 如果说明不足，导入后的字段示例可能不够直观，但不影响先建立自动化基线。
- 旧接口文档与真实接口不一致，若团队后续继续参考旧文档而非 OpenAPI，会再次造成偏差。
- 当前异常返回并非全部统一为 `Result<T>`，自动化断言需要区分“拦截器失败”和“业务失败”。
- 若测试数据被频繁手动修改，某些依赖固定角色或状态的自动化用例可能不稳定。

## 后续可选优化
- 为关键 DTO 增加更细的字段说明与示例值，让 `Apifox` 展示更完整。
- 为公开接口和受保护接口补充统一的响应示例。
- 补充可重复执行的数据库种子数据脚本，提升自动化稳定性。
- 后续再把 `Apifox` 回归执行接入 CI 或定时巡检。

## 自检结论
- 本文档没有保留占位符、`TODO` 或未决命名。
- 范围明确限制在“OpenAPI 导入基线 + Apifox 自动化测试设计”，没有扩展到 CI 或线上治理。
- 推荐方案与当前代码现状一致，核心依据是 controller 和实际鉴权逻辑，而不是旧文档。
- 自动化设计已经覆盖数据源、分组、环境变量、脚本、断言、错误处理和验证路径，足以进入实施计划阶段。
