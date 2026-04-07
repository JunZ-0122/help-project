import router from '@ohos.router';
import { NavBackButton } from '../../components/NavBackButton';
import { WatchCircularLayout } from '../../components/WatchCircularLayout';
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
      WatchCircularLayout({
        centerRadius: 120,
        edgePadding: 16,
        content: () => {
          this.pageContent()
        }
      })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  pageContent() {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        NavBackButton()
        Text('无障碍设�?)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
      }
      .width('100%')

      Row() {
        Text('大字�?)
          .fontSize(this.largeFontEnabled ? 14 : 12)
          .fontColor(this.highContrastEnabled ? '#000000' : '#334155')
          .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.largeFontEnabled })
          .onChange((isOn: boolean) => {
            this.largeFontEnabled = isOn;
            this.saveSetting('accessibility_large_font', isOn);
          })
      }
      .width('100%')
      .padding({ top: 6, bottom: 6 })

      Row() {
        Text('高对比度')
          .fontSize(this.largeFontEnabled ? 14 : 12)
          .fontColor(this.highContrastEnabled ? '#000000' : '#334155')
          .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.highContrastEnabled })
          .onChange((isOn: boolean) => {
            this.highContrastEnabled = isOn;
            this.saveSetting('accessibility_high_contrast', isOn);
          })
      }
      .width('100%')
      .padding({ top: 6, bottom: 6 })

      Text('设置即时生效')
        .fontSize(10)
        .fontColor('#94a3b8')
        .width('100%')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
  }
}
