import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { AuthService } from '../../services/AuthService';

interface UnsupportedParams {
  reason?: string;
}

/**
 * 账号在手表上不可用：无角色 / 社区管理员等，提示前往手机端处理。
 */
@Entry
@Component
struct WatchAccountUnsupportedPage {
  @State private reason: string = 'no-role';

  aboutToAppear(): void {
    const p = router.getParams() as UnsupportedParams;
    if (p && p.reason) {
      this.reason = p.reason as string;
    }
  }

  private message(): string {
    if (this.reason === 'community') {
      return '社区管理请在手机端使用';
    }
    return '请先在手机端完成账号与身份设置';
  }

  private async logout(): Promise<void> {
    await AuthService.logout();
    promptAction.showToast({ message: '已退出', duration: 1500 });
    router.replaceUrl({ url: 'pages/watch/WatchLoginPage' }).catch((err: Error) => {
      console.error('nav login failed:', err);
    });
  }

  build() {
    Column({ space: 16 }) {
      Text('当前账号')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .textAlign(TextAlign.Center)

      Text(this.message())
        .fontSize(13)
        .fontColor('#64748b')
        .textAlign(TextAlign.Center)

      Button('返回登录')
        .width('100%')
        .height(42)
        .onClick(() => {
          this.logout();
        })
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#f8fafc')
  }
}
