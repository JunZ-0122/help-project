import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { AuthService } from '../../services/AuthService';
import { CommunityApi, UserApi } from '../../services/ApiService';
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
  @State address: string = '';
  @State emergencyContact: string = '';
  @State emergencyPhone: string = '';
  @State isLoading: boolean = false;
  @State isSaving: boolean = false;
  @State isLoggingOut: boolean = false;
  @State showProfileForm: boolean = false;

  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;
  @State serviceCountDisplay: string = '--';
  @State pendingDisplay: string = '--';
  @State completionRateDisplay: string = '--';

  private menuItems: MenuItem[] = [
    { id: 'edit', icon: '📝', label: '编辑个人资料' },
    { id: 'manage', icon: '📋', label: '求助管理', path: 'pages/community/ManagePage' },
    { id: 'statistics', icon: '📊', label: '数据统计', path: 'pages/community/StatisticsPage' },
    { id: 'switch', icon: '🔄', label: '\u8eab\u4efd\u5207\u6362', path: 'pages/RoleSelectPage' },
    { id: 'accessibility', icon: '♿', label: '\u65e0\u969c\u788d\u8bbe\u7f6e' }
  ];

  async aboutToAppear() {
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

  private async loadProfileData(): Promise<void> {
    this.isLoading = true;

    try {
      const profile: UserProfile = await UserApi.getCurrentProfile();
      const statistics = await CommunityApi.getStatistics();
      await StorageUtil.set('user', profile);

      this.userName = profile.name ? profile.name : '';
      this.phone = profile.phone ? profile.phone : '';
      this.address = profile.address ? profile.address : '';
      this.emergencyContact = profile.emergencyContact ? profile.emergencyContact : '';
      this.emergencyPhone = profile.emergencyPhone ? profile.emergencyPhone : '';
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
        message: error.message ? error.message : '\u52a0\u8f7d\u4e2a\u4eba\u8d44\u6599\u5931\u8d25',
        duration: 1500
      });
    } finally {
      this.isLoading = false;
    }
  }

  handleMenuClick(item: MenuItem) {
    if (item.id === 'edit') {
      this.showProfileForm = !this.showProfileForm;
      return;
    }

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

  saveProfile() {
    const trimmedName: string = this.userName.trim();
    const trimmedAddress: string = this.address.trim();
    const trimmedEmergencyContact: string = this.emergencyContact.trim();
    const trimmedEmergencyPhone: string = this.emergencyPhone.trim();

    if (!trimmedName) {
      promptAction.showToast({
        message: '\u8bf7\u586b\u5199\u59d3\u540d',
        duration: 1500
      });
      return;
    }

    if (trimmedEmergencyPhone && trimmedEmergencyPhone.length < 7) {
      promptAction.showToast({
        message: '\u7d27\u6025\u8054\u7cfb\u7535\u8bdd\u683c\u5f0f\u4e0d\u6b63\u786e',
        duration: 1500
      });
      return;
    }

    this.isSaving = true;

    UserApi.updateUserProfile({
      name: trimmedName,
      address: trimmedAddress,
      emergencyContact: trimmedEmergencyContact,
      emergencyPhone: trimmedEmergencyPhone
    }).then((updatedProfile: UserProfile) => {
      // 更新页面状态
      this.userName = updatedProfile.name ? updatedProfile.name : trimmedName;
      this.phone = updatedProfile.phone ? updatedProfile.phone : this.phone;
      this.address = updatedProfile.address ? updatedProfile.address : trimmedAddress;
      this.emergencyContact = updatedProfile.emergencyContact
        ? updatedProfile.emergencyContact
        : trimmedEmergencyContact;
      this.emergencyPhone = updatedProfile.emergencyPhone
        ? updatedProfile.emergencyPhone
        : trimmedEmergencyPhone;

      // 保存到本地存储（预览器中不工作，但真机需要）
      StorageUtil.set('user', updatedProfile);
      
      // 注意：在预览器中，Toast 可能因 UI 上下文丢失而失败
      // 但数据已成功保存到后端，页面状态也已更新
      console.info('[ProfilePage] 个人资料保存成功');
    }).catch((err: Error) => {
      const error = err as Error;
      console.error('save community profile failed:', error);

      if (this.shouldRedirectToLogin(error)) {
        this.redirectToLogin();
        return;
      }

      // 错误提示（预览器中可能失败）
      console.error('[ProfilePage] 保存失败:', error.message);
    }).finally(() => {
      this.isSaving = false;
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

  @Builder
  MenuItemBuilder(item: MenuItem) {
    Button() {
      Row({ space: 12 }) {
        // 直接显示 emoji 图标
        Text(item.icon)
          .fontSize(this.largeFontEnabled ? 28 : 24)

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

  @Builder
  FormLabel(label: string) {
    Text(label)
      .fontSize(this.largeFontEnabled ? 17.5 : 14)
      .fontColor(this.highContrastEnabled ? '#000000' : '#374151')
      .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)
      .alignSelf(ItemAlign.Start)
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
                    : [[0x818cf8, 0.0], [0x6366f1, 0.5], [0x4f46e5, 1.0]]
                })
                .borderRadius(44)
                .justifyContent(FlexAlign.Center)
                .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : { width: 4, color: '#ffffff' })
                .shadow(this.highContrastEnabled ? undefined : {
                  radius: 12,
                  color: '#6366f120',
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
                    Text('\u793e\u533a\u7ba1\u7406\u5458')
                      .fontSize(this.largeFontEnabled ? 15 : 12)
                      .fontColor(this.highContrastEnabled ? '#000000' : '#4338ca')
                      .fontWeight(FontWeight.Medium)
                  }
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#e0e7ff')
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
              colors: [[0xffffff, 0.0], [0xf5f3ff, 1.0]]
            })
            .backgroundColor(this.highContrastEnabled ? '#ffffff' : undefined)
            .borderRadius(16)
            .margin({ top: 0 })
            .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
            .shadow(this.highContrastEnabled ? undefined : {
              radius: 8,
              color: '#0f00001a',
              offsetX: 0,
              offsetY: 2
            })

            Row({ space: 12 }) {
              ForEach(this.buildStats(), (item: StatCard) => {
                Column({ space: 6 }) {
                  Text(item.value)
                    .fontSize(this.largeFontEnabled ? 28 : 24)
                    .fontColor(this.highContrastEnabled ? '#000000' : item.color)
                    .fontWeight(FontWeight.Bold)
                  Text(item.label)
                    .fontSize(this.largeFontEnabled ? 15 : 12)
                    .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
                }
                .layoutWeight(1)
                .padding({ left: 10, right: 10, top: 14, bottom: 14 })
                .backgroundColor('#ffffff')
                .borderRadius(14)
                .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
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
              })
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

            if (this.showProfileForm) {
              Column({ space: 16 }) {
              Text('\u57fa\u7840\u8d44\u6599')
                .fontSize(this.largeFontEnabled ? 20 : 16)
                .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
                .fontWeight(FontWeight.Bold)
                .alignSelf(ItemAlign.Start)

              Column({ space: 8 }) {
                this.FormLabel('\u59d3\u540d')
                TextInput({
                  placeholder: '\u8bf7\u8f93\u5165\u59d3\u540d',
                  text: this.userName
                })
                  .width('100%')
                  .height(this.largeFontEnabled ? 56 : 48)
                  .fontSize(this.largeFontEnabled ? 18 : 15)
                  .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#f9fafb')
                  .borderRadius(10)
                  .border({
                    width: this.highContrastEnabled ? 3 : 1.5,
                    color: this.highContrastEnabled ? '#000000' : '#e5e7eb'
                  })
                  .padding({ left: 14, right: 14 })
                  .onChange((value: string) => {
                    this.userName = value;
                  })
              }
              .width('100%')

              Column({ space: 8 }) {
                this.FormLabel('\u624b\u673a\u53f7')
                TextInput({
                  placeholder: '',
                  text: this.phone
                })
                  .width('100%')
                  .height(this.largeFontEnabled ? 56 : 48)
                  .fontSize(this.largeFontEnabled ? 18 : 15)
                  .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#f3f4f6')
                  .borderRadius(10)
                  .border({
                    width: this.highContrastEnabled ? 3 : 1.5,
                    color: this.highContrastEnabled ? '#000000' : '#e5e7eb'
                  })
                  .padding({ left: 14, right: 14 })
                  .enabled(false)
              }
              .width('100%')

              Column({ space: 8 }) {
                this.FormLabel('\u5e38\u4f4f\u5730\u5740')
                TextInput({
                  placeholder: '\u8bf7\u8f93\u5165\u5e38\u7528\u5730\u5740',
                  text: this.address
                })
                  .width('100%')
                  .height(this.largeFontEnabled ? 56 : 48)
                  .fontSize(this.largeFontEnabled ? 18 : 15)
                  .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#f9fafb')
                  .borderRadius(10)
                  .border({
                    width: this.highContrastEnabled ? 3 : 1.5,
                    color: this.highContrastEnabled ? '#000000' : '#e5e7eb'
                  })
                  .padding({ left: 14, right: 14 })
                  .onChange((value: string) => {
                    this.address = value;
                  })
              }
              .width('100%')

              Column({ space: 8 }) {
                this.FormLabel('\u7d27\u6025\u8054\u7cfb\u4eba')
                TextInput({
                  placeholder: '\u8bf7\u8f93\u5165\u7d27\u6025\u8054\u7cfb\u4eba',
                  text: this.emergencyContact
                })
                  .width('100%')
                  .height(this.largeFontEnabled ? 56 : 48)
                  .fontSize(this.largeFontEnabled ? 18 : 15)
                  .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#f9fafb')
                  .borderRadius(10)
                  .border({
                    width: this.highContrastEnabled ? 3 : 1.5,
                    color: this.highContrastEnabled ? '#000000' : '#e5e7eb'
                  })
                  .padding({ left: 14, right: 14 })
                  .onChange((value: string) => {
                    this.emergencyContact = value;
                  })
              }
              .width('100%')

              Column({ space: 8 }) {
                this.FormLabel('\u7d27\u6025\u8054\u7cfb\u7535\u8bdd')
                TextInput({
                  placeholder: '\u8bf7\u8f93\u5165\u7d27\u6025\u8054\u7cfb\u7535\u8bdd',
                  text: this.emergencyPhone
                })
                  .width('100%')
                  .height(this.largeFontEnabled ? 56 : 48)
                  .fontSize(this.largeFontEnabled ? 18 : 15)
                  .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#f9fafb')
                  .borderRadius(10)
                  .border({
                    width: this.highContrastEnabled ? 3 : 1.5,
                    color: this.highContrastEnabled ? '#000000' : '#e5e7eb'
                  })
                  .padding({ left: 14, right: 14 })
                  .type(InputType.PhoneNumber)
                  .onChange((value: string) => {
                    this.emergencyPhone = value;
                  })
              }
              .width('100%')

              Button(this.isSaving ? '\u4fdd\u5b58\u4e2d...' : '\u4fdd\u5b58\u8d44\u6599')
                .width('100%')
                .height(this.largeFontEnabled ? 60 : 52)
                .fontSize(this.largeFontEnabled ? 20 : 17)
                .fontWeight(FontWeight.Bold)
                .fontColor('#ffffff')
                .linearGradient(this.highContrastEnabled ? undefined : {
                  angle: 135,
                  colors: [[0x60a5fa, 0.0], [0x3b82f6, 1.0]]
                })
                .backgroundColor(this.highContrastEnabled ? '#000000' : undefined)
                .borderRadius(12)
                .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
                .shadow(this.highContrastEnabled ? undefined : {
                  radius: 8,
                  color: '#3b82f640',
                  offsetX: 0,
                  offsetY: 4
                })
                .enabled(!this.isSaving)
                .onClick(() => {
                  this.saveProfile();
                })
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#ffffff')
              .borderRadius(16)
              .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
              .shadow(this.highContrastEnabled ? undefined : {
                radius: 4,
                color: '#0f00000a',
                offsetX: 0,
                offsetY: 2
              })
            }

            Button() {
              Row({ space: 8 }) {
                Text('🚪')
                  .fontSize(this.largeFontEnabled ? 28 : 24)
                Text(this.isLoggingOut ? '\u9000\u51fa\u4e2d...' : '\u9000\u51fa\u767b\u5f55')
                  .fontSize(this.largeFontEnabled ? 20 : 16)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#dc2626')
                  .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
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
          .padding({ left: 12, right: 12, top: 0, bottom: 24 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.highContrastEnabled ? '#ffffff' : '#f9fafb')
  }
}
