# 手表端：`pages/watch/` 页面拆分与功能复原说明

本文档约定：**在 `entry/src/main/ets/pages/watch/` 下为手表单独建页**，从「等待/启动 → 登录 → 求助者核心能力」顺序设计；**后端沿用现有 `AuthService` / `ApiService`（与手机端同一套 HTTP 接口）**，不在手表端重复造请求层。

**手表端账号策略（固定）**：**不提供注册**（默认用户已在手机端有账号）；**不在手表上切换身份**，登录后仅按账号 `user.role` 进入对应能力；无角色时提示去手机端设置。

---

## 1. 设计原则

| 原则 | 说明 |
|------|------|
| 页面物理拆分 | 手表 UI 一律落在 `watch/*.ets`，**不**在 `help-seeker/*.ets` 里堆 `isWatchLayout` 长分支（维护成本过高）。 |
| 服务层复用 | `services/AuthService`、`services/ApiService`、`utils/StorageUtil`、`utils/LocationUtil` 等与手机共用。 |
| 圆屏适配 | 单列、可滚动、单屏主操作；字号与触控高度按 wearable 规范预留（避免再次出现「只看到标题」）。 |
| 能力取舍 | 志愿者端、社区端、复杂聊天与统计**不在**本阶段手表页清单内；求助者闭环优先。 |
| 账号与身份 | **无注册页、无角色切换**；仅登录与按角色分流（见 §2）。 |

---

## 2. 用户动线（从「等待登录」到「可用功能」）

```
[手表启动]
    → WatchSplashPage（等待/品牌，可选自动进下一步）
    → 未登录 → WatchLoginPage（仅登录，无注册）
    → 已登录 → 按 user.role 分流（不切换身份）
           → help-seeker → WatchSeekerHomePage
           → volunteer → WatchVolunteerHomePage（若本包为单角色可省略另一套）
           → 无角色/不支持 → 提示「请在手机端完成账号与身份设置」
    → WatchSeekerHomePage（求助者手表首页）
           ├→ WatchEmergencyPage（一键紧急求助，对应现 WatchSeekerEmergencyPage 演进）
           ├→ WatchSimpleRequestPage（非紧急：类型 + 说明 + 提交）
           ├→ WatchMyRequestsPage（我的求助列表）
           └→ WatchRequestDetailPage（单条详情；沟通可为极简或后续迭代）
```

**与当前代码差异（目标态）**

| 当前行为 | 目标态 |
|----------|--------|
| `Index` 直接 `replaceUrl` 到 `WatchSeekerEmergencyPage` | `Index` 先到 **WatchSplashPage**，再由路由决定去登录或进首页（与「等待登录界面」产品描述一致）。 |
| `SplashPage` 在手表被重定向到紧急页 | 手表使用 **WatchSplashPage**，手机仍用 `SplashPage`（或 Index 分支只引用 watch 路由）。 |
| `LoginPage` 手机+手表共用且布局复杂 | **WatchLoginPage** 独立页，仅保留短信登录必要控件。 |

---

## 3. 页面清单（建议文件名与职责）

以下路径均相对于 `entry/src/main/ets/pages/watch/`。

| 顺序 | 文件（建议） | 职责 | 复用后端 |
|------|----------------|------|----------|
| ① | `WatchSplashPage.ets` | **等待/启动界面**：Logo、简短文案；检测 `token`/登录态；未登录则跳转 **WatchLogin**；已登录则按 **`user.role`** 跳转求助者/志愿者首页或 **账号不可用提示页**。可含 1～2 秒轻量动效或静态。 | `AuthService.isLoggedIn()`、`StorageUtil.getString('token')`、`UserApi.getCurrentProfile`（可选刷新） |
| ② | `WatchLoginPage.ets` | **仅登录**：手机号 + 验证码 + 获取验证码 + **登录**；**不包含注册**；UI 为手表专用（滚动、紧凑行高）。 | `AuthService.sendVerificationCode`、`AuthService.login` |
| ③ | `WatchAccountUnsupportedPage.ets`（可选） | **无角色或角色与当前应用不符**：短文案说明「请在手机端完成账号与身份」，提供退出登录/重试。 | `AuthService.logout`（若有） |
| ④ | `WatchSeekerHomePage.ets` | **求助者手表首页**（仅 `role === 'help-seeker'` 进入）：大入口「一键紧急」、可选「其他求助」、入口「我的求助」。 | `RequestApi.getRecentMyRequests`（可选） |
| ⑤ | `WatchEmergencyPage.ets` | **紧急求助**：定位 + 逆地理 + 默认说明文案 + 提交（可由现有 `WatchSeekerEmergencyPage.ets` **重命名/重构**而来，避免双份逻辑）。 | `EmergencyApi.createEmergencyRequest`、`GeocodeApi.getAddressFromCoordinates`、定位工具类 |
| ⑥ | `WatchSimpleRequestPage.ets` | **非紧急求助**：选择类型（medical/companion/shopping/other 等与手机 `RequestTypePage` 对齐的枚举）+ 简短描述 + 位置（可自动定位或手输简写）+ 提交。 | `RequestApi.createRequest`、`GeocodeApi`（若需要） |
| ⑦ | `WatchMyRequestsPage.ets` | **我的求助**：分页或最近 N 条列表，圆屏单列。 | `RequestApi.getMyRequests` 或 `getRecentMyRequests` |
| ⑧ | `WatchRequestDetailPage.ets` | **详情**：状态、时间、地点摘要；取消订单若产品需要（`RequestApi.cancelRequest`）。聊天 **可选**：若做，再引 `MessageApi`；首版可仅展示静态信息与热线提示。 | `RequestApi.getSeekerRequestDetail` 或 `getRequestDetail`、`MessageApi`（可选） |

**命名说明**：若短期保留 `WatchSeekerEmergencyPage.ets` 文件名，可在本文档中把「⑤」视为其别名，待稳定后再统一重命名为 `WatchEmergencyPage.ets`。

---

## 4. 功能复原范围（相对手机「求助者」）

| 手机端能力（help-seeker） | 手表是否复原 | 对应手表页 |
|---------------------------|--------------|------------|
| 启动图 / 进入应用 | ✅ 复原（手表专用 UI） | WatchSplashPage |
| 短信登录 | ✅ 复原（仅登录，无注册） | WatchLoginPage |
| 角色选择 / 切换 | ❌ 手表不做 | 由账号 `role` 决定；无角色则提示手机端处理 |
| 首页：分类入口（就医/出行等） | ⚠️ 简化为 1 屏类型选择或直接进入 SimpleRequest | WatchSeekerHomePage → WatchSimpleRequestPage |
| 长按紧急 → 紧急表单 | ✅ 复原（手表一键优先） | WatchEmergencyPage |
| 紧急页完整表单（描述/地址/电话） | ⚠️ 手表以默认文案 + 定位为主；必要时再展开 | 同左 |
| 非紧急下单（RequestType + 表单） | ✅ 简化为短流程 | WatchSimpleRequestPage |
| 我的求助列表 | ✅ 复原（信息密度降低） | WatchMyRequestsPage |
| 求助详情 + 时间线 | ✅ 复原核心字段；聊天视迭代 | WatchRequestDetailPage |
| 个人中心 / 资料编辑 | ❌ 首版可不复原；或 Watch 仅「退出登录」 | 可挂在 WatchSeekerHome 菜单或设置页（后续） |
| WebSocket 实时聊天 | ❌ 首版建议不做；或仅显示未读数（可选） | — |

---

## 5. 后端接口复用表（与 `ApiService` / `AuthService` 一致）

以下为**求助者手表端**预期会调用的接口（路径以前端 `API_BASE_URL` + 后缀为准，与手机相同）。

| 能力 | 封装类 | 方法 / 说明 |
|------|--------|-------------|
| 发验证码、登录 | `AuthService` | `sendVerificationCode`、`login`（`loginType: 'sms'`） |
| 当前用户 | `UserApi` | `getCurrentProfile`（用于读取 `role`）；**手表常规流程不调用 `updateUserRole` / `switchUserRole`** |
| 创建紧急求助 | `EmergencyApi` | `createEmergencyRequest` → `POST /emergency/requests` |
| 创建普通求助 | `RequestApi` | `createRequest` → `POST /requests` |
| 我的列表 / 最近 | `RequestApi` | `getMyRequests`、`getRecentMyRequests` |
| 详情 | `RequestApi` | `getSeekerRequestDetail` 或 `getRequestDetail` |
| 取消求助 | `RequestApi` | `cancelRequest` |
| 逆地理 | `GeocodeApi` | `getAddressFromCoordinates` → `GET /geocode/regeo` |
| 聊天（可选） | `MessageApi` | `getChatHistory`、`sendMessage` |

**说明**：`HttpClient` 已统一带 `Bearer token`，与手机共用存储；手表与手机 **本地缓存相互独立**，需在 UI 文案中提示「需在本设备登录」。

---

## 6. 路由与配置改动要点（实现时 checklist）

1. **`main_pages.json`**：注册上述 `pages/watch/*` 页面路径。  
2. **`Index.ets`**：wearable 时 `replaceUrl('pages/watch/WatchSplashPage')`（或最终确定的 ① 页名）。  
3. **删除/避免**：手表启动不再跳过「等待界面」直接进紧急页（除非你明确保留「极速紧急」快捷方式，可作为 Splash 上第二个按钮）。  
4. **手机端**：`SplashPage` / `LoginPage` 保持手机专用或仅 `Index` 区分设备，避免手表误入 `pages/LoginPage` 除非用户从手表页主动跳转共用登录页（推荐统一用 WatchLoginPage）。

---

## 7. 非目标（本阶段不做的手表页）

- 志愿者首页、接单、订单流程全套页面。  
- 社区管理、调度大屏。  
- 与手机完全一致的 `HelpSeekerHomePage` Tab 结构。  
- 复杂评价、富文本、长列表无虚拟化优化。

---

## 8. 与总规划文档的关系

- 总览里程碑与验收见：`docs/watch-seeker-app-development-plan.md`。  
- 本文档是 **页面级拆分 + 接口映射** 的执行说明，用于评审与排期。

---

## 9. 修订记录

| 日期 | 说明 |
|------|------|
| 2026-04-01 | 初稿：基于当前 `help_system` 代码结构整理 |

如需下一步，可在 issue/任务中按「① WatchSplash → ② WatchLogin → …」顺序拆任务，每页对接口做联调清单。
