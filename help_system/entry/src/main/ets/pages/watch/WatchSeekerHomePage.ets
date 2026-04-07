import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { AuthService } from '../../services/AuthService';
import { WatchCircularLayout } from '../../components/WatchCircularLayout';
import { WatchButton } from '../../components/WatchButton';

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

  private goRequest(): void {
    router.pushUrl({ url: 'pages/watch/WatchSeekerRequestPage' }).catch((err: Error) => {
      console.error('nav request failed:', err);
    });
  }

  private goSettings(): void {
    router.pushUrl({ url: 'pages/watch/WatchSettingsPage' }).catch((err: Error) => {
      console.error('nav settings failed:', err);
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
    Column({ space: 8 }) {
      Text('互助帮扶')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .textAlign(TextAlign.Center)

      Text('求助者')
        .fontSize(11)
        .fontColor('#64748b')
        .width('100%')
        .textAlign(TextAlign.Center)

      WatchButton({
        text: '一键紧急求助',
        type: 'emergency',
        size: 'large',
        width: '100%',
        accessibilityLabel: '一键紧急求助按钮',
        onClick: () => { this.goEmergency(); }
      })

      WatchButton({
        text: '分类求助',
        type: 'primary',
        size: 'medium',
        width: '100%',
        onClick: () => { this.goRequest(); }
      })

      WatchButton({
        text: '我的求助',
        type: 'primary',
        size: 'medium',
        width: '100%',
        onClick: () => { this.goMyRequests(); }
      })

      Row({ space: 6 }) {
        WatchButton({
          text: '设置',
          type: 'secondary',
          size: 'small',
          onClick: () => { this.goSettings(); }
        })
        WatchButton({
          text: '退出',
          type: 'secondary',
          size: 'small',
          onClick: () => { this.logout(); }
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
  }
}
