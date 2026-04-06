# 无障碍组件库

本目录包含可复用的无障碍组件，这些组件自动应用全局无障碍设置。

## 组件列表

### 1. AccessibleText

可复用的文本组件，自动应用无障碍样式。

**功能特性：**
- 大字体模式：文字大小增加 25%
- 高对比度模式：黑色文字、加粗字体

**使用示例：**
```typescript
import { AccessibleText } from '../components/AccessibleText';

AccessibleText({ text: '标题', baseSize: 20 })
AccessibleText({ text: '内容', baseSize: 14, weight: FontWeight.Medium })
```

**属性说明：**
- `text`: 显示的文本内容（必需）
- `baseSize`: 基础字体大小，默认 14
- `weight`: 字体粗细（可选）
- `color`: 文字颜色（可选，高对比度模式下会被覆盖）
- `maxLines`: 最大行数（可选）
- `textAlign`: 文本对齐方式（可选）

---

### 2. AccessibleButton

可复用的按钮组件，自动应用无障碍样式并支持震动反馈。

**功能特性：**
- 大字体模式：文字大小增加 25%，按钮高度自动增大
- 高对比度模式：黄色背景、黑色文字、3px 粗边框、加粗字体
- 震动反馈：点击时自动触发震动（如果启用）

**使用示例：**
```typescript
import { AccessibleButton } from '../components/AccessibleButton';

// 基础用法
AccessibleButton({
  text: '确认',
  onClick: () => {
    console.log('按钮被点击');
  }
})

// 自定义样式
AccessibleButton({
  text: '提交',
  onClick: () => { this.submit() },
  type: ButtonType.Normal,
  fontSize: 18,
  backgroundColor: '#10b981',
  width: '80%'
})

// 禁用状态
AccessibleButton({
  text: '禁用按钮',
  enabled: false,
  onClick: () => { /* 不会执行 */ }
})
```

**属性说明：**
- `text`: 按钮文本（必需）
- `onClick`: 点击回调函数（必需）
- `type`: 按钮类型，默认 ButtonType.Capsule
- `fontSize`: 基础字体大小，默认 16
- `width`: 按钮宽度，默认 '100%'
- `height`: 按钮高度（可选，会根据大字体模式自动调整）
- `backgroundColor`: 背景色（可选，高对比度模式下会被覆盖）
- `fontColor`: 文字颜色（可选，高对比度模式下会被覆盖）
- `enabled`: 是否启用按钮，默认 true

**无障碍行为：**

| 模式 | 效果 |
|------|------|
| 普通模式 | 使用自定义颜色或默认蓝色背景、白色文字 |
| 大字体模式 | 字体大小 × 1.25，按钮高度从 44 增加到 56 |
| 高对比度模式 | 黄色背景 (#ffff00)、黑色文字 (#000000)、3px 黑色边框、加粗字体 |
| 震动反馈启用 | 点击时触发 50ms 震动 |
| 禁用状态 | 灰色背景、透明度 0.5、不可点击、不触发震动 |

---

## 使用指南

### 1. 导入组件

```typescript
import { AccessibleText } from '../components/AccessibleText';
import { AccessibleButton } from '../components/AccessibleButton';
```

### 2. 在页面中使用

这些组件会自动绑定全局无障碍设置（通过 @StorageLink），无需手动管理状态。

```typescript
@Entry
@Component
struct MyPage {
  build() {
    Column({ space: 20 }) {
      // 使用 AccessibleText
      AccessibleText({ 
        text: '欢迎使用', 
        baseSize: 24 
      })
      
      // 使用 AccessibleButton
      AccessibleButton({
        text: '开始使用',
        onClick: () => {
          router.pushUrl({ url: 'pages/NextPage' });
        }
      })
    }
  }
}
```

### 3. 无障碍设置

用户可以在个人中心（ProfilePage）开启无障碍设置：
- 大字体模式
- 高对比度模式
- 震动反馈提示

一旦开启，所有使用这些组件的页面都会自动应用相应的样式。

---

## 设计原则

### 1. 自动化
组件自动应用无障碍设置，开发者无需手动处理。

### 2. 一致性
所有页面使用相同的无障碍样式规则，确保用户体验一致。

### 3. 可定制
支持自定义基础样式，但无障碍模式下会覆盖部分样式以确保可访问性。

### 4. 渐进增强
在普通模式下提供良好的默认样式，在无障碍模式下增强可访问性。

---

## 技术实现

### 状态绑定

组件使用 `@StorageLink` 装饰器绑定全局无障碍设置：

```typescript
@StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
@StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;
```

当 AccessibilityManager 更新设置时，AppStorage 中的值会自动更新，所有绑定的组件会自动重新渲染。

### 样式计算

组件根据无障碍设置动态计算样式：

```typescript
// 字体大小
.fontSize(this.largeFontEnabled ? this.baseSize * 1.25 : this.baseSize)

// 文字颜色
.fontColor(this.highContrastEnabled ? '#000000' : this.color)

// 边框
.border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
```

---

## 扩展组件

如果需要创建新的无障碍组件，请遵循以下模式：

```typescript
@Component
export struct AccessibleXXX {
  // 1. 绑定全局无障碍设置
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;
  
  // 2. 定义组件属性
  @Prop someProp: string;
  
  // 3. 根据无障碍设置计算样式
  private getStyle() {
    return {
      fontSize: this.largeFontEnabled ? baseSize * 1.25 : baseSize,
      color: this.highContrastEnabled ? '#000000' : normalColor
    };
  }
  
  // 4. 应用样式
  build() {
    // 组件实现
  }
}
```

---

## 测试

每个组件都有对应的测试文件：
- `AccessibleText.test.ets` - AccessibleText 组件测试
- `AccessibleButton.test.ets` - AccessibleButton 组件测试

测试覆盖：
- 无障碍设置绑定
- 样式计算逻辑
- 震动反馈触发
- 禁用状态处理

---

## 相关文档

- [AccessibilityManager 文档](../utils/AccessibilityManager.ets)
- [无障碍功能需求](../../../../../.kiro/specs/accessibility-global-state/requirements.md)
- [无障碍功能设计](../../../../../.kiro/specs/accessibility-global-state/design.md)

---

## 需求追溯

这些组件实现了以下需求：
- **需求 3.3**：样式应用（大字体、高对比度、震动反馈）
- **需求 4.4.1**：所有页面正确应用无障碍设置
- **需求 4.5.4**：震动反馈在支持的设备上正常工作
