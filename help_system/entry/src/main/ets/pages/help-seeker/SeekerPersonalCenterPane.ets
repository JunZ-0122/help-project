import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { AccessibilityManager } from '../../utils/AccessibilityManager';
import { ElderHighContrastTheme } from '../../utils/AccessibilityTheme';
import { AuthService } from '../../services/AuthService';
import { UserApi } from '../../services/ApiService';
import { StorageUtil } from '../../utils/StorageUtil';
import { AccessibilitySettingsBlock } from '../../components/AccessibilitySettingsBlock';
import type { UserProfile } from '../../models';

interface MenuItem {
  id: string;
  icon: string;
  label: string;
  path?: string;
}

/**
 * 求助者个人中心主体（头像/菜单/无障碍/退出），供首页 Tab 与独立 ProfilePage 复用。
 */
@Component
export struct SeekerPersonalCenterPane {
  /** 父组件递增即可触发重新拉取资料（首页 Tab 切换、独立页返回等） */
  @Prop @Watch('onRefreshSig') refreshSig: number = 0;

  @State showAccessibility: boolean = false;
  @State userName: string = '';
  @State phone: string = '';
  @State userTag: string = '求助者';
  @State isLoggingOut: boolean = false;

  /**
   * 与 AppStorage 绑定。父级 HelpSeekerHomePage 同样 @StorageLink 无障碍开关，切换后会整树重绘；
   * 若此处用 @State，子组件重建时初值会回到 false，界面会「刚亮又暗」。@StorageLink 与全局一致。
   */
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  private accessibilityManager = AccessibilityManager.getInstance();
  /** 避免 aboutToAppear 与 onRefreshSig 叠在一起时并发拉取资料 */
  private profileLoadInFlight: boolean = false;

  private menuItems: MenuItem[] = [
    { id: 'requests', icon: '📄', label: '我的求助记录', path: 'pages/help-seeker/MyRequestsPage' },
    { id: 'switch', icon: '⇄', label: '身份切换', path: 'pages/RoleSelectPage' },
    { id: 'accessibility', icon: '⚙', label: '无障碍设置' }
  ];

  /**
   * 老年人友好高对比：暖米底 + 白卡片 + 深灰字 + 深色描边（减轻眩光，区域清晰）
   */
  private hcPageBg(): string {
    return this.highContrastEnabled ? ElderHighContrastTheme.pageBg : '#f3f4f6';
  }

  private hcCardBg(): string {
    return this.highContrastEnabled ? ElderHighContrastTheme.surface : '#ffffff';
  }

  private hcTextMain(): string {
    return this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#111827';
  }

  private hcTextMuted(): string {
    return this.highContrastEnabled ? ElderHighContrastTheme.textSecondary : '#4b5563';
  }

  private hcMenuIconBg(): string {
    return this.highContrastEnabled ? ElderHighContrastTheme.iconBoxBg : '#f3f4f6';
  }

  private hcDivider(): string {
    return this.highContrastEnabled ? ElderHighContrastTheme.divider : '#f3f4f6';
  }

  private hcCardBorder(): BorderOptions | undefined {
    return this.highContrastEnabled ? ElderHighContrastTheme.cardBorder() : undefined;
  }

  async aboutToAppear() {
    await this.accessibilityManager.initDone;
    // 首次进入：@Watch 在 refreshSig 未变化时可能不触发
    this.loadProfile();
  }

  onRefreshSig(): void {
    this.loadProfile();
  }

  private shouldRedirectToLogin(error: Error): boolean {
    return error.message.indexOf('登录') >= 0 && error.message.indexOf('重新登录') >= 0;
  }

  private async redirectToLogin(): Promise<void> {
    await AuthService.logout();
    router.replaceUrl({
      url: 'pages/LoginPage'
    }).catch((err: Error) => {
      console.error('navigation failed:', err);
    });
  }

  private resolveTag(profile: UserProfile): string {
    if (profile.disabilities && profile.disabilities.length > 0) {
      return profile.disabilities[0];
    }
    return '弱势群体';
  }

  /**
   * 拉取个人资料。不使用全屏 Loading：
   * 父页 HelpSeekerHomePage 使用 @StorageLink 无障碍开关，切换时会整树重绘，
   * 若此处 isLoading=true 会整页换成「加载中」，与高对比度切换叠在一起产生明显闪烁。
   */
  async loadProfile(): Promise<void> {
    if (this.profileLoadInFlight) {
      return;
    }
    this.profileLoadInFlight = true;
    try {
      const profile: UserProfile = await UserApi.getCurrentProfile();
      await StorageUtil.set('user', profile);
      this.userName = profile.name ? profile.name : '';
      this.phone = profile.phone ? profile.phone : '';
      this.userTag = this.resolveTag(profile);
    } catch (err) {
      const error = err as Error;
      console.error('load profile failed:', error);
      if (this.shouldRedirectToLogin(error)) {
        await this.redirectToLogin();
        return;
      }
      promptAction.showToast({
        message: error.message ? error.message : '加载个人资料失败',
        duration: 1500
      });
    } finally {
      this.profileLoadInFlight = false;
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
    router.pushUrl({ url: item.path }).catch((err: Error) => {
      console.error('navigation failed:', err);
    });
  }

  handleLogout() {
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
        router.replaceUrl({ url: 'pages/LoginPage' }).catch((err: Error) => {
          console.error('navigation failed:', err);
        });
      }).finally(() => {
        this.isLoggingOut = false;
      });
    });
  }

  private getAvatarText(): string {
    const n = this.userName.trim();
    if (!n) {
      return 'U';
    }
    return n.substring(0, 1);
  }

  private getMaskedPhone(): string {
    if (!this.phone || this.phone.length < 7) {
      return this.phone ? this.phone : '--';
    }
    return this.phone.substring(0, 3) + '****' + this.phone.substring(this.phone.length - 4);
  }

  @Builder
  MenuItemBuilder(item: MenuItem, isLast: boolean) {
    Column() {
      Button() {
        Row({ space: 12 }) {
          Row() {
            Text(item.icon)
              .fontSize(this.largeFontEnabled ? 20 : 17)
          }
          .width(36)
          .height(36)
          .backgroundColor(this.hcMenuIconBg())
          .borderRadius(10)
          .justifyContent(FlexAlign.Center)
          .border(this.highContrastEnabled ? { width: 1, color: ElderHighContrastTheme.borderStrong } : undefined)

          Text(item.label)
            .fontSize(this.largeFontEnabled ? 20 : 16)
            .fontColor(this.hcTextMain())
            .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)
            .layoutWeight(1)
            .textAlign(TextAlign.Start)

          Text('›')
            .fontSize(this.largeFontEnabled ? 28 : 24)
            .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textTertiary : '#9ca3af')
        }
        .width('100%')
        .padding(this.highContrastEnabled
          ? { left: 16, right: 16, top: 18, bottom: 18 }
          : { left: 14, right: 14, top: 16, bottom: 16 })
      }
      .width('100%')
      .backgroundColor(this.hcCardBg())
      .borderRadius(0)
      .stateEffect(!this.highContrastEnabled)
      .onClick(() => {
        this.handleMenuClick(item);
      })

      if (!isLast) {
        Divider()
          .strokeWidth(this.highContrastEnabled ? 1 : 1)
          .color(this.hcDivider())
      }
    }
  }

  build() {
    Column() {
      Scroll() {
          Column({ space: 12 }) {
            Row({ space: 14 }) {
              Row() {
                Text(this.getAvatarText())
                  .fontSize(this.largeFontEnabled ? 34 : 30)
                  .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.avatarText : '#ffffff')
                  .fontWeight(FontWeight.Bold)
              }
              .width(84)
              .height(84)
              .linearGradient(this.highContrastEnabled ? undefined : {
                angle: 135,
                colors: [[0x60a5fa, 0.0], [0x3b82f6, 0.6], [0x2563eb, 1.0]]
              })
              .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.avatarBg : undefined)
              .borderRadius(42)
              .justifyContent(FlexAlign.Center)
              .border(this.highContrastEnabled ? { width: 2, color: ElderHighContrastTheme.borderStrong } : undefined)

              Column({ space: 6 }) {
                Text(this.userName ? this.userName : '未设置姓名')
                  .fontSize(this.largeFontEnabled ? 28 : 24)
                  .fontColor(this.hcTextMain())
                  .fontWeight(FontWeight.Bold)
                Text(this.getMaskedPhone())
                  .fontSize(this.largeFontEnabled ? 18 : 15)
                  .fontColor(this.hcTextMuted())
                Text(this.userTag)
                  .fontSize(this.largeFontEnabled ? 15 : 12)
                  .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.tagText : '#1d4ed8')
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.tagBg : '#dbeafe')
                  .borderRadius(99)
                  .border(this.highContrastEnabled ? ElderHighContrastTheme.subtleBorder() : undefined)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')
            .padding(this.highContrastEnabled ? 18 : 16)
            .backgroundColor(this.hcCardBg())
            .borderRadius(16)
            .border(this.hcCardBorder())

            Column() {
              ForEach(this.menuItems, (item: MenuItem, index: number) => {
                this.MenuItemBuilder(item, index === this.menuItems.length - 1);
              }, (item: MenuItem) => item.id)
            }
            .width('100%')
            .backgroundColor(this.hcCardBg())
            .borderRadius(16)
            .border(this.hcCardBorder())

            if (this.showAccessibility) {
              AccessibilitySettingsBlock()
            }

            Button() {
              Row({ space: 8 }) {
                Text('↪')
                  .fontSize(this.largeFontEnabled ? 22 : 18)
                  .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.accentDanger : '#ef4444')
                Text(this.isLoggingOut ? '退出中...' : '退出登录')
                  .fontSize(this.largeFontEnabled ? 20 : 16)
                  .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.accentDanger : '#ef4444')
                  .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)
              }
            }
            .width('100%')
            .height(this.highContrastEnabled ? 60 : 56)
            .backgroundColor(this.hcCardBg())
            .borderRadius(16)
            .border(this.hcCardBorder())
            .enabled(!this.isLoggingOut)
            .stateEffect(!this.highContrastEnabled)
            .onClick(() => {
              this.handleLogout();
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
          .alignItems(HorizontalAlign.Start)
          .padding(this.highContrastEnabled
            ? { left: 14, right: 14, top: 10, bottom: 28 }
            : { left: 12, right: 12, top: 8, bottom: 24 })
        }
        .layoutWeight(1)
        .align(Alignment.TopStart)
        .scrollBar(BarState.Off)
    }
    .width('100%')
    .layoutWeight(1)
    .backgroundColor(this.hcPageBg())
  }
}
