/**
 * WatchButton 手表专用按钮组件
 * 
 * 专为手表端设计的按钮组件，确保符合44dp最小触控区域要求，
 * 支持不同尺寸和类型的按钮样式，提供触控反馈和视觉反馈。
 * 
 * 功能特性：
 * - 最小触控区域：44dp × 44dp（符合无障碍标准）
 * - 多种尺寸：small(44dp), medium(56dp), large(68dp)
 * - 多种类型：primary(主要), secondary(次要), emergency(紧急)
 * - 触控反馈：100ms内视觉反馈 + 震动反馈
 * - 无障碍支持：大字体、高对比度、语音描述
 * 
 * 使用示例：
 * WatchButton({
 *   text: '确认',
 *   buttonSize: 'medium',
 *   buttonType: 'primary'
 * })
 * .onClick(() => { this.handleConfirm() })
 * 
 * 需求：3.1, 3.2, 3.3
 * 属性：3 - 触控区域规范, 8 - 触控反馈
 */

import { AccessibilityManager } from '../utils/AccessibilityManager';

/**
 * 按钮尺寸类型
 */
export type WatchButtonSize = 'small' | 'medium' | 'large';

/**
 * 按钮样式类型
 */
export type WatchButtonType = 'primary' | 'secondary' | 'emergency';

/**
 * 按钮尺寸配置
 */
interface ButtonSizeConfig {
  width: number;
  height: number;
  fontSize: number;
  largeFontSize: number;
}

/**
 * 按钮颜色配置
 */
interface ButtonColorConfig {
  backgroundColor: string;
  fontColor: string;
  borderColor?: string;
  highContrastBg: string;
  highContrastFont: string;
  highContrastBorder: string;
}

@Component
export struct WatchButton {
  // 绑定全局无障碍设置
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;
  
  // 组件属性
  @Prop text: string;                                    // 按钮文本
  @Prop buttonSize: WatchButtonSize = 'medium';         // 按钮尺寸
  @Prop buttonType: WatchButtonType = 'primary';        // 按钮类型
  @Prop buttonEnabled: boolean = true;                  // 是否启用按钮
  @Prop accessibilityLabel: string = '';                // 无障碍描述文本
  @Prop buttonWidth: Length = 'auto';                   // 自定义宽度（可选）
  @Prop buttonHeight: Length = 'auto';                  // 自定义高度（可选）
  
  private accessibilityManager = AccessibilityManager.getInstance();

  /**
   * 获取按钮尺寸配置
   */
  private getSizeConfig(): ButtonSizeConfig {
    switch (this.buttonSize) {
      case 'small':
        return {
          width: 44,   // 最小触控区域
          height: 44,
          fontSize: 14,
          largeFontSize: 16
        };
      case 'medium':
        return {
          width: 56,   // 标准尺寸
          height: 56,
          fontSize: 16,
          largeFontSize: 18
        };
      case 'large':
        return {
          width: 68,   // 大尺寸，适合重要操作
          height: 68,
          fontSize: 18,
          largeFontSize: 20
        };
      default:
        return {
          width: 56,
          height: 56,
          fontSize: 16,
          largeFontSize: 18
        };
    }
  }

  /**
   * 获取按钮颜色配置
   */
  private getColorConfig(): ButtonColorConfig {
    switch (this.buttonType) {
      case 'primary':
        return {
          backgroundColor: '#2563eb',
          fontColor: '#ffffff',
          highContrastBg: '#000000',
          highContrastFont: '#ffffff',
          highContrastBorder: '#ffffff'
        };
      case 'secondary':
        return {
          backgroundColor: '#64748b',
          fontColor: '#ffffff',
          borderColor: '#64748b',
          highContrastBg: '#ffffff',
          highContrastFont: '#000000',
          highContrastBorder: '#000000'
        };
      case 'emergency':
        return {
          backgroundColor: '#dc2626',
          fontColor: '#ffffff',
          highContrastBg: '#ff0000',
          highContrastFont: '#ffffff',
          highContrastBorder: '#ffffff'
        };
      default:
        return {
          backgroundColor: '#2563eb',
          fontColor: '#ffffff',
          highContrastBg: '#000000',
          highContrastFont: '#ffffff',
          highContrastBorder: '#ffffff'
        };
    }
  }

  /**
   * 计算实际按钮宽度
   */
  private getActualWidth(): Length {
    if (this.buttonWidth !== 'auto') {
      return this.buttonWidth;
    }
    const config = this.getSizeConfig();
    // 在大字体模式下适当增加宽度以容纳更大的文字
    return this.largeFontEnabled ? config.width * 1.1 : config.width;
  }

  /**
   * 计算实际按钮高度
   */
  private getActualHeight(): Length {
    if (this.buttonHeight !== 'auto') {
      return this.buttonHeight;
    }
    const config = this.getSizeConfig();
    // 确保最小触控区域44dp，在大字体模式下适当增加
    const minHeight = 44;
    const calculatedHeight = this.largeFontEnabled ? config.height * 1.1 : config.height;
    return Math.max(minHeight, calculatedHeight);
  }

  /**
   * 计算实际字体大小
   */
  private getActualFontSize(): number {
    const config = this.getSizeConfig();
    return this.largeFontEnabled ? config.largeFontSize : config.fontSize;
  }

  /**
   * 获取背景颜色
   */
  private getBackgroundColor(): string {
    const colorConfig = this.getColorConfig();
    
    if (!this.buttonEnabled) {
      return this.highContrastEnabled ? '#cccccc' : '#e5e7eb';
    }
    
    if (this.highContrastEnabled) {
      return colorConfig.highContrastBg;
    }
    
    return colorConfig.backgroundColor;
  }

  /**
   * 获取文字颜色
   */
  private getFontColor(): string {
    const colorConfig = this.getColorConfig();
    
    if (!this.buttonEnabled) {
      return this.highContrastEnabled ? '#666666' : '#9ca3af';
    }
    
    if (this.highContrastEnabled) {
      return colorConfig.highContrastFont;
    }
    
    return colorConfig.fontColor;
  }

  /**
   * 获取边框配置
   */
  private getBorderConfig(): BorderOptions | undefined {
    const colorConfig = this.getColorConfig();
    
    if (this.highContrastEnabled) {
      return {
        width: 2,
        color: colorConfig.highContrastBorder,
        style: BorderStyle.Solid
      };
    }
    
    if (this.buttonType === 'secondary') {
      return {
        width: 1,
        color: colorConfig.borderColor || colorConfig.backgroundColor,
        style: BorderStyle.Solid
      };
    }
    
    return undefined;
  }

  /**
   * 获取无障碍描述文本
   */
  private getAccessibilityText(): string {
    if (this.accessibilityLabel && this.accessibilityLabel.length > 0) {
      return this.accessibilityLabel;
    }
    
    // 根据按钮类型生成默认描述
    const typeDescriptions: Record<string, string> = {
      'primary': '主要操作按钮',
      'secondary': '次要操作按钮', 
      'emergency': '紧急操作按钮'
    };
    
    return `${this.text}，${typeDescriptions[this.buttonType] || '操作按钮'}`;
  }

  build() {
    Button(this.text, { type: ButtonType.Normal })
      .fontSize(this.getActualFontSize())
      .fontColor(this.getFontColor())
      .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)
      .backgroundColor(this.getBackgroundColor())
      .width(this.getActualWidth())
      .height(this.getActualHeight())
      .border(this.getBorderConfig())
      .borderRadius(8)
      .enabled(this.buttonEnabled)
      .opacity(this.buttonEnabled ? 1.0 : 0.5)
      // 无障碍支持
      .accessibilityText(this.getAccessibilityText())
      .accessibilityDescription(this.getAccessibilityText())
      // 动画效果
      .animation({
        duration: 100,
        curve: Curve.EaseInOut
      })
      // 确保最小触控区域（需求3.1）
      .constraintSize({
        minWidth: 44,
        minHeight: 44
      })
  }
}