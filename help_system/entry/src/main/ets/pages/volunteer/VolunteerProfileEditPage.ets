import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { AuthService } from '../../services/AuthService';
import { UserApi } from '../../services/ApiService';
import { StorageUtil } from '../../utils/StorageUtil';
import type { UserProfile } from '../../models';

@Entry
@Component
struct VolunteerProfileEditPage {
  @State userName: string = '';
  @State phone: string = '';
  @State address: string = '';
  @State emergencyContact: string = '';
  @State emergencyPhone: string = '';
  @State isLoading: boolean = false;
  @State isSaving: boolean = false;

  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  aboutToAppear() {
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
    router.replaceUrl({ url: 'pages/LoginPage' }).catch((err: Error) => {
      console.error('navigation failed:', err);
    });
  }

  private async loadProfileData(): Promise<void> {
    this.isLoading = true;
    try {
      const profile: UserProfile = await UserApi.getCurrentProfile();
      await StorageUtil.set('user', profile);
      this.userName = profile.name ? profile.name : '';
      this.phone = profile.phone ? profile.phone : '';
      this.address = profile.address ? profile.address : '';
      this.emergencyContact = profile.emergencyContact ? profile.emergencyContact : '';
      this.emergencyPhone = profile.emergencyPhone ? profile.emergencyPhone : '';
    } catch (err) {
      const error = err as Error;
      if (this.shouldRedirectToLogin(error)) {
        await this.redirectToLogin();
        return;
      }
      promptAction.showToast({
        message: error.message ? error.message : '\u52a0\u8f7d\u5931\u8d25',
        duration: 1500
      });
    } finally {
      this.isLoading = false;
    }
  }

  async saveProfile(): Promise<void> {
    const trimmedName: string = this.userName.trim();
    const trimmedAddress: string = this.address.trim();
    const trimmedEmergencyContact: string = this.emergencyContact.trim();
    const trimmedEmergencyPhone: string = this.emergencyPhone.trim();

    if (!trimmedName) {
      promptAction.showToast({ message: '\u8bf7\u586b\u5199\u59d3\u540d', duration: 1500 });
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
    try {
      const updatedProfile: UserProfile = await UserApi.updateUserProfile({
        name: trimmedName,
        address: trimmedAddress,
        emergencyContact: trimmedEmergencyContact,
        emergencyPhone: trimmedEmergencyPhone
      });
      await StorageUtil.set('user', updatedProfile);
      promptAction.showToast({ message: '\u5df2\u4fdd\u5b58', duration: 1500 });
      router.back();
    } catch (err) {
      const error = err as Error;
      if (this.shouldRedirectToLogin(error)) {
        await this.redirectToLogin();
        return;
      }
      promptAction.showToast({
        message: error.message ? error.message : '\u4fdd\u5b58\u5931\u8d25',
        duration: 1500
      });
    } finally {
      this.isSaving = false;
    }
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

        Text('\u7f16\u8f91\u8d44\u6599')
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
          Text('\u52a0\u8f7d\u4e2d...')
            .fontSize(this.largeFontEnabled ? 18 : 15)
            .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 16 }) {
            Column({ space: 8 }) {
              this.FormLabel('\u59d3\u540d')
              TextInput({ placeholder: '\u8bf7\u8f93\u5165\u59d3\u540d', text: this.userName })
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
              TextInput({ placeholder: '', text: this.phone })
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

            Button(this.isSaving ? '\u4fdd\u5b58\u4e2d...' : '\u4fdd\u5b58')
              .width('100%')
              .height(this.largeFontEnabled ? 56 : 48)
              .fontSize(this.largeFontEnabled ? 18 : 16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#ffffff')
              .backgroundColor(this.highContrastEnabled ? '#000000' : '#10b981')
              .borderRadius(12)
              .enabled(!this.isSaving)
              .onClick(() => {
                this.saveProfile();
              })
          }
          .width('100%')
          .padding(16)
        }
        .layoutWeight(1)
        .align(Alignment.TopStart)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.highContrastEnabled ? '#ffffff' : '#f9fafb')
  }
}
