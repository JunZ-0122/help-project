import router from '@ohos.router';
import { isWearableDevice } from '../utils/DeviceFormUtil';

@Entry
@Component
struct SplashPage {
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;
  
  @State showButton: boolean = false;
  @State logoScale: number = 0.5;
  @State logoOpacity: number = 0;
  @State titleOpacity: number = 0;
  @State buttonOpacity: number = 0;
  private autoTimer: number = -1;
  private buttonTimer: number = -1;

  aboutToAppear() {
    if (isWearableDevice()) {
      router.replaceUrl({ url: 'pages/watch/WatchSeekerEmergencyPage' }).catch((err: Error) => {
        console.error('watch route failed:', err);
      });
      return;
    }

    // Logo 动画
    animateTo({
      duration: 800,
      curve: Curve.EaseInOut,
      onFinish: () => {
        // 标题动画
        animateTo({
          duration: 600,
          curve: Curve.EaseOut
        }, () => {
          this.titleOpacity = 1;
        });
      }
    }, () => {
      this.logoScale = 1.0;
      this.logoOpacity = 1;
    });

    // 1秒后显示按钮
    this.buttonTimer = setTimeout(() => {
      animateTo({
        duration: 500,
        curve: Curve.EaseOut
      }, () => {
        this.showButton = true;
        this.buttonOpacity = 1;
      });
    }, 1200);

    // 3秒后自动跳转
    this.autoTimer = setTimeout(() => {
      this.navigateToLogin();
    }, 3500);
  }

  aboutToDisappear() {
    if (this.buttonTimer !== -1) {
      clearTimeout(this.buttonTimer);
    }
    if (this.autoTimer !== -1) {
      clearTimeout(this.autoTimer);
    }
  }

  navigateToLogin() {
    router.pushUrl({
      url: 'pages/LoginPage'
    }).catch((err: Error) => {
      console.error('导航失败:', err);
    });
  }

  build() {
    Column() {
      Column({ space: 40 }) {
        // App Logo with animation
        Column() {
          Row() {
            Image($r('app.media.startIcon'))
              .width(96)
              .height(96)
              .borderRadius(24)
          }
          .width(120)
          .height(120)
          .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
          .borderRadius(30)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
          .shadow(this.highContrastEnabled ? undefined : {
            radius: 24,
            color: '#3b82f640',
            offsetX: 0,
            offsetY: 12
          })
        }
        .scale({ x: this.logoScale, y: this.logoScale })
        .opacity(this.logoOpacity)

        // 系统名称 with animation
        Column({ space: 16 }) {
          Text('互助帮扶')
            .fontSize(this.largeFontEnabled ? 52.5 : 42)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
            .textAlign(TextAlign.Center)
            .letterSpacing(2)

          Text('一键求助 · 就在身边')
            .fontSize(this.largeFontEnabled ? 22.5 : 18)
            .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
            .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
            .textAlign(TextAlign.Center)
            .letterSpacing(1)
        }
        .opacity(this.titleOpacity)

        // 进入按钮 with animation
        if (this.showButton) {
          Button('立即进入')
            .width(this.largeFontEnabled ? 275 : 220)
            .height(this.largeFontEnabled ? 70 : 56)
            .fontSize(this.largeFontEnabled ? 22.5 : 18)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
            .backgroundColor(this.highContrastEnabled ? '#000000' : undefined)
            .linearGradient(this.highContrastEnabled ? undefined : {
              angle: 90,
              colors: [[0x3b82f6, 0.0], [0x6366f1, 1.0]]
            })
            .borderRadius(this.largeFontEnabled ? 35 : 28)
            .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
            .shadow(this.highContrastEnabled ? undefined : {
              radius: 16,
              color: '#3b82f640',
              offsetX: 0,
              offsetY: 8
            })
            .opacity(this.buttonOpacity)
            .onClick(() => {
              this.navigateToLogin();
            })
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      // 自动跳转提示
      Row({ space: 8 }) {
        LoadingProgress()
          .width(16)
          .height(16)
          .color(this.highContrastEnabled ? '#000000' : '#9ca3af')
        
        Text('正在自动跳转...')
          .fontSize(this.largeFontEnabled ? 17.5 : 14)
          .fontColor(this.highContrastEnabled ? '#000000' : '#9ca3af')
          .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
      }
      .position({ x: '50%', y: '88%' })
      .translate({ x: '-50%', y: '-50%' })
    }
    .width('100%')
    .height('100%')
    .linearGradient(this.highContrastEnabled ? undefined : {
      angle: 135,
      colors: [[0xdbeafe, 0.0], [0xe0e7ff, 1.0]]
    })
    .backgroundColor(this.highContrastEnabled ? '#ffff00' : undefined)
    .padding(24)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
