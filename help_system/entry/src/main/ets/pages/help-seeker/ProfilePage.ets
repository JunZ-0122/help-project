import { NavBackButton } from '../../components/NavBackButton';
import { SeekerPersonalCenterPane } from './SeekerPersonalCenterPane';
import { ElderHighContrastTheme } from '../../utils/AccessibilityTheme';

/**
 * 独立「个人中心」页：顶栏返回 + 与首页 Tab 相同的求助者个人中心主体。
 */
@Entry
@Component
struct ProfilePage {
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  @State refreshSig: number = 0;
  private skipNextPageShow: boolean = true;

  onPageShow() {
    if (this.skipNextPageShow) {
      this.skipNextPageShow = false;
      return;
    }
    this.refreshSig++;
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        NavBackButton()

        Text('个人中心')
          .fontSize(this.largeFontEnabled ? 22 : 18)
          .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#111827')
          .layoutWeight(1)
      }
      .width('100%')
      .padding(12)
      .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.surface : '#ffffff')
      .border({
        width: { bottom: this.highContrastEnabled ? 2 : 1 },
        color: this.highContrastEnabled ? ElderHighContrastTheme.borderStrong : '#e5e7eb'
      })

      SeekerPersonalCenterPane({ refreshSig: this.refreshSig })
        .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.pageBg : '#f3f4f6')
  }
}
