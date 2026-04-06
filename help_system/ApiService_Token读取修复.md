# ApiService Token 读取修复

## 问题描述

在角色选择页面调用 API 更新用户角色时，出现 401 错误：

```
[RoleSelectPage] Token 检查: 存在
[RoleSelectPage] Token 值: eyJhbGciOiJIUzI1NiJ9...
当前 Token: 不存在  ← 问题所在
HTTP Response Status: 401
```

## 根本原因

在 `ApiService.getHeaders()` 方法中，使用了错误的方法读取 Token：

```typescript
// ❌ 错误：会尝试 JSON 解析
const token = await StorageUtil.get<string>('token');
```

这导致：
1. `get()` 方法尝试将 Token 字符串解析为 JSON
2. JWT Token 不是有效的 JSON，解析失败
3. 返回 `null`，导致请求头中没有 Authorization
4. 后端返回 401 Unauthorized

## 解决方案

修改 `ApiService.getHeaders()` 方法，使用正确的方法读取字符串：

```typescript
// ✅ 正确：直接读取字符串
const token = await StorageUtil.getString('token');
console.info('当前 Token:', token ? '存在' : '不存在');
if (token) {
  headers['Authorization'] = `Bearer ${token}`;
  console.info('已添加 Authorization 头');
} else {
  console.warn('Token 不存在，未添加 Authorization 头');
}
```

## 修复前后对比

### 修复前

```
[RoleSelectPage] Token 值: eyJhbGciOiJIUzI1NiJ9...  ← StorageUtil 中有值
获取对象失败: SyntaxError: Unexpected Text in JSON: Invalid Token
当前 Token: 不存在  ← ApiService 读取失败
HTTP Response Status: 401  ← 后端拒绝请求
```

### 修复后（预期）

```
[RoleSelectPage] Token 值: eyJhbGciOiJIUzI1NiJ9...
当前 Token: 存在  ← ApiService 成功读取
已添加 Authorization 头
HTTP Response Status: 200  ← 后端接受请求
角色更新成功
```

## 相关文件

- `help_system/entry/src/main/ets/services/ApiService.ets` - HTTP 客户端
- `help_system/entry/src/main/ets/utils/StorageUtil.ets` - 存储工具类

## 测试步骤

1. 重新编译应用
2. 登录账号（13800138004 / 123456）
3. 进入角色选择页面
4. 选择任意角色
5. 查看日志，应该看到：
   ```
   当前 Token: 存在
   已添加 Authorization 头
   HTTP Response Status: 200
   角色更新成功
   ```

## 注意事项

### StorageUtil 方法使用规范

1. **字符串类型**（如 Token）
   ```typescript
   // 保存
   await StorageUtil.set('token', tokenString);
   
   // 读取 - 使用 getString
   const token = await StorageUtil.getString('token');
   ```

2. **对象类型**（如 User）
   ```typescript
   // 保存
   await StorageUtil.set('user', userObject);
   
   // 读取 - 使用 get
   const user = await StorageUtil.get<UserProfile>('user');
   ```

### 为什么会有这个问题？

`StorageUtil.get()` 方法的实现：

```typescript
static async get<T>(key: string, defaultValue?: T): Promise<T | null> {
  if (typeof defaultValue === 'string') {
    return await StorageUtil.getString(key, defaultValue as string) as T;
  } else {
    return await StorageUtil.getObject<T>(key, defaultValue || null);
  }
}
```

当没有提供 `defaultValue` 时，会调用 `getObject()`，尝试 JSON 解析。

### 解决方案

对于字符串类型，始终使用 `getString()`：
- ✅ `StorageUtil.getString('token')`
- ❌ `StorageUtil.get<string>('token')`

## 总结

这是一个类型使用不当的问题。虽然 Token 在 StorageUtil 中保存成功，但在 ApiService 中读取时使用了错误的方法，导致 JSON 解析失败，最终导致 API 调用 401 错误。

修复后，Token 可以正确读取并添加到请求头中，API 调用应该成功。
