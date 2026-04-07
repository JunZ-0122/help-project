import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { WatchButton } from '../../components/WatchButton';
import { OrderApi } from '../../services/ApiService';
import { DateUtil } from '../../utils/DateUtil';
import type { VolunteerOrder } from '../../models/Order';

/**
 * 手表：志愿者订单服务中 / 完成（对接 OrderApi，无 WebSocket）
 */
@Entry
@Component
struct WatchVolunteerServicePage {
  @State orderId: string = '';
  @State isLoading: boolean = true;
  @State isUpdating: boolean = false;
  @State order: VolunteerOrder | null = null;
  @State elapsedSec: number = 0;
  private tickTimer: number = -1;

  aboutToAppear(): void {
    const p = router.getParams() as Record<string, string>;
    if (p && p['id']) {
      this.orderId = p['id'] as string;
    }
    this.load();
  }

  aboutToDisappear(): void {
    this.clearTimer();
  }

  private clearTimer(): void {
    if (this.tickTimer !== -1) {
      clearInterval(this.tickTimer);
      this.tickTimer = -1;
    }
  }

  private startTimerIfNeeded(o: VolunteerOrder): void {
    this.clearTimer();
    if (o.status !== 'in-progress') {
      return;
    }
    const startStr = o.startedAt || o.acceptedAt;
    const startMs = startStr ? new Date(startStr).getTime() : Date.now();
    const tick = (): void => {
      this.elapsedSec = Math.max(0, Math.floor((Date.now() - startMs) / 1000));
    };
    tick();
    this.tickTimer = setInterval(tick, 1000);
  }

  private formatElapsed(sec: number): string {
    const m = Math.floor(sec / 60);
    const s = sec % 60;
    return `${m}分${s < 10 ? '0' : ''}${s}秒`;
  }

  private async load(): Promise<void> {
    if (!this.orderId) {
      this.isLoading = false;
      return;
    }
    this.isLoading = true;
    try {
      const o = await OrderApi.getOrderDetail(this.orderId);
      this.order = o;
      this.startTimerIfNeeded(o);
    } catch (e) {
      const err = e as Error;
      promptAction.showToast({ message: err.message || '加载失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  private statusLabel(s: string): string {
    switch (s) {
      case 'accepted':
        return '已接单';
      case 'in-progress':
        return '服务中';
      case 'completed':
        return '已完成';
      case 'cancelled':
        return '已取消';
      default:
        return s;
    }
  }

  private safeText(value: string | undefined, fallback: string): string {
    if (!value) {
      return fallback;
    }
    const t = value.trim();
    if (t.length === 0) {
      return fallback;
    }
    if (/^[\?？\uFFFD]+$/.test(t)) {
      return fallback;
    }
    return t;
  }

  private startService(): void {
    if (!this.order || this.order.status !== 'accepted' || this.isUpdating) {
      return;
    }
    this.isUpdating = true;
    OrderApi.updateOrderStatus(this.orderId, 'in-progress')
      .then(() => {
        promptAction.showToast({ message: '已开始服务', duration: 1500 });
        this.load();
      })
      .catch((err: Error) => {
        promptAction.showToast({ message: err.message || '操作失败', duration: 2000 });
      })
      .finally(() => {
        this.isUpdating = false;
      });
  }

  private completeService(): void {
    if (!this.order || this.order.status !== 'in-progress' || this.isUpdating) {
      return;
    }
    promptAction.showDialog({
      title: '完成服务',
      message: '确认标记为已完成？',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '完成', color: '#10b981' }
      ]
    }).then((result) => {
      if (result.index !== 1) {
        return;
      }
      this.isUpdating = true;
      OrderApi.completeOrder(this.orderId)
        .then(() => {
          this.clearTimer();
          promptAction.showToast({ message: '服务已完成', duration: 1500 });
          router.replaceUrl({
            url: 'pages/watch/WatchVolunteerReviewPage',
            params: { id: this.orderId }
          }).catch((err: Error) => {
            console.error('nav review failed:', err);
          });
        })
        .catch((err: Error) => {
          promptAction.showToast({ message: err.message || '操作失败', duration: 2000 });
        })
        .finally(() => {
          this.isUpdating = false;
        });
    });
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        NavBackButton()
        Text('服务进度')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 0, right: 0, top: 0, bottom: 6 })
      .backgroundColor('#ffffff')

      if (this.isLoading) {
        Column({ space: 8 }) {
          LoadingProgress().width(32).height(32)
          Text('加载中...').fontSize(13).fontColor('#64748b')
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else if (!this.order) {
        Text('无订单数据')
          .layoutWeight(1)
          .fontColor('#94a3b8')
      } else {
        Scroll() {
          Column({ space: 12 }) {
            Text(this.safeText(this.order.title, '订单'))
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
            Text(this.statusLabel(this.order.status))
              .fontSize(11)
              .fontColor('#2563eb')
            Text(this.safeText(this.order.location, '位置未填写'))
              .fontSize(10)
              .fontColor('#64748b')
            Text(`求助者：${this.safeText(this.order.helpSeekerName, '求助者')}`)
              .fontSize(10)
              .fontColor('#64748b')
            Text(`接单时间：${DateUtil.format(this.order.acceptedAt, 'MM-DD HH:mm')}`)
              .fontSize(10)
              .fontColor('#94a3b8')

            if (this.order.status === 'in-progress') {
              Text(`本次计时：${this.formatElapsed(this.elapsedSec)}`)
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
                .fontColor('#0f172a')
            }

            if (this.order.status === 'accepted') {
              WatchButton({
                text: this.isUpdating ? '...' : '开始服务',
                buttonType: 'primary',
                buttonSize: 'medium',
                buttonWidth: '100%',
                buttonEnabled: !this.isUpdating
              })
              .onClick(() => { this.startService(); })
            }

            if (this.order.status === 'in-progress') {
              WatchButton({
                text: this.isUpdating ? '...' : '完成服务',
                buttonType: 'primary',
                buttonSize: 'medium',
                buttonWidth: '100%',
                buttonEnabled: !this.isUpdating
              })
              .onClick(() => { this.completeService(); })
            }

            if (this.order.status === 'completed') {
              WatchButton({
                text: '去评价',
                buttonType: 'secondary',
                buttonSize: 'medium',
                buttonWidth: '100%'
              })
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/watch/WatchVolunteerReviewPage',
                  params: { id: this.orderId }
                }).catch((err: Error) => {
                  console.error('nav review failed:', err);
                });
              })
            }
          }
          .width('100%')
          .padding(0)
        }
        .layoutWeight(1)
        .align(Alignment.TopStart)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f8fafc')
    .padding({ top: 30, bottom: 30, left: 12, right: 12 })
  }
}
