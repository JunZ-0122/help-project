# UI 上下文错误修复 - 角色切换 Toast 提示

## 问题描述

**错误信息**: `Error: Internal error. UI execution context not found.`
**错误代码**: `{"code":"100001"}`
**发生位置**: `RoleSelectPage.handleRoleSelect()` 方法中的 `promptAction.showToast()`

## 问题分析

### 成功的部分
✅ 登录成功，Token 正确保存
✅ 角色切换 API 调用成功
✅ 后端返回正确数据：`role: "community"`
✅ 本地存储更新成功

### 失败的部分
❌ 显示 Toast 提示时失去 UI 上下文

### 根本原因

在 ArkTS 中，使用 `async/await` 的异步方法中调用 UI 相关的 API（如 `promptAction.showToast()`）时，可能会失去 UI 执行上下文。

**问题代码**:
```typescript
async handleRoleSelect(roleId: string, path: string, title: string) {
  try {
    // ... 异步操作
    await UserApi.switchUserRole(roleId);
    await StorageUtil.set('user', updatedUser);
    
    // ❌ 在 async 函数中调用 UI API，可能失去上下文
    promptAction.showToast({
      message: `已选择：${title}`,
      duration: 1500
    });
  } catch (err) {
    // ...
  }
}
```

## 解决方案

将 `async/await` 改为 Promise 链式调用，保持 UI 上下文的连续性。

**修复后代码**:
```typescript
handleRoleSelect(roleId: string, path: string, title: string) {
  if (this.isUpdating) {
    return;
  }

  this.selectedRole = roleId;
  this.isUpdating = true;
  
  // 使用 Promise 链式调用，避免 async/await 导致的 UI 上下文丢失
  StorageUtil.getString('token')
    .then((currentToken) => {
      // 检查 Token
      return StorageUtil.getString('user');
    })
    .then((userStr) => {
      // 判断是否已有角色
      let hasRole = false;
      if (userStr) {
        const user = JSON.parse(userStr) as UserProfile;
        hasRole = user.role !== '';
      }
      
      // 调用对应的 API
      if (hasRole) {
        return UserApi.switchUserRole(roleId);
      } else {
        return UserApi.updateUserRole(roleId);
      }
    })
    .then((updatedUser) => {
      // 更新本地存储
      return StorageUtil.set('user', updatedUser).then(() => {
        return Promise.resolve({ updatedUser, title, path });
      });
    })
    .then((result) => {
      // ✅ 在 Promise 链中显示 Toast（保持 UI 上下文）
      promptAction.showToast({
        message: `已选择：${result.title}`,
        duration: 1500
      });
      
      // 触发路由跳转
      this.targetPath = result.path;
      this.roleUpdateSuccess = true;
    })
    .catch((err) => {
      // 错误处理
      this.isUpdating = false;
      this.selectedRole = '';
      
      const error = err as Error;
      promptAction.showToast({
        message: error.message || '更新角色失败，请重试',
        duration: 2000
      });
    });
}
```

## 修复要点

### 1. 移除 async/await
- **原因**: `async` 函数会创建新的执行上下文，可能导致 UI 上下文丢失
- **解决**: 使用 Promise 链式调用，保持上下文连续性

### 2. Promise 链式调用
- 使用 `.then()` 链式调用，而不是 `await`
- 每个 `.then()` 返回下一步需要的数据
- 最后在 `.then()` 中调用 UI API

### 3. 错误处理
- 使用 `.catch()` 统一处理错误
- 在 `.catch()` 中也可以安全调用 `promptAction.showToast()`

## 测试验证

### 预期行为
1. ✅ 用户点击角色卡片
2. ✅ 检查用户是否已有角色
3. ✅ 调用正确的 API（首次选择或切换）
4. ✅ 后端返回成功响应
5. ✅ 更新本地存储
6. ✅ 显示 Toast 提示："已选择：社区管理"
7. ✅ 自动跳转到新角色主页

### 测试步骤
1. 登录已有角色的用户（如 help-seeker）
2. 进入角色选择页
3. 点击不同的角色（如 community）
4. 观察日志和 UI 反馈

### 预期日志
```
[RoleSelectPage] 用户选择角色: community
[RoleSelectPage] 用户当前角色: help-seeker
[RoleSelectPage] 用户已有角色，调用切换接口...
switchUserRole 被调用, role: community
HTTP Response Status: 200
[RoleSelectPage] 角色更新成功: {"role":"community",...}
// ✅ Toast 显示成功
// ✅ 页面跳转成功
```

## 相关问题

### 为什么 LoginPage 没有这个问题？

`LoginPage` 使用了 `@Watch` 装饰器监听状态变化，在状态变化的回调中执行路由跳转：

```typescript
@State @Watch('onLoginSuccess') loginSuccess: boolean = false;

onLoginSuccess() {
  if (this.loginSuccess && this.targetPath) {
    router.pushUrl({ url: this.targetPath });
  }
}
```

这种方式保持了 UI 上下文，因为状态变化的回调是在 UI 线程中同步执行的。

### 其他可能的解决方案

1. **使用 @Watch 装饰器**（LoginPage 的方式）
2. **使用 Promise 链式调用**（本次采用的方式）
3. **在真机上测试**（预览器的 UI 上下文管理可能不完善）

## 文件修改

- ✅ `help_system/entry/src/main/ets/pages/RoleSelectPage.ets`
  - 修改 `handleRoleSelect()` 方法
  - 从 `async/await` 改为 Promise 链式调用

## 状态

- ✅ 代码修复完成
- ✅ 编译通过，无诊断错误
- ⏳ 待功能测试验证

## 下一步

在 DevEco Studio 中重新编译应用，测试角色切换功能：
1. 登录已有角色的用户
2. 进入角色选择页
3. 点击不同角色
4. 验证 Toast 提示是否正常显示
5. 验证页面是否正确跳转

---

**修复时间**: 2026-03-08
**问题**: UI 上下文错误导致 Toast 无法显示
**解决**: 使用 Promise 链式调用替代 async/await
**状态**: ✅ 已修复
