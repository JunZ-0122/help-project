import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { AuthService } from '../../services/AuthService';
import { CommunityApi, UserApi } from '../../services/ApiService';
import { StorageUtil } from '../../utils/StorageUtil';
import { AccessibilitySettingsBlock } from '../../components/AccessibilitySettingsBlock';
import { ElderHighContrastTheme } from '../../utils/AccessibilityTheme';
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
  @State isLoading: boolean = false;
  @State isLoggingOut: boolean = false;

  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;
  @State serviceCountDisplay: string = '--';
  @State pendingDisplay: string = '--';
  @State completionRateDisplay: string = '--';

  private menuItems: MenuItem[] = [
    { id: 'manage', icon: '📋', label: '求助管理', path: 'pages/community/ManagePage' },
    { id: 'statistics', icon: '📊', label: '数据统计', path: 'pages/community/StatisticsPage' },
    { id: 'switch', icon: '🔄', label: '身份切换', path: 'pages/RoleSelectPage' },
    { id: 'accessibility', icon: '♿', label: '无障碍设置' }
  ];
  private skipNextPageShow: boolean = true;

  async aboutToAppear() {
    this.loadProfileData();
  }

  onPageShow() {
    if (this.skipNextPageShow) {
      this.skipNextPageShow = false;
      return;
    }
    this.loadProfileData();
  }

  private shouldRedirectToLogin(error: Error): boolean {
    return error.message.indexOf('登录') >= 0
      && error.message.indexOf('重新登录') >= 0;
  }

  private async redirectToLogin(): Promise<void> {
    await AuthService.logout();
    router.replaceUrl({
      url: 'pages/LoginPage'
    }).catch((err: Error) => {
      console.error('navigation failed:', err);
    });
  }

  private async loadProfileData(): Promise<void> {
    this.isLoading = true;

    try {
      const profile: UserProfile = await UserApi.getCurrentProfile();
      const statistics = await CommunityApi.getStatistics();
      await StorageUtil.set('user', profile);

      this.userName = profile.name ? profile.name : '';
      this.phone = profile.phone ? profile.phone : '';
      this.serviceCountDisplay = `${statistics.totalRequests}`;
      this.pendingDisplay = `${statistics.pendingRequests}`;
      this.completionRateDisplay = statistics.totalRequests > 0
        ? `${Math.round((statistics.completedRequests * 100) / statistics.totalRequests)}%`
        : '--';
    } catch (err) {
      const error = err as Error;
      console.error('load community profile failed:', error);

      if (this.shouldRedirectToLogin(error)) {
        await this.redirectToLogin();
        return;
      }

      promptAction.showToast({
        message: error.message ? error.message : '加载个人资料失败',
        duration: 1500
      });
    } finally {
      this.isLoading = false;
    }
  }

  private handleMenuClick(item: MenuItem) {
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

  private openProfileEdit(): void {
    router.pushUrl({
      url: 'pages/community/CommunityProfileEditPage'
    }).catch((err: Error) => {
      console.error('navigation failed:', err);
    });
  }

  private handleLogout() {
    if (this.isLoggingOut) {
      return;
    }

    promptAction.showDialog({
      title: '退出登录',
      message: '确定要退出登录吗？',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '确定', color: '#dc2626' }
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
      return 'C';
    }
    return trimmedName.substring(0, 1);
  }

  private getMaskedPhone(): string {
    if (this.phone.length < 7) {
      return this.phone;
    }
    return this.phone.substring(0, 3) + '****' + this.phone.substring(this.phone.length - 4);
  }

  private buildStats(): StatCard[] {
    return [
      { value: this.serviceCountDisplay, label: '累计工单', color: '#6366f1' },
      { value: this.pendingDisplay, label: '待处理', color: '#f59e0b' },
      { value: this.completionRateDisplay, label: '完成率', color: '#10b981' }
    ];
  }

  private hcRolePalette() {
    return ElderHighContrastTheme.getRolePalette('community');
  }

  private hcPageBg(): string {
    return this.highContrastEnabled ? ElderHighContrastTheme.pageBg : '#f9fafb';
  }

  private hcCardBg(): string {
    return this.highContrastEnabled ? ElderHighContrastTheme.surface : '#ffffff';
  }

  private hcCardBorder(): BorderOptions | undefined {
    return this.highContrastEnabled ? ElderHighContrastTheme.cardBorder() : undefined;
  }

  @Builder
  MenuItemBuilder(item: MenuItem) {
    Button() {
      Row({ space: 12 }) {
        Text(item.icon)
          .fontSize(this.largeFontEnabled ? 28 : 24)
          .fontColor(this.highContrastEnabled ? this.hcRolePalette().iconAccent : undefined)

        Text(item.label)
          .fontSize(this.largeFontEnabled ? 19 : 15)
          .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#1a1a1a')
          .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Start)

        Text('›')
          .fontSize(this.largeFontEnabled ? 32 : 28)
          .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textTertiary : '#cbd5e1')
          .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    }
    .width('100%')
    .backgroundColor(this.hcCardBg())
    .borderRadius(0)
    .onClick(() => {
      this.handleMenuClick(item);
    })
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        NavBackButton()

        Text('个人中心')
          .fontSize(this.largeFontEnabled ? 22 : 18)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#1a1a1a')
          .layoutWeight(1)
      }
      .width('100%')
      .padding(12)
      .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.headerSurface : '#ffffff')
      .border({
        width: { bottom: this.highContrastEnabled ? 2 : 1 },
        color: this.highContrastEnabled ? ElderHighContrastTheme.borderStrong : '#e5e7eb'
      })

      if (this.isLoading) {
        Column({ space: 12 }) {
          Text('加载个人资料中...')
            .fontSize(this.largeFontEnabled ? 20 : 16)
            .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textSecondary : '#6b7280')
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
                    : [[0x818cf8, 0.0], [0x6366f1, 0.5], [0x4f46e5, 1.0]]
                })
                .backgroundColor(this.highContrastEnabled ? this.hcRolePalette().avatarBg : undefined)
                .borderRadius(44)
                .justifyContent(FlexAlign.Center)
                .border(this.highContrastEnabled ? ElderHighContrastTheme.cardBorder() : { width: 4, color: '#ffffff' })
                .shadow(this.highContrastEnabled ? undefined : {
                  radius: 12,
                  color: '#6366f120',
                  offsetX: 0,
                  offsetY: 4
                })

                Column({ space: 6 }) {
                  Text(this.userName ? this.userName : '未设置姓名')
                    .fontSize(this.largeFontEnabled ? 26 : 22)
                    .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#111827')
                    .fontWeight(FontWeight.Bold)

                  Text(this.getMaskedPhone())
                    .fontSize(this.largeFontEnabled ? 17 : 14)
                    .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textSecondary : '#6b7280')
                    .fontWeight(this.highContrastEnabled ? FontWeight.Medium : FontWeight.Normal)

                  Row() {
                    Text('社区管理员')
                      .fontSize(this.largeFontEnabled ? 15 : 12)
                      .fontColor(this.highContrastEnabled ? this.hcRolePalette().tagText : '#4338ca')
                      .fontWeight(FontWeight.Medium)
                  }
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .backgroundColor(this.highContrastEnabled ? this.hcRolePalette().tagBg : '#e0e7ff')
                  .borderRadius(10)
                  .border(this.highContrastEnabled ? ElderHighContrastTheme.subtleBorder() : undefined)
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
              colors: [[0xffffff, 0.0], [0xf5f3ff, 1.0]]
            })
            .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.surface : undefined)
            .borderRadius(16)
            .margin({ top: 0 })
            .border(this.hcCardBorder())
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
                Column({ space: 6 }) {
                  Text(item.value)
                    .fontSize(this.largeFontEnabled ? 28 : 24)
                    .fontColor(this.highContrastEnabled ? this.hcRolePalette().statAccent : item.color)
                    .fontWeight(FontWeight.Bold)
                  Text(item.label)
                    .fontSize(this.largeFontEnabled ? 15 : 12)
                    .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textSecondary : '#6b7280')
                }
                .layoutWeight(1)
                .padding({ left: 10, right: 10, top: 14, bottom: 14 })
                .backgroundColor(this.hcCardBg())
                .borderRadius(14)
                .border(this.hcCardBorder())
              }, (item: StatCard) => `${item.label}-${item.value}`)
            }
            .width('100%')

            Column() {
              ForEach(this.menuItems, (item: MenuItem, index: number) => {
                Column() {
                  this.MenuItemBuilder(item)
                  if (index < this.menuItems.length - 1) {
                    Divider()
                      .color(this.highContrastEnabled ? ElderHighContrastTheme.divider : '#f3f4f6')
                      .strokeWidth(1)
                  }
                }
              }, (item: MenuItem) => item.id)
            }
            .width('100%')
            .backgroundColor(this.hcCardBg())
            .borderRadius(16)
            .border(this.hcCardBorder())
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
              Row({ space: 8 }) {
                Text('🚪')
                  .fontSize(this.largeFontEnabled ? 28 : 24)
                Text(this.isLoggingOut ? '退出中...' : '退出登录')
                  .fontSize(this.largeFontEnabled ? 20 : 16)
                  .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.accentDanger : '#dc2626')
                  .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
              }
            }
            .width('100%')
            .height(56)
            .backgroundColor(this.hcCardBg())
            .borderRadius(16)
            .border(this.hcCardBorder())
            .enabled(!this.isLoggingOut)
            .onClick(() => {
              this.handleLogout();
            })
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 0, bottom: 24 })
        }
        .layoutWeight(1)
        .align(Alignment.TopStart)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.hcPageBg())
  }
}
