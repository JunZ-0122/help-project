# 基于手机端清单的手表端可行性分析与开发建议

**日期**：2026-04-01  
**依据**：`help_system/entry` 下 `main_pages.json` 注册页 + `pages/**/*.ets` 文件清单；约束见 `2026-04-01-watch-development-isolation-design.md`（手表 UI 隔离、服务层只增不改、后端接口复用）。

---

## 1. 手机端界面与功能总览（按模块）

### 1.1 全局 / 账号

| 页面 / 组件 | 文件 | 主要能力 |
|-------------|------|----------|
| 入口 | `Index.ets` | 设备分流到 Splash 或手表页 |
| 启动 | `SplashPage.ets` | 品牌、进入登录 |
| 登录 | `LoginPage.ets` | 短信登录/注册流程 |
| 角色 | `RoleSelectPage.ets` | 求助者 / 志愿者 / 社区 |
| 错误 | `ErrorPage.ets` | 通用错误展示 |

**未在 `main_pages.json` 但存在的文件**：`HelpList.ets`、`PublishHelp.ets` — 视为遗留或次要，手机主路径以注册页为准。

### 1.2 求助者（help-seeker）

| 页面 | 文件 | 主要能力 |
|------|------|----------|
| 首页 | `HelpSeekerHomePage.ets` | Tab、分类入口、长按紧急、最近求助等（大页） |
| 子模块 | `SeekerPersonalCenterPane.ets` | 个人中心片段 |
| 紧急求助 | `EmergencyRequestPage.ets` | 类型/描述/位置/电话提交 |
| 类型与下单 | `RequestTypePage.ets` | 按类型填写并提交普通求助 |
| 我的求助 | `MyRequestsPage.ets` | 列表与状态 |
| 详情 | `RequestDetailPage.ets` | 聚合详情、时间线、聊天入口、WebSocket |
| 资料 | `ProfilePage.ets` | 求助者资料 |

### 1.3 志愿者（volunteer）

| 页面 | 文件 | 主要能力 |
|------|------|----------|
| 首页 | `VolunteerHomePage.ets` | 附近/待接单、统计卡片、接单 |
| 求助详情 | `RequestDetailPage.ets` | 查看、接单 |
| 我的订单 | `MyOrdersPage.ets` | 订单列表 |
| 订单详情 | `OrderDetailPage.ets` | 订单与评价展示 |
| 进度 | `ProgressPage.ets` | 状态推进、完成服务 |
| 聊天 | `ChatPage.ets` | 会话列表与发送 |
| 评价 | `ReviewPage.ets` | 志愿者评价求助者 |
| 资料 | `ProfilePage.ets`、`VolunteerProfileEditPage.ets` | 查看/编辑 |

### 1.4 社区管理（community）

| 页面 | 文件 | 主要能力 |
|------|------|----------|
| 首页 | `CommunityHomePage.ets` | 统计、待办 |
| 管理 | `ManagePage.ets` | 管理入口 |
| 统计 | `StatisticsPage.ets` | 数据图表类 |
| 志愿者管理 | `VolunteerManagementPage.ets` | 列表与管理 |
| 调度 | `QuickDispatchPage.ets`、`AssignPage.ets` | 派单、分配 |
| 详情 | `RequestDetailPage.ets` | 社区视角详情 |
| 资料 | `ProfilePage.ets` | 社区侧资料 |

### 1.5 手表（已有）

| 页面 | 文件 | 主要能力 |
|------|------|----------|
| 紧急一键 | `WatchSeekerEmergencyPage.ets` | 定位、逆地理、紧急下单 |

---

## 2. 手表端可行性分级（建议）

图例：**可行** = 圆屏 + 弱输入下可完成核心价值；**缩简** = 必须砍交互/信息密度；**不建议** = 默认不做手表版。

| 手机模块 | 手表可行性 | 说明 |
|----------|------------|------|
| 启动 / 品牌 | **可行** | 独立 `WatchSplash`，无手机文件改动。 |
| 登录（仅已有账号） | **可行** | 独立 `WatchLoginPage`，`TextInput` + 验证码；不复制注册流程。 |
| 角色选择 / 切换 | **不做** | 与产品约定一致：手表不切换身份；不在手表复刻 `RoleSelectPage`。 |
| 求助者：首页 | **缩简** | 手机 `HelpSeekerHomePage` 多 Tab + 长按紧急不适合照搬；手表用单屏大按钮 + 少量入口。 |
| 求助者：紧急 / 类型下单 | **可行** | 已有紧急 API；类型下单缩为 1～2 屏。 |
| 求助者：我的 / 详情 / 进度 | **缩简** | 列表短行、详情无长聊优先；WebSocket 可换轮询。 |
| 求助者：评价志愿者 | **缩简** | 接口可用 `ReviewApi`；UI 极简（星/标签 + 短文案）。 |
| 求助者：资料编辑 | **不建议** | 复杂表单；提示手机端维护。 |
| 志愿者：首页列表 + 接单 | **缩简** | 列表单列、详情精简；接口与手机一致。 |
| 志愿者：订单 / 进度 / 完成 | **可行** | `OrderApi` 状态机与手机一致；计时用本地时钟 + 服务端状态。 |
| 志愿者：评价求助者 | **缩简** | 同 `ReviewPage` 逻辑，手表独立页。 |
| 志愿者：聊天 | **缩简 / 可砍** | 圆屏长对话体验差；首版可用「拨打电话」或仅展示未读数。 |
| 志愿者：资料编辑 | **不建议** | 同求助者资料。 |
| 社区：全部 | **不建议** | 大屏、多列表、调度与统计；**手表端默认不做**（与既有文档一致）。 |

---

## 3. 手表端开发建议（与手机隔离前提下）

1. **只增 `pages/watch/**`**，**不改**非 watch 页面；入口仅改 `Index` 目标与 `main_pages.json` 注册（见隔离 spec）。  
2. **双角色两条产品链**：求助者手表闭环、志愿者手表闭环；**不做**社区管理手表版。  
3. **能力优先级**  
   - **P0**：`WatchSplash` → `WatchLogin` → 按 `user.role` 进求助者或志愿者首页 → 各自最小闭环（发单/接单 → 状态 → 完成）。  
   - **P1**：匹配动画、进度时间线、双向评价（极简 UI）。  
   - **P2**：聊天、富展示、与手机对齐的细节。  
4. **后端**：直接复用 `AuthService` / `ApiService`；手表专用封装 **新建文件**，**不修改**现有 `ApiService`/`AuthService` 实现（见隔离 spec）。  
5. **不要尝试**在手表上复刻 `HelpSeekerHomePage` / `CommunityHomePage` 的复杂度 — 只复用 **接口与业务结果**，**重做** 手表信息架构。

---

## 4. 分阶段计划（建议）

| 阶段 | 范围 | 验收 |
|------|------|------|
| **W0** | 工程：`Index` → `WatchSplash`；`main_pages` 登记；**不动手机页** | 手表能进启动/登录壳 |
| **W1** | `WatchLogin` + Token；按 role 分流壳页 | 求助者账号进求助者壳；志愿者进志愿者壳；无角色提示手机端 |
| **W2 求助者 P0** | 类型/确认/提交、紧急一键、我的列表、极简详情 | 与后端联调走通一单 |
| **W3 求助者 P1** | 匹配页（≥3s UI）、志愿者信息、进度、评价 | 闭环文档一致 |
| **W4 志愿者 P0** | 列表、详情、接单、服务中、完成 | 与 `OrderApi` 一致 |
| **W5 志愿者 P1** | 极简评价；可选聊天或电话 | 按产品取舍 |

社区模块 **不列入** 手表里程碑。

---

## 5. 风险与假设

- **手机页面未改**：回归手机时，非 watch 文件无 diff；手表问题集中在 `watch` 与入口。  
- **聊天**：若坚持手表也要 IM，需单独评估性能与输入；否则 P2 或永久砍掉。  
- **Seeker 评价志愿者**：后端字段与权限需与现网一致（可能和手机志愿者评价互为对称）。  

---

## 6. 相关文档

- `docs/watch-dual-role-closed-loop-plan.md`  
- `docs/watch-pages-split-spec.md`  
- `docs/superpowers/specs/2026-04-01-watch-development-isolation-design.md`  

---

**下一步（流程）**：你确认本 spec 后，可进入 **implementation plan**（任务拆解与顺序），再开始编码；编码仍遵守「不修改手机界面、服务层只增不改」。
