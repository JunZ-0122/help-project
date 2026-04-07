import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { AuthService } from '../../services/AuthService';
import { WatchCircularLayout } from '../../components/WatchCircularLayout';
import { WatchButton } from '../../components/WatchButton';
import { VolunteerApi, UserApi } from '../../services/ApiService';
import { StorageUtil } from '../../utils/StorageUtil';
import type { VolunteerStatistics } from '../../models/Common';
import type { UserProfile } from '../../models/User';

@Entry
@Component
struct WatchVolunteerHomePage {
  @State stats: VolunteerStatistics | null = null;
  @State isOnline: boolean = false;
  @State isTogglingStatus: boolean = false;

  aboutToAppear(): void {
    this.loadData();
  }

  onPageShow(): void {
    this.loadData();
  }

  private async loadData(): Promise<void> {
    try {
      const s = await VolunteerApi.getStatistics();
      this.stats = s;
    } catch (_) {
      // ignore
    }
    try {
      const user: UserProfile | null = await StorageUtil.get<UserProfile>('user');
      if (user && user.status) {
        this.isOnline = user.status === 'online';
      }
    } catch (_) {
      // ignore
    }
  }

  private async toggleOnline(): Promise<void> {
    if (this.isTogglingStatus) {
      return;
    }
    this.isTogglingStatus = true;
    const newStatus = this.isOnline ? 'offline' : 'online';
    try {
      const updated = await UserApi.updateUserProfile({ status: newStatus } as Partial<UserProfile>);
      await StorageUtil.set('user', updated);
      this.isOnline = newStatus === 'online';
      promptAction.showToast({ message: this.isOnline ? '已上线' : '已离线', duration: 1500 });
    } catch (e) {
      const err = e as Error;
      promptAction.showToast({ message: err.message || '操作失败', duration: 2000 });
    } finally {
      this.isTogglingStatus = false;
    }
  }

  private goNearby(): void {
    router.pushUrl({ url: 'pages/watch/WatchVolunteerNearbyPage' }).catch((err: Error) => {
      console.error('nav nearby failed:', err);
    });
  }

  private goOrders(): void {
    router.pushUrl({ url: 'pages/watch/WatchVolunteerOrdersPage' }).catch((err: Error) => {
      console.error('nav orders failed:', err);
    });
  }

  private goSettings(): void {
    router.pushUrl({ url: 'pages/watch/WatchSettingsPage' }).catch((err: Error) => {
      console.error('nav settings failed:', err);
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
    Column({ space: 6 }) {
      Text('志愿者')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .textAlign(TextAlign.Center)

      if (this.stats) {
        Row({ space: 6 }) {
          Text(`${this.stats.serviceCount}次`)
            .fontSize(10)
            .fontColor('#64748b')
          Text('|')
            .fontSize(10)
            .fontColor('#cbd5e1')
          Text(`${this.stats.satisfactionPercent !== null ? this.stats.satisfactionPercent + '%' : '--'}`)
            .fontSize(10)
            .fontColor('#64748b')
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }

      WatchButton({
        text: this.isTogglingStatus ? '...' : (this.isOnline ? '在线 (点击离线)' : '离线 (点击上线)'),
        type: this.isOnline ? 'primary' : 'secondary',
        size: 'small',
        width: '100%',
        onClick: () => {
          this.toggleOnline();
        }
      })

      WatchButton({
        text: '查看附近求助',
        type: 'primary',
        size: 'medium',
        width: '100%',
        onClick: () => {
          this.goNearby();
        }
      })

      WatchButton({
        text: '我的服务',
        type: 'primary',
        size: 'medium',
        width: '100%',
        onClick: () => {
          this.goOrders();
        }
      })

      Row({ space: 6 }) {
        WatchButton({
          text: '设置',
          type: 'secondary',
          size: 'small',
          onClick: () => {
            this.goSettings();
          }
        })
        WatchButton({
          text: '退出',
          type: 'secondary',
          size: 'small',
          onClick: () => {
            this.logout();
          }
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
  }
}
