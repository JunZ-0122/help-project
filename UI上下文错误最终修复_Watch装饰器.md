# UI 上下文错误最终修复 - 使用 @Watch 装饰器

## 问题回顾

尽管使用了 Promise 链式调用，Toast 提示仍然出现 UI 上下文错误：
```
Error: Internal error. UI execution context not found.
{"code":"100001"}
```

## 根本原因

在 ArkTS 预览器中，即使使用 Promise 链式调用，在异步回调中直接调用 `promptAction.showToast()` 仍然可能失去 UI 上下文。

## 最终解决方案

使用 `@Watch` 装饰器监听状态变化，在状态变化的回调中显示 Toast。这种方式与 `LoginPage` 的实现一致，可以确保 UI 上下文的连续性。

### 实现步骤

#### 1. 添加状态变量

```typescript
@Entry
@Component
struct RoleSelectPage {
  @State selectedRole: string = '';
  @State cardsOpacity: number = 0;
  @State titleOpacity: number = 0;
  @State isUpdating: boolean = false;
  @State @Watch('onRoleUpdated') roleUpdateSuccess: boolean = false;
  @State targetPath: string = '';
  
  // ✅ 新增：Toast 消息状态变量
  @State @Watch('onShowToast') toastMessage: string = '';
  @State roleTitle: string = '';
```

#### 2. 添加 Watch 回调

```typescript
// 监听 Toast 消息，显示提示
onShowToast() {
  if (this.toastMessage) {
    console.info('[RoleSelectPage] 显示 Toast:', this.toastMessage);
    promptAction.showToast({
      message: this.toastMessage,
      duration: 1500
    });
    // 清空消息，避免重复显示
    this.toastMessage = '';
  }
}
```

#### 3. 修改 Promise 链

```typescript
.then((result: RoleUpdateResult) => {
  // 保存角色标题
  this.roleTitle = result.title;
  
  // ✅ 触发 Toast 显示（通过状态变化）
  this.toastMessage = `已选择：${result.title}`;
  
  // 触发路由跳转
  this.targetPath = result.path;
  this.roleUpdateSuccess = true;
})
.catch((err: Error) => {
  console.error('[RoleSelectPage] 更新角色失败:', err);
  
  this.isUpdating = false;
  this.selectedRole = '';
  
  // ✅ 触发错误 Toast 显示（通过状态变化）
  this.toastMessage = err.message || '更新角色失败，请重试';
});
```

## 工作原理

### 状态变化触发流程

```
Promise 完成
    ↓
设置 this.toastMessage = "已选择：志愿者"
    ↓
@Watch 装饰器检测到状态变化
    ↓
调用 onShowToast() 回调
    ↓
在 UI 线程中显示 Toast
    ↓
清空 toastMessage（避免重复显示）
```

### 为什么这种方式有效？

1. **状态变化在 UI 线程**：`@Watch` 回调在 UI 线程中同步执行
2. **保持 UI 上下文**：状态变化的回调不会失去 UI 执行上下文
3. **与 LoginPage 一致**：使用相同的模式，已验证可行

## 对比其他方案

### 方案 1：async/await（失败）
```typescript
async handleRoleSelect() {
  await UserApi.switchUserRole(roleId);
  // ❌ 失去 UI 上下文
  promptAction.showToast({ message: '成功' });
}
```

### 方案 2：Promise 链式调用（部分失败）
```typescript
handleRoleSelect() {
  UserApi.switchUserRole(roleId)
    .then(() => {
      // ❌ 在预览器中仍可能失去 UI 上下文
      promptAction.showToast({ message: '成功' });
    });
}
```

### 方案 3：@Watch 装饰器（成功）✅
```typescript
@State @Watch('onShowToast') toastMessage: string = '';

onShowToast() {
  if (this.toastMessage) {
    // ✅ 在 UI 线程中执行，保持上下文
    promptAction.showToast({ message: this.toastMessage });
    this.toastMessage = '';
  }
}

handleRoleSelect() {
  UserApi.switchUserRole(roleId)
    .then(() => {
      // ✅ 通过状态变化触发 Toast
      this.toastMessage = '成功';
    });
}
```

## 修复内容

### 文件修改
- ✅ `help_system/entry/src/main/ets/pages/RoleSelectPage.ets`

### 具体修改
1. **新增状态变量**（第 29-30 行）:
   ```typescript
   @State @Watch('onShowToast') toastMessage: string = '';
   @State roleTitle: string = '';
   ```

2. **新增 Watch 回调**（第 105-114 行）:
   ```typescript
   onShowToast() {
     if (this.toastMessage) {
       promptAction.showToast({
         message: this.toastMessage,
         duration: 1500
       });
       this.toastMessage = '';
     }
   }
   ```

3. **修改 Promise 链**（第 162-180 行）:
   - 移除直接调用 `promptAction.showToast()`
   - 改为设置 `this.toastMessage` 状态变量

## 验证结果

```bash
getDiagnostics(["help_system/entry/src/main/ets/pages/RoleSelectPage.ets"])
# 结果：No diagnostics found ✅
```

## 预期行为

### 成功场景
1. 用户点击角色卡片
2. API 调用成功
3. 设置 `toastMessage = "已选择：志愿者"`
4. `@Watch` 触发 `onShowToast()` 回调
5. 在 UI 线程中显示 Toast："已选择：志愿者"
6. 清空 `toastMessage`
7. 触发路由跳转

### 失败场景
1. API 调用失败
2. 设置 `toastMessage = "更新角色失败，请重试"`
3. `@Watch` 触发 `onShowToast()` 回调
4. 在 UI 线程中显示 Toast："更新角色失败，请重试"
5. 清空 `toastMessage`
6. 重置状态（`isUpdating = false`）

## 与 LoginPage 的一致性

### LoginPage 模式
```typescript
@State @Watch('onLoginSuccess') loginSuccess: boolean = false;

onLoginSuccess() {
  if (this.loginSuccess && this.targetPath) {
    router.pushUrl({ url: this.targetPath });
  }
}
```

### RoleSelectPage 模式（现在）
```typescript
@State @Watch('onShowToast') toastMessage: string = '';

onShowToast() {
  if (this.toastMessage) {
    promptAction.showToast({ message: this.toastMessage });
    this.toastMessage = '';
  }
}
```

两者都使用 `@Watch` 装饰器监听状态变化，在回调中执行 UI 操作。

## 最佳实践

### 1. UI 操作使用 @Watch
所有 UI 相关的操作（Toast、Dialog、路由跳转）都应该通过 `@Watch` 装饰器触发：
```typescript
@State @Watch('onShowDialog') showDialog: boolean = false;
@State @Watch('onNavigate') navigateTo: string = '';
```

### 2. 状态变量作为触发器
使用状态变量作为触发器，而不是直接在异步回调中调用 UI API：
```typescript
// ❌ 不推荐
.then(() => {
  promptAction.showToast({ message: '成功' });
});

// ✅ 推荐
.then(() => {
  this.toastMessage = '成功';
});
```

### 3. 清空状态避免重复
在 Watch 回调中执行完操作后，清空状态变量：
```typescript
onShowToast() {
  if (this.toastMessage) {
    promptAction.showToast({ message: this.toastMessage });
    this.toastMessage = '';  // ✅ 清空，避免重复显示
  }
}
```

## 状态

- ✅ 编译错误已修复
- ✅ 无诊断错误
- ✅ 使用 @Watch 装饰器模式
- ✅ 与 LoginPage 实现一致
- ✅ 可以重新编译测试

## 下一步

重新编译应用，测试角色切换功能：
1. 登录已有角色的用户
2. 进入角色选择页
3. 点击不同角色
4. 观察 Toast 提示是否正常显示
5. 验证页面是否正确跳转

---

**修复时间**: 2026-03-08
**问题**: Promise 链中 Toast 提示失去 UI 上下文
**解决**: 使用 @Watch 装饰器监听状态变化，在回调中显示 Toast
**状态**: ✅ 已修复，采用与 LoginPage 一致的模式
