import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { UserApi } from '../../services/ApiService';
import { StorageUtil } from '../../utils/StorageUtil';
import type { UserProfile } from '../../models/User';
import { WatchCircularLayout } from '../../components/WatchCircularLayout';
import { WatchButton } from '../../components/WatchButton';

/**
 * 手表启动：读 Token / 刷新资料，按账号角色进入对应首页（不在手表切换身份）。
 */
@Entry
@Component
struct WatchSplashPage {
  @State isRouting: boolean = true;
  @State routeError: string = '';

  aboutToAppear(): void {
    this.routeBySession().catch((e: Error) => {
      console.error('WatchSplash route failed:', e);
      this.routeError = e.message ? e.message : '加载失败';
      this.isRouting = false;
    });
  }

  private navigateByRole(role: string): void {
    if (role === 'help-seeker') {
      router.replaceUrl({ url: 'pages/watch/WatchSeekerHomePage' }).catch((err: Error) => {
        console.error('nav seeker home failed:', err);
        this.routeError = err.message;
        this.isRouting = false;
      });
      return;
    }
    if (role === 'volunteer') {
      router.replaceUrl({ url: 'pages/watch/WatchVolunteerHomePage' }).catch((err: Error) => {
        console.error('nav volunteer home failed:', err);
        this.routeError = err.message;
        this.isRouting = false;
      });
      return;
    }
    if (role === 'community') {
      router.replaceUrl({
        url: 'pages/watch/WatchAccountUnsupportedPage',
        params: { reason: 'community' }
      }).catch((err: Error) => {
        console.error('nav unsupported failed:', err);
        this.routeError = err.message;
        this.isRouting = false;
      });
      return;
    }
    router.replaceUrl({
      url: 'pages/watch/WatchAccountUnsupportedPage',
      params: { reason: 'no-role' }
    }).catch((err: Error) => {
      console.error('nav unsupported failed:', err);
      this.routeError = err.message;
      this.isRouting = false;
    });
  }

  private async routeBySession(): Promise<void> {
    this.isRouting = true;
    this.routeError = '';
    const token: string = await StorageUtil.getString('token');
    if (!token || token.length === 0) {
      await router.replaceUrl({ url: 'pages/watch/WatchLoginPage' });
      return;
    }

    try {
      const profile: UserProfile = await UserApi.getCurrentProfile();
      await StorageUtil.set('user', profile);
      this.navigateByRole(profile.role as string);
    } catch (e) {
      const cached: UserProfile | null = await StorageUtil.get<UserProfile>('user');
      if (cached && cached.role) {
        this.navigateByRole(cached.role as string);
        return;
      }
      promptAction.showToast({
        message: '登录已失效，请重新登录',
        duration: 2000
      });
      await router.replaceUrl({ url: 'pages/watch/WatchLoginPage' });
    }
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
      if (this.isRouting && this.routeError.length === 0) {
        LoadingProgress()
          .width(28)
          .height(28)
        Text('加载中...')
          .fontSize(12)
          .fontColor('#64748b')
      } else if (this.routeError.length > 0) {
        Text(this.routeError)
          .fontSize(12)
          .fontColor('#b91c1c')
          .textAlign(TextAlign.Center)
        WatchButton({
          text: '重试',
          type: 'secondary',
          size: 'small',
          width: '100%',
          onClick: () => {
            this.routeBySession();
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#f8fafc')
  }
}
