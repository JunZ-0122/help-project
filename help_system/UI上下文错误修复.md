# UI 上下文错误修复

## 问题描述

### 错误信息
```
Error: Internal error. UI execution context not found.
```

### 发生场景
登录成功后，尝试使用 `router.pushUrl()` 跳转到角色选择页面时出现此错误。

### 日志分析
```
03-07 17:21:37.391   12276-21460   A03d00/JSAPP   I     登录成功: {...}
03-07 17:21:37.391   12276-21460   A03d00/JSAPP   E     登录失败: Error: Internal error. UI execution context not found.
```

可以看到：
1. ✅ 后端 API 调用成功
2. ✅ 返回了正确的用户数据和 Token
3. ❌ 路由跳转失败

## 问题原因

在 ArkTS 中，`router.pushUrl()` 必须在 UI 上下文中执行。当在异步回调（Promise.then）中直接调用路由跳转时，可能会丢失 UI 上下文，导致此错误。

### 错误代码
```typescript
AuthService.login(loginRequest).then((response) => {
  promptAction.showToast({
    message: '登录成功',
    duration: 2000
  });

  // ❌ 直接在 Promise 回调中调用路由跳转
  router.pushUrl({
    url: 'pages/RoleSelectPage',
    params: {
      user: response.user
    }
  });
});
```

## 解决方案

使用 `setTimeout` 将路由跳转延迟到下一个事件循环，确保在正确的 UI 上下文中执行。

### 修复后的代码
```typescript
AuthService.login(loginRequest).then((response) => {
  console.info('登录成功:', JSON.stringify(response));
  
  // 先更新 UI 状态
  this.isLoading = false;
  
  promptAction.showToast({
    message: '登录成功',
    duration: 2000
  });

  // ✅ 使用 setTimeout 确保在 UI 上下文中执行路由跳转
  setTimeout(() => {
    router.pushUrl({
      url: 'pages/RoleSelectPage',
      params: {
        user: response.user
      }
    }).then(() => {
      console.info('页面跳转成功');
    }).catch((err: Error) => {
      console.error('导航失败:', err);
      promptAction.showToast({
        message: '页面跳转失败',
        duration: 2000
      });
    });
  }, 100);
});
```

## 关键点

1. **先更新状态**: 在路由跳转前先更新 `this.isLoading = false`
2. **使用 setTimeout**: 延迟 100ms 执行路由跳转
3. **错误处理**: 为路由跳转添加 catch 处理

## 其他解决方案

### 方案 1: 使用 animateTo
```typescript
animateTo({ duration: 300 }, () => {
  router.pushUrl({
    url: 'pages/RoleSelectPage'
  });
});
```

### 方案 2: 使用 @State 触发
```typescript
@State shouldNavigate: boolean = false;

// 在 Promise 中
this.shouldNavigate = true;

// 在 build() 中监听
if (this.shouldNavigate) {
  router.pushUrl({...});
  this.shouldNavigate = false;
}
```

### 方案 3: 使用 postTask (推荐)
```typescript
import { taskpool } from '@kit.ArkTS';

// 在 Promise 中
taskpool.Task.postTask(() => {
  router.pushUrl({...});
});
```

## 最佳实践

### ArkTS 路由跳转规范
1. **避免在异步回调中直接调用路由**
2. **使用 setTimeout 或 postTask 延迟执行**
3. **始终添加错误处理**
4. **在跳转前更新 UI 状态**

### 示例模板
```typescript
async handleAction() {
  try {
    const result = await someAsyncOperation();
    
    // 更新 UI 状态
    this.isLoading = false;
    
    // 显示提示
    promptAction.showToast({
      message: '操作成功',
      duration: 2000
    });
    
    // 延迟路由跳转
    setTimeout(() => {
      router.pushUrl({
        url: 'pages/TargetPage',
        params: { data: result }
      }).catch((err: Error) => {
        console.error('路由跳转失败:', err);
      });
    }, 100);
  } catch (err) {
    this.isLoading = false;
    promptAction.showToast({
      message: '操作失败',
      duration: 2000
    });
  }
}
```

## 验证结果

修复后，登录流程应该能够正常完成：
1. ✅ 用户输入手机号和验证码
2. ✅ 调用后端登录 API
3. ✅ 接收并保存 Token
4. ✅ 显示"登录成功"提示
5. ✅ 跳转到角色选择页面

## 相关文档

- [HarmonyOS 路由导航](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/arkts-routing-0000001503325125-V3)
- [ArkTS 异步编程](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/arkts-async-0000001524089441-V3)

---

**修复时间**: 2026-03-07
**问题类型**: UI 上下文错误
**解决方案**: 使用 setTimeout 延迟路由跳转
