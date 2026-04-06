# 手表端实现总结（互助帮扶 · help_system）

> 本文档汇总当前仓库内 **手表 wearable 端** 已实现能力、工程约束、页面与接口对应关系及后续可迭代项。  
> 更新：随实现迭代维护。

---

## 1. 工程约束（固定）

| 约束 | 说明 |
|------|------|
| **不修改手机端界面** | `pages/` 下 **非 `watch/`** 的页面（如 `SplashPage`、`LoginPage`、`help-seeker/*`、`volunteer/*`、`community/*`）**不为手表去改 UI**。 |
| **手表 UI 隔离** | 手表专用界面均在 **`entry/src/main/ets/pages/watch/*.ets`**。 |
| **入口** | `Index.ets` 在 `isWearableDevice()` 为真时进入 **`pages/watch/WatchSplashPage`**；手机仍进 `SplashPage`。 |
| **路由注册** | `entry/src/main/resources/base/profile/main_pages.json` 中登记所有 `pages/watch/*`。 |
| **后端** | **优先复用** `services/AuthService`、`services/ApiService`；需要扩展时遵循「**只增不改**」既有服务实现（见 `docs/superpowers/specs/2026-04-01-watch-development-isolation-design.md`）。 |
| **账号策略** | 手表 **不提供注册**、**不在手表切换身份**；登录后按账号 `role` 分流；无角色/社区等走提示页。 |

---

## 2. 入口与用户动线（摘要）

```
Index（wearable）
  → WatchSplashPage（读 Token / UserApi.getCurrentProfile）
       → 未登录 → WatchLoginPage（短信登录，仅已有账号）
       → 已登录 + help-seeker → WatchSeekerHomePage
       → 已登录 + volunteer   → WatchVolunteerHomePage
       → 无角色 / community   → WatchAccountUnsupportedPage
```

---

## 3. 手表页面清单与职责

| 页面路径 | 文件 | 主要职责 |
|----------|------|----------|
| `pages/watch/WatchSplashPage` | `WatchSplashPage.ets` | 启动分流、刷新资料、按角色跳转 |
| `pages/watch/WatchLoginPage` | `WatchLoginPage.ets` | 短信登录；`LoginRequest` 含 `verificationCode`（与 `AuthService` SMS 逻辑一致） |
| `pages/watch/WatchSeekerHomePage` | `WatchSeekerHomePage.ets` | 求助者首页：一键紧急、我的求助、退出 |
| `pages/watch/WatchVolunteerHomePage` | `WatchVolunteerHomePage.ets` | 志愿者首页：附近待接列表、进行中订单、刷新、退出 |
| `pages/watch/WatchAccountUnsupportedPage` | `WatchAccountUnsupportedPage.ets` | 无角色或社区账号等提示，返回登录 |
| `pages/watch/WatchSeekerEmergencyPage` | `WatchSeekerEmergencyPage.ets` | 一键紧急求助；定位/逆地理；成功后跳转「我的求助」并带 `createdId` |
| `pages/watch/WatchMyRequestsPage` | `WatchMyRequestsPage.ets` | 求助者我的求助列表 |
| `pages/watch/WatchSeekerRequestDetailPage` | `WatchSeekerRequestDetailPage.ets` | 求助者详情（聚合时间线）、条件取消 |
| `pages/watch/WatchVolunteerRequestDetailPage` | `WatchVolunteerRequestDetailPage.ets` | 志愿者查看待接求助并接单 |
| `pages/watch/WatchVolunteerServicePage` | `WatchVolunteerServicePage.ets` | 志愿者订单：开始服务、计时、完成 |
| `pages/watch/WatchVolunteerReviewPage` | `WatchVolunteerReviewPage.ets` | 志愿者评价求助者 |

---

## 4. 与后端接口的对应（复用）

| 能力 | 典型封装 |
|------|----------|
| 登录 / 验证码 / 退出 | `AuthService` |
| 当前用户资料 | `UserApi.getCurrentProfile` 等 |
| 上报位置 | `UserApi.reportLocation`（志愿者首页加载附近列表时） |
| 附近待接 / 待接单列表 | `RequestApi.getNearbyRequests`、`RequestApi.getRequests`（降级） |
| 求助详情（志愿者） | `RequestApi.getRequestDetail` |
| 接单 | `OrderApi.acceptOrder` |
| 订单详情 / 状态 / 完成 | `OrderApi.getOrderDetail`、`updateOrderStatus`、`completeOrder` |
| 求助者我的列表 | `RequestApi.getMyRequests` |
| 求助者聚合详情 | `RequestApi.getSeekerRequestDetail` |
| 取消求助 | `RequestApi.cancelRequest` |
| 紧急求助 | `EmergencyApi.createEmergencyRequest` |
| 逆地理 | `GeocodeApi.getAddressFromCoordinates` |
| 评价 | `ReviewApi.getOrderReview`、`createReview` |

---

## 5. 与手机端差异（有意简化）

| 维度 | 说明 |
|------|------|
| **WebSocket** | 手表服务/详情页 **未接** 实时消息通道；以接口拉取与本地计时为主。 |
| **信息密度** | 列表与详情为圆屏单列、短文案，与手机长页不同。 |
| **社区端** | 手表 **不提供** 社区管理模块。 |

---

## 6. 配置与关键文件

| 文件 | 说明 |
|------|------|
| `entry/src/main/ets/pages/Index.ets` | 仅 wearable 分支目标为 `WatchSplashPage` |
| `entry/src/main/resources/base/profile/main_pages.json` | 注册全部 `pages/watch/*` 见上表 |
| `entry/src/main/module.json5` | `deviceTypes` 含 `wearable`（与手机同模块打包） |

---

## 7. 构建与测试

- 本地 **hvigor** 若因环境权限/沙箱失败，以 **DevEco Studio** 对 **wearable** 目标执行 **Build** / **Run** 为准。
- 建议在 **手表模拟器或真机** 上验证：登录 → 求助者/志愿者首页 → 各列表与详情 → 接单/服务/完成/评价（视账号角色与后端数据而定）。

---

## 8. 后续可迭代（未在本次「必须」范围）

- 求助者 **评价志愿者**（对称 `ReviewApi` 与 `revieweeId` 约定需与后端确认）。  
- **匹配动画**、更完整的进度与状态机展示。  
- 手表端 **IM/聊天**（可继续用电话或极简未读数）。  
- 独立工程（如 `entry_watch` 模块）若产品需要独立 HAP。

---

## 9. 相关设计文档索引

| 文档 | 内容 |
|------|------|
| `docs/superpowers/specs/2026-04-01-watch-development-isolation-design.md` | 隔离策略 + 服务层「只增不改」 |
| `docs/superpowers/specs/2026-04-01-watch-feasibility-from-phone-inventory-design.md` | 基于手机清单的可行性 |
| `docs/watch-dual-role-closed-loop-plan.md` | 双角色闭环产品规划 |
| `docs/watch-pages-split-spec.md` | `pages/watch` 拆分说明 |

---

## 10. 编译报错修复记录（ArkTS）

本次开发过程中，已处理以下 ArkTS 编译问题：

- `arkts-no-untyped-obj-literals`（`WatchVolunteerHomePage`）
  - 原因：严格模式下直接使用未显式约束的对象字面量。
  - 修复：为默认定位点使用 `LocationPoint` 类型；列表映射统一改为返回 `ReqRow` / `OrdRow` 的显式方法；请求过滤参数显式声明类型后再传入。

- `arkts-no-aliases-by-index`（`WatchSeekerRequestDetailPage`）
  - 原因：使用 `SeekerTimelineItem['state']` 索引访问类型。
  - 修复：新增显式联合类型 `SeekerTimelineState = 'done' | 'current' | 'upcoming'`，并替换函数参数类型。

- `arkts-no-structural-typing`（`WatchVolunteerHomePage`）
  - 原因：本地同构接口作为 `RequestApi.getRequests` 的 `filters` 参数传递，触发结构类型限制。
  - 修复：在 `ApiService.ets` 将 `RequestListFilters` 改为 `export interface`，手表页直接 `import type RequestListFilters` 使用。

说明：以上修复均未涉及手机端页面 UI 变更。

---

*文档用于交接与评审；实现细节以源码为准。*
