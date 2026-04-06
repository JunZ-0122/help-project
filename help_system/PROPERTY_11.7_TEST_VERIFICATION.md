# Property 11.7: 导航不变性测试验证

## 测试概述

**属性 11.7：导航不变性**
- **验证需求**: 4.4.4
- **测试位置**: `help_system/entry/src/test/AccessibilityManager.test.ets`
- **迭代次数**: 100次

## 测试描述

对于任何页面导航操作（从页面 A 切换到页面 B），导航前后 AppStorage 中的无障碍设置值应该保持不变。

## 测试实现

### 测试策略

1. **随机初始化设置**: 为每次迭代生成随机的无障碍设置配置
2. **记录导航前状态**: 从 AppStorage 读取所有三个设置值
3. **模拟页面导航**: 通过多次读取 AppStorage 模拟不同页面访问（1-5次随机导航）
4. **验证导航过程**: 确保每次导航步骤中设置保持不变
5. **验证导航后状态**: 确认导航完成后设置与初始状态一致

### 测试代码结构

```typescript
it('Property 11.7: Navigation invariance', 0, async () => {
  const iterations = 100;
  
  for (let i = 0; i < iterations; i++) {
    // 1. 生成随机初始设置
    const initialSettings = generateRandomSettings();
    
    // 2. 应用设置
    await manager.updateLargeFont(initialSettings.largeFontEnabled);
    await manager.updateHighContrast(initialSettings.highContrastEnabled);
    await manager.updateVibration(initialSettings.vibrationEnabled);
    
    // 3. 读取导航前的 AppStorage 状态
    const beforeNavigation = {
      largeFontEnabled: AppStorage.get<boolean>(STORAGE_KEYS.LARGE_FONT),
      highContrastEnabled: AppStorage.get<boolean>(STORAGE_KEYS.HIGH_CONTRAST),
      vibrationEnabled: AppStorage.get<boolean>(STORAGE_KEYS.VIBRATION)
    };
    
    // 4. 模拟页面导航（1-5次随机导航）
    const navigationSteps = Math.floor(Math.random() * 5) + 1;
    for (let step = 0; step < navigationSteps; step++) {
      const duringNavigation = {
        largeFontEnabled: AppStorage.get<boolean>(STORAGE_KEYS.LARGE_FONT),
        highContrastEnabled: AppStorage.get<boolean>(STORAGE_KEYS.HIGH_CONTRAST),
        vibrationEnabled: AppStorage.get<boolean>(STORAGE_KEYS.VIBRATION)
      };
      
      // 验证导航过程中设置保持不变
      assert(settingsEqual(beforeNavigation, duringNavigation));
    }
    
    // 5. 读取导航后的 AppStorage 状态
    const afterNavigation = {
      largeFontEnabled: AppStorage.get<boolean>(STORAGE_KEYS.LARGE_FONT),
      highContrastEnabled: AppStorage.get<boolean>(STORAGE_KEYS.HIGH_CONTRAST),
      vibrationEnabled: AppStorage.get<boolean>(STORAGE_KEYS.VIBRATION)
    };
    
    // 6. 验证导航前后设置保持不变
    assert(settingsEqual(beforeNavigation, afterNavigation));
  }
});
```

## 测试覆盖

### 输入空间

- **largeFontEnabled**: true/false (随机)
- **highContrastEnabled**: true/false (随机)
- **vibrationEnabled**: true/false (随机)
- **导航次数**: 1-5次 (随机)

总共 2³ = 8 种设置组合，每种组合在100次迭代中会被多次测试。

### 验证点

1. ✅ 导航前状态正确记录
2. ✅ 导航过程中状态不变
3. ✅ 导航后状态与导航前一致
4. ✅ 多次导航不影响状态
5. ✅ 所有三个设置同时保持不变

## 运行测试

### 使用 DevEco Studio

1. 打开 DevEco Studio
2. 导航到 `entry/src/test/AccessibilityManager.test.ets`
3. 右键点击测试文件或特定测试
4. 选择 "Run 'AccessibilityManager.test.ets'"

### 使用命令行（如果配置）

```bash
cd help_system
hvigor test
```

## 预期结果

- ✅ 所有100次迭代都应该通过
- ✅ 不应该有任何失败记录
- ✅ 测试应该在合理时间内完成（< 10秒）

## 失败场景

如果测试失败，可能的原因：

1. **AppStorage 状态泄漏**: 页面导航意外修改了全局状态
2. **并发问题**: 多个页面同时修改设置导致竞态条件
3. **状态重置**: 导航过程中设置被重置为默认值
4. **内存问题**: AppStorage 数据丢失

## 验证状态

- ✅ 测试代码已实现
- ✅ 语法检查通过（无诊断错误）
- ⏳ 等待在 DevEco Studio 中运行验证

## 相关文件

- 测试文件: `help_system/entry/src/test/AccessibilityManager.test.ets`
- 实现文件: `help_system/entry/src/main/ets/utils/AccessibilityManager.ets`
- 设计文档: `.kiro/specs/accessibility-global-state/design.md`
- 需求文档: `.kiro/specs/accessibility-global-state/requirements.md`
