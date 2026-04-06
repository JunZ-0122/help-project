# 手表端开发：与手机隔离 + 后端复用（只增不改）

**状态**：已确认（口径 A + 后端策略）  
**日期**：2026-04-01

---

## 1. 目标

- 手表端 **UI 与路由** 与手机端 **完全隔离**：能力在 `pages/watch/` 内闭环，不修改手机端界面与手机页面文件。
- **后端 HTTP 接口** 与手机端 **一致**（同一套服务地址与契约）。
- **服务层代码**：优先 **直接复用** 现有 `services/`*；若存在无法复用的情况，**允许新建文件**，**禁止修改**已有 `services`、`HttpClient`、既有封装逻辑。

---

## 2. 手机端 / 手表端边界（UI）


| 规则      | 说明                                                                                                                                     |
| ------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| **手表**  | 仅新增或修改 `entry/src/main/ets/pages/watch/**/*.ets`（及路由表登记）。                                                                              |
| **手机**  | `pages/SplashPage`、`pages/LoginPage`、`pages/help-seeker/`*、`pages/volunteer/*`、`pages/community/*` 等 **非 watch 路径** — **不为手表做 UI 改动**。 |
| **入口**  | 允许修改 `pages/Index.ets` **仅用于 wearable 路由目标**（如指向 `WatchSplashPage`）；不改变手机分支行为。                                                         |
| **路由表** | `main_pages.json` **只增加** `pages/watch/`* 条目，不删改手机页面注册（除非产品另有统一整理）。                                                                    |


---

## 3. 后端与服务层（复用 + 只增不改）

### 3.1 默认：直接复用

手表页面与手机页面相同方式引用：

- `AuthService`、`ApiService` 中的 `HttpClient`、`RequestApi`、`OrderApi`、`EmergencyApi`、`ReviewApi`、`UserApi`、`GeocodeApi` 等。

**不**为手表复制一套 `API_BASE_URL` 或重复实现登录协议，除非产品要求独立环境（当前不要求）。

### 3.2 若无法直接复用


| 情况                            | 做法                                                                                                                                                          |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 需要 **额外封装**（如手表专用错误文案映射、重试策略） | **新建** 文件，例如 `services/watch/WatchRequestHelper.ets` 或 `utils/WatchAuthHelper.ets`，内部 **调用** 现有 `HttpClient` / `AuthService`，**不修改** `ApiService.ets` 内类定义。 |
| 需要 **新的 API 集合**（后端新手表专用端点）   | **新建** `services/watch/WatchXxxApi.ets`（或 `services/XxxWatchApi.ets`），**不**往现有 `RequestApi` 等里塞手表专用方法（避免污染手机依赖路径）。                                          |
| 必须改 `HttpClient` 全局行为         | **禁止**直接改；改为 **新建** `WatchHttpClient` 或在外层 Helper 处理；若确属通用 bug 修复，走单独 **缺陷修复** 评审，与本「手表隔离」需求解耦。                                                             |


### 3.3 原则归纳

- **复用** > **新建包装** > **修改旧文件**（最后一项默认不允许）。
- 新建代码 **只增加** 能力，**不删除、不改变** 手机端已依赖的公共函数签名与行为。

---

## 4. 与已有文档的关系

- `docs/watch-dual-role-closed-loop-plan.md` — 业务闭环与页面规划  
- `docs/watch-pages-split-spec.md` — `pages/watch` 拆分  
- `docs/watch-seeker-app-development-plan.md` — 求助者里程碑

本文档约束 **工程隔离策略** 与 **服务层变更纪律**，实现阶段须与本说明一致。

---

## 5. 验收要点（工程）

- `git diff` 中 **无** 对非 `watch` 页面 `.ets` 的 UI 相关修改（口径 A）。  
- **无** 对 `services/ApiService.ets` / `AuthService.ets` 等 **破坏性修改**；若有新手表专用逻辑，体现为 **新增文件**。  
- 手表端功能 **仅依赖** 既有后端接口或 **新增** 的后端端点 + **新增** 前端封装文件。

