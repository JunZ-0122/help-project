import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { WatchButton } from '../../components/WatchButton';
import { getCurrentPosition } from '../../utils/LocationUtil';
import { OrderApi, RequestApi } from '../../services/ApiService';
import { DateUtil } from '../../utils/DateUtil';
import type { HelpRequest } from '../../models/Request';
import type { VolunteerOrder } from '../../models/Order';

interface ReqView {
  id: string;
  typeLabel: string;
  description: string;
  location: string;
  timeAgo: string;
  seekerName: string;
  status: string;
  statusLabel: string;
  acceptEnabled: boolean;
  distanceKm?: number;
}

/**
 * 手表：志愿者查看待接求助并接单
 */
@Entry
@Component
struct WatchVolunteerRequestDetailPage {
  @State requestId: string = '';
  @State isLoading: boolean = true;
  @State isAccepting: boolean = false;
  @State req: ReqView = {
    id: '',
    typeLabel: '',
    description: '',
    location: '',
    timeAgo: '',
    seekerName: '',
    status: 'pending',
    statusLabel: '待接单',
    acceptEnabled: false
  };

  aboutToAppear(): void {
    const p = router.getParams() as Record<string, string>;
    if (p && p['id']) {
      this.requestId = p['id'] as string;
    }
    this.load();
  }

  private static haversineKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371;
    const toRad = (d: number): number => d * Math.PI / 180;
    const dLat = toRad(lat2 - lat1);
    const dLon = toRad(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  private async load(): Promise<void> {
    if (!this.requestId) {
      this.isLoading = false;
      return;
    }
    this.isLoading = true;
    try {
      const raw: HelpRequest = await RequestApi.getRequestDetail(this.requestId);
      let v = this.mapReq(raw);
      const pos = await getCurrentPosition();
      if (pos && raw.latitude !== undefined && raw.longitude !== undefined) {
        v.distanceKm = WatchVolunteerRequestDetailPage.haversineKm(
          pos.latitude,
          pos.longitude,
          raw.latitude,
          raw.longitude
        );
      }
      this.req = v;
    } catch (e) {
      const err = e as Error;
      promptAction.showToast({ message: err.message || '\u52a0\u8f7d\u5931\u8d25', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  private mapReq(request: HelpRequest): ReqView {
    const desc =
      request.description && request.description.trim().length > 0
        ? request.description
        : this.safeText(request.title, '无');
    return {
      id: request.id,
      typeLabel: this.typeLabel(request.type),
      description: this.safeText(desc, '未填写描述'),
      location: this.safeText(request.location, '位置未填写'),
      timeAgo: DateUtil.getRelativeTime(request.createdAt),
      seekerName: this.safeText(request.userName, '求助者'),
      status: request.status,
      statusLabel: this.statusLabel(request.status),
      acceptEnabled: request.status === 'pending'
    };
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

  private typeLabel(t: string): string {
    switch (t) {
      case 'medical':
        return '就医协助';
      case 'shopping':
        return '生活帮扶';
      case 'companion':
        return '出行协助';
      case 'emergency':
        return '紧急';
      default:
        return '其他';
    }
  }

  private statusLabel(s: string): string {
    switch (s) {
      case 'pending':
        return '待接单';
      case 'assigned':
        return '已分配';
      case 'in-progress':
        return '进行中';
      case 'completed':
        return '已完成';
      case 'cancelled':
        return '已取消';
      default:
        return s;
    }
  }

  private accept(): void {
    if (!this.req.acceptEnabled || this.isAccepting) {
      return;
    }
    this.isAccepting = true;
    OrderApi.acceptOrder(this.requestId)
      .then((order: VolunteerOrder) => {
        promptAction.showToast({ message: '接单成功', duration: 1500 });
        router.replaceUrl({
          url: 'pages/watch/WatchVolunteerServicePage',
          params: { id: order.id }
        }).catch((err: Error) => {
          console.error('nav service failed:', err);
        });
      })
      .catch((err: Error) => {
        promptAction.showToast({ message: err.message || '接单失败', duration: 2000 });
      })
      .finally(() => {
        this.isAccepting = false;
        this.load();
      });
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        NavBackButton()
        Text('求助详情')
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
      } else {
        Scroll() {
          Column({ space: 10 }) {
            Text(this.req.typeLabel)
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
            Text(this.req.statusLabel)
              .fontSize(11)
              .fontColor('#2563eb')
            Text(this.req.description)
              .fontSize(11)
              .fontColor('#334155')
            Text(this.req.location)
              .fontSize(10)
              .fontColor('#64748b')
            Text(`${this.req.seekerName} · ${this.req.timeAgo}`)
              .fontSize(10)
              .fontColor('#94a3b8')
            if (this.req.distanceKm !== undefined) {
              Text(`距 ${this.req.distanceKm.toFixed(1)} km`)
                .fontSize(11)
                .fontColor('#64748b')
            }

            if (this.req.acceptEnabled) {
              WatchButton({
                text: this.isAccepting ? '接单中...' : '接单',
                buttonType: 'primary',
                buttonSize: 'medium',
                buttonWidth: '100%',
                buttonEnabled: !this.isAccepting
              })
              .onClick(() => { this.accept(); })
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
