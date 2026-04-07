import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { WatchButton } from '../../components/WatchButton';
import { getCurrentPosition, requestLocationPermission } from '../../utils/LocationUtil';
import type { LocationPoint } from '../../utils/LocationUtil';
import { HelpRequestWithDistance, RequestApi, UserApi, type RequestListFilters } from '../../services/ApiService';
import type { HelpRequest } from '../../models/Request';

interface ReqRow {
  id: string;
  title: string;
  sub: string;
  distanceKm?: number;
}

@Entry
@Component
struct WatchVolunteerNearbyPage {
  @State requests: ReqRow[] = [];
  @State isLoading: boolean = true;

  aboutToAppear(): void {
    this.loadRequests();
  }

  private safeText(value: string | undefined, fallback: string): string {
    if (!value) {
      return fallback;
    }
    const t = value.trim();
    if (t.length === 0) {
      return fallback;
    }
    if (/^[\?？\u{FFFD}]+$/u.test(t)) {
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
        return '紧�?;
      default:
        return '求助';
    }
  }

  private async loadRequests(): Promise<void> {
    this.isLoading = true;
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
        this.requests = res.items.map((it: HelpRequestWithDistance): ReqRow => ({
          id: it.request.id,
          title: this.safeText(it.request.title, this.typeLabel(it.request.type)),
          sub: this.safeText(it.request.location, '位置未填�?),
          distanceKm: it.distance
        }));
      } catch (_) {
        const pendingFilter: RequestListFilters = { status: 'pending' };
        const res = await RequestApi.getRequests(1, 15, pendingFilter);
        this.requests = res.items.map((r: HelpRequest): ReqRow => ({
          id: r.id,
          title: this.safeText(r.title, this.typeLabel(r.type)),
          sub: this.safeText(r.location, '位置未填�?)
        }));
      }
    } catch (e) {
      const err = e as Error;
      promptAction.showToast({ message: err.message || '加载失败', duration: 2000 });
    } finally {
      this.isLoading = false;
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

  build() {
    Column() {
      Row({ space: 8 }) {
        NavBackButton()
        Text('附近求助')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 0, right: 0, top: 0, bottom: 6 })

      if (this.isLoading) {
        Column({ space: 6 }) {
          LoadingProgress().width(28).height(28)
          Text('加载�?..').fontSize(11).fontColor('#64748b')
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.requests.length === 0) {
        Text('暂无待接求助')
          .fontSize(12)
          .fontColor('#94a3b8')
          .layoutWeight(1)
          .width('100%')
          .textAlign(TextAlign.Center)
      } else {
        List({ space: 6 }) {
          ForEach(this.requests, (r: ReqRow) => {
            ListItem() {
              Column({ space: 3 }) {
                Text(r.title)
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .maxLines(2)
                Text(r.sub)
                  .fontSize(10)
                  .fontColor('#64748b')
                  .maxLines(1)
                if (r.distanceKm !== undefined) {
                  Text(`�?${r.distanceKm.toFixed(1)} km`)
                    .fontSize(10)
                    .fontColor('#94a3b8')
                }
              }
              .width('100%')
              .padding(8)
              .backgroundColor('#ffffff')
              .borderRadius(8)
              .onClick(() => {
                this.openRequest(r.id);
              })
            }
          }, (r: ReqRow) => r.id)
        }
        .layoutWeight(1)
        .width('100%')
      }

      WatchButton({
        text: '刷新',
        buttonType: 'secondary',
        buttonSize: 'small',
        buttonWidth: '100%',
        onClick: () => {
          this.loadRequests();
        }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f8fafc')
    .padding({ top: 30, bottom: 30, left: 12, right: 12 })
  }
}
