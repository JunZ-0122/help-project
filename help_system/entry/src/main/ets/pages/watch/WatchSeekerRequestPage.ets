import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { WatchButton } from '../../components/WatchButton';
import { RequestApi, GeocodeApi } from '../../services/ApiService';
import { getCurrentPosition, requestLocationPermission } from '../../utils/LocationUtil';
import { StorageUtil } from '../../utils/StorageUtil';
import type { HelpRequest } from '../../models/Request';
import type { UserProfile } from '../../models/User';

@Entry
@Component
struct WatchSeekerRequestPage {
  @State selectedType: string = '';
  @State description: string = '';
  @State locationText: string = '';
  @State latitude: number = 0;
  @State longitude: number = 0;
  @State hasGeo: boolean = false;
  @State isLocating: boolean = false;
  @State isSubmitting: boolean = false;

  aboutToAppear(): void {
    this.tryLocate();
  }

  private async tryLocate(): Promise<void> {
    if (this.isLocating) {
      return;
    }
    this.isLocating = true;
    try {
      const granted = await requestLocationPermission();
      if (!granted) {
        return;
      }
      const pos = await getCurrentPosition();
      if (!pos) {
        return;
      }
      this.latitude = pos.latitude;
      this.longitude = pos.longitude;
      this.hasGeo = true;
      const address = await GeocodeApi.getAddressFromCoordinates(pos.latitude, pos.longitude);
      this.locationText = address && address.length > 0
        ? address
        : `${pos.latitude.toFixed(5)}, ${pos.longitude.toFixed(5)}`;
    } catch (e) {
      console.error('locate failed:', e);
    } finally {
      this.isLocating = false;
    }
  }

  private urgencyForType(type: string): string {
    if (type === 'medical') {
      return 'high';
    }
    if (type === 'emergency') {
      return 'emergency';
    }
    return 'medium';
  }

  private typeName(type: string): string {
    const typeNames: Record<string, string> = {
      'medical': '就医求助',
      'companion': '出行协助',
      'shopping': '生活帮扶'
    };
    return typeNames[type] || '其他求助';
  }

  private async submit(): Promise<void> {
    if (!this.selectedType || this.isSubmitting) {
      return;
    }
    this.isSubmitting = true;
    try {
      const loc = this.locationText.trim().length > 0
        ? this.locationText.trim()
        : '未知位置（手表端发起）';

      const payload: Partial<HelpRequest> = {
        type: this.selectedType as 'medical' | 'companion' | 'shopping' | 'other',
        title: this.typeName(this.selectedType),
        description: this.description.trim().length > 0
          ? `【手表端】${this.description.trim()}`
          : `【手表端】${this.typeName(this.selectedType)}`,
        location: loc,
        urgency: this.urgencyForType(this.selectedType) as 'low' | 'medium' | 'high' | 'emergency'
      };

      if (this.hasGeo) {
        payload.latitude = this.latitude;
        payload.longitude = this.longitude;
      }

      const created = await RequestApi.createRequest(payload);
      promptAction.showToast({ message: '已发起求助', duration: 1500 });
      router.replaceUrl({
        url: 'pages/watch/WatchMyRequestsPage',
        params: { createdId: created.id }
      }).catch((err: Error) => {
        console.error('nav failed:', err);
      });
    } catch (e) {
      const err = e as Error;
      const message = err.message || '提交失败';
      console.error('[WatchSeekerRequestPage] submit failed:', err);
      promptAction.showToast({ message: message.includes('Timeout') ? '网络超时，请稍后重试' : message, duration: 2000 });
    } finally {
      this.isSubmitting = false;
    }
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        NavBackButton()
        Text('发起求助')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 0, right: 0, top: 0, bottom: 6 })

      Scroll() {
        Column({ space: 8 }) {
          if (this.selectedType.length === 0) {
            Text('选择类型')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1e293b')
              .width('100%')
              .margin({ bottom: 4 })

            // 第一行:就医 + 出行
            Row({ space: 8 }) {
              Button('就医')
                .layoutWeight(1)
                .height(50)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .backgroundColor('#ef4444')
                .fontColor('#ffffff')
                .borderRadius(8)
                .onClick(() => { this.selectedType = 'medical'; })
              
              Button('出行')
                .layoutWeight(1)
                .height(50)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .backgroundColor('#3b82f6')
                .fontColor('#ffffff')
                .borderRadius(8)
                .onClick(() => { this.selectedType = 'companion'; })
            }
            .width('100%')

            // 第二行:生活 + 其他
            Row({ space: 8 }) {
              Button('生活')
                .layoutWeight(1)
                .height(50)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .backgroundColor('#10b981')
                .fontColor('#ffffff')
                .borderRadius(8)
                .onClick(() => { this.selectedType = 'shopping'; })
              
              Button('其他')
                .layoutWeight(1)
                .height(50)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .backgroundColor('#64748b')
                .fontColor('#ffffff')
                .borderRadius(8)
                .onClick(() => { this.selectedType = 'other'; })
            }
            .width('100%')
          } else {
            Row({ space: 6 }) {
              Text(`类型：${this.typeName(this.selectedType)}`)
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
              Text('重选')
                .fontSize(10)
                .fontColor('#2563eb')
                .onClick(() => { this.selectedType = ''; })
            }
            .width('100%')

            TextInput({ placeholder: '简要描述（可选）' })
              .height(32)
              .fontSize(11)
              .onChange((v: string) => {
                this.description = v;
              })

            Text(this.isLocating ? '定位中..' : (this.locationText || '未获取位置'))
              .fontSize(10)
              .fontColor('#64748b')
              .maxLines(2)
              .width('100%')

            WatchButton({
              text: this.isSubmitting ? '提交中..' : '提交求助',
              buttonType: 'primary',
              buttonSize: 'medium',
              buttonWidth: '100%',
              buttonEnabled: !this.isSubmitting
            })
            .onClick(() => {
              this.submit();
            })
          }
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f8fafc')
    .padding({ top: 30, bottom: 30, left: 12, right: 12 })
  }
}
