# 手表端圆屏适配 + 功能迁移 设计文档

## 1. 概述

### 1.1 目标
对互助帮扶系统的手表端进行两方面升级：
1. **圆屏 UI 适配** — 现有 11 个手表页面全部适配 466x466px 圆形屏幕
2. **功能迁移** — 从手机端迁移 4 项高优先级功能到手表端

### 1.2 目标设备
- 型号：Huawei_Wearable
- 分辨率：466x466px（圆形）
- 密度：320dpi（逻辑尺寸 ≈ 233vp）
- 屏幕：1.6"
- 系统：HarmonyOS 6.0.0 (API 20)
- 圆形安全内容区：内切正方形 ≈ 165x165vp

### 1.3 约束规则
- **不大幅修改手机端页面样式**，保持手机端 UI 稳定
- **不修改已有后端接口**，手表端优先复用现有接口，不够用才新建
- 手表端改动全部在 `pages/watch/` 和 `components/` 目录下完成

---

## 2. 圆屏适配方案

### 2.1 两类布局策略

| 类型 | 适用页面 | 策略 | 原因 |
|------|----------|------|------|
| **非滚动页** | SplashPage, SeekerHomePage, VolunteerHomePage, AccountUnsupportedPage | `WatchCircularLayout` 包裹 | 内容固定，需要居中在圆形安全区内 |
| **可滚动页** | LoginPage, EmergencyPage, MyRequestsPage, SeekerRequestDetailPage, VolunteerRequestDetailPage, ServicePage, ReviewPage | 顶部/底部 padding 适配 | 长内容需要垂直滚动，WatchCircularLayout 会过度限制可视区域 |

### 2.2 滚动页圆屏 padding 参数

```
顶部 padding: 30vp（避开圆形顶部弧线裁切）
底部 padding: 30vp（避开圆形底部弧线裁切）
左右 padding: 12vp（两侧弧线裁切较少）
```

滚动过程中，中间区域内容可以完整显示，顶底用 padding 留出安全距离。

### 2.3 全局样式规范

#### 字号体系（单位 px）

| 用途 | 当前值 | 适配后 | 大字体模式 |
|------|--------|--------|------------|
| 页面标题 | 16-18 | 14-15 | 17-18 |
| 正文/按钮文字 | 13-16 | 11-12 | 13-14 |
| 辅助信息 | 10-13 | 10 | 12 |
| 键盘按钮 | 12 | 11 | 13 |

#### 间距体系

| 用途 | 当前值 | 适配后 |
|------|--------|--------|
| 页面内容 padding | 10-16 | 8-10 |
| 元素间距 (space) | 10-16 | 6-8 |
| 卡片内 padding | 8-10 | 6-8 |
| 列表项间距 | 8 | 6 |

#### 圆角

| 用途 | 当前值 | 适配后 |
|------|--------|--------|
| 卡片 | 10-12 | 8-10 |
| 按钮 | 12-14 | 由 WatchButton 控制 |
| 输入框 | 12 | 10 |

### 2.4 WatchButton 全面替换

所有手表页面的 `Button` 组件统一替换为 `WatchButton`。

**WatchButton 三种类型对应场景：**

| 类型 | 场景 | 尺寸建议 |
|------|------|----------|
| `emergency` | 紧急求助、取消操作、不满评价 | `large` (68dp) |
| `primary` | 登录、接单、开始/完成服务、提交、满意评价 | `medium` (56dp) |
| `secondary` | 刷新、退出登录、我的求助、一般评价、返回 | `small` (44dp) |

**替换示例：**
```typescript
// 之前
Button('登录')
  .width('100%')
  .height(42)
  .backgroundColor('#2563eb')
  .onClick(() => { ... })

// 之后
WatchButton({
  text: '登录',
  type: 'primary',
  size: 'medium',
  accessibilityLabel: '登录按钮',
  onButtonClick: () => { ... }
})
```

---

## 3. 各页面适配详情

### 3.1 WatchSplashPage（启动页）

**布局策略：** WatchCircularLayout

**改动：**
- 用 `WatchCircularLayout` 包裹整体内容
- `LoadingProgress` 尺寸从 36x36 缩至 28x28
- 字号从 14px 降至 12px
- 重试按钮换 `WatchButton({ type: 'secondary', size: 'small' })`

### 3.2 WatchLoginPage（登录页）

**布局策略：** 可滚动 + 圆屏 padding

**改动：**
- Scroll 容器增加顶部 30vp、底部 30vp padding
- 数字键盘按钮高度从 36px 缩至 28px，间距从默认缩至 4px
- 输入框高度从 40px 降至 32px
- 标题字号从 18-20px 降至 14px
- 所有 Button 替换为 WatchButton：
  - 数字键按钮：`secondary` / `small`
  - "获取验证码"：`secondary` / `small`
  - "登录"：`primary` / `medium`

### 3.3 WatchAccountUnsupportedPage（不支持的账号）

**布局策略：** WatchCircularLayout

**改动：**
- 用 `WatchCircularLayout` 包裹
- 字号从 16/13px 降至 14/11px
- 退出按钮换 `WatchButton({ type: 'secondary', size: 'medium' })`

### 3.4 WatchSeekerHomePage（求助者首页）

**布局策略：** WatchCircularLayout（已使用）

**改动：**
- 所有 Button 替换为 WatchButton：
  - "一键紧急求助"：`emergency` / `large`
  - "分类求助"（新增）：`primary` / `medium`
  - "我的求助"：`primary` / `medium`
  - "设置"（新增）：`secondary` / `small`
  - "退出登录"：`secondary` / `small`
- 按钮高度统一由 WatchButton 控制，移除硬编码 48/44/40px
- 元素间距从 16px 缩至 8px
- 新增"分类求助"和"设置"入口（见第 4 节）

### 3.5 WatchSeekerEmergencyPage（紧急求助页）

**布局策略：** 可滚动 + 圆屏 padding

**改动：**
- Scroll 增加顶底 30vp padding
- 标题字号从 18-22px 降至 14-16px
- 提示文字从 12-14px 降至 10-11px
- 紧急按钮换 `WatchButton({ type: 'emergency', size: 'large' })`
- 刷新位置按钮换 `WatchButton({ type: 'secondary', size: 'small' })`
- 元素间距从 16px 缩至 8px

### 3.6 WatchMyRequestsPage（我的求助列表）

**布局策略：** 可滚动 + 圆屏 padding

**改动：**
- 顶部/底部增加 30vp padding
- 列表项标题字号从 14px 降至 12px
- 详情字号从 13/11px 降至 11/10px
- 列表项 padding 从 10px 降至 8px
- 列表项圆角从 12px 降至 10px
- 头部 padding 调整适配弧线

### 3.7 WatchSeekerRequestDetailPage（求助详情页）

**布局策略：** 可滚动 + 圆屏 padding

**改动：**
- Scroll 增加顶底 30vp padding
- 时间线圆点从 22x22 缩至 18x18
- 标题字号从 15px 降至 13px
- 时间线文字从 13/10px 降至 11/10px
- 取消按钮换 `WatchButton({ type: 'emergency', size: 'medium' })`
- **新增一键拨打志愿者电话按钮**（见第 4 节）

### 3.8 WatchVolunteerHomePage（志愿者首页）

**布局策略：** WatchCircularLayout

**改动：**
- 改用 `WatchCircularLayout` 包裹（当前是纯 Column + Scroll）
- 内容改为精简的按钮导航（类似求助者首页），而非滚动列表
  - "查看附近求助"：`primary` / `medium` → 跳转独立列表页
  - "我的服务"：`primary` / `medium` → 跳转订单列表
  - "设置"（新增）：`secondary` / `small`
  - "退出登录"：`secondary` / `small`
- **顶部显示服务统计**（新增，见第 4 节）
- **增加在线/离线状态切换**（新增，见第 4 节）
- 附近求助列表和活跃订单移到独立页面

> **注意：** 志愿者首页从"滚动列表"改为"按钮导航"是为了配合 WatchCircularLayout。附近求助的滚动列表移到新的独立页面 `WatchVolunteerNearbyPage`。

### 3.9 WatchVolunteerRequestDetailPage（志愿者求助详情）

**布局策略：** 可滚动 + 圆屏 padding

**改动：**
- Scroll 增加顶底 30vp padding
- 字号整体缩小：标题 14px，正文 11-12px，辅助 10px
- 接单按钮换 `WatchButton({ type: 'primary', size: 'medium' })`
- 卡片 padding 从 10px 降至 8px

### 3.10 WatchVolunteerServicePage（服务进度页）

**布局策略：** 可滚动 + 圆屏 padding

**改动：**
- Scroll 增加顶底 30vp padding
- 计时器字号从 13px 降至 12px
- 状态字号从 12px 降至 11px
- 操作按钮替换：
  - "开始服务"：`WatchButton({ type: 'primary', size: 'medium' })`
  - "完成服务"：`WatchButton({ type: 'primary', size: 'medium' })`
  - "去评价"：`WatchButton({ type: 'secondary', size: 'medium' })`

### 3.11 WatchVolunteerReviewPage（评价页）

**布局策略：** 可滚动 + 圆屏 padding

**改动：**
- Scroll 增加顶底 30vp padding
- 三个评分按钮替换为 WatchButton：
  - "满意"(5分)：`primary` / `small`
  - "一般"(3分)：`secondary` / `small`
  - "不满"(1分)：`emergency` / `small`
- 反馈输入框高度从 72px 降至 56px
- 提交按钮换 `WatchButton({ type: 'primary', size: 'medium' })`
- 字号整体缩小 2px

---

## 4. 新增功能设计

### 4.1 分类求助（新增页面：WatchSeekerRequestPage）

**入口：** WatchSeekerHomePage → "分类求助" 按钮

**页面流程：**
```
选择类型（4个按钮）→ 简短描述（可选，TextInput 单行）→ GPS 自动定位 → 提交
```

**UI 布局：** 可滚动 + 圆屏 padding

**页面结构：**
1. 标题 "发起求助"（14px bold）
2. 四个类型按钮（2x2 网格），每个 WatchButton：
   - "就医求助" — `emergency` / `small`
   - "出行协助" — `primary` / `small`
   - "生活帮扶" — `primary` / `small`
   - "其他求助" — `secondary` / `small`
3. 选中后显示：
   - 描述输入框（TextInput，单行，可选，placeholder "简要描述（可选）"，高度 32px）
   - 位置信息文字（GPS 自动获取，10px，显示地址或"定位中..."）
   - 提交按钮 — `WatchButton({ type: 'primary', size: 'medium' })`

**API 复用：**
- `POST /api/requests` — 创建求助请求（已有）
- `GET /api/geocode/regeo` — 逆地理编码（已有）
- 无需新建后端接口

**与手机端差异：**
- 描述可选（手机端必填 500 字），手表端不强制文字输入
- 无手动位置输入，纯 GPS
- 紧急程度自动根据类型设定（medical→high，其他→medium）

---

### 4.2 一键拨打志愿者电话

**入口：** WatchSeekerRequestDetailPage 详情页

**改动位置：** 在现有的志愿者信息区域下方，增加一个拨打电话按钮

**UI 设计：**
```typescript
// 当志愿者已分配时，显示拨打按钮
if (detail.volunteerPhone) {
  WatchButton({
    text: '拨打志愿者电话',
    type: 'primary',
    size: 'medium',
    accessibilityLabel: '拨打志愿者电话',
    onButtonClick: () => {
      // 调用系统拨号
      call.makeCall(detail.volunteerPhone)
    }
  })
}
```

**API 复用：**
- `GET /api/requests/{id}/seeker-detail` — 已返回志愿者电话信息，无需新接口

**注意：** 使用鸿蒙 `@ohos.telephony.call` 的 `makeCall` API 发起电话呼叫。

---

### 4.3 角色切换

**入口：** 新增设置页面 `WatchSettingsPage`（求助者首页和志愿者首页的"设置"按钮进入）

**UI 布局：** WatchCircularLayout

**页面结构：**
1. 标题 "设置"（14px bold）
2. 当前角色显示（文字，11px）
3. "切换为志愿者/求助者" — `WatchButton({ type: 'primary', size: 'medium' })`
4. "无障碍设置" — `WatchButton({ type: 'secondary', size: 'medium' })`（进入 4.4 的页面）
5. "返回" — `NavBackButton`

**切换逻辑：**
```
点击切换 → 调用 API → 成功 → 更新本地存储的 user.role → router.replaceUrl 到对应首页
```

**API 复用：**
- `PUT /api/users/me/role/switch` — 切换角色（已有）
- 无需新建后端接口

---

### 4.4 无障碍设置页（新增页面：WatchAccessibilityPage）

**入口：** WatchSettingsPage → "无障碍设置"

**UI 布局：** WatchCircularLayout

**页面结构：**
1. 标题 "无障碍设置"（14px bold）
2. 大字体开关：文字标签 + Toggle
3. 高对比度开关：文字标签 + Toggle
4. "返回" — `NavBackButton`

**实现方式：**
- 读写 `@StorageLink('accessibility_large_font')` 和 `@StorageLink('accessibility_high_contrast')`
- Toggle 变化时通过 `StorageUtil` 持久化
- 所有手表页面已通过 `@StorageLink` 绑定这两个变量，切换即时生效

**API：** 无需后端，纯本地存储。

---

## 5. 新增页面/文件清单

| 文件 | 类型 | 说明 |
|------|------|------|
| `pages/watch/WatchSeekerRequestPage.ets` | 新增 | 分类求助页 |
| `pages/watch/WatchSettingsPage.ets` | 新增 | 设置页（角色切换入口） |
| `pages/watch/WatchAccessibilityPage.ets` | 新增 | 无障碍设置页 |
| `pages/watch/WatchVolunteerNearbyPage.ets` | 新增 | 志愿者附近求助列表（从首页拆出） |
| `pages/watch/WatchVolunteerOrdersPage.ets` | 新增 | 志愿者订单列表（从首页拆出） |

**修改文件（11个现有页面）：**
- `pages/watch/WatchSplashPage.ets`
- `pages/watch/WatchLoginPage.ets`
- `pages/watch/WatchAccountUnsupportedPage.ets`
- `pages/watch/WatchSeekerHomePage.ets`
- `pages/watch/WatchSeekerEmergencyPage.ets`
- `pages/watch/WatchMyRequestsPage.ets`
- `pages/watch/WatchSeekerRequestDetailPage.ets`
- `pages/watch/WatchVolunteerHomePage.ets`
- `pages/watch/WatchVolunteerRequestDetailPage.ets`
- `pages/watch/WatchVolunteerServicePage.ets`
- `pages/watch/WatchVolunteerReviewPage.ets`

**可能修改的组件：**
- `components/WatchCircularLayout.ets` — 如果需要调整默认参数
- `components/index.ets` — 导出 WatchButton（如果未导出）

**路由注册：**
- 5 个新页面需要在 `entry/src/main/resources/base/profile/main_pages.json` 中注册路由

---

## 6. 导航架构（更新后）

### 求助者导航

```
WatchSplashPage
└─ WatchLoginPage
   └─ WatchSeekerHomePage
      ├─ 一键紧急求助 → WatchSeekerEmergencyPage
      │  └─ 提交成功 → WatchMyRequestsPage
      ├─ 分类求助 → WatchSeekerRequestPage (新增)
      │  └─ 提交成功 → WatchMyRequestsPage
      ├─ 我的求助 → WatchMyRequestsPage
      │  └─ 点击条目 → WatchSeekerRequestDetailPage
      │     └─ 拨打志愿者电话 (新增)
      ├─ 设置 → WatchSettingsPage (新增)
      │  ├─ 切换角色 → WatchVolunteerHomePage
      │  └─ 无障碍设置 → WatchAccessibilityPage (新增)
      └─ 退出登录 → WatchLoginPage
```

### 志愿者导航

```
WatchVolunteerHomePage (重构为按钮导航)
├─ 查看附近求助 → WatchVolunteerNearbyPage (新增)
│  └─ 点击条目 → WatchVolunteerRequestDetailPage
│     └─ 接单 → WatchVolunteerServicePage
│        └─ 完成 → WatchVolunteerReviewPage
│           └─ 提交 → WatchVolunteerHomePage
├─ 我的服务 → WatchVolunteerOrdersPage (新增)
│  └─ 点击条目 → WatchVolunteerServicePage
├─ 设置 → WatchSettingsPage (新增，同求助者共用)
│  ├─ 切换角色 → WatchSeekerHomePage
│  └─ 无障碍设置 → WatchAccessibilityPage
└─ 退出登录 → WatchLoginPage
```

---

## 7. 后端接口使用清单

### 全部复用已有接口，无需新建

| 功能 | 接口 | 方法 | 备注 |
|------|------|------|------|
| 分类求助提交 | `/api/requests` | POST | 已有 |
| GPS 逆地理编码 | `/api/geocode/regeo` | GET | 已有 |
| 角色切换 | `/api/users/me/role/switch` | PUT | 已有 |
| 志愿者服务统计 | `/api/volunteer/statistics` | GET | 已有（新调用） |
| 附近求助列表 | `/api/volunteer/nearby-requests` | GET | 已有 |
| 求助详情（含志愿者电话） | `/api/requests/{id}/seeker-detail` | GET | 已有 |
| 志愿者订单列表 | `/api/volunteer/orders/my` | GET | 已有 |
| 用户在线状态更新 | `/api/users/me` | PUT | 已有（新调用） |

---

## 8. 工作量估算

| 模块 | 文件数 | 工作类型 |
|------|--------|----------|
| 圆屏适配（11个现有页面） | 11 | 修改：布局 + 字号 + 间距 + WatchButton 替换 |
| 分类求助页 | 1 | 新增页面 |
| 设置页 | 1 | 新增页面 |
| 无障碍设置页 | 1 | 新增页面 |
| 志愿者附近求助列表页 | 1 | 新增页面（从首页拆出内容） |
| 志愿者订单列表页 | 1 | 新增页面（从首页拆出内容） |
| 拨打电话功能 | 0 | 在现有详情页增加按钮 |
| 路由注册 | 1 | 修改 main_pages.json |
| 组件导出 | 1 | 修改 components/index.ets |
| **合计** | **18 个文件** | 11 修改 + 5 新增 + 2 配置 |
