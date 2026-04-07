import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { EmergencyApi, GeocodeApi, type CreateEmergencyRequestPayload } from '../../services/ApiService';
import { getCurrentPosition, requestLocationPermission } from '../../utils/LocationUtil';
import { StorageUtil } from '../../utils/StorageUtil';
import type { UserProfile } from '../../models/User';
import { WatchButton } from '../../components/WatchButton';

/**
 * 手表端：求助者一键紧急求助（大按钮、少输入，复用 EmergencyApi）
 * 需已登录且账号为求助者侧（与手机端接口一致）
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
    this.hint = '正在准备...';
    this.prepare().then(() => {
      this.applyHintAfterPrepare();
    }).catch(() => {
      this.hint = '请先登录后再试';
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
      this.hint = '未登录：手表与手机缓存独立，请在本设备登录';
      return;
    }
    if (this.contactPhone.trim().length < 7) {
      this.hint = '已登录但缺少手机号，请在手机端完善个人资料后再试';
      return;
    }
    this.hint = this.locationText.length > 0
      ? '已获取位置，可发送'
      : '未获取位置，仍可发送（建议允许定位）';
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
    const desc = '【手表端】一键紧急求助，请尽快联系我。';
    const loc = this.locationText.trim().length > 0
      ? this.locationText.trim()
      : '未知位置（手表端发起）';
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
        message: '请先登录',
        duration: 1500
      });
      this.goLogin();
      return;
    }
    if (this.contactPhone.trim().length < 7) {
      promptAction.showToast({
        message: '请在手机端完善手机号后再试',
        duration: 2000
      });
      return;
    }

    this.isSubmitting = true;
    try {
      const payload = this.buildPayload();
      const created = await EmergencyApi.createEmergencyRequest(payload);
      promptAction.showToast({
        message: '已发送求助',
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
        message: e.message ? e.message : '发送失败',
        duration: 2000
      });
      if (e.message && e.message.indexOf('登录') >= 0) {
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
          // Title
          Text('一键求助')
            .fontSize(this.largeFontEnabled ? 16 : 14)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.highContrastEnabled ? '#000000' : '#0f172a')
            .width('100%')
            .textAlign(TextAlign.Center)

          // Hint text
          Text(this.hint)
            .fontSize(this.largeFontEnabled ? 12 : 10)
            .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
            .width('100%')
            .textAlign(TextAlign.Center)
            .maxLines(5)

          // Login button (when not logged in)
          if (!this.hasLoginToken) {
            WatchButton({
              text: '登录',
              buttonType: 'primary',
              buttonSize: 'medium',
              buttonWidth: '100%'
            })
            .onClick(() => { this.goLogin(); })
          }

          // Emergency submit button
          WatchButton({
            text: this.isSubmitting ? '发送中...' : '发送紧急求助',
            buttonType: 'emergency',
            buttonSize: 'large',
            buttonWidth: '100%',
            buttonEnabled: !this.isSubmitting,
            accessibilityLabel: '发送紧急求助按钮'
          })
          .onClick(() => { this.submit(); })

          // Refresh location button
          WatchButton({
            text: this.isLocating ? '定位中...' : '刷新位置',
            buttonType: 'secondary',
            buttonSize: 'small',
            buttonWidth: '100%',
            buttonEnabled: !this.isLocating
          })
          .onClick(() => {
            this.tryLocate().then(() => {
              this.hint = this.locationText.length > 0 ? '已更新位置' : '仍未获取位置';
            });
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
