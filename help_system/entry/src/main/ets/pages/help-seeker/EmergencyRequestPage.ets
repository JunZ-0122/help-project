import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { EmergencyApi, GeocodeApi, type CreateEmergencyRequestPayload } from '../../services/ApiService';
import { getCurrentPosition, requestLocationPermission } from '../../utils/LocationUtil';
import { StorageUtil } from '../../utils/StorageUtil';
import { ElderHighContrastTheme } from '../../utils/AccessibilityTheme';
import type { UserProfile } from '../../models/User';

type EmergencyTypeId = 'medical' | 'safety' | 'accident' | 'other';

interface CreatedRequestRouteParams {
  createdId: string;
}

const DESC_MAX = 500;

@Entry
@Component
struct EmergencyRequestPage {
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  /** 后端必填；界面按设计稿不展示类型选择，默认「其他紧急」 */
  @State selectedType: EmergencyTypeId = 'other';
  @State description: string = '';
  @State location: string = '';
  @State contactPhone: string = '';
  @State isSubmitting: boolean = false;
  @State createdRequestId: string = '';
  @State @Watch('onSubmitSuccess') submitSuccessful: boolean = false;
  @State @Watch('onSubmitError') submitErrorMessage: string = '';
  @State shouldRedirectToLogin: boolean = false;
  @State isLocating: boolean = false;
  @State locationReady: boolean = false;
  @State lastLatitude: number = 0;
  @State lastLongitude: number = 0;
  @State hasGeoCoordinates: boolean = false;

  aboutToAppear() {
    this.loadDefaultContactPhone();
    this.fetchCurrentLocation();
  }

  private canSubmit(): boolean {
    return this.description.trim().length > 0 &&
      this.location.trim().length > 0 &&
      this.contactPhone.trim().length > 0 &&
      !this.isSubmitting;
  }

  private onDescriptionChange(value: string): void {
    if (value.length > DESC_MAX) {
      this.description = value.substring(0, DESC_MAX);
    } else {
      this.description = value;
    }
  }

  async loadDefaultContactPhone(): Promise<void> {
    try {
      const user: UserProfile | null = await StorageUtil.get<UserProfile>('user');
      if (user && user.phone && !this.contactPhone) {
        this.contactPhone = user.phone;
      }
    } catch (err) {
      console.error('load default phone failed:', err);
    }
  }

  async fetchCurrentLocation(): Promise<void> {
    if (this.isLocating) {
      return;
    }
    this.isLocating = true;
    this.locationReady = false;
    try {
      const granted = await requestLocationPermission();
      if (!granted) {
        promptAction.showToast({
          message: '\u8bf7\u5728\u5f39\u6846\u4e2d\u5141\u8bb8\u5b9a\u4f4d\u6743\u9650\uff0c\u6216\u524d\u5f80\u8bbe\u7f6e-\u5e94\u7528-\u6743\u9650\u4e2d\u5f00\u542f\u5b9a\u4f4d',
          duration: 2500
        });
        return;
      }
      const pos = await getCurrentPosition();
      if (!pos) {
        promptAction.showToast({
          message: '\u672a\u6536\u5230\u5b9a\u4f4d\uff0c\u53ef\u4e0b\u65b9\u586b\u5199\u6216\u4f7f\u7528\u6d4b\u8bd5\u586b\u5145',
          duration: 3000
        });
        return;
      }
      this.lastLatitude = pos.latitude;
      this.lastLongitude = pos.longitude;
      this.hasGeoCoordinates = true;
      const address = await GeocodeApi.getAddressFromCoordinates(pos.latitude, pos.longitude);
      if (address && address.length > 0) {
        this.location = address;
        this.locationReady = true;
        promptAction.showToast({ message: '\u5df2\u83b7\u53d6\u5f53\u524d\u4f4d\u7f6e', duration: 1500 });
      } else {
        this.location = `${pos.latitude.toFixed(6)}, ${pos.longitude.toFixed(6)}`;
        this.locationReady = true;
        promptAction.showToast({ message: '\u5df2\u586b\u5165\u7ecf\u7eac\u5ea6\uff0c\u53ef\u624b\u52a8\u8865\u5145\u5730\u5740', duration: 1500 });
      }
    } catch (err) {
      const msg = (err as Error).message ? (err as Error).message : '\u83b7\u53d6\u4f4d\u7f6e\u5931\u8d25';
      promptAction.showToast({ message: msg, duration: 2000 });
    } finally {
      this.isLocating = false;
    }
  }

  /** 模拟器/无 GPS 时测试用 */
  async fillMockLocationForTest(): Promise<void> {
    if (this.isLocating) {
      return;
    }
    this.isLocating = true;
    try {
      this.lastLatitude = 39.998;
      this.lastLongitude = 116.478;
      this.hasGeoCoordinates = true;
      const address = await GeocodeApi.getAddressFromCoordinates(39.998, 116.478);
      this.location = address && address.length > 0 ? address : '\u5317\u4eac\u5e02\u671d\u9633\u533a\u671b\u4eac\u8857\u9053\u671b\u4eacSOHO';
      this.locationReady = true;
      promptAction.showToast({ message: '\u5df2\u586b\u5165\u6d4b\u8bd5\u5730\u5740', duration: 1500 });
    } catch (err) {
      this.lastLatitude = 39.998;
      this.lastLongitude = 116.478;
      this.hasGeoCoordinates = true;
      this.location = '\u5317\u4eac\u5e02\u671d\u9633\u533a\u671b\u4eac\u8857\u9053\u671b\u4eacSOHO';
      this.locationReady = true;
    } finally {
      this.isLocating = false;
    }
  }

  onMicClick(): void {
    promptAction.showToast({
      message: '\u8bed\u97f3\u8f93\u5165\u529f\u80fd\u9700\u96c6\u6210\u7cfb\u7edf\u8bed\u97f3\u670d\u52a1\uff08\u5f85\u6269\u5c55\uff09',
      duration: 2000
    });
  }

  onSubmitSuccess() {
    if (!this.submitSuccessful || !this.createdRequestId) {
      return;
    }

    promptAction.showToast({
      message: '\u7d27\u6025\u6c42\u52a9\u5df2\u63d0\u4ea4',
      duration: 1500
    });

    router.replaceUrl({
      url: 'pages/help-seeker/MyRequestsPage',
      params: {
        createdId: this.createdRequestId
      } as CreatedRequestRouteParams
    }).catch((err: Error) => {
      console.error('navigation failed:', err);
    });

    this.submitSuccessful = false;
  }

  onSubmitError() {
    if (!this.submitErrorMessage) {
      return;
    }

    promptAction.showToast({
      message: this.submitErrorMessage,
      duration: 1500
    });

    if (this.shouldRedirectToLogin) {
      router.replaceUrl({
        url: 'pages/LoginPage'
      }).catch((err: Error) => {
        console.error('navigation failed:', err);
      });
    }

    this.submitErrorMessage = '';
    this.shouldRedirectToLogin = false;
  }

  private shouldGoToLogin(error: Error): boolean {
    return error.message.indexOf('\u767b\u5f55') >= 0
      && error.message.indexOf('\u91cd\u65b0\u767b\u5f55') >= 0;
  }

  submitEmergencyRequest() {
    if (!this.description.trim()) {
      promptAction.showToast({
        message: '\u8bf7\u586b\u5199\u7d27\u6025\u60c5\u51b5\u8bf4\u660e',
        duration: 1500
      });
      return;
    }

    if (!this.location.trim()) {
      promptAction.showToast({
        message: '\u8bf7\u586b\u5199\u6216\u83b7\u53d6\u4f4d\u7f6e\u4fe1\u606f',
        duration: 1500
      });
      return;
    }

    if (!this.contactPhone.trim()) {
      promptAction.showToast({
        message: '\u8bf7\u586b\u5199\u8054\u7cfb\u7535\u8bdd',
        duration: 1500
      });
      return;
    }

    this.isSubmitting = true;

    const payload: CreateEmergencyRequestPayload = {
      type: this.selectedType,
      description: this.description.trim(),
      location: this.location.trim(),
      contactPhone: this.contactPhone.trim()
    };
    if (this.hasGeoCoordinates) {
      payload.latitude = this.lastLatitude;
      payload.longitude = this.lastLongitude;
    }

    EmergencyApi.createEmergencyRequest(payload).then((createdRequest) => {
      this.createdRequestId = createdRequest.id;
      this.submitSuccessful = true;
    }).catch((err: Error) => {
      console.error('create emergency request failed:', err);
      this.shouldRedirectToLogin = this.shouldGoToLogin(err);
      this.submitErrorMessage = err.message ? err.message : '\u63d0\u4ea4\u7d27\u6025\u6c42\u52a9\u5931\u8d25';
    }).finally(() => {
      this.isSubmitting = false;
    });
  }

  build() {
    Column() {
      Row({ space: 16 }) {
        NavBackButton()

        Text('\u7d27\u6025\u6c42\u52a9')
          .fontSize(this.largeFontEnabled ? 25 : 20)
          .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#1a1a1a')
          .layoutWeight(1)
      }
      .width('100%')
      .padding(16)
      .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.pageBg : '#ffffff')
      .border({
        width: { bottom: this.highContrastEnabled ? ElderHighContrastTheme.borderWidth : 1 },
        color: this.highContrastEnabled ? ElderHighContrastTheme.borderStrong : '#e5e7eb'
      })

      Scroll() {
        Column({ space: 20 }) {
          Row({ space: 0 }) {
            Column()
              .width(4)
              .constraintSize({ minHeight: 72 })
              .backgroundColor('#ef4444')
              .borderRadius({ topLeft: 10, bottomLeft: 10 })

            Text('\u60a8\u7684\u7d27\u6025\u6c42\u52a9\u5c06\u4f18\u5148\u63a8\u9001\u7ed9\u9644\u8fd1\u7684\u5fd7\u613f\u8005\u548c\u793e\u533a\u7ba1\u7406\u5458\u3002\u8bf7\u7b80\u8981\u63cf\u8ff0\u60a8\u7684\u7d27\u6025\u60c5\u51b5\u3002')
              .fontSize(this.largeFontEnabled ? 16 : 14)
              .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#7f1d1d')
              .lineHeight(this.largeFontEnabled ? 24 : 21)
              .layoutWeight(1)
              .padding({
                left: 12,
                right: 14,
                top: 14,
                bottom: 14
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
          .backgroundColor(this.highContrastEnabled ? '#ffebee' : '#fff1f2')
          .borderRadius(12)
          .border(this.highContrastEnabled ? ElderHighContrastTheme.cardBorder() : {
            width: 1,
            color: '#fecdd3'
          })

          Column({ space: 10 }) {
            Row({ space: 4 }) {
              Text('\u7d27\u6025\u60c5\u51b5\u8bf4\u660e')
                .fontSize(this.largeFontEnabled ? 18 : 15)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#1a1a1a')
              Text('*')
                .fontSize(this.largeFontEnabled ? 18 : 15)
                .fontColor('#ef4444')
            }
            .alignSelf(ItemAlign.Start)

            Stack({ alignContent: Alignment.BottomEnd }) {
              TextArea({
                placeholder: '\u8bf7\u63cf\u8ff0\u60a8\u9047\u5230\u7684\u7d27\u6025\u60c5\u51b5...',
                text: this.description
              })
                .width('100%')
                .height(this.largeFontEnabled ? 160 : 140)
                .fontSize(this.largeFontEnabled ? 17 : 14)
                .borderRadius(12)
                .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.surface : '#ffffff')
                .border({
                  width: this.highContrastEnabled ? ElderHighContrastTheme.borderWidth : 1,
                  color: this.highContrastEnabled ? ElderHighContrastTheme.borderStrong : '#e5e7eb'
                })
                .padding({ left: 12, right: 12, top: 12, bottom: 40 })
                .maxLength(DESC_MAX)
                .onChange((value: string) => {
                  this.onDescriptionChange(value);
                })

              Row({ space: 10 }) {
                Text(`${this.description.length}/${DESC_MAX}`)
                  .fontSize(12)
                  .fontColor('#9ca3af')
                Button() {
                  Text('\u9ea6')
                    .fontSize(18)
                    .fontColor('#ef4444')
                    .fontWeight(FontWeight.Bold)
                }
                .width(40)
                .height(40)
                .backgroundColor(Color.Transparent)
                .onClick(() => {
                  this.onMicClick();
                })
              }
              .padding({ right: 10, bottom: 8 })
            }
            .width('100%')

            Row({ space: 6 }) {
              Text('\u9ea6')
                .fontSize(14)
                .fontColor('#9ca3af')
              Text('\u70b9\u51fb\u9ea6\u514b\u98ce\u56fe\u6807\u53ef\u4f7f\u7528\u8bed\u97f3\u8f93\u5165')
                .fontSize(12)
                .fontColor('#9ca3af')
            }
            .alignSelf(ItemAlign.Start)
          }
          .width('100%')

          Column({ space: 10 }) {
            Text('\u4f4d\u7f6e\u4fe1\u606f')
              .fontSize(this.largeFontEnabled ? 18 : 15)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#1a1a1a')
              .alignSelf(ItemAlign.Start)

            Column({ space: 10 }) {
              Row({ space: 12 }) {
                Row() {
                  Text('\uD83D\uDCCD')
                    .fontSize(18)
                }
                .width(40)
                .height(40)
                .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.tagBg : '#dbeafe')
                .borderRadius(20)
                .justifyContent(FlexAlign.Center)
                .border(this.highContrastEnabled ? ElderHighContrastTheme.cardBorder() : undefined)

                Column({ space: 6 }) {
                  Row({ space: 8 }) {
                    Text(this.isLocating ? '\u6b63\u5728\u83b7\u53d6\u4f4d\u7f6e...' : '\u5df2\u83b7\u53d6\u5f53\u524d\u4f4d\u7f6e')
                      .fontSize(this.largeFontEnabled ? 16 : 14)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#1e40af')
                    Row() {
                      Column()
                        .width(8)
                        .height(8)
                        .backgroundColor(this.locationReady ? '#22c55e' : '#d1d5db')
                        .borderRadius(4)
                    }
                    .width(12)
                    .height(12)
                    .justifyContent(FlexAlign.Center)
                  }
                  .alignItems(VerticalAlign.Center)

                  Text(this.location || '\u6682\u672a\u83b7\u53d6\u5730\u5740\uff0c\u8bf7\u7a0d\u5019\u6216\u70b9\u51fb\u91cd\u8bd5')
                    .fontSize(this.largeFontEnabled ? 15 : 13)
                    .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#4b5563')
                    .lineHeight(20)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              .width('100%')
              .alignItems(VerticalAlign.Top)

              Row({ space: 12 }) {
                Button(this.isLocating ? '\u5b9a\u4f4d\u4e2d...' : '\u91cd\u65b0\u5b9a\u4f4d')
                  .fontSize(13)
                  .height(36)
                  .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.accentBlue : '#2563eb')
                  .fontColor('#ffffff')
                  .enabled(!this.isLocating)
                  .onClick(() => {
                    this.fetchCurrentLocation();
                  })
                Button('\u6d4b\u8bd5\u586b\u5145\u5730\u5740')
                  .fontSize(13)
                  .height(36)
                  .fontColor('#6b7280')
                  .backgroundColor('#f3f4f6')
                  .enabled(!this.isLocating)
                  .onClick(() => {
                    this.fillMockLocationForTest();
                  })
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.tagBg : '#eff6ff')
            .borderRadius(14)
            .border(this.highContrastEnabled ? ElderHighContrastTheme.cardBorder() : undefined)
          }
          .width('100%')

          Column({ space: 8 }) {
            Text('\u8054\u7cfb\u7535\u8bdd')
              .fontSize(this.largeFontEnabled ? 16 : 14)
              .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#6b7280')
              .alignSelf(ItemAlign.Start)
            TextInput({
              placeholder: '\u7528\u4e8e\u5fd7\u613f\u8005\u4e0e\u60a8\u8054\u7cfb',
              text: this.contactPhone
            })
              .width('100%')
              .height(48)
              .fontSize(this.largeFontEnabled ? 16 : 14)
              .type(InputType.PhoneNumber)
              .borderRadius(10)
              .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.surface : '#ffffff')
              .border({
                width: this.highContrastEnabled ? ElderHighContrastTheme.borderWidth : 1,
                color: this.highContrastEnabled ? ElderHighContrastTheme.borderStrong : '#e5e7eb'
              })
              .padding({ left: 12, right: 12 })
              .onChange((value: string) => {
                this.contactPhone = value;
              })
          }
          .width('100%')

          Row().height(80)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      }
      .layoutWeight(1)
      .align(Alignment.TopStart)
      .scrollBar(BarState.Off)
      .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.pageBg : '#f9fafb')

      Column() {
        Button(this.isSubmitting ? '\u63d0\u4ea4\u4e2d...' : '\u7acb\u5373\u53d1\u9001\u7d27\u6025\u6c42\u52a9')
          .width('100%')
          .height(this.largeFontEnabled ? 56 : 52)
          .fontSize(this.largeFontEnabled ? 18 : 16)
          .fontWeight(FontWeight.Medium)
          .borderRadius(14)
          .backgroundColor(this.canSubmit()
            ? (this.highContrastEnabled ? ElderHighContrastTheme.accentDanger : '#ef4444')
            : (this.highContrastEnabled ? '#d1d5db' : '#e5e7eb'))
          .fontColor(this.canSubmit()
            ? '#ffffff'
            : '#9ca3af')
          .enabled(this.canSubmit())
          .onClick(() => {
            this.submitEmergencyRequest();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 24 })
      .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.pageBg : '#ffffff')
      .shadow(this.highContrastEnabled ? undefined : {
        radius: 8,
        color: '#0f000008',
        offsetX: 0,
        offsetY: -2
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.pageBg : '#f9fafb')
  }
}
