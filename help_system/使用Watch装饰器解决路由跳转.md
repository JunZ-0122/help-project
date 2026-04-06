# 使用 @Watch 装饰器解决路由跳转问题

## 解决方案

使用 ArkTS 的 `@Watch` 装饰器来监听状态变化，在状态变化的回调中执行路由跳转。这样可以确保路由跳转在正确的 UI 上下文中执行。

## 实现原理

### 1. 定义状态变量
```typescript
@State @Watch('onLoginSuccess') loginSuccessful: boolean = false;
@State loginUserData: LoginResponse | null = null;
```

- `@State`: 使变量成为响应式状态
- `@Watch('onLoginSuccess')`: 当状态变化时，自动调用 `onLoginSuccess` 方法
- `loginUserData`: 保存登录响应数据

### 2. 定义监听回调
```typescript
onLoginSuccess() {
  if (this.loginSuccessful && this.loginUserData) {
    console.info('检测到登录成功，准备跳转到角色选择页');
    
    // 显示成功提示
    promptAction.showToast({
      message: '登录成功',
      duration: 2000
    });
    
    // 执行路由跳转
    router.pushUrl({
      url: 'pages/RoleSelectPage',
      params: {
        user: this.loginUserData.user
      }
    });
  }
}
```

### 3. 在 Promise 回调中触发状态变化
```typescript
AuthService.login(loginRequest).then((response) => {
  console.info('登录成功:', JSON.stringify(response));
  
  this.isLoading = false;
  
  // 保存数据并触发状态变化
  this.loginUserData = response;
  this.loginSuccessful = true; // 触发 @Watch 回调
});
```

## 工作流程

```
1. 用户点击登录按钮
   ↓
2. 调用 AuthService.login()
   ↓
3. Promise 回调中：
   - 保存 loginUserData
   - 设置 loginSuccessful = true
   ↓
4. @Watch 装饰器检测到状态变化
   ↓
5. 自动调用 onLoginSuccess() 方法
   ↓
6. 在 onLoginSuccess() 中：
   - 显示 Toast 提示
   - 执行路由跳转
   ↓
7. 跳转到角色选择页
```

## 为什么这个方案有效？

### 问题根源
Promise 回调可能不在 UI 线程中执行，导致：
- `router.pushUrl()` 失败 → UI execution context not found
- `promptAction.showToast()` 失败 → UI execution context not found

### 解决原理
`@Watch` 装饰器的回调函数是由 ArkUI 框架调用的，**保证在 UI 上下文中执行**：

1. **状态变化检测**: ArkUI 框架监听 `@State` 变量的变化
2. **UI 线程调度**: 框架在 UI 线程中调用 `@Watch` 回调
3. **上下文保证**: 回调函数在正确的 UI 上下文中执行

## 优势

### ✅ 可靠性
- 由 ArkUI 框架保证在 UI 上下文中执行
- 不依赖 setTimeout 等不可靠的方法

### ✅ 简洁性
- 代码结构清晰
- 符合 ArkTS 的响应式编程模式

### ✅ 可维护性
- 状态管理和 UI 操作分离
- 易于理解和调试

### ✅ 可扩展性
- 可以轻松添加更多的状态监听
- 可以在回调中执行其他 UI 操作

## 完整代码示例

```typescript
import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { AuthService } from '../services/AuthService';
import type { LoginRequest, LoginResponse } from '../models/Auth';

@Entry
@Component
struct LoginPage {
  // 状态变量
  @State @Watch('onLoginSuccess') loginSuccessful: boolean = false;
  @State loginUserData: LoginResponse | null = null;
  @State isLoading: boolean = false;

  // 监听登录成功状态
  onLoginSuccess() {
    if (this.loginSuccessful && this.loginUserData) {
      console.info('检测到登录成功，准备跳转');
      
      promptAction.showToast({
        message: '登录成功',
        duration: 2000
      });
      
      router.pushUrl({
        url: 'pages/RoleSelectPage',
        params: {
          user: this.loginUserData.user
        }
      }).then(() => {
        console.info('页面跳转成功');
      }).catch((err: Error) => {
        console.error('导航失败:', err);
      });
    }
  }

  // 登录处理
  handleLogin() {
    this.isLoading = true;
    
    const loginRequest: LoginRequest = {
      phone: this.phone,
      password: this.code,
      loginType: 'sms'
    };
    
    AuthService.login(loginRequest).then((response) => {
      console.info('登录成功');
      this.isLoading = false;
      
      // 触发状态变化
      this.loginUserData = response;
      this.loginSuccessful = true; // 触发 @Watch
    }).catch((err: Error) => {
      console.error('登录失败:', err);
      this.isLoading = false;
      
      promptAction.showToast({
        message: err.message || '登录失败',
        duration: 2000
      });
    });
  }

  build() {
    // UI 代码...
  }
}
```

## 其他应用场景

这个模式可以用于任何需要在异步操作后执行 UI 操作的场景：

### 1. 数据加载后显示弹窗
```typescript
@State @Watch('onDataLoaded') dataReady: boolean = false;

onDataLoaded() {
  if (this.dataReady) {
    AlertDialog.show({
      title: '数据加载完成',
      message: '共加载了 100 条数据'
    });
  }
}
```

### 2. 操作成功后刷新列表
```typescript
@State @Watch('onOperationSuccess') operationDone: boolean = false;

onOperationSuccess() {
  if (this.operationDone) {
    this.refreshList();
    this.operationDone = false; // 重置状态
  }
}
```

### 3. 错误处理
```typescript
@State @Watch('onError') hasError: boolean = false;
@State errorMessage: string = '';

onError() {
  if (this.hasError) {
    promptAction.showToast({
      message: this.errorMessage,
      duration: 2000
    });
    this.hasError = false; // 重置状态
  }
}
```

## 注意事项

### 1. 避免无限循环
```typescript
// ❌ 错误：在 @Watch 回调中修改被监听的状态
onLoginSuccess() {
  this.loginSuccessful = false; // 会再次触发回调
  this.loginSuccessful = true;  // 无限循环！
}

// ✅ 正确：只在需要时重置状态
onLoginSuccess() {
  if (this.loginSuccessful) {
    // 执行操作
    router.pushUrl({...});
    // 如果需要重置，确保不会再次触发
  }
}
```

### 2. 检查状态有效性
```typescript
onLoginSuccess() {
  // 始终检查状态是否有效
  if (this.loginSuccessful && this.loginUserData) {
    // 执行操作
  }
}
```

### 3. 处理异常
```typescript
onLoginSuccess() {
  if (this.loginSuccessful && this.loginUserData) {
    router.pushUrl({...})
      .then(() => {
        console.info('跳转成功');
      })
      .catch((err: Error) => {
        console.error('跳转失败:', err);
        // 显示错误提示
      });
  }
}
```

## 对比其他方案

### setTimeout 方案
```typescript
// ❌ 不可靠
setTimeout(() => {
  router.pushUrl({...}); // 可能仍然失败
}, 100);
```

### @Watch 方案
```typescript
// ✅ 可靠
@State @Watch('onSuccess') success: boolean = false;

onSuccess() {
  router.pushUrl({...}); // 保证在 UI 上下文中
}
```

## 总结

使用 `@Watch` 装饰器是解决 HarmonyOS 异步操作后 UI 上下文问题的**最佳实践**：

1. ✅ 由框架保证在 UI 上下文中执行
2. ✅ 代码清晰，易于维护
3. ✅ 符合 ArkTS 响应式编程模式
4. ✅ 可靠性高，不依赖 hack 方法

---

**创建时间**: 2026-03-07
**状态**: 推荐方案
**适用场景**: 所有需要在异步操作后执行 UI 操作的场景
