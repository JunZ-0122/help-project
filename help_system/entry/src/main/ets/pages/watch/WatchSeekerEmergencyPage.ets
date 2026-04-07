import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { EmergencyApi, GeocodeApi, type CreateEmergencyRequestPayload } from '../../services/ApiService';
import { getCurrentPosition, requestLocationPermission } from '../../utils/LocationUtil';
import { StorageUtil } from '../../utils/StorageUtil';
import type { UserProfile } from '../../models/User';
import { WatchButton } from '../../components/WatchButton';

/**
 * 手表端：求助者一键紧急求助（大按钮、少输入，复用 EmergencyApi）。
 * 需已登录且账号为求助者侧（与手机端接口一致）。
 */
@Entry
@Component
struct WatchSeekerEmergencyPage {
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  @State contactPhone: string = '';
  @State locationText: string = '';
  @State hasGeo: boolean = false;
  @State lastLat: number = 0;
  @State lastLng: number = 0;
  @State isLocating: boolean = false;
  @State isSubmitting: boolean = false;
  @State hint: string = '';
  @State hasLoginToken: boolean = false;
  private skipFirstPageShow: boolean = true;

  aboutToAppear(): void {
    this.hint = '\u6b63\u5728\u51c6\u5907...';
    this.prepare().then(() => {
      this.applyHintAfterPrepare();
    }).catch(() => {
      this.hint = '\u8bf7\u5148\u767b\u5f55\u540e\u518d\u8bd5';
    });
  }

  onPageShow(): void {
    if (this.skipFirstPageShow) {
      this.skipFirstPageShow = false;
      return;
    }
    this.prepare().then(() => {
      this.applyHintAfterPrepare();
    }).catch(() => {
    });
  }

  private applyHintAfterPrepare(): void {
    if (!this.hasLoginToken) {
      this.hint = '\u672a\u767b\u5f55\uff1a\u624b\u8868\u4e0e\u624b\u673a\u7f13\u5b58\u72ec\u7acb\uff0c\u8bf7\u5728\u672c\u8bbe\u5907\u767b\u5f55';
      return;
    }
    if (this.contactPhone.trim().length < 7) {
      this.hint = '\u5df2\u767b\u5f55\u4f46\u7f3a\u5c11\u624b\u673a\u53f7\uff0c\u8bf7\u5728\u624b\u673a\u7aef\u5b8c\u5584\u4e2a\u4eba\u8d44\u6599\u540e\u518d\u8bd5';
      return;
    }
    this.hint = this.locationText.length > 0
      ? '\u5df2\u83b7\u53d6\u4f4d\u7f6e\uff0c\u53ef\u53d1\u9001'
      : '\u672a\u83b7\u53d6\u4f4d\u7f6e\uff0c\u4ecd\u53ef\u53d1\u9001\uff08\u5efa\u8bae\u5141\u8bb8\u5b9a\u4f4d\uff09';
  }

  private async prepare(): Promise<void> {
    try {
      const token = await StorageUtil.getString('token');
      this.hasLoginToken = token !== null && token !== undefined && token.length > 0;
    } catch (e) {
      this.hasLoginToken = false;
      console.error('watch load token failed:', e);
    }
    try {
      const user: UserProfile | null = await StorageUtil.get<UserProfile>('user');
      if (user && user.phone) {
        this.contactPhone = user.phone;
      }
    } catch (e) {
      console.error('watch load user failed:', e);
    }
    await this.tryLocate();
  }

  private goLogin(): void {
    router.pushUrl({ url: 'pages/watch/WatchLoginPage' }).catch((err: Error) => {
      console.error('watch go login failed:', err);
    });
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
      this.lastLat = pos.latitude;
      this.lastLng = pos.longitude;
      this.hasGeo = true;
      const address = await GeocodeApi.getAddressFromCoordinates(pos.latitude, pos.longitude);
      this.locationText = address && address.length > 0
        ? address
        : `${pos.latitude.toFixed(5)}, ${pos.longitude.toFixed(5)}`;
    } catch (e) {
      console.error('watch locate failed:', e);
    } finally {
      this.isLocating = false;
    }
  }

  private buildPayload(): CreateEmergencyRequestPayload {
    const desc =
      '\u3010\u624b\u8868\u7aef\u3011\u4e00\u952e\u7d27\u6025\u6c42\u52a9\uff0c\u8bf7\u5c3d\u5feb\u8054\u7cfb\u6211\u3002';
    const loc = this.locationText.trim().length > 0
      ? this.locationText.trim()
      : '\u672a\u77e5\u4f4d\u7f6e\uff08\u624b\u8868\u7aef\u53d1\u8d77\uff09';
    const payload: CreateEmergencyRequestPayload = {
      type: 'other',
      description: desc,
      location: loc,
      contactPhone: this.contactPhone.trim()
    };
    if (this.hasGeo) {
      payload.latitude = this.lastLat;
      payload.longitude = this.lastLng;
    }
    return payload;
  }

  private async submit(): Promise<void> {
    if (this.isSubmitting) {
      return;
    }
    if (!this.hasLoginToken) {
      promptAction.showToast({
        message: '\u8bf7\u5148\u767b\u5f55',
        duration: 1500
      });
      this.goLogin();
      return;
    }
    if (this.contactPhone.trim().length < 7) {
      promptAction.showToast({
        message: '\u8bf7\u5728\u624b\u673a\u7aef\u5b8c\u5584\u624b\u673a\u53f7\u540e\u518d\u8bd5',
        duration: 2000
      });
      return;
    }

    this.isSubmitting = true;
    try {
      const payload = this.buildPayload();
      const created = await EmergencyApi.createEmergencyRequest(payload);
      promptAction.showToast({
        message: '\u5df2\u53d1\u9001\u6c42\u52a9',
        duration: 1500
      });
      router.replaceUrl({
        url: 'pages/watch/WatchMyRequestsPage',
        params: { createdId: created.id }
      }).catch((err: Error) => {
        console.error('nav after emergency failed:', err);
      });
    } catch (err) {
      const e = err as Error;
      console.error('watch emergency failed:', e);
      promptAction.showToast({
        message: e.message ? e.message : '\u53d1\u9001\u5931\u8d25',
        duration: 2000
      });
      if (e.message && e.message.indexOf('\u767b\u5f55') >= 0) {
        router.replaceUrl({ url: 'pages/watch/WatchLoginPage' }).catch(() => {
        });
      }
    } finally {
      this.isSubmitting = false;
    }
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 8 }) {
          // Title - reduce font size
          Text('\u4e00\u952e\u6c42\u52a9')
            .fontSize(this.largeFontEnabled ? 16 : 14)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.highContrastEnabled ? '#000000' : '#0f172a')
            .width('100%')
            .textAlign(TextAlign.Center)

          // Hint text - reduce font size
          Text(this.hint)
            .fontSize(this.largeFontEnabled ? 12 : 10)
            .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
            .width('100%')
            .textAlign(TextAlign.Center)
            .maxLines(5)

          // Login button (when not logged in) - replace with WatchButton
          if (!this.hasLoginToken) {
            WatchButton({
              text: '\u767b\u5f55',
              type: 'primary',
              size: 'medium',
              width: '100%',
              onClick: () => { this.goLogin(); }
            })
          }

          // Emergency submit button - replace with WatchButton
          WatchButton({
            text: this.isSubmitting ? '\u53d1\u9001\u4e2d...' : '\u53d1\u9001\u7d27\u6025\u6c42\u52a9',
            type: 'emergency',
            size: 'large',
            width: '100%',
            enabled: !this.isSubmitting,
            accessibilityLabel: '发送紧急求助按钮',
            onClick: () => { this.submit(); }
          })

          // Refresh location button - replace with WatchButton
          WatchButton({
            text: this.isLocating ? '\u5b9a\u4f4d\u4e2d...' : '\u5237\u65b0\u4f4d\u7f6e',
            type: 'secondary',
            size: 'small',
            width: '100%',
            enabled: !this.isLocating,
            onClick: () => {
              this.tryLocate().then(() => {
                this.hint = this.locationText.length > 0 ? '\u5df2\u66f4\u65b0\u4f4d\u7f6e' : '\u4ecd\u672a\u83b7\u53d6\u4f4d\u7f6e';
              });
            }
          })
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 30, bottom: 30 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.highContrastEnabled ? '#ffffff' : '#f8fafc')
  }
}
