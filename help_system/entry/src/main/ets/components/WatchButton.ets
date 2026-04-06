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
 *   size: 'medium',
 *   type: 'primary',
 *   onClick: () => { this.handleConfirm() }
 * })
 * 
 * WatchButton({
 *   text: '紧急求助',
 *   size: 'large', 
 *   type: 'emergency',
 *   onClick: () => { this.handleEmergency() }
 * })
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
  @Prop size: WatchButtonSize = 'medium';               // 按钮尺寸
  @Prop type: WatchButtonType = 'primary';              // 按钮类型
  @Prop onClick: () => void;                            // 点击回调函数
  @Prop enabled: boolean = true;                        // 是否启用按钮
  @Prop accessibilityLabel?: string;                    // 无障碍描述文本
  @Prop width?: Length;                                 // 自定义宽度（可选）
  @Prop height?: Length;                                // 自定义高度（可选）
  
  // 内部状态
  @State isPressed: boolean = false;                    // 按钮按下状态
  @State pressStartTime: number = 0;                    // 按下开始时间
  
  private accessibilityManager = AccessibilityManager.getInstance();

  /**
   * 获取按钮尺寸配置
   */
  private getSizeConfig(): ButtonSizeConfig {
    const configs: Record<WatchButtonSize, ButtonSizeConfig> = {
      small: {
        width: 44,   // 最小触控区域
        height: 44,
        fontSize: 14,
        largeFontSize: 16
      },
      medium: {
        width: 56,   // 标准尺寸
        height: 56,
        fontSize: 16,
        largeFontSize: 18
      },
      large: {
        width: 68,   // 大尺寸，适合重要操作
        height: 68,
        fontSize: 18,
        largeFontSize: 20
      }
    };
    return configs[this.size];
  }

  /**
   * 获取按钮颜色配置
   */
  private getColorConfig(): ButtonColorConfig {
    const configs: Record<WatchButtonType, ButtonColorConfig> = {
      primary: {
        backgroundColor: '#2563eb',
        fontColor: '#ffffff',
        highContrastBg: '#000000',
        highContrastFont: '#ffffff',
        highContrastBorder: '#ffffff'
      },
      secondary: {
        backgroundColor: '#64748b',
        fontColor: '#ffffff',
        borderColor: '#64748b',
        highContrastBg: '#ffffff',
        highContrastFont: '#000000',
        highContrastBorder: '#000000'
      },
      emergency: {
        backgroundColor: '#dc2626',
        fontColor: '#ffffff',
        highContrastBg: '#ff0000',
        highContrastFont: '#ffffff',
        highContrastBorder: '#ffffff'
      }
    };
    return configs[this.type];
  }

  /**
   * 计算实际按钮宽度
   */
  private getActualWidth(): Length {
    if (this.width) {
      return this.width;
    }
    const config = this.getSizeConfig();
    // 在大字体模式下适当增加宽度以容纳更大的文字
    return this.largeFontEnabled ? config.width * 1.1 : config.width;
  }

  /**
   * 计算实际按钮高度
   */
  private getActualHeight(): Length {
    if (this.height) {
      return this.height;
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
    
    if (!this.enabled) {
      return this.highContrastEnabled ? '#cccccc' : '#e5e7eb';
    }
    
    if (this.highContrastEnabled) {
      return colorConfig.highContrastBg;
    }
    
    // 按下状态时稍微变暗
    if (this.isPressed) {
      return this.darkenColor(colorConfig.backgroundColor, 0.1);
    }
    
    return colorConfig.backgroundColor;
  }

  /**
   * 获取文字颜色
   */
  private getFontColor(): string {
    const colorConfig = this.getColorConfig();
    
    if (!this.enabled) {
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
    
    if (this.type === 'secondary') {
      return {
        width: 1,
        color: colorConfig.borderColor || colorConfig.backgroundColor,
        style: BorderStyle.Solid
      };
    }
    
    return undefined;
  }

  /**
   * 颜色变暗工具函数
   */
  private darkenColor(color: string, amount: number): string {
    // 简单的颜色变暗实现
    if (color.startsWith('#')) {
      const hex = color.slice(1);
      const num = parseInt(hex, 16);
      const r = Math.max(0, Math.floor((num >> 16) * (1 - amount)));
      const g = Math.max(0, Math.floor(((num >> 8) & 0x00FF) * (1 - amount)));
      const b = Math.max(0, Math.floor((num & 0x0000FF) * (1 - amount)));
      return `#${((r << 16) | (g << 8) | b).toString(16).padStart(6, '0')}`;
    }
    return color;
  }

  /**
   * 处理按钮按下
   */
  private handleTouchStart(): void {
    if (!this.enabled) {
      return;
    }
    
    this.isPressed = true;
    this.pressStartTime = Date.now();
    
    // 触发震动反馈
    this.accessibilityManager.triggerVibration();
  }

  /**
   * 处理按钮释放
   */
  private handleTouchEnd(): void {
    if (!this.enabled) {
      return;
    }
    
    const pressDuration = Date.now() - this.pressStartTime;
    
    // 确保视觉反馈至少持续100ms（需求8.1）
    const minFeedbackDuration = 100;
    if (pressDuration < minFeedbackDuration) {
      setTimeout(() => {
        this.isPressed = false;
      }, minFeedbackDuration - pressDuration);
    } else {
      this.isPressed = false;
    }
    
    // 执行点击回调
    if (this.onClick) {
      this.onClick();
    }
  }

  /**
   * 处理按钮取消（手指移出按钮区域）
   */
  private handleTouchCancel(): void {
    this.isPressed = false;
  }

  /**
   * 获取无障碍描述文本
   */
  private getAccessibilityText(): string {
    if (this.accessibilityLabel) {
      return this.accessibilityLabel;
    }
    
    // 根据按钮类型生成默认描述
    const typeDescriptions: Record<WatchButtonType, string> = {
      primary: '主要操作按钮',
      secondary: '次要操作按钮', 
      emergency: '紧急操作按钮'
    };
    
    return `${this.text}，${typeDescriptions[this.type]}`;
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
      .enabled(this.enabled)
      .opacity(this.enabled ? 1.0 : 0.5)
      // 触控事件处理
      .onTouch((event: TouchEvent) => {
        switch (event.type) {
          case TouchType.Down:
            this.handleTouchStart();
            break;
          case TouchType.Up:
            this.handleTouchEnd();
            break;
          case TouchType.Cancel:
            this.handleTouchCancel();
            break;
        }
      })
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