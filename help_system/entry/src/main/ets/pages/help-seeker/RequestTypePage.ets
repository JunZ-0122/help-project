import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { GeocodeApi, RequestApi } from '../../services/ApiService';
import { getCurrentPosition, requestLocationPermission, type LocationPoint } from '../../utils/LocationUtil';
import { ElderHighContrastTheme } from '../../utils/AccessibilityTheme';

type HelpRequestType = 'medical' | 'shopping' | 'repair' | 'companion' | 'emergency' | 'other';
type HelpRequestUrgency = 'low' | 'medium' | 'high' | 'emergency';

interface RequestTypeOption {
  id: HelpRequestType;
  label: string;
}

interface CreateHelpRequestPayload {
  type: HelpRequestType;
  title: string;
  description: string;
  location: string;
  urgency: HelpRequestUrgency;
}

/** 发布求助请求体（可带经纬度） */
interface CreateHelpRequestPayloadWithLocation extends CreateHelpRequestPayload {
  latitude?: number;
  longitude?: number;
}

interface RequestTypeRouteParams {
  type?: HelpRequestType;
}

interface CreatedRequestRouteParams {
  createdId: string;
}

const DESC_MAX = 500;

@Entry
@Component
struct RequestTypePage {
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  @State selectedType: HelpRequestType | '' = '';
  @State description: string = '';
  @State isSubmitting: boolean = false;

  /** 逆地理得到的地址或经纬度兜底文案，提交时写入求助 */
  @State locationDisplay: string = '';
  @State locationReady: boolean = false;
  @State isLocating: boolean = false;
  @State lastLatitude: number = 0;
  @State lastLongitude: number = 0;
  @State hasGeoCoordinates: boolean = false;
  /** 定位失败时手动填写，仍可提交（非死数据，来自用户输入） */
  @State manualLocation: string = '';

  /**
   * 设计稿：医疗、出行、生活、其他（不含「陪伴」；后端仍用 companion 表示出行协助）
   */
  private requestTypes: RequestTypeOption[] = [
    { id: 'medical', label: '医疗' },
    { id: 'companion', label: '出行' },
    { id: 'shopping', label: '生活' },
    { id: 'other', label: '其他' }
  ];

  aboutToAppear() {
    const params = router.getParams() as RequestTypeRouteParams;
    if (params && params.type) {
      const t = params.type;
      const allowed: HelpRequestType[] = ['medical', 'companion', 'shopping', 'other'];
      const idx = allowed.indexOf(t as HelpRequestType);
      this.selectedType = idx >= 0 ? (t as HelpRequestType) : '';
    }
    this.fetchCurrentLocation();
  }

  private showToast(message: string): void {
    promptAction.showToast({
      message: message,
      duration: 1500
    });
  }

  /** 导航栏标题：选中类型名，否则「发布求助」 */
  private getHeaderTitle(): string {
    if (this.selectedType === '') {
      return '\u53d1\u5e03\u6c42\u52a9';
    }
    return this.getTypeChipLabel(this.selectedType as HelpRequestType);
  }

  private getTypeChipLabel(id: HelpRequestType): string {
    switch (id) {
      case 'medical':
        return '\u533b\u7597';
      case 'companion':
        return '\u51fa\u884c';
      case 'shopping':
        return '\u751f\u6d3b';
      case 'repair':
        return '\u7ef4\u4fee';
      case 'emergency':
        return '\u7d27\u6025';
      case 'other':
        return '\u5176\u4ed6';
      default:
        return '\u6c42\u52a9';
    }
  }

  private getRequestTitle(): string {
    switch (this.selectedType) {
      case 'medical':
        return '\u5c31\u533b\u6c42\u52a9';
      case 'shopping':
        return '\u751f\u6d3b\u5e2e\u6276';
      case 'repair':
        return '\u7ef4\u4fee\u5e2e\u52a9';
      case 'companion':
        return '\u51fa\u884c\u534f\u52a9';
      case 'emergency':
        return '\u7d27\u6025\u6c42\u52a9';
      case 'other':
        return '\u5176\u4ed6\u6c42\u52a9';
      default:
        return '\u6c42\u52a9\u8bf7\u6c42';
    }
  }

  private getUrgency(): HelpRequestUrgency {
    switch (this.selectedType) {
      case 'medical':
        return 'high';
      case 'shopping':
      case 'repair':
      case 'companion':
        return 'medium';
      default:
        return 'low';
    }
  }

  /** 优先使用定位结果，否则用手动地址 */
  private getEffectiveLocationText(): string {
    if (this.locationReady && this.locationDisplay.trim().length > 0) {
      return this.locationDisplay.trim();
    }
    return this.manualLocation.trim();
  }

  /**
   * 定位 + GET /api/geocode/regeo 逆地理，写入 locationDisplay；无地址时用经纬度字符串
   */
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
          message:
            '\u8bf7\u5728\u5f39\u6846\u4e2d\u5141\u8bb8\u5b9a\u4f4d\u6743\u9650\uff0c\u6216\u524d\u5f80\u8bbe\u7f6e\u5f00\u542f\u5b9a\u4f4d',
          duration: 2500
        });
        return;
      }
      let pos: LocationPoint | null = null;
      const maxAttempts = 3;
      const delayMs = 700;
      for (let attempt = 0; attempt < maxAttempts; attempt++) {
        pos = await getCurrentPosition();
        if (pos) {
          break;
        }
        if (attempt < maxAttempts - 1) {
          await new Promise<void>((resolve) => {
            setTimeout(() => {
              resolve();
            }, delayMs);
          });
        }
      }
      if (!pos) {
        promptAction.showToast({
          message:
            '\u672a\u6536\u5230\u5b9a\u4f4d\u3002\u6a21\u62df\u5668\u8bf7\u5728\u300cGPS\u6a21\u62df\u300d\u8bbe\u7f6e\u7ecf\u7eac\u5ea6\u5e76\u70b9\u51fb\u5e94\u7528\uff0c\u518d\u70b9\u83b7\u53d6\u4f4d\u7f6e\uff1b\u6216\u5728\u4e0b\u65b9\u624b\u52a8\u586b\u5199\u5730\u5740\u3002',
          duration: 4000
        });
        return;
      }
      this.lastLatitude = pos.latitude;
      this.lastLongitude = pos.longitude;
      this.hasGeoCoordinates = true;
      this.manualLocation = '';
      const address = await GeocodeApi.getAddressFromCoordinates(pos.latitude, pos.longitude);
      if (address && address.length > 0) {
        this.locationDisplay = address;
      } else {
        this.locationDisplay = `${pos.latitude.toFixed(6)}, ${pos.longitude.toFixed(6)}`;
      }
      this.locationReady = true;
      promptAction.showToast({ message: '\u5df2\u83b7\u53d6\u5f53\u524d\u4f4d\u7f6e', duration: 1500 });
    } catch (err) {
      const msg = (err as Error).message ? (err as Error).message : '\u83b7\u53d6\u4f4d\u7f6e\u5931\u8d25';
      promptAction.showToast({ message: msg, duration: 2000 });
    } finally {
      this.isLocating = false;
    }
  }

  private canSubmit(): boolean {
    return this.selectedType !== '' &&
      this.description.trim().length > 0 &&
      this.getEffectiveLocationText().length > 0 &&
      !this.isSubmitting;
  }

  async handleSubmit() {
    if (!this.canSubmit()) {
      this.showToast('\u8bf7\u586b\u5199\u5b8c\u6574\u4fe1\u606f\u5e76\u586b\u5199\u4f4d\u7f6e\uff08\u5b9a\u4f4d\u6216\u624b\u52a8\u5730\u5740\uff09');
      return;
    }

    this.isSubmitting = true;

    const payload: CreateHelpRequestPayloadWithLocation = {
      type: this.selectedType as HelpRequestType,
      title: this.getRequestTitle(),
      description: this.description.trim(),
      location: this.getEffectiveLocationText(),
      urgency: this.getUrgency()
    };
    if (this.hasGeoCoordinates) {
      payload.latitude = this.lastLatitude;
      payload.longitude = this.lastLongitude;
    }

    RequestApi.createRequest(payload).then((createdRequest) => {
      this.showToast('\u6c42\u52a9\u53d1\u5e03\u6210\u529f');
      router.replaceUrl({
        url: 'pages/help-seeker/MyRequestsPage',
        params: {
          createdId: createdRequest.id
        } as CreatedRequestRouteParams
      }).catch((err: Error) => {
        console.error('navigation failed:', err);
      });
    }).catch((err: Error) => {
      console.error('create request failed:', err);
      this.showToast(err.message ? err.message : '\u53d1\u5e03\u6c42\u52a9\u5931\u8d25');
    }).finally(() => {
      this.isSubmitting = false;
    });
  }

  private onDescriptionChange(value: string): void {
    if (value.length > DESC_MAX) {
      this.description = value.substring(0, DESC_MAX);
    } else {
      this.description = value;
    }
  }

  @Builder
  TypeChip(type: RequestTypeOption) {
    Stack({ alignContent: Alignment.TopEnd }) {
      Button(type.label)
        .width('100%')
        .height(this.largeFontEnabled ? 56 : 48)
        .fontSize(this.largeFontEnabled ? 17.5 : 14)
        .fontColor(this.highContrastEnabled
          ? (this.selectedType === type.id ? '#ffffff' : ElderHighContrastTheme.textPrimary)
          : (this.selectedType === type.id ? '#ffffff' : '#374151'))
        .backgroundColor(this.highContrastEnabled
          ? (this.selectedType === type.id ? ElderHighContrastTheme.accentBlue : ElderHighContrastTheme.surface)
          : (this.selectedType === type.id ? '#2563eb' : '#ffffff'))
        .borderRadius(12)
        .border({
          width: this.highContrastEnabled ? 2 : (this.selectedType === type.id ? 0 : 1),
          color: this.highContrastEnabled ? ElderHighContrastTheme.borderStrong : '#e5e7eb'
        })
        .onClick(() => {
          this.selectedType = type.id;
        })

      if (this.selectedType === type.id) {
        Text('\u2713')
          .fontSize(11)
          .fontColor('#ffffff')
          .fontWeight(FontWeight.Bold)
          .padding({ top: 5, right: 6 })
      }
    }
    .layoutWeight(1)
  }

  build() {
    Column() {
      Column() {
        Row({ space: 12 }) {
          NavBackButton()

          Text(this.getHeaderTitle())
            .fontSize(this.largeFontEnabled ? 22.5 : 18)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#1a1a1a')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          Row().width(this.largeFontEnabled ? 48 : 40)
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 0, bottom: 8 })

        Divider()
          .strokeWidth(this.highContrastEnabled ? 2 : 1)
          .color(this.highContrastEnabled ? ElderHighContrastTheme.divider : '#e5e7eb')
      }
      .width('100%')
      .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.surface : '#ffffff')

      Scroll() {
        Column({ space: 16 }) {
          Column({ space: 10 }) {
            Row({ space: 4 }) {
              Text('\u6c42\u52a9\u7c7b\u578b')
                .fontSize(this.largeFontEnabled ? 20 : 16)
                .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#1a1a1a')
              Text('*')
                .fontSize(this.largeFontEnabled ? 20 : 16)
                .fontColor('#ef4444')
            }
            .width('100%')

            Row({ space: 8 }) {
              ForEach(this.requestTypes, (type: RequestTypeOption) => {
                this.TypeChip(type);
              }, (type: RequestTypeOption) => type.id)
            }
            .width('100%')
          }
          .width('100%')

          Column({ space: 10 }) {
            Row({ space: 4 }) {
              Text('\u6c42\u52a9\u8bf4\u660e')
                .fontSize(this.largeFontEnabled ? 20 : 16)
                .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#1a1a1a')
              Text('*')
                .fontSize(this.largeFontEnabled ? 20 : 16)
                .fontColor('#ef4444')
            }
            .width('100%')

            Stack({ alignContent: Alignment.BottomEnd }) {
              TextArea({
                placeholder: '\u8bf7\u7b80\u5355\u63cf\u8ff0\u60a8\u9700\u8981\u7684\u5e2e\u52a9',
                text: this.description
              })
                .width('100%')
                .height(this.largeFontEnabled ? 188 : 168)
                .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.surface : '#ffffff')
                .borderRadius(12)
                .padding({ left: 14, right: 14, top: 12, bottom: 36 })
                .fontSize(this.largeFontEnabled ? 18.75 : 15)
                .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#1a1a1a')
                .border(this.highContrastEnabled ? { width: ElderHighContrastTheme.borderWidth, color: ElderHighContrastTheme.borderStrong } : {
                  width: 1,
                  color: '#e8eaed'
                })
                .maxLength(DESC_MAX)
                .onChange((value: string) => {
                  this.onDescriptionChange(value);
                })
                .shadow(this.highContrastEnabled ? undefined : {
                  radius: 10,
                  color: '#0f000012',
                  offsetX: 0,
                  offsetY: 2
                })

              Row({ space: 10 }) {
                Button() {
                  Text('🎤')
                    .fontSize(this.largeFontEnabled ? 20 : 17)
                }
                .width(this.largeFontEnabled ? 40 : 36)
                .height(this.largeFontEnabled ? 40 : 36)
                .borderRadius(99)
                .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.tagBg : '#eff6ff')
                .border(this.highContrastEnabled ? { width: ElderHighContrastTheme.borderWidth, color: ElderHighContrastTheme.borderStrong } : undefined)
                .onClick(() => {
                  promptAction.showToast({
                    message:
                      '\u53ef\u4f7f\u7528\u7cfb\u7edf\u8f93\u5165\u6cd5\u7684\u8bed\u97f3\u8f93\u5165\uff0c\u6216\u7eed\u5199\u6587\u5b57',
                    duration: 2000
                  });
                })

                Text(`${this.description.length}/${DESC_MAX}`)
                  .fontSize(this.largeFontEnabled ? 15 : 12)
                  .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#9ca3af')
              }
              .padding({ right: 10, bottom: 8 })
            }
            .width('100%')

            Row({ space: 6 }) {
              Text('🎤')
                .fontSize(this.largeFontEnabled ? 14 : 12)
              Text('\u70b9\u51fb\u9ea6\u514b\u98ce\u56fe\u6807\u53ef\u4f7f\u7528\u8bed\u97f3\u8f93\u5165')
                .fontSize(this.largeFontEnabled ? 15 : 12)
                .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#6b7280')
            }
            .width('100%')
          }
          .width('100%')

          Column({ space: 10 }) {
            Text('\u4f4d\u7f6e\u4fe1\u606f')
              .fontSize(this.largeFontEnabled ? 20 : 16)
              .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#1a1a1a')
              .width('100%')

            if (this.isLocating) {
              Row({ space: 12 }) {
                LoadingProgress()
                  .width(28)
                  .height(28)
                Text('\u6b63\u5728\u83b7\u53d6\u4f4d\u7f6e...')
                  .fontSize(this.largeFontEnabled ? 17.5 : 14)
                  .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#6b7280')
              }
              .width('100%')
              .padding(16)
              .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.tagBg : '#eff6ff')
              .borderRadius(12)
              .border(this.highContrastEnabled ? { width: ElderHighContrastTheme.borderWidth, color: ElderHighContrastTheme.borderStrong } : undefined)
            } else if (this.locationReady && this.locationDisplay.length > 0) {
              Row({ space: 12 }) {
                Row() {
                  Text('\uD83D\uDCCD')
                    .fontSize(this.largeFontEnabled ? 22 : 18)
                }
                .width(this.largeFontEnabled ? 44 : 40)
                .height(this.largeFontEnabled ? 44 : 40)
                .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.tagBg : '#dbeafe')
                .borderRadius(99)
                .justifyContent(FlexAlign.Center)
                .border(this.highContrastEnabled ? { width: ElderHighContrastTheme.borderWidth, color: ElderHighContrastTheme.borderStrong } : undefined)

                Column({ space: 6 }) {
                  Row({ space: 8 }) {
                    Text('\u5df2\u83b7\u53d6\u5f53\u524d\u4f4d\u7f6e')
                      .fontSize(this.largeFontEnabled ? 17.5 : 14)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#111827')
                    Row()
                      .width(8)
                      .height(8)
                      .backgroundColor('#10b981')
                      .borderRadius(4)
                  }
                  .alignItems(VerticalAlign.Center)

                  Text(this.locationDisplay)
                    .fontSize(this.largeFontEnabled ? 16 : 13)
                    .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#4b5563')
                    .width('100%')
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .padding(16)
              .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.tagBg : '#eff6ff')
              .borderRadius(12)
              .border(this.highContrastEnabled ? { width: ElderHighContrastTheme.borderWidth, color: ElderHighContrastTheme.borderStrong } : { width: 1, color: '#bfdbfe' })
            } else {
              Column({ space: 10 }) {
                Text('\u6682\u672a\u83b7\u53d6\u4f4d\u7f6e\uff0c\u53d1\u5e03\u524d\u9700\u586b\u5199\u4f4d\u7f6e')
                  .fontSize(this.largeFontEnabled ? 16 : 13)
                  .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#6b7280')
                Text(
                  '\u6a21\u62df\u5668\uff1a\u8bf7\u5148\u5728\u300cGPS\u6a21\u62df\u300d\u4e2d\u8bbe\u7f6e\u7ecf\u7eac\u5ea6\u5e76\u70b9\u51fb\u5e94\u7528\uff0c\u518d\u70b9\u4e0b\u65b9\u300c\u83b7\u53d6\u5f53\u524d\u4f4d\u7f6e\u300d\u3002\u4ecd\u5931\u8d25\u65f6\u53ef\u624b\u52a8\u586b\u5199\u5730\u5740\u3002'
                )
                  .fontSize(this.largeFontEnabled ? 14 : 12)
                  .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#9ca3af')
                  .width('100%')
                Button('\u83b7\u53d6\u5f53\u524d\u4f4d\u7f6e')
                  .fontSize(this.largeFontEnabled ? 16 : 14)
                  .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#2563eb')
                  .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.surface : '#ffffff')
                  .borderRadius(8)
                  .border(this.highContrastEnabled ? { width: ElderHighContrastTheme.borderWidth, color: ElderHighContrastTheme.borderStrong } : { width: 1, color: '#93c5fd' })
                  .onClick(() => {
                    this.fetchCurrentLocation();
                  })
                Text('\u6216\u624b\u52a8\u586b\u5199\u5730\u5740')
                  .fontSize(this.largeFontEnabled ? 16 : 13)
                  .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#374151')
                  .margin({ top: 4 })
                TextInput({ placeholder: '\u4f8b\u5982\uff1a\u91cd\u5e86\u5e02\u671d\u9633\u8def\u67d0\u53f7', text: this.manualLocation })
                  .width('100%')
                  .height(this.largeFontEnabled ? 48 : 44)
                  .fontSize(this.largeFontEnabled ? 17.5 : 14)
                  .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.surface : '#ffffff')
                  .borderRadius(8)
                  .border(this.highContrastEnabled ? { width: ElderHighContrastTheme.borderWidth, color: ElderHighContrastTheme.borderStrong } : { width: 1, color: '#e5e7eb' })
                  .onChange((value: string) => {
                    this.manualLocation = value;
                  })
              }
              .width('100%')
              .padding(16)
              .alignItems(HorizontalAlign.Start)
              .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.pageBg : '#f9fafb')
              .borderRadius(12)
              .border(this.highContrastEnabled ? { width: ElderHighContrastTheme.borderWidth, color: ElderHighContrastTheme.borderStrong } : { width: 1, color: '#e5e7eb' })
            }

            if (this.locationReady) {
              Button('\u91cd\u65b0\u5b9a\u4f4d')
                .fontSize(this.largeFontEnabled ? 15 : 12)
                .fontColor('#2563eb')
                .backgroundColor(Color.Transparent)
                .onClick(() => {
                  this.fetchCurrentLocation();
                })
            }
          }
          .width('100%')
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 0, bottom: 24 })
      }
      .layoutWeight(1)
      .align(Alignment.TopStart)
      .scrollBar(BarState.Off)
      .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.pageBg : '#f3f4f6')

      Column() {
        Button(this.isSubmitting ? '\u53d1\u5e03\u4e2d...' : '\u786e\u8ba4\u53d1\u5e03\u6c42\u52a9')
          .width('100%')
          .height(this.largeFontEnabled ? 64 : 56)
          .fontSize(this.largeFontEnabled ? 22.5 : 18)
          .fontColor('#ffffff')
          .fontWeight(FontWeight.Bold)
          .backgroundColor(this.canSubmit() ? '#2563eb' : '#d1d5db')
          .borderRadius(16)
          .enabled(this.canSubmit())
          .onClick(() => {
            this.handleSubmit();
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 6, bottom: 16 })
      .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.surface : '#ffffff')
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
