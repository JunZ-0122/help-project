import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { EmergencyApi, GeocodeApi, RequestApi, type CreateEmergencyRequestPayload, type WatchRequestStatus } from '../../services/ApiService';
import { getCurrentPosition, requestLocationPermission } from '../../utils/LocationUtil';
import { StorageUtil } from '../../utils/StorageUtil';
import type { UserProfile } from '../../models/User';
import { WatchButton } from '../../components/WatchButton';

/**
 * 手表端：紧急求助五态流程页
 * 1. 确认发送
 * 2. 发送中
 * 3. 正在匹配志愿者
 * 4. 匹配成功
 * 5. 服务进度
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
  @State flowStage: 'confirm' | 'sending' | 'matching' | 'matched' | 'progress' | 'completed' | 'cancelled' = 'confirm';
  @State matchedVolunteerName: string = '李明';
  @State matchedDistance: string = '0.5公里';
  @State matchedTrust: string = '98%';
  @State currentRequestId: string = '';
  @State hasMatched: boolean = false;
  private pollTimer: number = -1;
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

  private goBack(): void {
    this.stopPolling();
    router.back();
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

  private stopPolling(): void {
    if (this.pollTimer !== -1) {
      globalThis.clearInterval(this.pollTimer);
      this.pollTimer = -1;
    }
  }

  private syncStageFromStatus(status: WatchRequestStatus): void {
    if (status.stage === 'matching' || status.stage === 'matched' || status.stage === 'progress' || status.stage === 'completed' || status.stage === 'cancelled') {
      this.flowStage = status.stage;
    }
    this.hasMatched = status.stage === 'matched' || status.stage === 'progress' || status.stage === 'completed';
    if (status.volunteerName && status.volunteerName.length > 0) {
      this.matchedVolunteerName = status.volunteerName;
    }
    if (status.distanceKm !== undefined && status.distanceKm !== null) {
      this.matchedDistance = `${status.distanceKm.toFixed(1)}公里`;
    }
    if (status.etaMinutes !== undefined && status.etaMinutes !== null) {
      this.matchedTrust = `${status.etaMinutes}分钟`;
    }
  }

  private async pollOnce(): Promise<void> {
    if (this.currentRequestId.length === 0) {
      return;
    }
    try {
      const status = await RequestApi.getWatchRequestStatus(this.currentRequestId);
      this.syncStageFromStatus(status);
      if (status.stage === 'completed' || status.stage === 'cancelled') {
        this.stopPolling();
      }
    } catch (e) {
      console.error('poll watch status failed:', e);
    }
  }

  private startPolling(requestId: string): void {
    this.currentRequestId = requestId;
    this.stopPolling();
    this.pollOnce().catch((err: Error) => {
      console.error('initial poll failed:', err);
    });
    this.pollTimer = setInterval(() => {
      this.pollOnce().catch((err: Error) => {
        console.error('poll tick failed:', err);
      });
    }, 3000);
  }

  private runFlow(): void {
    this.flowStage = 'sending';
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
    this.runFlow();
    try {
      const payload = this.buildPayload();
      const created = await EmergencyApi.createEmergencyRequest(payload);
      await EmergencyApi.startDevFlow(created.id);
      this.startPolling(created.id);
      promptAction.showToast({
        message: '已发送求助',
        duration: 1500
      });
    } catch (err) {
      const e = err as Error;
      console.error('watch emergency failed:', e);
      promptAction.showToast({
        message: e.message ? e.message : '发送失败',
        duration: 2000
      });
      this.flowStage = 'confirm';
      if (e.message && e.message.indexOf('登录') >= 0) {
        router.replaceUrl({ url: 'pages/watch/WatchLoginPage' }).catch(() => {
        });
      }
    } finally {
      this.isSubmitting = false;
    }
  }

  @Builder
  buildTopBar() {
    Row() {
      Stack() {
        Circle()
          .width(24)
          .height(24)
          .fill('#eef2ff')
        Text('←')
          .fontSize(16)
          .fontColor('#1e293b')
      }
      .onClick(() => { this.goBack(); })

      Blank()

      Text('紧急求助')
        .fontSize(this.largeFontEnabled ? 15 : 13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#0f172a')

      Blank()

      Stack() {
        Circle()
          .width(24)
          .height(24)
          .fill('transparent')
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  buildConfirmView() {
    Column({ space: 12 }) {
      Circle()
        .width(70)
        .height(70)
        .fill('#ef4444')
      Text('!')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor('#ffffff')
        .margin({ top: -58 })

      Text('紧急求助')
        .fontSize(this.largeFontEnabled ? 16 : 15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1f2937')

      Text('确认发送求助？')
        .fontSize(10)
        .fontColor('#6b7280')

      Row({ space: 4 }) {
        WatchButton({ text: '取消', buttonType: 'secondary', buttonSize: 'small', buttonWidth: '34%' })
          .onClick(() => { this.goBack(); })
        WatchButton({ text: '发送', buttonType: 'emergency', buttonSize: 'small', buttonWidth: '34%' })
          .onClick(() => { this.submit(); })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .padding({ left: 4, right: 4 })

      Text(this.hint)
        .fontSize(10)
        .fontColor('#64748b')
        .maxLines(3)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildSendingView() {
    Column({ space: 10 }) {
      Circle()
        .width(68)
        .height(68)
        .fill('rgba(239,68,68,0.12)')
      Text('◔')
        .fontSize(28)
        .fontColor('#ef4444')
        .margin({ top: -52 })

      Text('发送中...')
        .fontSize(this.largeFontEnabled ? 16 : 15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1f2937')

      Text('确认发送求助？')
        .fontSize(11)
        .fontColor('#6b7280')

      Text('正在将求助信息发送给系统')
        .fontSize(10)
        .fontColor('#94a3b8')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildMatchingView() {
    Column({ space: 10 }) {
      Circle()
        .width(72)
        .height(72)
        .fill('rgba(59,130,246,0.20)')
      Text('◎')
        .fontSize(30)
        .fontColor('#3b82f6')
        .margin({ top: -54 })

      Text('正在匹配志愿者')
        .fontSize(this.largeFontEnabled ? 16 : 15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1f2937')

      Text('请稍候')
        .fontSize(11)
        .fontColor('#6b7280')

      Text('正在为您寻找附近可协助人员')
        .fontSize(10)
        .fontColor('#94a3b8')
        .textAlign(TextAlign.Center)

      Row({ space: 4 }) {
        Circle().width(6).height(6).fill('#cbd5e1')
        Circle().width(6).height(6).fill('#cbd5e1')
        Circle().width(6).height(6).fill('#3b82f6')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildMatchedView() {
    Column({ space: 6 }) {
      Circle()
        .width(28)
        .height(16)
        .fill('#22c55e')
      Text('✓')
        .fontSize(12)
        .fontColor('#0f172a')
        .margin({ top: -16 })

      Text('匹配成功')
        .fontSize(this.largeFontEnabled ? 16 : 15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1f2937')

      Column({ space: 4 }) {
        Stack() {
          Circle()
            .width(26)
            .height(26)
            .fill('#e2e8f0')
          Circle()
            .width(9)
            .height(9)
            .fill('#4f46e5')
            .position({ x: 8, y: 4 })
          Circle()
            .width(12)
            .height(12)
            .fill('#4f46e5')
            .position({ x: 7, y: 11 })
        }
        .width(26)
        .height(26)

        Text('李明')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1f2937')
        Text('138****1234')
          .fontSize(9)
          .fontColor('#6b7280')
        Row({ space: 8 }) {
          Text('0.5公里')
            .fontSize(9)
            .fontColor('#6b7280')
          Text('98%')
            .fontSize(9)
            .fontColor('#6b7280')
        }
      }
      .width('100%')
      .padding(6)
      .backgroundColor('rgba(255,255,255,0.76)')
      .borderRadius(12)

      WatchButton({ text: '查看进度', buttonType: 'primary', buttonSize: 'small', buttonWidth: '64%' })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/watch/WatchMyRequestsPage',
            params: { createdId: this.currentRequestId }
          }).catch((err: Error) => {
            console.error('nav my requests failed:', err);
          });
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildProgressView() {
    Column({ space: 10 }) {
      Text('服务进度')
        .fontSize(this.largeFontEnabled ? 18 : 16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1f2937')

      Column({ space: 10 }) {
        Row({ space: 8 }) {
          Circle().width(16).height(16).fill('#22c55e')
          Text('已接单').fontSize(11).fontColor('#374151')
          Blank()
          Text('✓').fontSize(12).fontColor('#22c55e')
        }
        .width('100%')

        Row({ space: 8 }) {
          Circle().width(16).height(16).fill('#22c55e')
          Text('正在赶来').fontSize(11).fontColor('#374151')
          Blank()
          Text('✓').fontSize(12).fontColor('#22c55e')
        }
        .width('100%')

        Row({ space: 8 }) {
          Circle().width(16).height(16).fill('#4f46e5')
          Text('服务中').fontSize(11).fontColor('#374151')
          Blank()
          Text('3').fontSize(11).fontColor('#ffffff')
        }
        .width('100%')

        Row({ space: 8 }) {
          Circle().width(16).height(16).fill('#94a3b8')
          Text('已完成').fontSize(11).fontColor('#94a3b8')
          Blank()
          Text('4').fontSize(11).fontColor('#ffffff')
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 8, right: 8, top: 6, bottom: 6 })

      Row() {
        Text('志愿者 李明 正在为您服务')
          .fontSize(10)
          .fontColor('#6b7280')
          .maxLines(2)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Stack() {
      Circle()
        .width('100%')
        .height('100%')
        .fill(this.highContrastEnabled ? '#f8fafc' : '#ffffff')

      Column() {
        this.buildTopBar()

        Blank().height(6)

        Column({ space: 10 }) {
          if (this.flowStage === 'confirm') {
            this.buildConfirmView()
          } else if (this.flowStage === 'sending') {
            this.buildSendingView()
          } else if (this.flowStage === 'matching') {
            this.buildMatchingView()
          } else if (this.flowStage === 'matched') {
            this.buildMatchedView()
          } else {
            this.buildProgressView()
          }
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .padding({ top: 4, bottom: 4 })
      }
      .width('100%')
      .height('100%')
      .padding({ left: 12, right: 12, top: 12, bottom: 18 })

      Stack() {
        Circle()
          .width(28)
          .height(28)
          .fill('#f1f5f9')
          .shadow({ radius: 2, color: '#00000010', offsetY: 1 })

        Text('↺')
          .fontSize(18)
          .fontColor('#64748b')
      }
      .position({ x: 10, y: 10 })
      .onClick(() => {
        if (this.flowStage === 'confirm') {
          router.back();
          return;
        }
        this.flowStage = 'confirm';
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ffffff')
  }
}
