import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { AccessibilityManager } from '../../utils/AccessibilityManager';
import { AuthService } from '../../services/AuthService';
import { UserApi, VolunteerApi } from '../../services/ApiService';
import { StorageUtil } from '../../utils/StorageUtil';
import { AccessibilitySettingsBlock } from '../../components/AccessibilitySettingsBlock';
import type { UserProfile } from '../../models';

interface MenuItem {
  id: string;
  icon: string;
  label: string;
  path?: string;
}

interface StatCard {
  value: string;
  label: string;
  color: string;
}

@Entry
@Component
struct ProfilePage {
  @State showAccessibility: boolean = false;
  @State userName: string = '';
  @State phone: string = '';
  @State serviceCount: number = 0;
  @State satisfactionDisplay: string = '--';
  @State serviceHoursDisplay: string = '0h';
  @State isLoading: boolean = false;
  @State isLoggingOut: boolean = false;

  /** 与全局 AppStorage 同步，与求助者个人中心无障碍块一致 */
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  private menuItems: MenuItem[] = [
    { id: 'orders', icon: '\u2630', label: '\u6211\u7684\u63a5\u5355\u8bb0\u5f55', path: 'pages/volunteer/MyOrdersPage' },
    { id: 'switch', icon: '\u21C4', label: '\u8eab\u4efd\u5207\u6362', path: 'pages/RoleSelectPage' },
    { id: 'accessibility', icon: '\u2699', label: '\u65e0\u969c\u788d\u8bbe\u7f6e' }
  ];

  private skipNextPageShow: boolean = true;

  private accessibilityManager = AccessibilityManager.getInstance();

  async aboutToAppear() {
    await this.accessibilityManager.initDone;
    this.loadProfileData();
  }

  onPageShow() {
    if (this.skipNextPageShow) {
      this.skipNextPageShow = false;
      return;
    }
    this.loadProfileData();
  }

  goBack() {
    router.back();
  }

  private shouldRedirectToLogin(error: Error): boolean {
    return error.message.indexOf('\u767b\u5f55') >= 0
      && error.message.indexOf('\u91cd\u65b0\u767b\u5f55') >= 0;
  }

  private async redirectToLogin(): Promise<void> {
    await AuthService.logout();
    router.replaceUrl({
      url: 'pages/LoginPage'
    }).catch((err: Error) => {
      console.error('navigation failed:', err);
    });
  }

  private buildStats(): StatCard[] {
    return [
      { value: this.serviceCount.toString(), label: '\u670d\u52a1\u6b21\u6570', color: '#10b981' },
      { value: this.satisfactionDisplay, label: '\u6ee1\u610f\u5ea6', color: '#2563eb' },
      { value: this.serviceHoursDisplay, label: '\u670d\u52a1\u65f6\u957f', color: '#f59e0b' }
    ];
  }

  private formatHours(h: number): string {
    if (h <= 0) {
      return '0h';
    }
    if (h < 100 && Math.abs(h - Math.round(h)) > 0.05) {
      return `${h.toFixed(1)}h`;
    }
    return `${Math.round(h)}h`;
  }

  private async loadProfileData(): Promise<void> {
    this.isLoading = true;

    try {
      const profile: UserProfile = await UserApi.getCurrentProfile();
      const stats = await VolunteerApi.getStatistics();
      await StorageUtil.set('user', profile);

      this.userName = profile.name ? profile.name : '';
      this.phone = profile.phone ? profile.phone : '';
      this.serviceCount = stats.serviceCount;
      this.satisfactionDisplay = stats.satisfactionPercent !== undefined && stats.satisfactionPercent !== null ?
        `${stats.satisfactionPercent}%` :
        '--';
      this.serviceHoursDisplay = this.formatHours(stats.serviceHoursTotal);
    } catch (err) {
      const error = err as Error;
      console.error('load volunteer profile failed:', error);

      if (this.shouldRedirectToLogin(error)) {
        await this.redirectToLogin();
        return;
      }

      promptAction.showToast({
        message: error.message ? error.message : '\u52a0\u8f7d\u4e2a\u4eba\u8d44\u6599\u5931\u8d25',
        duration: 1500
      });
    } finally {
      this.isLoading = false;
    }
  }

  handleMenuClick(item: MenuItem) {
    if (item.id === 'accessibility') {
      this.showAccessibility = !this.showAccessibility;
      return;
    }

    if (!item.path) {
      return;
    }

    router.pushUrl({
      url: item.path
    }).catch((err: Error) => {
      console.error('navigation failed:', err);
    });
  }

  openProfileEdit() {
    router.pushUrl({
      url: 'pages/volunteer/VolunteerProfileEditPage'
    }).catch((err: Error) => {
      console.error('navigation failed:', err);
    });
  }

  handleLogout() {
    if (this.isLoggingOut) {
      return;
    }

    promptAction.showDialog({
      title: '\u9000\u51fa\u767b\u5f55',
      message: '\u786e\u5b9a\u8981\u9000\u51fa\u767b\u5f55\u5417\uff1f',
      buttons: [
        { text: '\u53d6\u6d88', color: '#666666' },
        { text: '\u786e\u5b9a', color: '#dc2626' }
      ]
    }).then((result) => {
      if (result.index !== 1) {
        return;
      }

      this.isLoggingOut = true;
      AuthService.logout().then(() => {
        router.replaceUrl({
          url: 'pages/LoginPage'
        }).catch((err: Error) => {
          console.error('navigation failed:', err);
        });
      }).finally(() => {
        this.isLoggingOut = false;
      });
    });
  }

  private getAvatarText(): string {
    const trimmedName: string = this.userName.trim();
    if (!trimmedName) {
      return 'V';
    }
    return trimmedName.substring(0, 1);
  }

  private getMaskedPhone(): string {
    if (this.phone.length < 7) {
      return this.phone;
    }
    return this.phone.substring(0, 3) + '****' + this.phone.substring(this.phone.length - 4);
  }

  @Builder
  MenuItemBuilder(item: MenuItem) {
    Button() {
      Row({ space: 12 }) {
        Row() {
          Text(item.icon)
            .fontSize(this.largeFontEnabled ? 24 : 20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.highContrastEnabled ? '#000000' : '#10b981')
        }
        .width(44)
        .height(44)
        .linearGradient(this.highContrastEnabled ? undefined : {
          angle: 135,
          colors: [[0xecfdf5, 0.0], [0xd1fae5, 1.0]]
        })
        .backgroundColor(this.highContrastEnabled ? '#ffff00' : undefined)
        .borderRadius(12)
        .border(this.highContrastEnabled ? { width: 2, color: '#000000' } : undefined)
        .justifyContent(FlexAlign.Center)

        Text(item.label)
          .fontSize(this.largeFontEnabled ? 19 : 15)
          .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
          .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Start)

        Text('›')
          .fontSize(this.largeFontEnabled ? 32 : 28)
          .fontColor(this.highContrastEnabled ? '#000000' : '#cbd5e1')
          .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    }
    .width('100%')
    .backgroundColor('#ffffff')
    .borderRadius(0)
    .onClick(() => {
      this.handleMenuClick(item);
    })
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        NavBackButton()

        Text('\u4e2a\u4eba\u4e2d\u5fc3')
          .fontSize(this.largeFontEnabled ? 22 : 18)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
          .layoutWeight(1)
      }
      .width('100%')
      .padding(12)
      .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
      .border({
        width: { bottom: this.highContrastEnabled ? 3 : 1 },
        color: this.highContrastEnabled ? '#000000' : '#e5e7eb'
      })

      if (this.isLoading) {
        Column({ space: 12 }) {
          Text('\u52a0\u8f7d\u4e2a\u4eba\u8d44\u6599\u4e2d...')
            .fontSize(this.largeFontEnabled ? 20 : 16)
            .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column({ space: 12 }) {
            Column() {
              Row({ space: 16 }) {
                Row() {
                  Text(this.getAvatarText())
                    .fontSize(this.largeFontEnabled ? 40 : 34)
                    .fontColor('#ffffff')
                    .fontWeight(FontWeight.Bold)
                }
                .width(88)
                .height(88)
                .linearGradient({
                  angle: 135,
                  colors: this.highContrastEnabled
                    ? [[0x000000, 0.0], [0x333333, 1.0]]
                    : [[0x34d399, 0.0], [0x10b981, 0.5], [0x059669, 1.0]]
                })
                .borderRadius(44)
                .justifyContent(FlexAlign.Center)
                .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : { width: 4, color: '#ffffff' })
                .shadow(this.highContrastEnabled ? undefined : {
                  radius: 12,
                  color: '#10b98120',
                  offsetX: 0,
                  offsetY: 4
                })

                Column({ space: 6 }) {
                  Text(this.userName ? this.userName : '\u672a\u8bbe\u7f6e\u59d3\u540d')
                    .fontSize(this.largeFontEnabled ? 26 : 22)
                    .fontColor(this.highContrastEnabled ? '#000000' : '#111827')
                    .fontWeight(FontWeight.Bold)

                  Text(this.getMaskedPhone())
                    .fontSize(this.largeFontEnabled ? 17 : 14)
                    .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
                    .fontWeight(this.highContrastEnabled ? FontWeight.Medium : FontWeight.Normal)

                  Row() {
                    Text('\u5fd7\u613f\u8005')
                      .fontSize(this.largeFontEnabled ? 15 : 12)
                      .fontColor(this.highContrastEnabled ? '#000000' : '#065f46')
                      .fontWeight(FontWeight.Medium)
                  }
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#d1fae5')
                  .borderRadius(10)
                  .border(this.highContrastEnabled ? { width: 2, color: '#000000' } : undefined)
                  .margin({ top: 2 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              .padding(20)
            }
            .width('100%')
            .linearGradient(this.highContrastEnabled ? undefined : {
              angle: 180,
              colors: [[0xffffff, 0.0], [0xf0fdf4, 1.0]]
            })
            .backgroundColor(this.highContrastEnabled ? '#ffffff' : undefined)
            .borderRadius(16)
            .margin({ top: 4 })
            .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
            .shadow(this.highContrastEnabled ? undefined : {
              radius: 8,
              color: '#0f00001a',
              offsetX: 0,
              offsetY: 2
            })
            .onClick(() => {
              this.openProfileEdit();
            })

            Row({ space: 12 }) {
              ForEach(this.buildStats(), (item: StatCard) => {
                Column({ space: 8 }) {
                  Text(item.value)
                    .fontSize(this.largeFontEnabled ? 30 : 26)
                    .fontColor(this.highContrastEnabled ? '#000000' : item.color)
                    .fontWeight(FontWeight.Bold)
                  Text(item.label)
                    .fontSize(this.largeFontEnabled ? 15 : 12)
                    .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
                    .fontWeight(this.highContrastEnabled ? FontWeight.Medium : FontWeight.Normal)
                }
                .layoutWeight(1)
                .padding({ top: 18, bottom: 18, left: 12, right: 12 })
                .backgroundColor('#ffffff')
                .borderRadius(14)
                .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
                .shadow(this.highContrastEnabled ? undefined : {
                  radius: 6,
                  color: '#0f00001a',
                  offsetX: 0,
                  offsetY: 2
                })
              }, (item: StatCard) => `${item.label}-${item.value}`)
            }
            .width('100%')

            Column() {
              ForEach(this.menuItems, (item: MenuItem, index: number) => {
                Column() {
                  this.MenuItemBuilder(item)
                  if (index < this.menuItems.length - 1) {
                    Divider()
                      .color(this.highContrastEnabled ? '#000000' : '#f3f4f6')
                      .strokeWidth(this.highContrastEnabled ? 2 : 1)
                  }
                }
              }, (item: MenuItem) => item.id)
            }
            .width('100%')
            .backgroundColor('#ffffff')
            .borderRadius(16)
            .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
            .shadow(this.highContrastEnabled ? undefined : {
              radius: 4,
              color: '#0f00000a',
              offsetX: 0,
              offsetY: 2
            })

            if (this.showAccessibility) {
              AccessibilitySettingsBlock()
            }

            Button() {
              Row({ space: 10 }) {
                Text('\u21AA')
                  .fontSize(this.largeFontEnabled ? 22 : 18)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#dc2626')
                Text(this.isLoggingOut ? '\u9000\u51fa\u4e2d...' : '\u9000\u51fa\u767b\u5f55')
                  .fontSize(this.largeFontEnabled ? 18 : 16)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#dc2626')
                  .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)
              }
            }
            .width('100%')
            .height(56)
            .backgroundColor('#ffffff')
            .borderRadius(16)
            .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
            .enabled(!this.isLoggingOut)
            .onClick(() => {
              this.handleLogout();
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 12, right: 12, top: 8, bottom: 24 })
        }
        .layoutWeight(1)
        .align(Alignment.TopStart)
        .scrollBar(BarState.Off)
        .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#f9fafb')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.highContrastEnabled ? '#ffffff' : '#f9fafb')
  }
}
