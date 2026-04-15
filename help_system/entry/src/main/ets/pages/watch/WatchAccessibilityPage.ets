import router from '@ohos.router';
import { NavBackButton } from '../../components/NavBackButton';
import { StorageUtil } from '../../utils/StorageUtil';

@Entry
@Component
struct WatchAccessibilityPage {
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  private async saveSetting(key: string, value: boolean): Promise<void> {
    try {
      await StorageUtil.set(key, value);
    } catch (e) {
      console.error('save setting failed:', e);
    }
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 8 }) {
          Row({ space: 8 }) {
            NavBackButton()
            Text('无障碍设置')
              .fontSize(this.largeFontEnabled ? 16 : 14)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.highContrastEnabled ? '#000000' : '#1e293b')
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          this.optionCard(
            '大字体',
            this.largeFontEnabled,
            () => {
              const nextValue = !this.largeFontEnabled;
              this.largeFontEnabled = nextValue;
              this.saveSetting('accessibility_large_font', nextValue);
            }
          )

          this.optionCard(
            '高对比度',
            this.highContrastEnabled,
            () => {
              const nextValue = !this.highContrastEnabled;
              this.highContrastEnabled = nextValue;
              this.saveSetting('accessibility_high_contrast', nextValue);
            }
          )

          Text('设置即时生效，可随时在本页恢复。')
            .fontSize(this.largeFontEnabled ? 10 : 9)
            .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ top: 2 })
        }
        .width('100%')
        .padding({ left: 10, right: 10, top: 10, bottom: 12 })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#f0f4ff')
  }

  @Builder
  optionCard(title: string, enabled: boolean, onToggle: () => void) {
    Row({ space: 8 }) {
      Column({ space: 4 }) {
        Text(title)
          .fontSize(this.largeFontEnabled ? 13 : 12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.highContrastEnabled ? '#000000' : '#334155')
          .width('100%')
          .textAlign(TextAlign.Center)

        Text(enabled ? '当前已开启' : '当前已关闭')
          .fontSize(this.largeFontEnabled ? 10 : 9)
          .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
          .width('100%')
          .textAlign(TextAlign.Center)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)

      Button(enabled ? '点击关闭' : '点击开启')
        .width(72)
        .height(34)
        .fontSize(this.largeFontEnabled ? 10 : 9)
        .fontColor('#ffffff')
        .backgroundColor(enabled ? '#16a34a' : '#64748b')
        .borderRadius(10)
        .onClick(() => {
          onToggle();
        })
    }
    .width('100%')
    .padding(10)
    .alignItems(VerticalAlign.Center)
    .backgroundColor(this.highContrastEnabled ? '#ffffff' : '#ffffffcc')
    .borderRadius(14)
    .border({ width: this.highContrastEnabled ? 2 : 1, color: this.highContrastEnabled ? '#000000' : '#e2e8f0' })
  }
}
