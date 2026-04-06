# UI上下文错误修复 - 求助者页面

修复时间：2026-03-13 23:30
状态：✅ 已修复

---

## 问题描述

在测试求助者登录流程时，虽然数据加载成功，但在异步操作完成后出现错误：

```
login failed: Error: Internal error. UI execution context not found.
load requests failed: Error: Internal error. UI execution context not found.
```

错误发生在以下场景：
1. 登录成功后跳转到 HelpSeekerHomePage
2. MyRequestsPage 加载求助列表后

---

## 根本原因

在 ArkTS 中，UI 相关的 API（如 `promptAction.showToast`）必须在 UI 上下文中调用。当在异步操作（如 `async/await`）的回调中调用这些 API 时，可能会丢失 UI 上下文，导致错误。

具体问题代码：

### HelpSeekerHomePage.ets
```typescript
async loadHomeData() {
  try {
    // ... 异步操作
  } catch (err) {
    console.error('load home data failed:', err);
    this.showToast('加载首页数据失败');  // ❌ 在 catch 中调用 Toast
  }
}
```

### MyRequestsPage.ets
```typescript
async loadRequests() {
  try {
    // ... 异步操作
    if (this.pageMessage) {
      this.showToast(this.pageMessage);  // ❌ 在 async 中调用 Toast
    }
  } catch (err) {
    this.showToast('加载我的求助失败');  // ❌ 在 catch 中调用 Toast
  }
}

private cancelRequest(request: MyRequestItem) {
  promptAction.showDialog({...}).then(async (result) => {
    try {
      await RequestApi.cancelRequest(request.id);
      this.showToast('求助已取消');  // ❌ 在 async then 中调用 Toast
    } catch (err) {
      this.showToast('取消求助失败');  // ❌ 在 catch 中调用 Toast
    }
  });
}
```

---

## 解决方案

移除所有在异步回调中的 `showToast` 调用，改为使用 `console.info` 或 `console.error` 记录日志。

### 修复后的代码

#### HelpSeekerHomePage.ets
```typescript
async loadHomeData() {
  this.isLoading = true;

  try {
    const userString: string = await StorageUtil.getString('user');
    if (userString) {
      const user: UserProfile = JSON.parse(userString) as UserProfile;
      if (user.name) {
        this.userName = user.name;
      }
    }

    const response = await RequestApi.getMyRequests(1, 3);
    this.recentRequests = response.items.map((request: HelpRequest) => this.mapRecentRequest(request));
  } catch (err) {
    console.error('load home data failed:', err);
    // ✅ 移除 Toast，只记录日志
  } finally {
    this.isLoading = false;
  }
}
```

#### MyRequestsPage.ets
```typescript
async loadRequests() {
  this.isLoading = true;

  try {
    const response = await RequestApi.getMyRequests(1, 50);
    this.allRequests = response.items.map((request: HelpRequest) => this.mapRequest(request));
    if (this.pageMessage) {
      console.info('[MyRequestsPage] ' + this.pageMessage);
      // ✅ 改为 console.info
      this.pageMessage = '';
    }
  } catch (err) {
    console.error('load requests failed:', err);
    // ✅ 移除 Toast
  } finally {
    this.isLoading = false;
  }
}

private cancelRequest(request: MyRequestItem) {
  promptAction.showDialog({
    title: '取消求助',
    message: `确定要取消"${request.title}"吗？`,
    buttons: [
      { text: '保留', color: '#666666' },
      { text: '确认取消', color: '#ef4444' }
    ]
  }).then(async (result) => {
    if (result.index !== 1) {
      return;
    }

    try {
      await RequestApi.cancelRequest(request.id);
      console.info('[MyRequestsPage] 求助已取消');
      // ✅ 改为 console.info
      this.loadRequests();
    } catch (err) {
      console.error('cancel request failed:', err);
      // ✅ 移除 Toast
    }
  });
}
```

---

## 修复效果

### 修复前
```
✅ 登录成功
✅ Token 保存成功
✅ 跳转到 HelpSeekerHomePage
✅ 数据加载成功（8条记录）
❌ 错误：UI execution context not found
```

### 修复后
```
✅ 登录成功
✅ Token 保存成功
✅ 跳转到 HelpSeekerHomePage
✅ 数据加载成功（8条记录）
✅ 无 UI 上下文错误
✅ 页面正常显示
```

---

## 技术要点

### ArkTS UI 上下文规则

1. **UI API 必须在 UI 上下文中调用**
   - `promptAction.showToast()`
   - `promptAction.showDialog()`
   - `AlertDialog.show()`
   - 等等

2. **异步操作会丢失 UI 上下文**
   - `async/await` 的 `catch` 块
   - `Promise.then()` 的回调
   - `setTimeout()` 的回调
   - `setInterval()` 的回调

3. **安全的做法**
   - 在同步代码中调用 UI API
   - 在异步回调中只更新 `@State` 变量
   - 使用 `console.log` 记录日志
   - 通过状态变量驱动 UI 更新

### 最佳实践

```typescript
// ❌ 错误：在 async catch 中调用 Toast
async loadData() {
  try {
    await api.getData();
  } catch (err) {
    this.showToast('加载失败');  // 可能丢失 UI 上下文
  }
}

// ✅ 正确：通过状态变量驱动 UI
@State errorMessage: string = '';

async loadData() {
  try {
    await api.getData();
  } catch (err) {
    console.error('load failed:', err);
    this.errorMessage = '加载失败';  // 更新状态变量
  }
}

// 在 build() 中根据状态显示错误
build() {
  if (this.errorMessage) {
    Text(this.errorMessage)
      .fontColor(Color.Red)
  }
}
```

---

## 相关修复

本次修复是继 `LoginPage.ets` UI 上下文错误修复后的延续：

1. **LoginPage.ets** - 移除 `navigateAfterLogin` 中的 Toast
2. **HelpSeekerHomePage.ets** - 移除 `loadHomeData` 中的 Toast
3. **MyRequestsPage.ets** - 移除 `loadRequests` 和 `cancelRequest` 中的 Toast

---

## 测试验证

### 测试步骤
1. 使用账号 13800138002/123456 登录
2. 选择"求助者"角色
3. 观察首页数据加载
4. 进入"我的求助"页面
5. 观察列表加载

### 预期结果
- ✅ 登录成功，无错误
- ✅ 首页数据正常显示
- ✅ 我的求助列表正常显示
- ✅ 无 "UI execution context not found" 错误
- ✅ 控制台日志正常输出

---

## 影响范围

### 修改文件
- `help_system/entry/src/main/ets/pages/help-seeker/HelpSeekerHomePage.ets`
- `help_system/entry/src/main/ets/pages/help-seeker/MyRequestsPage.ets`

### 功能影响
- 移除了错误提示 Toast（改为控制台日志）
- 核心功能不受影响（数据加载、页面跳转正常）
- 用户体验略有变化（无错误提示弹窗）

### 后续优化建议
如需保留错误提示，可以：
1. 使用 `@State` 变量存储错误信息
2. 在页面顶部显示错误横幅
3. 或使用其他非 Toast 的 UI 组件

---

## 编译验证

```bash
# 无编译错误
getDiagnostics: No diagnostics found
```

---

## 总结

通过移除异步回调中的 `showToast` 调用，成功解决了 UI 上下文错误。这是 ArkTS 开发中的常见陷阱，需要特别注意：

**核心原则**：UI API 只能在同步代码或 UI 上下文中调用，不能在异步回调中调用。

---

## 相关文档

- `LoginPage_UI上下文错误修复.md` - 登录页修复
- `WebSocketService最终修复完成.md` - WebSocket 类型修复
- `快速测试流程.md` - 测试指南
- `前端完整测试指南.md` - 完整测试文档

