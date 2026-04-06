# UI 上下文错误修复 - 角色选择页导航

更新时间：2026-03-14 09:20

## 问题描述

角色切换 API 调用成功，用户信息保存成功，但导航失败：

```
[RoleSelect] Error: Error: Internal error. UI execution context not found.
```

## 问题根因

在预览器环境中，使用 `setTimeout` 延迟执行 `router.replaceUrl()` 时，UI 上下文可能已经丢失，导致路由跳转失败。

这是 HarmonyOS 预览器的已知限制：异步回调（如 setTimeout）中访问 UI 相关 API 可能会失败。

## 解决方案

### 修改内容

移除 `setTimeout` 延迟，直接在 async 函数的 try 块中执行导航：

```typescript
// 修改前：使用 setTimeout（会导致 UI 上下文丢失）
this.showToast(`已选择：${role.title}`);
setTimeout(() => {
  router.replaceUrl({ url: role.path })
    .then(() => console.log('Navigation successful'))
    .catch((err) => console.error('Navigation failed:', err));
}, 500);

// 修改后：直接执行导航（保持 UI 上下文）
this.showToast(`已选择：${role.title}`);
console.log('[RoleSelect] Navigating to:', role.path);
await router.replaceUrl({ url: role.path });
console.log('[RoleSelect] Navigation successful');
```

### 改进的错误处理

```typescript
catch (err) {
  const error = err as Error;
  console.error('[RoleSelect] Error:', error);
  
  // 区分导航错误和 API 错误
  if (error.message && error.message.includes('UI execution context')) {
    this.showToast('页面跳转失败，请重试');
  } else {
    this.showToast(error.message || '角色更新失败');
  }
  
  this.selectedRole = '';
}
```

## 测试步骤

### 1. 重新编译

**必须重新编译才能生效！**

在 DevEco Studio 中：
1. `Build` → `Clean Project`
2. `Build` → `Rebuild Project`
3. 重启预览器

或使用命令行：
```powershell
cd help_system
.\rebuild.ps1
```

### 2. 测试角色切换

1. 登录应用（13800138002 / 123456）
2. 进入个人中心 → 点击"切换身份"
3. 点击任意角色卡片
4. **预期结果**：
   - 显示 Toast："已选择：XXX"
   - 立即跳转到对应角色主页（无延迟）
   - 不再出现 "UI execution context not found" 错误

### 3. 查看日志

应该看到完整的成功日志：

```
[RoleSelect] Starting role selection: community
[StorageUtil-PERSISTENT] 开始读取: user
[StorageUtil-PERSISTENT] 读取结果: user = 有值
[RoleSelect] Current user: [object Object]
[RoleSelect] Has role: true
[RoleSelect] Switching role to: community
[HttpClient][PUT] url=http://localhost:8080/api/users/me/role/switch
[HttpClient][PUT] body={"role":"community"}
[StorageUtil-PERSISTENT] 开始保存: user
[StorageUtil-PERSISTENT] 保存成功: user
[RoleSelect] User saved to storage
[RoleSelect] Navigating to: pages/community/CommunityHomePage
[RoleSelect] Navigation successful
```

## 技术说明

### 为什么移除 setTimeout？

1. **UI 上下文生命周期**
   - 在 HarmonyOS 中，UI 上下文与组件生命周期绑定
   - 异步回调（setTimeout）执行时，原始 UI 上下文可能已失效

2. **预览器限制**
   - 预览器环境对 UI 上下文管理更严格
   - 真机环境可能不会出现此问题，但为了兼容性应避免

3. **最佳实践**
   - 在 async 函数中直接 await 路由跳转
   - 避免在 setTimeout/setInterval 中调用 UI API
   - 保持 UI 操作在同一个执行上下文中

### Toast 会被跳转打断吗？

不会。`router.replaceUrl()` 是异步操作，Toast 已经在调用前显示，跳转不会影响 Toast 的显示。

### 如果确实需要延迟怎么办？

如果必须延迟（例如等待动画完成），使用 `animateTo` 或其他 UI 相关的延迟机制，而不是 `setTimeout`：

```typescript
// 不推荐
setTimeout(() => router.replaceUrl(...), 500);

// 推荐（如果需要延迟）
animateTo({ duration: 500 }, () => {
  // 动画完成后的回调
});
// 然后在回调中执行导航
```

但对于简单的页面跳转，直接执行是最佳选择。

## 相关问题

这个问题与之前修复的其他 UI 上下文错误类似：

- `LoginPage_UI上下文错误修复.md` - 登录页的类似问题
- `UI上下文错误修复_求助者页面.md` - 求助者页面的类似问题
- `志愿者接单UI上下文错误修复.md` - 志愿者接单的类似问题

**通用规则**：在 HarmonyOS 中，避免在异步回调（setTimeout/Promise.then）中调用 UI API，改用 async/await 保持上下文连续性。

## 验证清单

- [ ] 前端已重新编译（Clean + Rebuild）
- [ ] 预览器已重启
- [ ] 可以成功登录
- [ ] 点击"切换身份"可以跳转到角色选择页
- [ ] 点击角色卡片后显示 Toast
- [ ] 立即跳转到对应角色主页（无延迟）
- [ ] 控制台没有 "UI execution context not found" 错误
- [ ] 控制台显示 "[RoleSelect] Navigation successful"

## 总结

通过移除 `setTimeout` 并直接在 async 函数中 await 路由跳转，解决了预览器环境中的 UI 上下文丢失问题。这是 HarmonyOS 开发的最佳实践，确保 UI 操作在同一个执行上下文中完成。
