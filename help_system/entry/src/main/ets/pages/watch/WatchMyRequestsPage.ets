import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { RequestApi } from '../../services/ApiService';
import { DateUtil } from '../../utils/DateUtil';
import type { HelpRequest } from '../../models/Request';

interface WatchRequestRow {
  id: string;
  title: string;
  statusLabel: string;
  timeShort: string;
}

interface RouteParams {
  createdId?: string;
}

/**
 * 手表：我的求助列表（�?UI 适配，接口与手机 MyRequestsPage 一致）�?
 */
@Entry
@Component
struct WatchMyRequestsPage {
  @State items: WatchRequestRow[] = [];
  @State isLoading: boolean = true;
  @State highlightId: string = '';

  aboutToAppear(): void {
    const p = router.getParams() as RouteParams;
    if (p && p.createdId) {
      this.highlightId = p.createdId as string;
    }
    this.loadList();
  }

  private async loadList(): Promise<void> {
    this.isLoading = true;
    try {
      const res = await RequestApi.getMyRequests(1, 40);
      this.items = res.items.map((r: HelpRequest): WatchRequestRow => ({
        id: r.id,
        title: this.safeText(r.title, this.typeLabel(r.type)),
        statusLabel: this.statusLabel(r.status),
        timeShort: DateUtil.format(r.createdAt, 'MM-DD HH:mm')
      }));
    } catch (e) {
      const err = e as Error;
      promptAction.showToast({ message: err.message || '加载失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  private typeLabel(t: string): string {
    switch (t) {
      case 'medical':
        return '就医求助';
      case 'companion':
        return '出行协助';
      case 'shopping':
        return '生活帮扶';
      case 'emergency':
        return '紧急求�?;
      default:
        return '求助';
    }
  }

  private statusLabel(s: string): string {
    switch (s) {
      case 'pending':
        return '待接�?;
      case 'assigned':
        return '已分�?;
      case 'in-progress':
        return '进行�?;
      case 'completed':
        return '已完�?;
      case 'cancelled':
        return '已取�?;
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
    // 后端偶发乱码/问号串时，手表端做兜底文�?
    if (/^[\?？�]+$/.test(t)) {
      return fallback;
    }
    return t;
  }

  private openDetail(id: string): void {
    router.pushUrl({
      url: 'pages/watch/WatchSeekerRequestDetailPage',
      params: { id: id }
    }).catch((err: Error) => {
      console.error('nav detail failed:', err);
    });
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        NavBackButton()
        Text('我的求助')
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
          Text('加载�?..').fontSize(13).fontColor('#64748b')
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.items.length === 0) {
        Text('暂无记录')
          .fontSize(14)
          .fontColor('#94a3b8')
          .layoutWeight(1)
          .width('100%')
          .textAlign(TextAlign.Center)
      } else {
        List({ space: 6 }) {
          ForEach(this.items, (row: WatchRequestRow) => {
            ListItem() {
              Column({ space: 4 }) {
                Text(row.title)
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .maxLines(2)
                  .fontColor(row.id === this.highlightId ? '#2563eb' : '#0f172a')
                Row() {
                  Text(row.statusLabel).fontSize(10).fontColor('#64748b')
                  Text(row.timeShort).fontSize(10).fontColor('#94a3b8')
                }
                .width('100%')
                .justifyContent(FlexAlign.SpaceBetween)
              }
              .width('100%')
              .padding(8)
              .backgroundColor(row.id === this.highlightId ? '#eff6ff' : '#ffffff')
              .borderRadius(10)
              .onClick(() => {
                this.openDetail(row.id);
              })
            }
          }, (row: WatchRequestRow) => row.id)
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: 0, right: 0, bottom: 0 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f8fafc')
    .padding({ top: 30, bottom: 30, left: 12, right: 12 })
  }
}
