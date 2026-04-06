# 手表端双角色闭环：计划文档

本文档约定 **求助者** 与 **志愿者** 在手表上各自形成**完整业务闭环**，页面落在 `pages/watch/` 下单独实现；**后端优先复用** 现有 `AuthService`、`ApiService` 中与手机端相同的接口。

### 产品约束（手表端固定）

| 约束 | 说明 |
|------|------|
| **不提供注册** | 手表只做**已有账号登录**（如短信验证码登录）；新用户注册、完善资料、选角在 **手机端**完成。 |
| **不在手表上切换身份** | 不提供「求助者 ⟷ 志愿者」切换入口；登录后 **仅根据账号自带 `user.role`** 进入对应首页（`WatchSeekerHome` 或 `WatchVolunteerHome`）。 |
| **无角色或角色与端能力不符** | 提示用户 **在手机端完成身份设置**，手表不调用 `UserApi.switchUserRole` / `updateUserRole` 作为常规能力。 |

工程上可发布 **两款独立安装包**（求助者手表版 / 志愿者手表版），或单包内按账号角色自动分流，但 **UI 层永不提供切换**。

---

## 1. 目标闭环（产品级）

### 1.1 求助者

```
选择类型 → 确认 → 匹配(约 3 秒) → 查看志愿者 → 进度追踪 → 评价 → 完成 ✓
```

### 1.2 志愿者

```
浏览列表 → 查看详情 → 接单 → 开始服务 → 计时服务 → 完成 ✓
```

（若产品需要志愿者侧「评价求助者」，可在「完成」后增加一步；与现有手机端 **志愿者评价求助者** 能力对齐，见 §4.2。）

---

## 2. 登录与身份（手表实现方案）

| 环节 | 建议做法 | 复用能力 |
|------|----------|----------|
| 启动 | `WatchSplashPage`：展示品牌/短暂等待；读取本地 `token` | `AuthService.isLoggedIn` / `StorageUtil` |
| 未登录 | `WatchLoginPage`：**仅登录**（手机号 + 短信验证码）；**无注册页、无「首次创建账号」流程**；按钮文案避免强调「注册」 | `AuthService.sendVerificationCode`、`AuthService.login` |
| 已登录 | 拉取或读取 `user.role`（可 `UserApi.getCurrentProfile` 刷新） | 与后端一致 |
| 分流 | `role === 'help-seeker'` → `WatchSeekerHome`；`role === 'volunteer'` → `WatchVolunteerHome`；其他 / 空 | **不提供切换**；若无法进入任一端，展示 `WatchAccountUnsupportedPage`（或对话框）：提示 **前往手机端**完成开户/身份设置 |
| 会话内 | 全程无「切换身份」菜单 | — |

**说明**

- 与手机端 **缓存独立**：文案需提示「在本设备登录」。
- **双角色闭环**指：产品上有 **求助者手表应用** 与 **志愿者手表应用** 两条完整链路（或同一 App 内账号二选一），而非同一用户在手表上随时切换角色。

---

## 3. 求助者闭环：步骤与手表页规划

| 步骤 | 用户感知 | 建议页面（`pages/watch/`） | 数据与接口 |
|------|----------|------------------------------|------------|
| 1 选择类型 | 就医 / 出行 / 生活 / 其他等 | `WatchSeekerTypePage` | 仅前端枚举，与手机 `RequestTypePage` 对齐的 `type` 字段 |
| 2 确认 | 展示简要说明、位置、联系方式（可极简） | `WatchSeekerConfirmPage` | 组装 `RequestApi.createRequest` 或 `EmergencyApi.createEmergencyRequest`（紧急类单独走紧急接口时） |
| 3 匹配(约 3 秒) | 全屏动画/文案「正在匹配志愿者…」 | `WatchSeekerMatchingPage` | **① 提交后进入本页**；**② 至少展示 3 秒**（`setTimeout`+进度）；**③ 轮询 `RequestApi.getSeekerRequestDetail` 或 `getRequestDetail`**，直到 `request.status` 表示已分配/志愿者信息出现，或超时进入错误/重试 |
| 4 查看志愿者 | 展示姓名、距离、脱敏电话等 | `WatchSeekerVolunteerPage` | 数据来自 `SeekerRequestDetail.volunteer`（`SeekerVolunteerBlock`） |
| 5 进度追踪 | 时间线、当前状态 | `WatchSeekerProgressPage` | `RequestApi.getSeekerRequestDetail` → `timeline`、`SeekerBanner`；可选轮询或 WebSocket（与手机 `RequestDetailPage` 一致时可复用 `WebSocketService`） |
| 6 评价 | 星级/标签 + 简短评价 | `WatchSeekerReviewPage` | `ReviewApi.createReview(orderId, volunteerId, ...)`，`revieweeId` 为 **志愿者**（与手机志愿者端评价求助者相反） |
| 7 完成 | 成功页或 Toast + 回首页 | `WatchSeekerDonePage` 或 弹窗后 `replaceUrl` 回 `WatchSeekerHome` | 以订单状态 `completed` 为准 |

**关于「匹配 3 秒」**

- **UI 保证**：进入匹配页后 **不少于 3 秒** 再允许进入「查看志愿者」（避免一闪而过）。
- **业务**：若 3 秒内轮询未到「已分配」，可继续显示「匹配中」并延长轮询，或提示「暂无志愿者，请稍后重试」——具体文案与后端 SLA 联调时确定。

**关于求助者「评价」**

- 现有手机端 `ReviewPage` 为 **志愿者评价求助者**；手表求助者闭环需要 **求助者评价志愿者**，需使用同一 `ReviewApi.createReview`，**`revieweeId` 传志愿者用户 ID**（来自 `SeekerVolunteerBlock.id` 或订单详情中的 `volunteerId`）。
- 若后端要求 `orderId`：从 `VolunteerOrder` 或 `SeekerRequestDetail` 关联订单 id 获取（与联调确认字段）。

---

## 4. 志愿者闭环：步骤与手表页规划

| 步骤 | 用户感知 | 建议页面（`pages/watch/`） | 数据与接口 |
|------|----------|------------------------------|------------|
| 1 浏览列表 | 附近求助 / 待接单列表 | `WatchVolunteerListPage` | `RequestApi.getNearbyRequests`（带定位）或 `getRequests` + `status: pending`（与 `VolunteerHomePage` 一致） |
| 2 查看详情 | 标题、类型、距离、地址 | `WatchVolunteerRequestDetailPage` | `RequestApi.getRequestDetail(requestId)` |
| 3 接单 | 确认后接单 | 同上页或弹窗 | `OrderApi.acceptOrder(requestId)` |
| 4 开始服务 | 从「已接单」进入服务中 | `WatchVolunteerServicePage`（或命名 `WatchVolunteerProgressPage`） | `OrderApi.updateOrderStatus(orderId, 'in-progress')`（与手机 `ProgressPage` 一致） |
| 5 计时服务 | 界面展示已用时长（本地计时器 + 可选 `startedAt`） | 同上 | 前端 `setInterval` 更新 UI；数据以 `OrderApi.getOrderDetail` 为准 |
| 6 完成 | 确认完成 | 同上 | `OrderApi.completeOrder(orderId)` |
| 7 （可选）评价求助者 | 与手机一致 | `WatchVolunteerReviewPage` | `ReviewApi.createReview` + `revieweeId = helpSeekerId`（与现 `volunteer/ReviewPage.ets` 一致） |
| 8 完成 ✓ | 结束 | 回 `WatchVolunteerHome` 或订单详情 | `OrderApi.getOrderDetail` 校验 `status === 'completed'` |

**与手机端对应关系**

| 手机页 | 手表页职责 |
|--------|------------|
| `VolunteerHomePage` | `WatchVolunteerListPage`（仅保留列表 + 入口） |
| `volunteer/RequestDetailPage` | `WatchVolunteerRequestDetailPage` + 接单 |
| `volunteer/ProgressPage` | `WatchVolunteerServicePage`（开始服务 / 计时 / 完成） |
| `volunteer/ReviewPage` | `WatchVolunteerReviewPage`（可选） |

---

## 5. 后端接口汇总（复用，不重复造轮子）

| 模块 | 用途 |
|------|------|
| `AuthService` | 验证码、登录 |
| `UserApi` | 拉取资料（`getCurrentProfile`）；**手表端不把「切换角色」列为常规功能** |
| `RequestApi` | 创建求助、我的列表、详情、`getSeekerRequestDetail`、附近/待接单列表 |
| `EmergencyApi` | 紧急求助（若求助者闭环包含「紧急」入口） |
| `OrderApi` | 接单、状态、完成、订单详情 |
| `ReviewApi` | 双向评价（注意 `revieweeId` 区分） |
| `MessageApi` | 可选：聊天/未读（闭环可简化为「电话联系」） |
| `GeocodeApi` + 定位工具 | 地址展示与提交 |

---

## 6. 路由与工程注意点

1. **`main_pages.json`**：注册所有 `pages/watch/*` 新页面。  
2. **`Index.ets`**：wearable 进入 `WatchSplashPage`，再按登录态/角色路由。  
3. **参数传递**：`requestId`、`orderId` 在 `router.pushUrl` 的 `params` 中与手机端字段名保持一致，便于复用 `OrderApi`/`RequestApi`。  
4. **状态机**：求助者侧以 `HelpRequest.status` + `SeekerRequestDetail` 为准；志愿者侧以 `VolunteerOrder.status`（`accepted` → `in-progress` → `completed`）为准。  

---

## 7. 里程碑建议

| 阶段 | 内容 |
|------|------|
| M1 | 仅登录（无注册）+ 按账号 `role` 分流双角色首页壳（无身份切换 UI） |
| M2 | 求助者：类型 → 确认 → 提交 → 匹配页 → 志愿者信息 → 进度 |
| M3 | 求助者：评价 → 完成 |
| M4 | 志愿者：列表 → 详情接单 → 服务中计时 → 完成（+ 可选评价） |
| M5 | 联调：匹配时长、轮询间隔、失败重试；无障碍与圆屏适配 |

---

## 8. 非目标（本阶段可不做）

- **手表端注册**、手表端完善资料、手表端 **切换/选择身份**。  
- 社区端、调度大屏。  
- 手表上完整 IM（可仅保留「拨打电话」跳转 `tel:`）。  
- 与手机完全一致的复杂 UI 与统计图表。

---

## 9. 文档关系

- 页面拆分总览：`docs/watch-pages-split-spec.md`  
- 总里程碑：`docs/watch-seeker-app-development-plan.md`  

本文档在以上基础上 **扩展为双角色闭环**，并作为排期与验收的主依据。

---

*修订：2026-04-01 初稿；同日补充手表端「无注册、不切换身份」约束。*
