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
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;
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
    Column() {
      Scroll() {
        Column({ space: 8 }) {
          this.pageContent()
        }
        .width('100%')
        .padding({ left: 10, right: 10, top: 10, bottom: 10 })
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
  pageContent() {
    Column({ space: 8 }) {
      Column({ space: 6 }) {
        Text('志愿者服务')
          .fontSize(this.largeFontEnabled ? 14 : 12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.highContrastEnabled ? '#000000' : '#1e293b')
          .width('100%')
          .textAlign(TextAlign.Center)

        Text(this.isOnline ? '当前在线，可接收求助' : '当前离线，请先切换状态')
          .fontSize(this.largeFontEnabled ? 10 : 9)
          .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
          .width('100%')
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .padding({ top: 2 })

      Column({ space: 6 }) {
        Stack() {
          Circle()
            .width(74)
            .height(74)
            .fill(this.isOnline ? (this.highContrastEnabled ? '#2563eb' : '#2563eb') : (this.highContrastEnabled ? '#ef4444' : '#dc2626'))

          Column({ space: 2 }) {
            Stack() {
              Circle()
                .width(18)
                .height(18)
                .fill('#ffffff')

              Text(this.isOnline ? '●' : '○')
                .fontSize(10)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.isOnline ? '#16a34a' : '#64748b')
            }

            Text(this.isOnline ? '在线' : '离线')
              .fontSize(10)
              .fontWeight(FontWeight.Bold)
              .fontColor('#ffffff')
          }
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .height(82)

        Text(this.stats ? `${this.stats.serviceCount}次服务 · ${this.stats.satisfactionPercent !== null ? this.stats.satisfactionPercent + '%' : '--'}` : '服务统计加载中')
          .fontSize(this.largeFontEnabled ? 8 : 7)
          .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
          .width('100%')
          .textAlign(TextAlign.Center)

        WatchButton({
          text: this.isTogglingStatus ? '...' : (this.isOnline ? '点击离线' : '点击上线'),
          buttonType: this.isOnline ? 'primary' : 'secondary',
          buttonSize: 'small',
          buttonWidth: '72%'
        })
        .onClick(() => {
          this.toggleOnline();
        })
      }
      .width('100%')
      .padding(10)
      .alignItems(HorizontalAlign.Center)

      Column({ space: 8 }) {
        Text('快捷入口')
          .fontSize(this.largeFontEnabled ? 11 : 10)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.highContrastEnabled ? '#000000' : '#1e293b')
          .width('100%')
          .textAlign(TextAlign.Start)

        Row({ space: 6 }) {
          WatchButton({
            text: '附近求助',
            buttonType: 'primary',
            buttonSize: 'small',
            buttonWidth: '48%'
          })
          .onClick(() => {
            this.goNearby();
          })

          WatchButton({
            text: '我的服务',
            buttonType: 'primary',
            buttonSize: 'small',
            buttonWidth: '48%'
          })
          .onClick(() => {
            this.goOrders();
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        Row({ space: 6 }) {
          WatchButton({
            text: '设置',
            buttonType: 'secondary',
            buttonSize: 'small',
            buttonWidth: '48%'
          })
          .onClick(() => {
            this.goSettings();
          })

          WatchButton({
            text: '退出',
            buttonType: 'secondary',
            buttonSize: 'small',
            buttonWidth: '48%'
          })
          .onClick(() => {
            this.logout();
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .width('100%')
      .padding(10)
      .backgroundColor(this.highContrastEnabled ? '#ffffff' : '#f8fafc')
      .borderRadius(18)
      .border({ width: this.highContrastEnabled ? 2 : 1, color: this.highContrastEnabled ? '#000000' : '#e2e8f0' })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }
}
