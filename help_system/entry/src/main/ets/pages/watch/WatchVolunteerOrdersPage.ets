import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { WatchButton } from '../../components/WatchButton';
import { OrderApi } from '../../services/ApiService';
import type { VolunteerOrder } from '../../models/Order';

interface OrdRow {
  orderId: string;
  title: string;
  statusLabel: string;
  status: string;
}

@Entry
@Component
struct WatchVolunteerOrdersPage {
  @State orders: OrdRow[] = [];
  @State isLoading: boolean = true;

  aboutToAppear(): void {
    this.loadOrders();
  }

  onPageShow(): void {
    this.loadOrders();
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

  private statusColor(s: string): string {
    switch (s) {
      case 'accepted':
        return '#f59e0b';
      case 'in-progress':
        return '#2563eb';
      case 'completed':
        return '#10b981';
      case 'cancelled':
        return '#94a3b8';
      default:
        return '#64748b';
    }
  }

  private async loadOrders(): Promise<void> {
    this.isLoading = true;
    try {
      const list: VolunteerOrder[] = await OrderApi.getMyOrders();
      this.orders = list.map((o: VolunteerOrder): OrdRow => ({
        orderId: o.id,
        title: this.safeText(o.title, '订单'),
        statusLabel: this.statusLabel(o.status),
        status: o.status
      }));
    } catch (e) {
      const err = e as Error;
      promptAction.showToast({ message: err.message || '加载失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  private openOrder(orderId: string): void {
    router.pushUrl({
      url: 'pages/watch/WatchVolunteerServicePage',
      params: { id: orderId }
    }).catch((err: Error) => {
      console.error('nav failed:', err);
    });
  }

  build() {
    Column({ space: 6 }) {
      Row({ space: 8 }) {
        NavBackButton()
        Column({ space: 2 }) {
          Text('我的服务')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#0f172a')
          Text(this.orders.length > 0 ? `${this.orders.length}条服务记录` : '查看服务记录')
            .fontSize(9)
            .fontColor('#64748b')
        }
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 0, right: 0, top: 0, bottom: 2 })

      if (this.isLoading) {
        Column({ space: 6 }) {
          LoadingProgress().width(28).height(28)
          Text('加载中...').fontSize(11).fontColor('#64748b')
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.orders.length === 0) {
        Column({ space: 6 }) {
          Text('暂无订单')
            .fontSize(12)
            .fontColor('#94a3b8')
            .width('100%')
            .textAlign(TextAlign.Center)
          Text('完成服务后，这里会显示你的服务记录')
            .fontSize(9)
            .fontColor('#cbd5e1')
            .width('100%')
            .textAlign(TextAlign.Center)
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          List({ space: 8 }) {
            ForEach(this.orders, (o: OrdRow) => {
              ListItem() {
                Column({ space: 4 }) {
                  Row() {
                    Text(o.title)
                      .fontSize(12)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#0f172a')
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1)

                    Text(o.statusLabel)
                      .fontSize(10)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(this.statusColor(o.status))
                      .backgroundColor('#ffffff')
                      .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                      .borderRadius(999)
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Center)

                  Text(o.status === 'completed' ? '点击查看服务记录' : '点击进入服务详情')
                    .fontSize(9)
                    .fontColor('#64748b')
                }
                .width('100%')
                .padding(10)
                .backgroundColor('#ffffff')
                .border({ width: 1, color: '#e2e8f0' })
                .borderRadius(12)
                .shadow({ radius: 3, color: '#00000010', offsetY: 1 })
                .onClick(() => {
                  this.openOrder(o.orderId);
                })
              }
            }, (o: OrdRow) => o.orderId)
          }
          .width('100%')
        }
        .layoutWeight(1)
        .width('100%')
      }

      WatchButton({
        text: '刷新列表',
        buttonType: 'secondary',
        buttonSize: 'small',
        buttonWidth: '100%'
      })
      .onClick(() => {
        this.loadOrders();
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f8fafc')
    .padding({ top: 24, bottom: 20, left: 10, right: 10 })
  }

}
