# 手表端圆屏适配 + 功能迁移 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 对 11 个手表页面做圆屏 UI 适配（WatchCircularLayout / padding + WatchButton 替换），并新增 5 个页面迁移手机端功能（分类求助、拨打电话、角色切换、无障碍设置、志愿者列表拆分）。

**Architecture:** 非滚动页用 WatchCircularLayout 包裹，可滚动页用 top/bottom 30vp + left/right 12vp 圆屏 padding。所有 Button 替换为 WatchButton 组件。新增功能全部复用已有后端 API，不修改已有接口。

**Tech Stack:** HarmonyOS ArkTS, ArkUI 组件, WatchButton/WatchCircularLayout 自定义组件

---

## Task 1: 导出 WatchButton + 更新组件索引

**Files:**
- Modify: `entry/src/main/ets/components/index.ets`

- [ ] **Step 1: 在 index.ets 中导出 WatchButton**

```typescript
/**
 * 组件模块统一导出
 */

export { AccessibleButton } from './AccessibleButton';
export { AccessibleText } from './AccessibleText';
export { WatchCircularLayout } from './WatchCircularLayout';
export { WatchButton } from './WatchButton';
export { NavBackButton } from './NavBackButton';
export { AccessibilitySettingsBlock } from './AccessibilitySettingsBlock';
```

- [ ] **Step 2: 验证导出**

Run: 在项目中搜索确认 WatchButton 可被其他文件 import。

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/components/index.ets
git commit -m "feat(watch): 导出 WatchButton 组件供所有手表页面使用"
```

---

## Task 2: 适配 WatchSplashPage（非滚动 → WatchCircularLayout）

**Files:**
- Modify: `entry/src/main/ets/pages/watch/WatchSplashPage.ets`

- [ ] **Step 1: 添加 import**

在文件顶部添加：
```typescript
import { WatchCircularLayout } from '../../components/WatchCircularLayout';
import { WatchButton } from '../../components/WatchButton';
```

- [ ] **Step 2: 重写 build 方法**

将现有 `build()` 替换为：
```typescript
build() {
  WatchCircularLayout({
    centerRadius: 120,
    edgePadding: 16,
    content: () => {
      this.pageContent()
    }
  })
}

@Builder
pageContent() {
  Column({ space: 8 }) {
    if (this.isRouting && this.routeError.length === 0) {
      LoadingProgress()
        .width(28)
        .height(28)
      Text('加载中...')
        .fontSize(12)
        .fontColor('#64748b')
    } else if (this.routeError.length > 0) {
      Text(this.routeError)
        .fontSize(12)
        .fontColor('#b91c1c')
        .textAlign(TextAlign.Center)
      WatchButton({
        text: '重试',
        type: 'secondary',
        size: 'small',
        width: '100%',
        onClick: () => {
          this.routeBySession();
        }
      })
    }
  }
  .width('100%')
  .justifyContent(FlexAlign.Center)
  .alignItems(HorizontalAlign.Center)
}
```

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/pages/watch/WatchSplashPage.ets
git commit -m "feat(watch): WatchSplashPage 圆屏适配 + WatchButton"
```

---

## Task 3: 适配 WatchAccountUnsupportedPage（非滚动 → WatchCircularLayout）

**Files:**
- Modify: `entry/src/main/ets/pages/watch/WatchAccountUnsupportedPage.ets`

- [ ] **Step 1: 添加 import**

```typescript
import { WatchCircularLayout } from '../../components/WatchCircularLayout';
import { WatchButton } from '../../components/WatchButton';
```

- [ ] **Step 2: 重写 build 方法**

```typescript
build() {
  WatchCircularLayout({
    centerRadius: 120,
    edgePadding: 16,
    content: () => {
      this.pageContent()
    }
  })
}

@Builder
pageContent() {
  Column({ space: 8 }) {
    Text('当前账号')
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .width('100%')
      .textAlign(TextAlign.Center)

    Text(this.message())
      .fontSize(11)
      .fontColor('#64748b')
      .textAlign(TextAlign.Center)

    WatchButton({
      text: '返回登录',
      type: 'secondary',
      size: 'medium',
      width: '100%',
      onClick: () => {
        this.logout();
      }
    })
  }
  .width('100%')
}
```

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/pages/watch/WatchAccountUnsupportedPage.ets
git commit -m "feat(watch): WatchAccountUnsupportedPage 圆屏适配 + WatchButton"
```

---

## Task 4: 适配 WatchLoginPage（可滚动 + 圆屏 padding）

**Files:**
- Modify: `entry/src/main/ets/pages/watch/WatchLoginPage.ets`

- [ ] **Step 1: 添加 import**

```typescript
import { WatchButton } from '../../components/WatchButton';
```

- [ ] **Step 2: 调整外层布局 padding**

将最外层 Column 的 `.padding(8)` 改为圆屏安全 padding：
```typescript
.padding({ left: 12, right: 12, top: 30, bottom: 30 })
```

- [ ] **Step 3: 缩小标题和标签字号**

将 `'登录'` 标题的 fontSize 从 `this.largeFontEnabled ? 20 : 18` 改为 `this.largeFontEnabled ? 16 : 14`。

将 `'请使用已在手机端注册的账号'` 的 fontSize 从 `12` 改为 `10`。

将两个 `'手机号'` / `'验证码'` 标签的 fontSize 从 `14` 改为 `12`。

- [ ] **Step 4: 缩小输入框高度**

将所有 `TextInput` 的 `.height(40)` 改为 `.height(32)`。

- [ ] **Step 5: 缩小数字键盘按钮**

将所有数字键盘 Button 行的 `.height(36)` 改为 `.height(28)`，行间 `space: 8` 改为 `space: 4`：

```typescript
Column({ space: 4 }) {
  Row({ space: 4 }) {
    Button('1').layoutWeight(1).height(28).onClick(() => { this.appendDigit('1'); })
    Button('2').layoutWeight(1).height(28).onClick(() => { this.appendDigit('2'); })
    Button('3').layoutWeight(1).height(28).onClick(() => { this.appendDigit('3'); })
  }
  Row({ space: 4 }) {
    Button('4').layoutWeight(1).height(28).onClick(() => { this.appendDigit('4'); })
    Button('5').layoutWeight(1).height(28).onClick(() => { this.appendDigit('5'); })
    Button('6').layoutWeight(1).height(28).onClick(() => { this.appendDigit('6'); })
  }
  Row({ space: 4 }) {
    Button('7').layoutWeight(1).height(28).onClick(() => { this.appendDigit('7'); })
    Button('8').layoutWeight(1).height(28).onClick(() => { this.appendDigit('8'); })
    Button('9').layoutWeight(1).height(28).onClick(() => { this.appendDigit('9'); })
  }
  Row({ space: 4 }) {
    Button('清空')
      .layoutWeight(1)
      .height(28)
      .fontSize(11)
      .backgroundColor('#e2e8f0')
      .fontColor('#334155')
      .onClick(() => { this.clearActiveField(); })
    Button('0').layoutWeight(1).height(28).onClick(() => { this.appendDigit('0'); })
    Button('删除')
      .layoutWeight(1)
      .height(28)
      .fontSize(11)
      .backgroundColor('#e2e8f0')
      .fontColor('#334155')
      .onClick(() => { this.deleteOne(); })
  }
}
.width('100%')
```

> 注意：数字键盘按钮保持原生 Button（不用 WatchButton），因为它们是紧凑的 3x4 网格，WatchButton 的 44dp 最小尺寸会导致键盘过大。

- [ ] **Step 6: 登录按钮换 WatchButton**

将底部登录按钮替换为：
```typescript
WatchButton({
  text: this.isLoading ? '登录中...' : '登录',
  type: 'primary',
  size: 'medium',
  width: '100%',
  enabled: this.phone.length === 11 && this.code.length > 0 && !this.isLoading,
  onClick: () => {
    this.handleLogin();
  }
})
```

- [ ] **Step 7: 获取验证码按钮换 WatchButton**

将获取验证码 Button 替换为：
```typescript
WatchButton({
  text: this.countdown > 0 ? `${this.countdown}秒` : '获取验证码',
  type: 'secondary',
  size: 'small',
  enabled: this.phone.length === 11 && this.countdown === 0,
  onClick: () => {
    this.handleSendCode();
  }
})
```

- [ ] **Step 8: Commit**

```bash
git add entry/src/main/ets/pages/watch/WatchLoginPage.ets
git commit -m "feat(watch): WatchLoginPage 圆屏 padding + 键盘缩小 + WatchButton"
```

---

## Task 5: 适配 WatchSeekerHomePage + 新增"分类求助"和"设置"入口

**Files:**
- Modify: `entry/src/main/ets/pages/watch/WatchSeekerHomePage.ets`

- [ ] **Step 1: 添加 import**

```typescript
import { WatchButton } from '../../components/WatchButton';
```

- [ ] **Step 2: 添加导航方法**

在 `logout()` 方法之后添加：
```typescript
private goRequest(): void {
  router.pushUrl({ url: 'pages/watch/WatchSeekerRequestPage' }).catch((err: Error) => {
    console.error('nav request failed:', err);
  });
}

private goSettings(): void {
  router.pushUrl({ url: 'pages/watch/WatchSettingsPage' }).catch((err: Error) => {
    console.error('nav settings failed:', err);
  });
}
```

- [ ] **Step 3: 重写 pageContent Builder**

```typescript
@Builder
pageContent() {
  Column({ space: 8 }) {
    Text('互助帮扶')
      .fontSize(15)
      .fontWeight(FontWeight.Bold)
      .width('100%')
      .textAlign(TextAlign.Center)

    Text('求助者')
      .fontSize(11)
      .fontColor('#64748b')
      .width('100%')
      .textAlign(TextAlign.Center)

    WatchButton({
      text: '一键紧急求助',
      type: 'emergency',
      size: 'large',
      width: '100%',
      accessibilityLabel: '一键紧急求助按钮',
      onClick: () => {
        this.goEmergency();
      }
    })

    WatchButton({
      text: '分类求助',
      type: 'primary',
      size: 'medium',
      width: '100%',
      onClick: () => {
        this.goRequest();
      }
    })

    WatchButton({
      text: '我的求助',
      type: 'primary',
      size: 'medium',
      width: '100%',
      onClick: () => {
        this.goMyRequests();
      }
    })

    Row({ space: 6 }) {
      WatchButton({
        text: '设置',
        type: 'secondary',
        size: 'small',
        onClick: () => {
          this.goSettings();
        }
      })
      WatchButton({
        text: '退出',
        type: 'secondary',
        size: 'small',
        onClick: () => {
          this.logout();
        }
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }
  .width('100%')
}
```

- [ ] **Step 4: Commit**

```bash
git add entry/src/main/ets/pages/watch/WatchSeekerHomePage.ets
git commit -m "feat(watch): WatchSeekerHomePage WatchButton + 分类求助/设置入口"
```

---

## Task 6: 适配 WatchSeekerEmergencyPage（可滚动 + 圆屏 padding）

**Files:**
- Modify: `entry/src/main/ets/pages/watch/WatchSeekerEmergencyPage.ets`

- [ ] **Step 1: 添加 import**

```typescript
import { WatchButton } from '../../components/WatchButton';
```

- [ ] **Step 2: 调整外层布局**

将 build() 中最外层 Column 改为 Scroll 包裹，并应用圆屏 padding：
```typescript
build() {
  Column() {
    Scroll() {
      Column({ space: 8 }) {
        Text('\u4e00\u952e\u6c42\u52a9')
          .fontSize(this.largeFontEnabled ? 16 : 14)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.highContrastEnabled ? '#000000' : '#0f172a')
          .width('100%')
          .textAlign(TextAlign.Center)

        Text(this.hint)
          .fontSize(this.largeFontEnabled ? 12 : 10)
          .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
          .width('100%')
          .textAlign(TextAlign.Center)
          .maxLines(5)

        if (!this.hasLoginToken) {
          WatchButton({
            text: '\u767b\u5f55',
            type: 'primary',
            size: 'medium',
            width: '100%',
            onClick: () => {
              this.goLogin();
            }
          })
        }

        WatchButton({
          text: this.isSubmitting ? '\u53d1\u9001\u4e2d...' : '\u53d1\u9001\u7d27\u6025\u6c42\u52a9',
          type: 'emergency',
          size: 'large',
          width: '100%',
          enabled: !this.isSubmitting,
          accessibilityLabel: '发送紧急求助按钮',
          onClick: () => {
            this.submit();
          }
        })

        WatchButton({
          text: this.isLocating ? '\u5b9a\u4f4d\u4e2d...' : '\u5237\u65b0\u4f4d\u7f6e',
          type: 'secondary',
          size: 'small',
          width: '100%',
          enabled: !this.isLocating,
          onClick: () => {
            this.tryLocate().then(() => {
              this.hint = this.locationText.length > 0 ? '\u5df2\u66f4\u65b0\u4f4d\u7f6e' : '\u4ecd\u672a\u83b7\u53d6\u4f4d\u7f6e';
            });
          }
        })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 30, bottom: 30 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }
  .width('100%')
  .height('100%')
  .backgroundColor(this.highContrastEnabled ? '#ffffff' : '#f8fafc')
}
```

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/pages/watch/WatchSeekerEmergencyPage.ets
git commit -m "feat(watch): WatchSeekerEmergencyPage 圆屏 padding + WatchButton"
```

---

## Task 7: 适配 WatchMyRequestsPage（可滚动 + 圆屏 padding）

**Files:**
- Modify: `entry/src/main/ets/pages/watch/WatchMyRequestsPage.ets`

- [ ] **Step 1: 调整外层 padding**

将最外层 Column 的 `.padding({ top: 6 })` 改为：
```typescript
.padding({ top: 30, bottom: 30, left: 12, right: 12 })
```

- [ ] **Step 2: 缩小头部 padding 和字号**

将头部 Row 的 padding 调整：
```typescript
.padding({ left: 0, right: 0, top: 0, bottom: 6 })
```

将标题字号从 `16` 改为 `14`。

- [ ] **Step 3: 缩小列表项尺寸**

将列表项中 `Text(row.title)` 的 `.fontSize(14)` 改为 `.fontSize(12)`。
将 `Row` 中两个 Text 的 `.fontSize(11)` 改为 `.fontSize(10)`。
将列表项 Column 的 `.padding(10)` 改为 `.padding(8)`。
将 `.borderRadius(12)` 改为 `.borderRadius(10)`。
将 List 的 `space: 8` 改为 `space: 6`。

- [ ] **Step 4: 缩小列表区域的 padding**

将列表区域的 `.padding({ left: 10, right: 10, bottom: 10 })` 改为 `.padding({ left: 0, right: 0, bottom: 0 })`（外层已有 padding）。

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/pages/watch/WatchMyRequestsPage.ets
git commit -m "feat(watch): WatchMyRequestsPage 圆屏 padding + 字号缩小"
```

---

## Task 8: 适配 WatchSeekerRequestDetailPage + 拨打志愿者电话

**Files:**
- Modify: `entry/src/main/ets/pages/watch/WatchSeekerRequestDetailPage.ets`

- [ ] **Step 1: 添加 import**

```typescript
import { WatchButton } from '../../components/WatchButton';
import call from '@ohos.telephony.call';
```

- [ ] **Step 2: 调整外层 padding**

将最外层 Column 的 `.padding({ top: 6 })` 改为：
```typescript
.padding({ top: 30, bottom: 30, left: 12, right: 12 })
```

- [ ] **Step 3: 缩小头部字号**

将头部标题 fontSize 从 `16` 改为 `14`。
将头部 Row padding 改为：
```typescript
.padding({ left: 0, right: 0, top: 0, bottom: 6 })
```

- [ ] **Step 4: 缩小内容字号和尺寸**

将 `this.detail.request.title` 的 `.fontSize(15)` 改为 `.fontSize(13)`。
将 `this.detail.request.location` 的 `.fontSize(12)` 改为 `.fontSize(11)`。
将志愿者卡片内 `'志愿者'` 的 `.fontSize(11)` 改为 `.fontSize(10)`。
将志愿者名+电话的 `.fontSize(13)` 改为 `.fontSize(11)`。
将时间线数字圆点从 `.width(22).height(22).borderRadius(11)` 改为 `.width(18).height(18).borderRadius(9)`。
将时间线 label 的 `.fontSize(12)` 改为 `.fontSize(11)`。
将 `'进度'` 标题的 `.fontSize(13)` 改为 `.fontSize(12)`。
将 Scroll 内 Column 的 `.padding(10)` 改为 `.padding(0)`（外层已有 padding）。

- [ ] **Step 5: 在志愿者信息块下方添加拨打电话按钮**

在志愿者信息 `Column` 之后（`if (this.detail.volunteer)` 块内），在关闭的 `.borderRadius(10)` 之后，添加：

```typescript
if (this.detail.volunteer && this.detail.volunteer.phone) {
  WatchButton({
    text: '拨打志愿者电话',
    type: 'primary',
    size: 'medium',
    width: '100%',
    accessibilityLabel: '拨打志愿者电话',
    onClick: () => {
      try {
        call.makeCall(this.detail!.volunteer!.phone!);
      } catch (e) {
        promptAction.showToast({
          message: `电话：${this.detail!.volunteer!.phoneMasked}`,
          duration: 3000
        });
      }
    }
  })
}
```

- [ ] **Step 6: 取消按钮换 WatchButton**

将取消按钮替换为：
```typescript
if (this.canCancel()) {
  WatchButton({
    text: this.isCancelling ? '处理中...' : '取消求助',
    type: 'emergency',
    size: 'medium',
    width: '100%',
    enabled: !this.isCancelling,
    onClick: () => {
      this.cancel();
    }
  })
}
```

- [ ] **Step 7: Commit**

```bash
git add entry/src/main/ets/pages/watch/WatchSeekerRequestDetailPage.ets
git commit -m "feat(watch): 求助详情页圆屏适配 + 一键拨打志愿者电话"
```

---

## Task 9: 重构 WatchVolunteerHomePage（按钮导航 + 统计 + 在线状态）

**Files:**
- Modify: `entry/src/main/ets/pages/watch/WatchVolunteerHomePage.ets`

- [ ] **Step 1: 重写整个文件**

志愿者首页从"滚动列表"改为"WatchCircularLayout 按钮导航"，附近求助和订单列表拆到独立页面。

```typescript
import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { AuthService } from '../../services/AuthService';
import { WatchCircularLayout } from '../../components/WatchCircularLayout';
import { WatchButton } from '../../components/WatchButton';
import { VolunteerApi, UserApi } from '../../services/ApiService';
import { StorageUtil } from '../../utils/StorageUtil';
import type { VolunteerStatistics } from '../../models/Common';
import type { UserProfile } from '../../models/User';

@Entry
@Component
struct WatchVolunteerHomePage {
  @State stats: VolunteerStatistics | null = null;
  @State isOnline: boolean = false;
  @State isTogglingStatus: boolean = false;

  aboutToAppear(): void {
    this.loadData();
  }

  onPageShow(): void {
    this.loadData();
  }

  private async loadData(): Promise<void> {
    try {
      const s = await VolunteerApi.getStatistics();
      this.stats = s;
    } catch (_) {
      // ignore
    }
    try {
      const user: UserProfile | null = await StorageUtil.get<UserProfile>('user');
      if (user && user.status) {
        this.isOnline = user.status === 'online';
      }
    } catch (_) {
      // ignore
    }
  }

  private async toggleOnline(): Promise<void> {
    if (this.isTogglingStatus) {
      return;
    }
    this.isTogglingStatus = true;
    const newStatus = this.isOnline ? 'offline' : 'online';
    try {
      const updated = await UserApi.updateUserProfile({ status: newStatus } as Partial<UserProfile>);
      await StorageUtil.set('user', updated);
      this.isOnline = newStatus === 'online';
      promptAction.showToast({ message: this.isOnline ? '已上线' : '已离线', duration: 1500 });
    } catch (e) {
      const err = e as Error;
      promptAction.showToast({ message: err.message || '操作失败', duration: 2000 });
    } finally {
      this.isTogglingStatus = false;
    }
  }

  private goNearby(): void {
    router.pushUrl({ url: 'pages/watch/WatchVolunteerNearbyPage' }).catch((err: Error) => {
      console.error('nav nearby failed:', err);
    });
  }

  private goOrders(): void {
    router.pushUrl({ url: 'pages/watch/WatchVolunteerOrdersPage' }).catch((err: Error) => {
      console.error('nav orders failed:', err);
    });
  }

  private goSettings(): void {
    router.pushUrl({ url: 'pages/watch/WatchSettingsPage' }).catch((err: Error) => {
      console.error('nav settings failed:', err);
    });
  }

  private async logout(): Promise<void> {
    await AuthService.logout();
    promptAction.showToast({ message: '已退出', duration: 1500 });
    router.replaceUrl({ url: 'pages/watch/WatchLoginPage' }).catch((err: Error) => {
      console.error('nav login failed:', err);
    });
  }

  build() {
    WatchCircularLayout({
      centerRadius: 120,
      edgePadding: 16,
      content: () => {
        this.pageContent()
      }
    })
  }

  @Builder
  pageContent() {
    Column({ space: 6 }) {
      Text('志愿者')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .textAlign(TextAlign.Center)

      if (this.stats) {
        Row({ space: 6 }) {
          Text(`${this.stats.serviceCount}次`)
            .fontSize(10)
            .fontColor('#64748b')
          Text('|')
            .fontSize(10)
            .fontColor('#cbd5e1')
          Text(`${this.stats.satisfactionPercent !== null ? this.stats.satisfactionPercent + '%' : '--'}`)
            .fontSize(10)
            .fontColor('#64748b')
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }

      WatchButton({
        text: this.isTogglingStatus ? '...' : (this.isOnline ? '在线 (点击离线)' : '离线 (点击上线)'),
        type: this.isOnline ? 'primary' : 'secondary',
        size: 'small',
        width: '100%',
        onClick: () => {
          this.toggleOnline();
        }
      })

      WatchButton({
        text: '查看附近求助',
        type: 'primary',
        size: 'medium',
        width: '100%',
        onClick: () => {
          this.goNearby();
        }
      })

      WatchButton({
        text: '我的服务',
        type: 'primary',
        size: 'medium',
        width: '100%',
        onClick: () => {
          this.goOrders();
        }
      })

      Row({ space: 6 }) {
        WatchButton({
          text: '设置',
          type: 'secondary',
          size: 'small',
          onClick: () => {
            this.goSettings();
          }
        })
        WatchButton({
          text: '退出',
          type: 'secondary',
          size: 'small',
          onClick: () => {
            this.logout();
          }
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/pages/watch/WatchVolunteerHomePage.ets
git commit -m "feat(watch): 志愿者首页重构为按钮导航 + 统计 + 在线状态"
```

---

## Task 10: 新增 WatchVolunteerNearbyPage（附近求助列表）

**Files:**
- Create: `entry/src/main/ets/pages/watch/WatchVolunteerNearbyPage.ets`

- [ ] **Step 1: 创建文件**

这个页面从原 WatchVolunteerHomePage 拆出附近求助列表的逻辑：

```typescript
import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { WatchButton } from '../../components/WatchButton';
import { getCurrentPosition, requestLocationPermission } from '../../utils/LocationUtil';
import type { LocationPoint } from '../../utils/LocationUtil';
import { HelpRequestWithDistance, RequestApi, UserApi, type RequestListFilters } from '../../services/ApiService';
import type { HelpRequest } from '../../models/Request';

interface ReqRow {
  id: string;
  title: string;
  sub: string;
  distanceKm?: number;
}

@Entry
@Component
struct WatchVolunteerNearbyPage {
  @State requests: ReqRow[] = [];
  @State isLoading: boolean = true;

  aboutToAppear(): void {
    this.loadRequests();
  }

  private safeText(value: string | undefined, fallback: string): string {
    if (!value) {
      return fallback;
    }
    const t = value.trim();
    if (t.length === 0) {
      return fallback;
    }
    if (/^[\?？�]+$/.test(t)) {
      return fallback;
    }
    return t;
  }

  private typeLabel(t: string): string {
    switch (t) {
      case 'medical':
        return '就医';
      case 'companion':
        return '出行';
      case 'emergency':
        return '紧急';
      default:
        return '求助';
    }
  }

  private async loadRequests(): Promise<void> {
    this.isLoading = true;
    try {
      await requestLocationPermission();
      let pos = await getCurrentPosition();
      if (!pos) {
        const fallback: LocationPoint = { latitude: 39.9042, longitude: 116.4074 };
        pos = fallback;
      }
      try {
        await UserApi.reportLocation(pos.latitude, pos.longitude, undefined, 'watch');
      } catch (_) {
        // ignore
      }
      try {
        const res = await RequestApi.getNearbyRequests(1, 15, pos.latitude, pos.longitude);
        this.requests = res.items.map((it: HelpRequestWithDistance): ReqRow => ({
          id: it.request.id,
          title: this.safeText(it.request.title, this.typeLabel(it.request.type)),
          sub: this.safeText(it.request.location, '位置未填写'),
          distanceKm: it.distance
        }));
      } catch (_) {
        const pendingFilter: RequestListFilters = { status: 'pending' };
        const res = await RequestApi.getRequests(1, 15, pendingFilter);
        this.requests = res.items.map((r: HelpRequest): ReqRow => ({
          id: r.id,
          title: this.safeText(r.title, this.typeLabel(r.type)),
          sub: this.safeText(r.location, '位置未填写')
        }));
      }
    } catch (e) {
      const err = e as Error;
      promptAction.showToast({ message: err.message || '加载失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  private openRequest(id: string): void {
    router.pushUrl({
      url: 'pages/watch/WatchVolunteerRequestDetailPage',
      params: { id: id }
    }).catch((err: Error) => {
      console.error('nav failed:', err);
    });
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        NavBackButton()
        Text('附近求助')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 0, right: 0, top: 0, bottom: 6 })

      if (this.isLoading) {
        Column({ space: 6 }) {
          LoadingProgress().width(28).height(28)
          Text('加载中...').fontSize(11).fontColor('#64748b')
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.requests.length === 0) {
        Text('暂无待接求助')
          .fontSize(12)
          .fontColor('#94a3b8')
          .layoutWeight(1)
          .width('100%')
          .textAlign(TextAlign.Center)
      } else {
        List({ space: 6 }) {
          ForEach(this.requests, (r: ReqRow) => {
            ListItem() {
              Column({ space: 3 }) {
                Text(r.title)
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .maxLines(2)
                Text(r.sub)
                  .fontSize(10)
                  .fontColor('#64748b')
                  .maxLines(1)
                if (r.distanceKm !== undefined) {
                  Text(`约 ${r.distanceKm.toFixed(1)} km`)
                    .fontSize(10)
                    .fontColor('#94a3b8')
                }
              }
              .width('100%')
              .padding(8)
              .backgroundColor('#ffffff')
              .borderRadius(8)
              .onClick(() => {
                this.openRequest(r.id);
              })
            }
          }, (r: ReqRow) => r.id)
        }
        .layoutWeight(1)
        .width('100%')
      }

      WatchButton({
        text: '刷新',
        type: 'secondary',
        size: 'small',
        width: '100%',
        onClick: () => {
          this.loadRequests();
        }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f8fafc')
    .padding({ top: 30, bottom: 30, left: 12, right: 12 })
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/pages/watch/WatchVolunteerNearbyPage.ets
git commit -m "feat(watch): 新增志愿者附近求助列表页"
```

---

## Task 11: 新增 WatchVolunteerOrdersPage（志愿者订单列表）

**Files:**
- Create: `entry/src/main/ets/pages/watch/WatchVolunteerOrdersPage.ets`

- [ ] **Step 1: 创建文件**

```typescript
import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { WatchButton } from '../../components/WatchButton';
import { OrderApi } from '../../services/ApiService';
import type { VolunteerOrder } from '../../models/Order';

interface OrdRow {
  orderId: string;
  title: string;
  statusLabel: string;
  status: string;
}

@Entry
@Component
struct WatchVolunteerOrdersPage {
  @State orders: OrdRow[] = [];
  @State isLoading: boolean = true;

  aboutToAppear(): void {
    this.loadOrders();
  }

  onPageShow(): void {
    this.loadOrders();
  }

  private safeText(value: string | undefined, fallback: string): string {
    if (!value) {
      return fallback;
    }
    const t = value.trim();
    if (t.length === 0) {
      return fallback;
    }
    if (/^[\?？�]+$/.test(t)) {
      return fallback;
    }
    return t;
  }

  private statusLabel(s: string): string {
    switch (s) {
      case 'accepted':
        return '已接单';
      case 'in-progress':
        return '服务中';
      case 'completed':
        return '已完成';
      case 'cancelled':
        return '已取消';
      default:
        return s;
    }
  }

  private statusColor(s: string): string {
    switch (s) {
      case 'accepted':
        return '#f59e0b';
      case 'in-progress':
        return '#2563eb';
      case 'completed':
        return '#10b981';
      case 'cancelled':
        return '#94a3b8';
      default:
        return '#64748b';
    }
  }

  private async loadOrders(): Promise<void> {
    this.isLoading = true;
    try {
      const list: VolunteerOrder[] = await OrderApi.getMyOrders();
      this.orders = list.map((o: VolunteerOrder): OrdRow => ({
        orderId: o.id,
        title: this.safeText(o.title, '订单'),
        statusLabel: this.statusLabel(o.status),
        status: o.status
      }));
    } catch (e) {
      const err = e as Error;
      promptAction.showToast({ message: err.message || '加载失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  private openOrder(orderId: string): void {
    router.pushUrl({
      url: 'pages/watch/WatchVolunteerServicePage',
      params: { id: orderId }
    }).catch((err: Error) => {
      console.error('nav failed:', err);
    });
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        NavBackButton()
        Text('我的服务')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 0, right: 0, top: 0, bottom: 6 })

      if (this.isLoading) {
        Column({ space: 6 }) {
          LoadingProgress().width(28).height(28)
          Text('加载中...').fontSize(11).fontColor('#64748b')
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.orders.length === 0) {
        Text('暂无订单')
          .fontSize(12)
          .fontColor('#94a3b8')
          .layoutWeight(1)
          .width('100%')
          .textAlign(TextAlign.Center)
      } else {
        List({ space: 6 }) {
          ForEach(this.orders, (o: OrdRow) => {
            ListItem() {
              Row() {
                Column({ space: 3 }) {
                  Text(o.title)
                    .fontSize(12)
                    .fontWeight(FontWeight.Medium)
                    .maxLines(2)
                  Text(o.statusLabel)
                    .fontSize(10)
                    .fontColor(this.statusColor(o.status))
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              .width('100%')
              .padding(8)
              .backgroundColor(o.status === 'accepted' || o.status === 'in-progress' ? '#eff6ff' : '#ffffff')
              .borderRadius(8)
              .onClick(() => {
                this.openOrder(o.orderId);
              })
            }
          }, (o: OrdRow) => o.orderId)
        }
        .layoutWeight(1)
        .width('100%')
      }

      WatchButton({
        text: '刷新',
        type: 'secondary',
        size: 'small',
        width: '100%',
        onClick: () => {
          this.loadOrders();
        }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f8fafc')
    .padding({ top: 30, bottom: 30, left: 12, right: 12 })
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/pages/watch/WatchVolunteerOrdersPage.ets
git commit -m "feat(watch): 新增志愿者订单列表页"
```

---

## Task 12: 适配 WatchVolunteerRequestDetailPage（可滚动 + 圆屏 padding）

**Files:**
- Modify: `entry/src/main/ets/pages/watch/WatchVolunteerRequestDetailPage.ets`

- [ ] **Step 1: 添加 import**

```typescript
import { WatchButton } from '../../components/WatchButton';
```

- [ ] **Step 2: 调整外层 padding**

将最外层 Column 的 `.padding({ top: 6 })` 改为：
```typescript
.padding({ top: 30, bottom: 30, left: 12, right: 12 })
```

- [ ] **Step 3: 缩小头部和内容字号**

头部标题 fontSize 从 `16` 改为 `14`。
头部 Row padding 改为 `.padding({ left: 0, right: 0, top: 0, bottom: 6 })`。
`this.req.typeLabel` 的 `.fontSize(15)` 改为 `.fontSize(13)`。
`this.req.statusLabel` 的 `.fontSize(11)` 保持不变。
`this.req.description` 的 `.fontSize(12)` 改为 `.fontSize(11)`。
`this.req.location` 和 seekerName 的 `.fontSize(11)` 改为 `.fontSize(10)`。
Scroll 内 Column 的 `.padding(10)` 改为 `.padding(0)`。

- [ ] **Step 4: 接单按钮换 WatchButton**

```typescript
if (this.req.acceptEnabled) {
  WatchButton({
    text: this.isAccepting ? '接单中...' : '接单',
    type: 'primary',
    size: 'medium',
    width: '100%',
    enabled: !this.isAccepting,
    onClick: () => {
      this.accept();
    }
  })
}
```

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/pages/watch/WatchVolunteerRequestDetailPage.ets
git commit -m "feat(watch): 志愿者求助详情页圆屏适配 + WatchButton"
```

---

## Task 13: 适配 WatchVolunteerServicePage（可滚动 + 圆屏 padding）

**Files:**
- Modify: `entry/src/main/ets/pages/watch/WatchVolunteerServicePage.ets`

- [ ] **Step 1: 添加 import**

```typescript
import { WatchButton } from '../../components/WatchButton';
```

- [ ] **Step 2: 调整外层 padding**

将最外层 Column 的 `.padding({ top: 6 })` 改为：
```typescript
.padding({ top: 30, bottom: 30, left: 12, right: 12 })
```

- [ ] **Step 3: 缩小头部和内容字号**

头部标题 fontSize 从 `16` 改为 `14`。
头部 Row padding 改为 `.padding({ left: 0, right: 0, top: 0, bottom: 6 })`。
`this.order.title` 的 `.fontSize(15)` 改为 `.fontSize(13)`。
`statusLabel` 的 `.fontSize(12)` 改为 `.fontSize(11)`。
`location` / `求助者` 的 `.fontSize(11)` 改为 `.fontSize(10)`。
`接单时间` 的 `.fontSize(10)` 保持不变。
计时器的 `.fontSize(13)` 改为 `.fontSize(12)`。
Scroll 内 Column 的 `.padding(10)` 改为 `.padding(0)`。

- [ ] **Step 4: 替换操作按钮**

将三个操作按钮替换为 WatchButton：

```typescript
if (this.order.status === 'accepted') {
  WatchButton({
    text: this.isUpdating ? '...' : '开始服务',
    type: 'primary',
    size: 'medium',
    width: '100%',
    enabled: !this.isUpdating,
    onClick: () => {
      this.startService();
    }
  })
}

if (this.order.status === 'in-progress') {
  WatchButton({
    text: this.isUpdating ? '...' : '完成服务',
    type: 'primary',
    size: 'medium',
    width: '100%',
    enabled: !this.isUpdating,
    onClick: () => {
      this.completeService();
    }
  })
}

if (this.order.status === 'completed') {
  WatchButton({
    text: '去评价',
    type: 'secondary',
    size: 'medium',
    width: '100%',
    onClick: () => {
      router.pushUrl({
        url: 'pages/watch/WatchVolunteerReviewPage',
        params: { id: this.orderId }
      }).catch((err: Error) => {
        console.error('nav review failed:', err);
      });
    }
  })
}
```

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/pages/watch/WatchVolunteerServicePage.ets
git commit -m "feat(watch): 服务进度页圆屏适配 + WatchButton"
```

---

## Task 14: 适配 WatchVolunteerReviewPage（可滚动 + 圆屏 padding）

**Files:**
- Modify: `entry/src/main/ets/pages/watch/WatchVolunteerReviewPage.ets`

- [ ] **Step 1: 添加 import**

```typescript
import { WatchButton } from '../../components/WatchButton';
```

- [ ] **Step 2: 调整外层和头部**

在最外层 Column 上添加：
```typescript
.padding({ top: 30, bottom: 30, left: 12, right: 12 })
```

头部标题 fontSize 从 `17` 改为 `14`。
头部 Row padding 从 `12` 改为 `.padding({ left: 0, right: 0, top: 0, bottom: 6 })`。
Scroll 内 Column 的 `.padding(12)` 改为 `.padding(0)`。
Column 的 `space: 12` 改为 `space: 8`。

- [ ] **Step 3: 缩小内容字号**

`服务对象` 文字的 `.fontSize(14)` 改为 `.fontSize(12)`。

- [ ] **Step 4: 评分按钮换 WatchButton**

将三个评分 Button 替换为：

```typescript
Row({ space: 6 }) {
  WatchButton({
    text: '满意',
    type: this.selectedScore === 5 ? 'primary' : 'secondary',
    size: 'small',
    enabled: this.existing === null,
    onClick: () => {
      this.selectedScore = 5;
    }
  })
  WatchButton({
    text: '一般',
    type: this.selectedScore === 3 ? 'primary' : 'secondary',
    size: 'small',
    enabled: this.existing === null,
    onClick: () => {
      this.selectedScore = 3;
    }
  })
  WatchButton({
    text: '不满',
    type: this.selectedScore === 1 ? 'emergency' : 'secondary',
    size: 'small',
    enabled: this.existing === null,
    onClick: () => {
      this.selectedScore = 1;
    }
  })
}
.width('100%')
.justifyContent(FlexAlign.SpaceBetween)
```

- [ ] **Step 5: 反馈输入框和提交按钮**

将 TextInput 高度从 `72` 改为 `56`，fontSize 从 `13` 改为 `11`。

将提交按钮替换为：
```typescript
if (this.existing !== null) {
  Text('已提交评价')
    .fontSize(11)
    .fontColor('#64748b')
} else {
  WatchButton({
    text: this.isSubmitting ? '提交中...' : '提交评价',
    type: 'primary',
    size: 'medium',
    width: '100%',
    enabled: this.selectedScore > 0 && !this.isSubmitting,
    onClick: () => {
      this.submit();
    }
  })
}
```

- [ ] **Step 6: Commit**

```bash
git add entry/src/main/ets/pages/watch/WatchVolunteerReviewPage.ets
git commit -m "feat(watch): 评价页圆屏适配 + WatchButton"
```

---

## Task 15: 新增 WatchSeekerRequestPage（分类求助）

**Files:**
- Create: `entry/src/main/ets/pages/watch/WatchSeekerRequestPage.ets`

- [ ] **Step 1: 创建文件**

```typescript
import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { WatchButton } from '../../components/WatchButton';
import { RequestApi, GeocodeApi } from '../../services/ApiService';
import { getCurrentPosition, requestLocationPermission } from '../../utils/LocationUtil';
import { StorageUtil } from '../../utils/StorageUtil';
import type { HelpRequest } from '../../models/Request';
import type { UserProfile } from '../../models/User';

@Entry
@Component
struct WatchSeekerRequestPage {
  @State selectedType: string = '';
  @State description: string = '';
  @State locationText: string = '';
  @State latitude: number = 0;
  @State longitude: number = 0;
  @State hasGeo: boolean = false;
  @State isLocating: boolean = false;
  @State isSubmitting: boolean = false;

  aboutToAppear(): void {
    this.tryLocate();
  }

  private async tryLocate(): Promise<void> {
    if (this.isLocating) {
      return;
    }
    this.isLocating = true;
    try {
      const granted = await requestLocationPermission();
      if (!granted) {
        return;
      }
      const pos = await getCurrentPosition();
      if (!pos) {
        return;
      }
      this.latitude = pos.latitude;
      this.longitude = pos.longitude;
      this.hasGeo = true;
      const address = await GeocodeApi.getAddressFromCoordinates(pos.latitude, pos.longitude);
      this.locationText = address && address.length > 0
        ? address
        : `${pos.latitude.toFixed(5)}, ${pos.longitude.toFixed(5)}`;
    } catch (e) {
      console.error('locate failed:', e);
    } finally {
      this.isLocating = false;
    }
  }

  private urgencyForType(type: string): string {
    if (type === 'medical') {
      return 'high';
    }
    if (type === 'emergency') {
      return 'emergency';
    }
    return 'medium';
  }

  private typeName(type: string): string {
    switch (type) {
      case 'medical':
        return '就医求助';
      case 'companion':
        return '出行协助';
      case 'shopping':
        return '生活帮扶';
      default:
        return '其他求助';
    }
  }

  private async submit(): Promise<void> {
    if (!this.selectedType || this.isSubmitting) {
      return;
    }
    this.isSubmitting = true;
    try {
      const user: UserProfile | null = await StorageUtil.get<UserProfile>('user');
      const loc = this.locationText.trim().length > 0
        ? this.locationText.trim()
        : '未知位置（手表端发起）';

      const payload: Partial<HelpRequest> = {
        type: this.selectedType as HelpRequest['type'],
        title: this.typeName(this.selectedType),
        description: this.description.trim().length > 0
          ? `【手表端】${this.description.trim()}`
          : `【手表端】${this.typeName(this.selectedType)}`,
        location: loc,
        urgency: this.urgencyForType(this.selectedType) as HelpRequest['urgency']
      };

      if (this.hasGeo) {
        payload.latitude = this.latitude;
        payload.longitude = this.longitude;
      }

      const created = await RequestApi.createRequest(payload);
      promptAction.showToast({ message: '已发起求助', duration: 1500 });
      router.replaceUrl({
        url: 'pages/watch/WatchMyRequestsPage',
        params: { createdId: created.id }
      }).catch((err: Error) => {
        console.error('nav failed:', err);
      });
    } catch (e) {
      const err = e as Error;
      promptAction.showToast({ message: err.message || '提交失败', duration: 2000 });
    } finally {
      this.isSubmitting = false;
    }
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        NavBackButton()
        Text('发起求助')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 0, right: 0, top: 0, bottom: 6 })

      Scroll() {
        Column({ space: 8 }) {
          if (this.selectedType.length === 0) {
            Text('选择类型')
              .fontSize(12)
              .fontColor('#64748b')
              .width('100%')

            Row({ space: 6 }) {
              WatchButton({
                text: '就医',
                type: 'emergency',
                size: 'small',
                onClick: () => { this.selectedType = 'medical'; }
              })
              WatchButton({
                text: '出行',
                type: 'primary',
                size: 'small',
                onClick: () => { this.selectedType = 'companion'; }
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceEvenly)

            Row({ space: 6 }) {
              WatchButton({
                text: '生活',
                type: 'primary',
                size: 'small',
                onClick: () => { this.selectedType = 'shopping'; }
              })
              WatchButton({
                text: '其他',
                type: 'secondary',
                size: 'small',
                onClick: () => { this.selectedType = 'other'; }
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceEvenly)
          } else {
            Row({ space: 6 }) {
              Text(`类型：${this.typeName(this.selectedType)}`)
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
              Text('重选')
                .fontSize(10)
                .fontColor('#2563eb')
                .onClick(() => { this.selectedType = ''; })
            }
            .width('100%')

            TextInput({ placeholder: '简要描述（可选）' })
              .height(32)
              .fontSize(11)
              .onChange((v: string) => {
                this.description = v;
              })

            Text(this.isLocating ? '定位中...' : (this.locationText || '未获取位置'))
              .fontSize(10)
              .fontColor('#64748b')
              .maxLines(2)
              .width('100%')

            WatchButton({
              text: this.isSubmitting ? '提交中...' : '提交求助',
              type: 'primary',
              size: 'medium',
              width: '100%',
              enabled: !this.isSubmitting,
              onClick: () => {
                this.submit();
              }
            })
          }
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f8fafc')
    .padding({ top: 30, bottom: 30, left: 12, right: 12 })
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/pages/watch/WatchSeekerRequestPage.ets
git commit -m "feat(watch): 新增分类求助页"
```

---

## Task 16: 新增 WatchSettingsPage（设置 + 角色切换）

**Files:**
- Create: `entry/src/main/ets/pages/watch/WatchSettingsPage.ets`

- [ ] **Step 1: 创建文件**

```typescript
import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { WatchButton } from '../../components/WatchButton';
import { WatchCircularLayout } from '../../components/WatchCircularLayout';
import { UserApi } from '../../services/ApiService';
import { StorageUtil } from '../../utils/StorageUtil';
import type { UserProfile } from '../../models/User';

@Entry
@Component
struct WatchSettingsPage {
  @State currentRole: string = '';
  @State isSwitching: boolean = false;

  aboutToAppear(): void {
    this.loadRole();
  }

  private async loadRole(): Promise<void> {
    try {
      const user: UserProfile | null = await StorageUtil.get<UserProfile>('user');
      if (user && user.role) {
        this.currentRole = user.role as string;
      }
    } catch (_) {
      // ignore
    }
  }

  private roleLabel(role: string): string {
    switch (role) {
      case 'help-seeker':
        return '求助者';
      case 'volunteer':
        return '志愿者';
      default:
        return role;
    }
  }

  private targetRole(): string {
    return this.currentRole === 'help-seeker' ? 'volunteer' : 'help-seeker';
  }

  private async switchRole(): Promise<void> {
    if (this.isSwitching) {
      return;
    }
    this.isSwitching = true;
    const target = this.targetRole();
    try {
      const updated = await UserApi.switchUserRole(target);
      await StorageUtil.set('user', updated);
      promptAction.showToast({ message: `已切换为${this.roleLabel(target)}`, duration: 1500 });
      if (target === 'help-seeker') {
        router.replaceUrl({ url: 'pages/watch/WatchSeekerHomePage' }).catch((err: Error) => {
          console.error('nav failed:', err);
        });
      } else {
        router.replaceUrl({ url: 'pages/watch/WatchVolunteerHomePage' }).catch((err: Error) => {
          console.error('nav failed:', err);
        });
      }
    } catch (e) {
      const err = e as Error;
      promptAction.showToast({ message: err.message || '切换失败', duration: 2000 });
    } finally {
      this.isSwitching = false;
    }
  }

  build() {
    WatchCircularLayout({
      centerRadius: 120,
      edgePadding: 16,
      content: () => {
        this.pageContent()
      }
    })
  }

  @Builder
  pageContent() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        NavBackButton()
        Text('设置')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
      }
      .width('100%')

      Text(`当前身份：${this.roleLabel(this.currentRole)}`)
        .fontSize(11)
        .fontColor('#64748b')
        .width('100%')
        .textAlign(TextAlign.Center)

      WatchButton({
        text: this.isSwitching ? '切换中...' : `切换为${this.roleLabel(this.targetRole())}`,
        type: 'primary',
        size: 'medium',
        width: '100%',
        enabled: !this.isSwitching,
        onClick: () => {
          this.switchRole();
        }
      })

      WatchButton({
        text: '无障碍设置',
        type: 'secondary',
        size: 'medium',
        width: '100%',
        onClick: () => {
          router.pushUrl({ url: 'pages/watch/WatchAccessibilityPage' }).catch((err: Error) => {
            console.error('nav accessibility failed:', err);
          });
        }
      })
    }
    .width('100%')
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/pages/watch/WatchSettingsPage.ets
git commit -m "feat(watch): 新增设置页（角色切换 + 无障碍入口）"
```

---

## Task 17: 新增 WatchAccessibilityPage（无障碍设置）

**Files:**
- Create: `entry/src/main/ets/pages/watch/WatchAccessibilityPage.ets`

- [ ] **Step 1: 创建文件**

```typescript
import router from '@ohos.router';
import { NavBackButton } from '../../components/NavBackButton';
import { WatchCircularLayout } from '../../components/WatchCircularLayout';
import { StorageUtil } from '../../utils/StorageUtil';

@Entry
@Component
struct WatchAccessibilityPage {
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  private async saveSetting(key: string, value: boolean): Promise<void> {
    try {
      await StorageUtil.set(key, value);
    } catch (e) {
      console.error('save setting failed:', e);
    }
  }

  build() {
    WatchCircularLayout({
      centerRadius: 120,
      edgePadding: 16,
      content: () => {
        this.pageContent()
      }
    })
  }

  @Builder
  pageContent() {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        NavBackButton()
        Text('无障碍设置')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
      }
      .width('100%')

      Row() {
        Text('大字体')
          .fontSize(this.largeFontEnabled ? 14 : 12)
          .fontColor(this.highContrastEnabled ? '#000000' : '#334155')
          .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.largeFontEnabled })
          .onChange((isOn: boolean) => {
            this.largeFontEnabled = isOn;
            this.saveSetting('accessibility_large_font', isOn);
          })
      }
      .width('100%')
      .padding({ top: 6, bottom: 6 })

      Row() {
        Text('高对比度')
          .fontSize(this.largeFontEnabled ? 14 : 12)
          .fontColor(this.highContrastEnabled ? '#000000' : '#334155')
          .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.highContrastEnabled })
          .onChange((isOn: boolean) => {
            this.highContrastEnabled = isOn;
            this.saveSetting('accessibility_high_contrast', isOn);
          })
      }
      .width('100%')
      .padding({ top: 6, bottom: 6 })

      Text('设置即时生效')
        .fontSize(10)
        .fontColor('#94a3b8')
        .width('100%')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/pages/watch/WatchAccessibilityPage.ets
git commit -m "feat(watch): 新增无障碍设置页（大字体 + 高对比度）"
```

---

## Task 18: 注册新页面路由

**Files:**
- Modify: `entry/src/main/resources/base/profile/main_pages.json`

- [ ] **Step 1: 添加 5 个新页面路由**

在 `main_pages.json` 的 `src` 数组末尾（最后一个 Watch 页面之后）添加：

```json
"pages/watch/WatchSeekerRequestPage",
"pages/watch/WatchSettingsPage",
"pages/watch/WatchAccessibilityPage",
"pages/watch/WatchVolunteerNearbyPage",
"pages/watch/WatchVolunteerOrdersPage"
```

确保添加在 JSON 数组内，逗号正确。

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/resources/base/profile/main_pages.json
git commit -m "feat(watch): 注册 5 个新手表页面路由"
```

---

## Task 19: 最终验证

- [ ] **Step 1: 检查所有文件 import 无遗漏**

确认所有修改/新增的 .ets 文件中 `import { WatchButton }` 和 `import { WatchCircularLayout }` 正确。

- [ ] **Step 2: 检查路由路径一致性**

确认以下路由在 `main_pages.json` 和代码中的 `router.pushUrl` / `router.replaceUrl` 一致：
- `pages/watch/WatchSeekerRequestPage`
- `pages/watch/WatchSettingsPage`
- `pages/watch/WatchAccessibilityPage`
- `pages/watch/WatchVolunteerNearbyPage`
- `pages/watch/WatchVolunteerOrdersPage`

- [ ] **Step 3: Commit 全部改动（如有遗漏修正）**

```bash
git add -A
git commit -m "feat(watch): 手表端圆屏适配 + 功能迁移完成"
```
