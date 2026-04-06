import router from '@ohos.router';

/**
 * 统一返回按钮：浅灰圆底 + 左箭头「←」，与数据统计页一致。
 */
@Component
export struct NavBackButton {
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  build() {
    Button() {
      Text('←')
        .fontSize(this.largeFontEnabled ? 22 : 18)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.highContrastEnabled ? '#000000' : '#334155')
    }
    .width(this.largeFontEnabled ? 44 : 40)
    .height(this.largeFontEnabled ? 44 : 40)
    .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#f1f5f9')
    .borderRadius(999)
    .border(this.highContrastEnabled ? { width: 2, color: '#000000' } : undefined)
    .onClick(() => {
      router.back();
    })
  }
}
