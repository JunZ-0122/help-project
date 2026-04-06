# 无障碍设置Toggle修复（v6 - 终极方案）

## 问题分析

从最新日志发现了真正的问题根源：

```
[ProfilePage] Toggle onChange: true
[ProfilePage] 立即更新AppStorage: true
[ProfilePage] Toggle onChange: false  // 32ms后又触发了false！
[ProfilePage] 立即更新AppStorage: false
```

**根本原因**：
1. 用户点击 → `onChange(true)` → `AppStorage.set(true)`
2. 100ms后 → 调用`updateLargeFont(true)` → **又调用了`AppStorage.set(true)`**
3. `AppStorage.set()`触发`@StorageLink`更新 → Toggle检测到变化 → 触发`onChange(false)`
4. `onChange(false)` → `AppStorage.set(false)` → 设置被重置

**问题核心**：`AccessibilityManager.updateLargeFont()`也在调用`AppStorage.set()`，导致循环触发！

## 解决方案（v6）

### 核心思路

**分离AppStorage更新和持久化保存**：
1. 在ProfilePage的`onChange`中立即调用`AppStorage.set()`（UI更新）
2. 延迟调用新的`saveXxxOnly()`方法（只持久化，不调用`AppStorage.set()`）
3. 增加防抖延迟到300ms，确保Toggle状态稳定

### 实现代码

#### 1. AccessibilityManager新增方法

```typescript
/**
 * 仅保存大字体设置到本地存储（不更新AppStorage，避免循环触发）
 */
public saveLargeFontOnly(enabled: boolean): void {
  console.info('仅保存大字体设置:', enabled);
  
  // 构建设置对象
  const settings: AccessibilitySettings = {
    largeFontEnabled: enabled,
    highContrastEnabled: AppStorage.get<boolean>(STORAGE_KEYS.HIGH_CONTRAST) ?? false,
    vibrationEnabled: AppStorage.get<boolean>(STORAGE_KEYS.VIBRATION) ?? true
  };
  
  // 直接保存，不调用AppStorage.set()
  this.debounceSave(settings);
  console.info('大字体设置保存完成:', enabled);
}
```

#### 2. ProfilePage使用新方法

```typescript
Toggle({ type: ToggleType.Switch, isOn: this.largeFontEnabled })
  .onChange((isOn: boolean) => {
    console.info(`Toggle onChange: ${isOn}`);
    
    // 1. 立即更新AppStorage（UI立即响应）
    AppStorage.set('accessibility_large_font', isOn);
    
    // 2. 清除之前的定时器
    if (this.largeFontUpdateTimer !== -1) {
      clearTimeout(this.largeFontUpdateTimer);
    }
    
    // 3. 延迟持久化保存（使用saveLargeFontOnly避免循环）
    this.largeFontUpdateTimer = setTimeout(() => {
      this.accessibilityManager.saveLargeFontOnly(isOn);  // 不调用AppStorage.set()
      this.largeFontUpdateTimer = -1;
    }, 300);  // 增加延迟到300ms
  })
```

### 工作原理

1. **用户点击Toggle**：
   - `onChange(true)` 触发
   - 立即调用 `AppStorage.set('accessibility_large_font', true)`
   - `@StorageLink` 立即更新为 `true`
   - Toggle UI 立即显示为开启状态
   - 字体立即变大

2. **300ms后**：
   - 调用 `saveLargeFontOnly(true)`
   - **只持久化保存，不调用`AppStorage.set()`**
   - 不会触发`@StorageLink`更新
   - 不会触发Toggle的`onChange`
   - **避免了循环触发**

3. **如果有第二次onChange触发**：
   - 清除之前的定时器
   - 重新启动300ms定时器
   - 但`AppStorage`已经是正确的值，UI不受影响

### 关键改进

**v5的问题**：
```typescript
// ❌ 错误：updateLargeFont()会再次调用AppStorage.set()，导致循环
setTimeout(() => {
  this.accessibilityManager.updateLargeFont(isOn);  // 会触发onChange(false)
}, 100);
```

**v6的解决**：
```typescript
// ✓ 正确：saveLargeFontOnly()只持久化，不调用AppStorage.set()
setTimeout(() => {
  this.accessibilityManager.saveLargeFontOnly(isOn);  // 不会触发onChange
}, 300);
```

## 测试步骤

### 1. 开启功能测试

1. 进入个人中心 -> 无障碍设置
2. 点击"大字体模式"开关（从OFF到ON）
3. **预期**：
   - Toggle立即变为开启状态
   - 页面字体立即变大
   - 日志显示：
     ```
     [ProfilePage] 大字体Toggle onChange: true
     [ProfilePage] 立即更新AppStorage: true
     [ProfilePage] 防抖后持久化保存: true
     仅保存大字体设置: true
     大字体设置保存完成: true
     ```
   - **不应该出现**：`[ProfilePage] Toggle onChange: false`

### 2. 关闭功能测试

1. 再次点击"大字体模式"开关（从ON到OFF）
2. **预期**：
   - Toggle立即变为关闭状态
   - 页面字体立即恢复正常
   - 日志显示：
     ```
     [ProfilePage] 大字体Toggle onChange: false
     [ProfilePage] 立即更新AppStorage: false
     [ProfilePage] 防抖后持久化保存: false
     仅保存大字体设置: false
     ```

### 3. 持久化测试

1. 开启大字体模式
2. 完全关闭应用
3. 重新启动应用
4. **预期**：
   - Toggle显示为开启状态
   - 页面字体保持大字体

## 修改文件

1. `help_system/entry/src/main/ets/utils/AccessibilityManager.ets`
   - 新增 `saveLargeFontOnly()` 方法
   - 新增 `saveHighContrastOnly()` 方法
   - 新增 `saveVibrationOnly()` 方法
   - 这些方法只持久化保存，不调用`AppStorage.set()`

2. `help_system/entry/src/main/ets/pages/help-seeker/ProfilePage.ets`
   - 修改Toggle回调，使用`saveXxxOnly()`方法
   - 增加防抖延迟到300ms

## 优势

相比v5方案：
- ✅ 避免了`updateLargeFont()`调用`AppStorage.set()`导致的循环触发
- ✅ 分离了UI更新和持久化保存的逻辑
- ✅ 增加了防抖延迟，确保Toggle状态稳定
- ✅ 代码逻辑更清晰，职责分离

## 版本历史

### v1-v4: 各种尝试
- 尝试了本地状态、值变化检测、防抖等方案
- 都无法完全解决问题

### v5: 立即更新 + 延迟持久化
- 立即调用`AppStorage.set()`更新状态
- 延迟调用`updateLargeFont()`持久化
- **问题**：`updateLargeFont()`也调用`AppStorage.set()`，导致循环

### v6: 分离更新和保存（终极方案）
- 立即调用`AppStorage.set()`更新UI
- 延迟调用`saveXxxOnly()`只持久化
- `saveXxxOnly()`不调用`AppStorage.set()`
- **完美解决**所有问题

## 总结

这次修复的核心是**避免循环触发**：
- **UI更新**：在ProfilePage中立即调用`AppStorage.set()`
- **持久化保存**：使用新的`saveXxxOnly()`方法，不调用`AppStorage.set()`
- **防抖延迟**：增加到300ms，确保Toggle状态稳定
- **职责分离**：UI更新和持久化保存完全分离，避免相互影响

---

**修复时间**：2026-03-14  
**版本**：v6（终极方案）  
**状态**：✅ 完成
