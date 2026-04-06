/**
 * WatchCircularLayout 圆屏布局组件
 * 
 * 专为手表端圆形屏幕设计的布局容器组件，确保内容在圆形安全区域内正确显示。
 * 
 * 功能特性：
 * - 圆形安全区域控制：确保重要内容在圆形区域内显示
 * - 边缘安全距离：避免内容被圆屏边缘裁切
 * - 自动适配：支持内容自动适配圆屏显示
 * - 无障碍支持：兼容大字体和高对比度模式
 * 
 * 使用示例：
 * WatchCircularLayout({
 *   centerRadius: 120,
 *   padding: 16
 * }) {
 *   // 页面内容
 *   Column() {
 *     Text('内容')
 *   }
 * }
 * 
 * 需求：1.1, 1.4
 * 属性：1 - 圆屏完全适配
 */

import { AccessibilityManager } from '../utils/AccessibilityManager';

@Component
export struct WatchCircularLayout {
  // 绑定全局无障碍设置
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;
  
  // 组件属性
  @Prop centerRadius: number = 120;        // 中心安全区域半径（dp）
  @Prop edgePadding: number = 16;          // 边缘安全距离（dp）
  @Prop bgColor: string = '#f8fafc';       // 背景颜色
  @BuilderParam content: () => void;       // 子内容构建器
  
  private accessibilityManager = AccessibilityManager.getInstance();

  /**
   * 计算实际的中心半径
   * 在大字体模式下适当减小半径以留出更多空间
   */
  private getActualCenterRadius(): number {
    return this.largeFontEnabled ? this.centerRadius * 0.9 : this.centerRadius;
  }

  /**
   * 计算实际的边缘安全距离
   * 在大字体模式下增加安全距离
   */
  private getActualPadding(): number {
    return this.largeFontEnabled ? this.edgePadding * 1.2 : this.edgePadding;
  }

  /**
   * 获取背景颜色
   * 支持高对比度模式
   */
  private getBackgroundColor(): string {
    if (this.highContrastEnabled) {
      return '#ffffff'; // 高对比度模式使用白色背景
    }
    return this.bgColor;
  }

  /**
   * 计算圆形容器的直径
   */
  private getCircularContainerSize(): number {
    return (this.getActualCenterRadius() - this.getActualPadding()) * 2;
  }

  /**
   * 检查元素是否在圆形安全区域内
   * 这是一个辅助方法，用于验证布局的正确性
   */
  private isInSafeArea(x: number, y: number): boolean {
    const centerX = this.getActualCenterRadius();
    const centerY = this.getActualCenterRadius();
    const safeRadius = this.getActualCenterRadius() - this.getActualPadding();
    
    const distance = Math.sqrt(Math.pow(x - centerX, 2) + Math.pow(y - centerY, 2));
    return distance <= safeRadius;
  }

  build() {
    Stack() {
      // 圆形安全区域指示器（仅在开发模式下显示）
      if (false) { // 设置为 true 可在开发时显示安全区域边界
        Circle()
          .width(this.getCircularContainerSize())
          .height(this.getCircularContainerSize())
          .fill(Color.Transparent)
          .stroke('#ff0000')
          .strokeWidth(1)
          .strokeDashArray([5, 5])
      }

      // 主要内容容器
      Column() {
        // 使用 Scroll 确保内容可以滚动查看
        Scroll() {
          Column() {
            // 渲染传入的内容
            if (this.content) {
              this.content();
            }
          }
          .width('100%')
          .padding({
            left: this.getActualPadding(),
            right: this.getActualPadding(),
            top: this.getActualPadding(),
            bottom: this.getActualPadding()
          })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.TopStart)
        // 限制滚动区域在圆形安全区域内
        .constraintSize({
          maxWidth: this.getCircularContainerSize(),
          maxHeight: this.getCircularContainerSize()
        })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.getBackgroundColor())
    .alignContent(Alignment.Center)
  }
}