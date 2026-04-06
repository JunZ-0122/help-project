/**
 * AccessibleButton 组件
 * 
 * 可复用的按钮组件，自动应用全局无障碍设置：
 * - 大字体模式：文字大小增加 25%，按钮尺寸相应增大
 * - 高对比度模式：深蓝主色、白字、粗描边（ElderHighContrastTheme）
 * - 震动反馈：点击时触发震动反馈（如果启用）
 * 
 * 使用示例：
 * AccessibleButton({ 
 *   text: '确认', 
 *   onClick: () => { this.handleConfirm() }
 * })
 * 
 * AccessibleButton({ 
 *   text: '提交', 
 *   onClick: () => { this.submit() },
 *   type: ButtonType.Normal,
 *   fontSize: 16
 * })
 * 
 * 需求：3.3
 */

import { AccessibilityManager } from '../utils/AccessibilityManager';
import { ElderHighContrastTheme } from '../utils/AccessibilityTheme';

@Component
export struct AccessibleButton {
  // 绑定全局无障碍设置
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;
  
  // 组件属性
  @Prop text: string;                           // 按钮文本
  @Prop onClick: () => void;                    // 点击回调函数
  @Prop type?: ButtonType = ButtonType.Capsule; // 按钮类型
  @Prop fontSize?: number = 16;                 // 基础字体大小
  @Prop width?: Length = '100%';                // 按钮宽度
  @Prop height?: Length;                        // 按钮高度（可选，会根据大字体模式自动调整）
  @Prop backgroundColor?: string;               // 背景色（可选，高对比度模式下会被覆盖）
  @Prop fontColor?: string;                     // 文字颜色（可选，高对比度模式下会被覆盖）
  @Prop enabled?: boolean = true;               // 是否启用按钮
  
  private accessibilityManager = AccessibilityManager.getInstance();

  /**
   * 计算实际字体大小
   */
  private getActualFontSize(): number {
    return this.largeFontEnabled ? this.fontSize! * 1.25 : this.fontSize!;
  }

  /**
   * 计算实际按钮高度
   */
  private getActualHeight(): Length {
    if (this.height) {
      return this.height;
    }
    // 默认高度根据大字体模式调整
    return this.largeFontEnabled ? 56 : 44;
  }

  /**
   * 获取背景颜色
   */
  private getBackgroundColor(): string {
    if (!this.enabled) {
      return this.highContrastEnabled ? '#cccccc' : '#e5e7eb';
    }
    if (this.highContrastEnabled) {
      return this.backgroundColor || ElderHighContrastTheme.accentBlue;
    }
    return this.backgroundColor || '#3b82f6';
  }

  /**
   * 获取文字颜色
   */
  private getFontColor(): string {
    if (!this.enabled) {
      return this.highContrastEnabled ? '#666666' : '#9ca3af';
    }
    if (this.highContrastEnabled) {
      return this.fontColor || '#ffffff';
    }
    return this.fontColor || '#ffffff';
  }

  /**
   * 处理按钮点击
   */
  private handleClick(): void {
    if (!this.enabled) {
      return;
    }
    
    // 触发震动反馈
    this.accessibilityManager.triggerVibration();
    
    // 执行点击回调
    if (this.onClick) {
      this.onClick();
    }
  }

  build() {
    Button(this.text, { type: this.type })
      .fontSize(this.getActualFontSize())
      .fontColor(this.getFontColor())
      .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
      .backgroundColor(this.getBackgroundColor())
      .width(this.width)
      .height(this.getActualHeight())
      .border(
        this.highContrastEnabled
          ? ElderHighContrastTheme.cardBorder()
          : undefined
      )
      .enabled(this.enabled!)
      .opacity(this.enabled ? 1.0 : 0.5)
      .onClick(() => this.handleClick())
  }
}
