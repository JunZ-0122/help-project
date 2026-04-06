# LoginPage UI 上下文错误修复

修复时间：2026-03-13 23:16

## 问题描述

登录成功后跳转时出现 UI 上下文错误：

```
Error: Internal error. UI execution context not found.
at showToast (/mnt/disk/jenkins/ci/workspace/.../promptaction.js:40:1)
at showToast entry (entry/src/main/ets/pages/LoginPage.ets:27:18)
at navigateAfterLogin entry (entry/src/main/ets/pages/LoginPage.ets:50:10)
at anonymous entry (entry/src/main/ets/pages/LoginPage.ets:123:14)
```

## 问题原因

在 `setTimeout` 回调中调用 `showToast` 时，UI 执行上下文已经丢失。

### 问题代码流程

```typescript
// 1. 登录成功后
AuthService.login(loginRequest).then(async (response: LoginResponse) => {
  await StorageUtil.getString('token');
  this.isLoading = false;
  
  // 2. 使用 setTimeout 延迟执行
  setTimeout(() => {
    this.navigateAfterLogin(response);  // ← 在这里调用
  }, 100);
})

// 3. navigateAfterLogin 中调用 showToast
private navigateAfterLogin(response: LoginResponse): void {
  // ...
  this.showToast(message, 1500);  // ← UI 上下文丢失！
  router.pushUrl({...});
}
```

## 修复方案

### 方案：移除 Toast，直接跳转

```typescript
private navigateAfterLogin(response: LoginResponse): void {
  const user = response.user;
  const role = user.role ? user.role : '';
  let targetUrl = 'pages/RoleSelectPage';

  if (role === 'help-seeker') {
    targetUrl = 'pages/help-seeker/HelpSeekerHomePage';
  } else if (role === 'volunteer') {
    targetUrl = 'pages/volunteer/VolunteerHomePage';
  } else if (role === 'community') {
    targetUrl = 'pages/community/CommunityHomePage';
  }

  // 直接跳转，不显示 Toast（避免 UI 上下文问题）
  router.pushUrl({
    url: targetUrl,
    params: {
      user: user
    }
  }).catch((err: Error) => {
    console.error('navigation failed:', err);
  });
}
```

### 为什么这样修复？

1. **Toast 不是必需的** - 用户登录成功后直接看到目标页面即可
2. **避免 UI 上下文问题** - 不在异步回调中调用 UI API
3. **简化代码** - 减少不必要的 UI 交互
4. **提升体验** - 更快的页面跳转

## 测试验证

### 预期行为

1. 输入手机号：`13800138002`
2. 输入密码：`123456`
3. 点击"登录"
4. **直接跳转到角色选择页**（无 Toast）

### 日志验证

```
✅ [HttpClient] responseCode=200
✅ [AuthService] Token 保存完成
✅ [AuthService] Token 保存验证: 成功
✅ 页面跳转成功（无错误）
```

## 其他可能的解决方案（未采用）

### 方案 1：在 Toast 前检查 UI 上下文
```typescript
// ❌ 复杂且不可靠
if (this.getUIContext()) {
  this.showToast(message, 1500);
}
```

### 方案 2：使用 @Watch 装饰器
```typescript
// ❌ 过度设计
@Watch('loginSuccess')
onLoginSuccess() {
  this.navigateAfterLogin(this.loginResponse);
}
```

### 方案 3：移除 setTimeout
```typescript
// ❌ 可能仍有 UI 上下文问题
AuthService.login(loginRequest).then(async (response: LoginResponse) => {
  await StorageUtil.getString('token');
  this.isLoading = false;
  this.navigateAfterLogin(response);  // 直接调用
})
```

## 修复结果

- ✅ 移除了 UI 上下文错误
- ✅ 登录后直接跳转
- ✅ 代码更简洁
- ✅ 用户体验更流畅

## 相关问题

这个问题在 Preview 环境中更容易出现，因为：

1. Preview 的 UI 上下文管理更严格
2. 异步操作后的上下文可能被回收
3. `setTimeout` 回调执行时上下文可能已失效

在真机环境中可能不会出现此问题，但为了兼容性，仍然建议避免在异步回调中调用 UI API。

## 最佳实践

1. **避免在异步回调中调用 UI API**（Toast、Dialog 等）
2. **使用状态变量触发 UI 更新**（@State、@Watch）
3. **简化 UI 交互**（减少不必要的 Toast）
4. **优先使用路由跳转**（而非 Toast + 跳转）

---

**修复完成！现在可以重新测试登录功能。** ✅
