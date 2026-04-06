# Token 存储测试指南

## 测试目标

验证 Token 持久化存储是否正常工作，确保用户登录后可以成功选择角色。

## 测试步骤

### 1. 重新编译应用

在 DevEco Studio 中：
1. 点击 `Build` -> `Clean Project`
2. 点击 `Build` -> `Rebuild Project`
3. 等待编译完成

### 2. 运行应用

1. 点击 `Run` 按钮或按 `Shift+F10`
2. 选择预览器或模拟器

### 3. 测试登录流程

#### 步骤 1：打开应用
- 应用启动后，查看日志输出
- 应该看到：`[StorageUtil] Context 初始化成功`

#### 步骤 2：进入登录页面
- 点击进入登录页面
- 输入测试账号：`13800138001`
- 点击"获取验证码"
- 输入验证码：`123456`（或任意6位数字）

#### 步骤 3：点击登录
- 点击"登录/注册"按钮
- 查看日志输出，应该看到：

```
[AuthService] 开始保存 Token...
[AuthService] Token 保存完成
[AuthService] RefreshToken 保存完成
[AuthService] User 保存完成
[AuthService] Token 保存验证: 成功
[LoginPage] 当前存储模式: PERSISTENT (或 PREFERENCES)
[LoginPage] Token 保存验证: 成功
[LoginPage] Token 二次验证: 成功
```

#### 步骤 4：进入角色选择页面
- 登录成功后，应该自动跳转到角色选择页面
- 查看日志输出，应该看到：

```
[RoleSelectPage] 页面加载，检查 Token...
[RoleSelectPage] 当前存储模式: PERSISTENT (或 PREFERENCES)
[RoleSelectPage] Token 检查: 存在
[RoleSelectPage] Token 值: eyJhbGciOiJIUzI1NiJ9...
```

#### 步骤 5：选择角色
- 点击任意角色（如"弱势群体"）
- 查看日志输出，应该看到：

```
[RoleSelectPage] 用户选择角色: help-seeker
[RoleSelectPage] 当前 Token 状态: 存在
[RoleSelectPage] Token 值: eyJhbGciOiJIUzI1NiJ9...
[RoleSelectPage] 开始调用 API 更新角色...
updateUserRole 被调用, role: help-seeker
当前 Token: eyJhbGciOiJIUzI1NiJ9...
```

#### 步骤 6：验证角色更新成功
- 应该看到成功提示："已选择：弱势群体"
- 自动跳转到对应的主页
- 查看日志输出，应该看到：

```
[RoleSelectPage] 角色更新成功: {...}
角色更新成功，跳转到主页: pages/help-seeker/HelpSeekerHomePage
页面跳转成功
```

## 预期结果

### ✅ 成功标志

1. **存储模式正确**
   - 预览模式：`PERSISTENT`
   - 真机/模拟器：`PREFERENCES`

2. **Token 保存成功**
   - 登录后日志显示：`Token 保存验证: 成功`
   - Token 值不为空

3. **Token 读取成功**
   - 角色选择页面日志显示：`Token 检查: 存在`
   - Token 值与保存的一致

4. **API 调用成功**
   - 更新角色 API 返回 200
   - 没有 401 错误
   - 成功跳转到主页

### ❌ 失败标志

1. **Token 保存失败**
   - 日志显示：`Token 保存验证: 失败`
   - Token 值为空或 null

2. **Token 读取失败**
   - 日志显示：`Token 检查: 不存在`
   - 日志显示：`当前 Token: 不存在`

3. **API 调用失败**
   - HTTP 状态码：401
   - 错误信息：`服务器返回空响应` 或 `Unauthorized`

## 故障排查

### 问题 1：Token 保存失败

**症状**：
```
[AuthService] Token 保存验证: 失败
[LoginPage] Token 保存验证: 失败
```

**解决方案**：
1. 检查 EntryAbility.onCreate() 是否调用了 `StorageUtil.initContext()`
2. 查看存储模式是否正确初始化
3. 检查是否有异常日志

### 问题 2：Token 读取失败

**症状**：
```
[RoleSelectPage] Token 检查: 不存在
[RoleSelectPage] 当前 Token: 不存在
```

**解决方案**：
1. 确认登录时 Token 已保存成功
2. 检查存储键名是否一致（都是 'token'）
3. 查看是否有存储模式切换

### 问题 3：API 调用 401 错误

**症状**：
```
HTTP Response Status: 401
收到空响应
```

**解决方案**：
1. 确认 Token 存在且不为空
2. 检查 API 请求头是否正确添加 Authorization
3. 验证后端服务是否正常运行
4. 检查 Token 格式是否正确（Bearer + Token）

### 问题 4：存储模式为 MEMORY

**症状**：
```
[StorageUtil] 当前存储模式: MEMORY
使用内存存储模式（数据不会持久化）
```

**解决方案**：
1. 这是降级方案，数据不会持久化
2. 检查 Preferences API 初始化是否失败
3. 检查 PersistentStorage 初始化是否失败
4. 查看详细错误日志

## 测试账号

| 手机号 | 密码 | 角色 | 说明 |
|--------|------|------|------|
| 13800138001 | 123456 | help-seeker | 求助者 |
| 13800138004 | 123456 | volunteer | 志愿者 |
| 13800138007 | 123456 | community | 社区管理 |

## 日志关键字

搜索以下关键字快速定位问题：

- `[StorageUtil]` - 存储相关日志
- `[AuthService]` - 认证服务日志
- `[LoginPage]` - 登录页面日志
- `[RoleSelectPage]` - 角色选择页面日志
- `Token 保存` - Token 保存操作
- `Token 检查` - Token 读取操作
- `当前存储模式` - 存储模式信息
- `401` - 认证失败错误

## 成功案例日志示例

```
[StorageUtil] Context 初始化成功
[StorageUtil] Preferences API 初始化成功 - 使用真实持久化存储
[AuthService] 开始保存 Token...
[StorageUtil-PREFERENCES] 开始保存: token
[StorageUtil-PREFERENCES] 保存成功: token
[AuthService] Token 保存完成
[AuthService] Token 保存验证: 成功
[LoginPage] 当前存储模式: PREFERENCES
[LoginPage] Token 保存验证: 成功
[LoginPage] Token 二次验证: 成功
[RoleSelectPage] 页面加载，检查 Token...
[RoleSelectPage] 当前存储模式: PREFERENCES
[RoleSelectPage] Token 检查: 存在
[RoleSelectPage] 用户选择角色: help-seeker
[RoleSelectPage] 当前 Token 状态: 存在
[RoleSelectPage] 开始调用 API 更新角色...
[RoleSelectPage] 角色更新成功
```

## 下一步

如果测试成功：
1. ✅ Token 持久化存储正常工作
2. ✅ 用户可以正常登录和选择角色
3. ✅ 可以继续开发其他功能

如果测试失败：
1. 查看详细日志
2. 根据故障排查指南定位问题
3. 检查相关代码实现
4. 必要时联系开发人员
