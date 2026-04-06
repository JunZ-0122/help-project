# Token 持久化存储解决方案

## 问题描述

用户登录后，Token 没有被正确保存，导致在角色选择页面调用 API 时出现 401 错误（Token 不存在）。

## 根本原因

StorageUtil 之前使用的是 TODO 占位代码，没有真正实现数据持久化。虽然后来添加了 HarmonyOS Preferences API，但在预览模式下可能无法正常工作。

## 解决方案

### 三层存储策略

实现了三种存储模式，按优先级自动降级：

1. **Preferences API（生产环境）**
   - 使用 HarmonyOS 官方 Preferences API
   - 真实持久化存储，数据保存在应用沙箱
   - 适用于真机和模拟器

2. **PersistentStorage（预览模式）**
   - 使用 ArkUI 的 PersistentStorage
   - 数据持久化到应用存储
   - 适用于 DevEco Studio 预览模式

3. **Memory Storage（降级方案）**
   - 使用内存 Map 存储
   - 仅在内存中，应用重启后丢失
   - 最后的降级方案

### 核心实现

```typescript
enum StorageMode {
  PREFERENCES = 'PREFERENCES',      // Preferences API
  PERSISTENT = 'PERSISTENT',        // PersistentStorage
  MEMORY = 'MEMORY'                 // Memory Storage
}

export class StorageUtil {
  private static currentMode: StorageMode = StorageMode.MEMORY;
  
  // 初始化时自动选择最佳存储模式
  static initContext(ctx: common.UIAbilityContext): void {
    StorageUtil.context = ctx;
    StorageUtil.initPreferences(); // 尝试初始化 Preferences
  }
  
  // 保存数据时根据当前模式选择存储方式
  static async saveString(key: string, value: string): Promise<boolean> {
    if (StorageUtil.currentMode === StorageMode.PERSISTENT) {
      AppStorage.setOrCreate(key, value); // 使用 PersistentStorage
    } else {
      const prefs = await StorageUtil.getPreferences();
      await prefs.put(key, value);
      await prefs.flush();
    }
  }
}
```

### 初始化流程

1. **EntryAbility.onCreate()**
   ```typescript
   StorageUtil.initContext(this.context);
   ```

2. **StorageUtil 自动检测**
   - 尝试初始化 Preferences API
   - 失败则降级到 PersistentStorage
   - 再失败则使用 Memory Storage

3. **运行时自适应**
   - 每次操作时检查当前模式
   - 使用对应的存储方式

## 增强的日志系统

为了便于调试，添加了详细的日志：

### StorageUtil 日志
```
[StorageUtil-PREFERENCES] 保存成功: token
[StorageUtil-PERSISTENT] 读取结果: token = 有值
[StorageUtil-MEMORY] 删除: token
```

### AuthService 日志
```
[AuthService] 开始保存 Token...
[AuthService] Token 保存完成
[AuthService] Token 保存验证: 成功
```

### LoginPage 日志
```
[LoginPage] 当前存储模式: PERSISTENT
[LoginPage] Token 保存验证: 成功
[LoginPage] Token 二次验证: 成功
```

### RoleSelectPage 日志
```
[RoleSelectPage] 页面加载，检查 Token...
[RoleSelectPage] 当前存储模式: PERSISTENT
[RoleSelectPage] Token 检查: 存在
[RoleSelectPage] 当前 Token 状态: 存在
```

## 使用方法

### 1. 保存 Token
```typescript
await StorageUtil.set('token', tokenValue);
```

### 2. 读取 Token
```typescript
const token = await StorageUtil.get<string>('token');
```

### 3. 检查存储模式
```typescript
const mode = StorageUtil.getStorageMode();
console.info('当前存储模式:', mode);
```

## 测试验证

### 预览模式测试
1. 在 DevEco Studio 中运行预览
2. 查看日志确认存储模式（应该是 PERSISTENT）
3. 登录后检查 Token 是否保存成功
4. 选择角色时检查 Token 是否存在

### 真机/模拟器测试
1. 编译并安装到设备
2. 查看日志确认存储模式（应该是 PREFERENCES）
3. 登录后退出应用
4. 重新打开应用，检查 Token 是否仍然存在

## 优势

1. **生产就绪**：使用官方 Preferences API，真实持久化
2. **开发友好**：预览模式下使用 PersistentStorage，无需真机
3. **容错性强**：三层降级策略，确保应用不会崩溃
4. **易于调试**：详细的日志输出，快速定位问题
5. **向后兼容**：保留了旧的 API（set/get），无需修改现有代码

## 注意事项

1. **Context 初始化**：必须在 EntryAbility.onCreate() 中调用 initContext()
2. **异步操作**：所有存储操作都是异步的，需要使用 await
3. **日志监控**：通过日志确认当前使用的存储模式
4. **数据迁移**：从 Memory 模式切换到 Persistent/Preferences 时，数据不会自动迁移

## 相关文件

- `help_system/entry/src/main/ets/utils/StorageUtil.ets` - 存储工具类
- `help_system/entry/src/main/ets/entryability/EntryAbility.ets` - Context 初始化
- `help_system/entry/src/main/ets/services/AuthService.ets` - Token 保存逻辑
- `help_system/entry/src/main/ets/pages/LoginPage.ets` - 登录页面
- `help_system/entry/src/main/ets/pages/RoleSelectPage.ets` - 角色选择页面

## 下一步

1. 测试预览模式下的 Token 持久化
2. 测试真机/模拟器下的 Token 持久化
3. 验证角色选择 API 调用成功
4. 确认应用重启后 Token 仍然存在
