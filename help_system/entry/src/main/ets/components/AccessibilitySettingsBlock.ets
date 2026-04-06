import { AccessibilityManager } from '../utils/AccessibilityManager';
import { ElderHighContrastTheme } from '../utils/AccessibilityTheme';

/**
 * 无障碍设置：大字体 + 高对比度（与求助者个人中心同款胶囊滑块，全局 AppStorage 同步）
 */
@Component
export struct AccessibilitySettingsBlock {
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  private accessibilityManager = AccessibilityManager.getInstance();

  private hcTextMain(): string {
    return this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#111827';
  }

  private a11yTrackOnColor(): string {
    return this.highContrastEnabled ? ElderHighContrastTheme.accentOn : '#2563eb';
  }

  private a11yRowIconBg(): string {
    return this.highContrastEnabled ? ElderHighContrastTheme.iconBoxBg : '#eef2ff';
  }

  private a11yRowIconBorder(): BorderOptions {
    return this.highContrastEnabled
      ? ElderHighContrastTheme.subtleBorder()
      : { width: 1, color: '#e5e7eb' };
  }

  @Builder
  LargeFontA11yRow() {
    Row() {
      Row({ space: 12 }) {
        Row() {
          Text('F')
            .fontSize(this.largeFontEnabled ? 15 : 13)
            .fontColor(this.hcTextMain())
            .fontWeight(FontWeight.Medium)
        }
        .width(34)
        .height(34)
        .justifyContent(FlexAlign.Center)
        .borderRadius(10)
        .backgroundColor(this.a11yRowIconBg())
        .border(this.a11yRowIconBorder())

        Text('大字体模式')
          .fontSize(this.largeFontEnabled ? 18 : 15)
          .fontColor(this.hcTextMain())
          .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)
          .layoutWeight(1)
      }
      .layoutWeight(1)
      .alignItems(VerticalAlign.Center)

      Stack({ alignContent: Alignment.Start }) {
        Row()
          .width(52)
          .height(32)
          .borderRadius(16)
          .backgroundColor(this.largeFontEnabled ? this.a11yTrackOnColor() : '#d1d5db')
          .shadow(this.largeFontEnabled ? {
            radius: 4,
            color: '#2563eb33',
            offsetX: 0,
            offsetY: 1
          } : { radius: 1, color: '#00000014', offsetX: 0, offsetY: 1 })
        Row()
          .width(28)
          .height(28)
          .borderRadius(14)
          .backgroundColor('#ffffff')
          .shadow({ radius: 3, color: '#00000026', offsetX: 0, offsetY: 1 })
          .offset({ x: this.largeFontEnabled ? 22 : 2, y: 2 })
      }
      .width(52)
      .height(32)
      .onClick(() => {
        this.accessibilityManager.updateLargeFont(!this.largeFontEnabled);
      })
    }
    .width('100%')
    .constraintSize({ minHeight: 52 })
    .padding(this.highContrastEnabled
      ? { left: 14, right: 14, top: 12, bottom: 12 }
      : { left: 12, right: 12, top: 12, bottom: 12 })
    .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.surface : '#ffffff')
    .borderRadius(10)
    .border(this.highContrastEnabled ? ElderHighContrastTheme.subtleBorder() : { width: 1, color: '#e8eaef' })
  }

  @Builder
  HighContrastA11yRow() {
    Row() {
      Row({ space: 12 }) {
        Row() {
          Text('C')
            .fontSize(this.largeFontEnabled ? 15 : 13)
            .fontColor(this.hcTextMain())
            .fontWeight(FontWeight.Medium)
        }
        .width(34)
        .height(34)
        .justifyContent(FlexAlign.Center)
        .borderRadius(10)
        .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.iconBoxBg : '#ecfdf5')
        .border(this.a11yRowIconBorder())

        Text('高对比度模式')
          .fontSize(this.largeFontEnabled ? 18 : 15)
          .fontColor(this.hcTextMain())
          .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)
          .layoutWeight(1)
      }
      .layoutWeight(1)
      .alignItems(VerticalAlign.Center)

      Stack({ alignContent: Alignment.Start }) {
        Row()
          .width(52)
          .height(32)
          .borderRadius(16)
          .backgroundColor(this.highContrastEnabled ? this.a11yTrackOnColor() : '#d1d5db')
          .shadow(this.highContrastEnabled ? {
            radius: 4,
            color: '#2e7d3240',
            offsetX: 0,
            offsetY: 1
          } : { radius: 1, color: '#00000014', offsetX: 0, offsetY: 1 })
        Row()
          .width(28)
          .height(28)
          .borderRadius(14)
          .backgroundColor('#ffffff')
          .shadow({ radius: 3, color: '#00000026', offsetX: 0, offsetY: 1 })
          .offset({ x: this.highContrastEnabled ? 22 : 2, y: 2 })
      }
      .width(52)
      .height(32)
      .onClick(() => {
        this.accessibilityManager.updateHighContrast(!this.highContrastEnabled, true);
      })
    }
    .width('100%')
    .constraintSize({ minHeight: 52 })
    .padding(this.highContrastEnabled
      ? { left: 14, right: 14, top: 12, bottom: 12 }
      : { left: 12, right: 12, top: 12, bottom: 12 })
    .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.surface : '#ffffff')
    .borderRadius(10)
    .border(this.highContrastEnabled ? ElderHighContrastTheme.subtleBorder() : { width: 1, color: '#e8eaef' })
  }

  build() {
    Column({ space: 8 }) {
      Text('无障碍设置')
        .width('100%')
        .fontSize(this.largeFontEnabled ? 20 : 16)
        .fontColor(this.hcTextMain())
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Start)
        .margin({ bottom: 2 })
      this.LargeFontA11yRow()
      Divider()
        .strokeWidth(1)
        .color(this.highContrastEnabled ? ElderHighContrastTheme.divider : '#f0f2f5')
        .margin({ left: 4, right: 4 })
      this.HighContrastA11yRow()
    }
    .width('100%')
    .padding({
      left: 14,
      right: 14,
      top: 14,
      bottom: 14
    })
    .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.surface : '#ffffff')
    .borderRadius(16)
    .border(this.highContrastEnabled ? ElderHighContrastTheme.cardBorder() : undefined)
  }
}
