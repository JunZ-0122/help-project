/**
 * AccessibleText 组件
 * 
 * 可复用的文本组件，自动应用全局无障碍设置：
 * - 大字体模式：文字大小增加 25%
 * - 高对比度模式：黑色文字、加粗字体
 * 
 * 使用示例：
 * AccessibleText({ text: '标题', baseSize: 20 })
 * AccessibleText({ text: '内容', baseSize: 14, weight: FontWeight.Medium })
 */

@Component
export struct AccessibleText {
  // 绑定全局无障碍设置
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;
  
  // 组件属性
  @Prop text: string;                    // 显示的文本内容
  @Prop baseSize: number = 14;           // 基础字体大小
  @Prop weight?: FontWeight;             // 字体粗细（可选）
  @Prop color?: string;                  // 文字颜色（可选，高对比度模式下会被覆盖）
  @Prop maxLines?: number;               // 最大行数（可选）
  @Prop textAlign?: TextAlign;           // 文本对齐方式（可选）

  build() {
    Text(this.text)
      .fontSize(this.largeFontEnabled ? this.baseSize * 1.25 : this.baseSize)
      .fontColor(
        this.highContrastEnabled 
          ? '#000000'                    // 高对比度：黑色文字
          : (this.color || '#1a1a1a')    // 普通模式：使用指定颜色或默认深灰色
      )
      .fontWeight(
        this.highContrastEnabled 
          ? FontWeight.Bold              // 高对比度：加粗
          : (this.weight || FontWeight.Normal)  // 普通模式：使用指定粗细或正常
      )
      .maxLines(this.maxLines)
      .textAlign(this.textAlign)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
  }
}
