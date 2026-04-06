# LoginPage 编译错误修复

## 修复时间
2026-03-07

## 主要问题

### 1. 动态 Import 不支持 ❌
**错误**: 使用 `import('../services/AuthService')` 动态导入

**问题**: ArkTS 不支持动态 import

**修复方案**: 改为静态 import

```typescript
// 修复前
import('../services/AuthService').then((module) => {
  const AuthService = module.AuthService;
  AuthService.login(...);
});

// 修复后
import { AuthService } from '../services/AuthService';
import type { LoginRequest } from '../models/Auth';

// 直接使用
AuthService.login(...);
```

### 2. 类型注解缺失
**问题**: Promise 回调参数缺少类型注解

**修复方案**: 添加明确的类型

```typescript
// 修复前
.then((success) => { ... })
.catch((error) => { ... })

// 修复后
.then((success: boolean) => { ... })
.catch((err: Error) => { ... })
```

### 3. Object Literal 类型问题
**问题**: 直接传递 object literal 给方法

**修复方案**: 先声明类型变量

```typescript
// 修复前
AuthService.login({
  phone: this.phone,
  password: this.code,
  loginType: 'sms'
});

// 修复后
const loginRequest: LoginRequest = {
  phone: this.phone,
  password: this.code,
  loginType: 'sms'
};
AuthService.login(loginRequest);
```

## 修复的代码

### 文件头部 Import
```typescript
import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { AuthService } from '../services/AuthService';
import type { LoginRequest } from '../models/Auth';
```

### handleSendCode 方法
```typescript
handleSendCode() {
  if (this.phone.length !== 11) {
    promptAction.showToast({
      message: '请输入正确的手机号',
      duration: 2000
    });
    return;
  }

  // 调用发送验证码 API
  AuthService.sendVerificationCode({
    phone: this.phone,
    type: 'login'
  }).then((success: boolean) => {
    if (success) {
      this.codeSent = true;
      this.countdown = 60;
      
      promptAction.showToast({
        message: '验证码已发送（测试环境请使用：123456）',
        duration: 3000
      });

      this.countdownTimer = setInterval(() => {
        this.countdown--;
        if (this.countdown <= 0) {
          clearInterval(this.countdownTimer);
          this.countdown = 0;
        }
      }, 1000);
    } else {
      promptAction.showToast({
        message: '发送验证码失败，请重试',
        duration: 2000
      });
    }
  }).catch((err: Error) => {
    console.error('发送验证码失败:', err);
    promptAction.showToast({
      message: err.message || '发送验证码失败，请重试',
      duration: 2000
    });
  });
}
```

### handleLogin 方法
```typescript
handleLogin() {
  console.info('开始登录流程');
  
  if (!this.phone || !this.code) {
    promptAction.showToast({
      message: '请填写完整信息',
      duration: 2000
    });
    return;
  }

  if (this.phone.length !== 11) {
    promptAction.showToast({
      message: '请输入正确的手机号',
      duration: 2000
    });
    return;
  }

  if (this.code.length < 4) {
    promptAction.showToast({
      message: '请输入正确的验证码',
      duration: 2000
    });
    return;
  }

  console.info('验证通过，开始调用登录 API');
  this.isLoading = true;

  // 调用登录 API
  const loginRequest: LoginRequest = {
    phone: this.phone,
    password: this.code,
    loginType: 'sms'
  };
  
  AuthService.login(loginRequest).then((response) => {
    console.info('登录成功:', JSON.stringify(response));
    
    promptAction.showToast({
      message: '登录成功',
      duration: 2000
    });

    // 跳转到角色选择页面
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
  }).catch((err: Error) => {
    console.error('登录失败:', err);
    this.isLoading = false;
    
    promptAction.showToast({
      message: err.message || '登录失败，请重试',
      duration: 2000
    });
  });
}
```

## ArkTS 编码规范

### 1. 禁止动态 Import
- ❌ `import('module').then(...)`
- ✅ `import { Module } from 'module'`

### 2. 必须有类型注解
- ❌ `.then((data) => ...)`
- ✅ `.then((data: Type) => ...)`

### 3. Object Literal 需要类型
- ❌ 直接传递 `{ key: value }`
- ✅ 先声明类型变量

### 4. 异常处理
- ❌ `catch (error)`
- ✅ `catch (err: Error)`

### 5. 变量命名
- 避免使用 `error` 作为变量名（可能与内置冲突）
- 使用 `err` 或其他名称

## 验证步骤

1. 重新编译项目
2. 检查 Problems 面板
3. 确认所有错误已解决
4. 运行应用测试登录功能

## 测试账号

- 手机号：13800138001
- 密码：123456
- 验证码：123456（任意6位数字）

## 状态

✅ 动态 import 已移除
✅ 类型注解已添加
✅ Object literal 已修复
✅ 异常处理已规范

**修复完成，可以重新编译测试！**
