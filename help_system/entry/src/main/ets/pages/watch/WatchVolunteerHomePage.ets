import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { getCurrentPosition, requestLocationPermission } from '../../utils/LocationUtil';
import type { LocationPoint } from '../../utils/LocationUtil';
import { HelpRequestWithDistance, OrderApi, RequestApi, UserApi, type RequestListFilters } from '../../services/ApiService';
import { AuthService } from '../../services/AuthService';
import type { HelpRequest } from '../../models/Request';
import type { VolunteerOrder } from '../../models/Order';

interface ReqRow {
  id: string;
  title: string;
  sub: string;
  distanceKm?: number;
}

interface OrdRow {
  orderId: string;
  title: string;
  status: string;
}

/**
 * 手表：志愿者首页 — 附近待接求助 + 进行中订单（接口与手机 VolunteerHomePage 一致）。
 */
@Entry
@Component
struct WatchVolunteerHomePage {
  @State requests: ReqRow[] = [];
  @State orders: OrdRow[] = [];
  @State isLoading: boolean = true;

  aboutToAppear(): void {
    this.loadAll();
  }

  private async loadAll(): Promise<void> {
    this.isLoading = true;
    await Promise.all([this.loadRequests(), this.loadOrders()]);
    this.isLoading = false;
  }

  private async loadRequests(): Promise<void> {
    try {
      await requestLocationPermission();
      let pos = await getCurrentPosition();
      if (!pos) {
        const fallback: LocationPoint = { latitude: 39.9042, longitude: 116.4074 };
        pos = fallback;
      }
      try {
        await UserApi.reportLocation(pos.latitude, pos.longitude, undefined, 'watch');
      } catch (_) {
        // ignore
      }
      try {
        const res = await RequestApi.getNearbyRequests(1, 15, pos.latitude, pos.longitude);
        this.requests = res.items.map((it: HelpRequestWithDistance): ReqRow => this.mapNearbyToReqRow(it));
      } catch (_) {
        const pendingFilter: RequestListFilters = { status: 'pending' };
        const res = await RequestApi.getRequests(1, 15, pendingFilter);
        this.requests = res.items.map((r: HelpRequest): ReqRow => this.mapHelpRequestToReqRow(r));
      }
    } catch (e) {
      const err = e as Error;
      console.error('watch load requests failed:', err);
    }
  }

  private async loadOrders(): Promise<void> {
    try {
      const list: VolunteerOrder[] = await OrderApi.getMyOrders();
      const active = list.filter(
        (o: VolunteerOrder) => o.status === 'accepted' || o.status === 'in-progress'
      );
      this.orders = active.map((o: VolunteerOrder): OrdRow => this.mapOrderToOrdRow(o));
    } catch (e) {
      const err = e as Error;
      console.error('watch load orders failed:', err);
    }
  }

  private mapNearbyToReqRow(it: HelpRequestWithDistance): ReqRow {
    const row: ReqRow = {
      id: it.request.id,
      title: this.safeText(it.request.title, this.typeLabel(it.request.type)),
      sub: this.safeText(it.request.location, '位置未填写'),
      distanceKm: it.distance
    };
    return row;
  }

  private mapHelpRequestToReqRow(r: HelpRequest): ReqRow {
    const row: ReqRow = {
      id: r.id,
      title: this.safeText(r.title, this.typeLabel(r.type)),
      sub: this.safeText(r.location, '位置未填写')
    };
    return row;
  }

  private mapOrderToOrdRow(o: VolunteerOrder): OrdRow {
    const row: OrdRow = {
      orderId: o.id,
      title: this.safeText(o.title, '订单'),
      status: o.status
    };
    return row;
  }

  private safeText(value: string | undefined, fallback: string): string {
    if (!value) {
      return fallback;
    }
    const t = value.trim();
    if (t.length === 0) {
      return fallback;
    }
    if (/^[\?？�]+$/.test(t)) {
      return fallback;
    }
    return t;
  }

  private typeLabel(t: string): string {
    switch (t) {
      case 'medical':
        return '就医';
      case 'companion':
        return '出行';
      case 'emergency':
        return '紧急';
      default:
        return '求助';
    }
  }

  private openRequest(id: string): void {
    router.pushUrl({
      url: 'pages/watch/WatchVolunteerRequestDetailPage',
      params: { id: id }
    }).catch((err: Error) => {
      console.error('nav failed:', err);
    });
  }

  private openOrder(orderId: string): void {
    router.pushUrl({
      url: 'pages/watch/WatchVolunteerServicePage',
      params: { id: orderId }
    }).catch((err: Error) => {
      console.error('nav failed:', err);
    });
  }

  private async logout(): Promise<void> {
    await AuthService.logout();
    promptAction.showToast({ message: '已退出', duration: 1500 });
    router.replaceUrl({ url: 'pages/watch/WatchLoginPage' }).catch((err: Error) => {
      console.error('nav login failed:', err);
    });
  }

  build() {
    Column() {
      Text('志愿者')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 6, bottom: 6 })

      if (this.isLoading) {
        Column({ space: 8 }) {
          LoadingProgress().width(32).height(32)
          Text('加载中...').fontSize(12).fontColor('#64748b')
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 12 }) {
            Text('附近待接')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .width('100%')

            if (this.requests.length === 0) {
              Text('暂无待接求助').fontSize(12).fontColor('#94a3b8')
            } else {
              ForEach(this.requests, (r: ReqRow) => {
                Column({ space: 4 }) {
                  Text(r.title)
                    .fontSize(13)
                    .fontWeight(FontWeight.Medium)
                    .maxLines(2)
                  Text(r.sub)
                    .fontSize(10)
                    .fontColor('#64748b')
                    .maxLines(2)
                  if (r.distanceKm !== undefined) {
                    Text(`约 ${r.distanceKm.toFixed(1)} km`)
                      .fontSize(10)
                      .fontColor('#94a3b8')
                  }
                }
                .width('100%')
                .padding(8)
                .backgroundColor('#ffffff')
                .borderRadius(10)
                .onClick(() => {
                  this.openRequest(r.id);
                })
              }, (r: ReqRow) => r.id)
            }

            Text('进行中的订单')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .width('100%')
              .margin({ top: 8 })

            if (this.orders.length === 0) {
              Text('暂无').fontSize(12).fontColor('#94a3b8')
            } else {
              ForEach(this.orders, (o: OrdRow) => {
                Row() {
                  Column({ space: 4 }) {
                    Text(o.title).fontSize(13).maxLines(1)
                    Text(o.status === 'accepted' ? '已接单' : '服务中')
                      .fontSize(10)
                      .fontColor('#2563eb')
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                }
                .width('100%')
                .padding(8)
                .backgroundColor('#eff6ff')
                .borderRadius(10)
                .onClick(() => {
                  this.openOrder(o.orderId);
                })
              }, (o: OrdRow) => o.orderId)
            }

            Button('刷新')
              .width('100%')
              .height(36)
              .fontSize(13)
              .margin({ top: 8 })
              .onClick(() => {
                this.loadAll();
              })

            Button('退出登录')
              .width('100%')
              .height(36)
              .fontSize(13)
              .backgroundColor('#f1f5f9')
              .fontColor('#334155')
              .onClick(() => {
                this.logout();
              })
          }
          .width('100%')
          .padding(10)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.TopStart)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f8fafc')
    .padding({ top: 4 })
  }
}
