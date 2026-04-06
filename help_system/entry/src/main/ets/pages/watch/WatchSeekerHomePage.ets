import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { AuthService } from '../../services/AuthService';
import { WatchCircularLayout } from '../../components/WatchCircularLayout';

/**
 * 求助者手表首页（壳）：进入一键紧急等能力，后续在此扩展闭环。
 */
@Entry
@Component
struct WatchSeekerHomePage {
  private goEmergency(): void {
    router.pushUrl({ url: 'pages/watch/WatchSeekerEmergencyPage' }).catch((err: Error) => {
      console.error('nav emergency failed:', err);
    });
  }

  private goMyRequests(): void {
    router.pushUrl({ url: 'pages/watch/WatchMyRequestsPage' }).catch((err: Error) => {
      console.error('nav my requests failed:', err);
    });
  }

  private async logout(): Promise<void> {
    await AuthService.logout();
    promptAction.showToast({ message: '已退出', duration: 1500 });
    router.replaceUrl({ url: 'pages/watch/WatchLoginPage' }).catch((err: Error) => {
      console.error('nav login failed:', err);
    });
  }

  build() {
    WatchCircularLayout({
      centerRadius: 120,
      edgePadding: 16,
      content: () => {
        this.pageContent()
      }
    })
  }

  @Builder
  pageContent() {
    Column({ space: 16 }) {
      Text('互助帮扶')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .textAlign(TextAlign.Center)

      Text('求助者')
        .fontSize(14)
        .fontColor('#64748b')
        .width('100%')
        .textAlign(TextAlign.Center)

      Button('一键紧急求助')
        .width('100%')
        .height(48)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#ffffff')
        .backgroundColor('#dc2626')
        .borderRadius(14)
        .onClick(() => {
          this.goEmergency();
        })

      Button('我的求助')
        .width('100%')
        .height(44)
        .fontSize(15)
        .fontColor('#ffffff')
        .backgroundColor('#2563eb')
        .borderRadius(14)
        .onClick(() => {
          this.goMyRequests();
        })

      Button('退出登录')
        .width('100%')
        .height(40)
        .fontSize(14)
        .backgroundColor('#f1f5f9')
        .fontColor('#334155')
        .borderRadius(12)
        .onClick(() => {
          this.logout();
        })
    }
    .width('100%')
  }
}
