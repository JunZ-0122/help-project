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
    Column() {
      Row({ space: 8 }) {
        NavBackButton()
        Text('我的服务')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 0, right: 0, top: 0, bottom: 6 })

      if (this.isLoading) {
        Column({ space: 6 }) {
          LoadingProgress().width(28).height(28)
          Text('加载中...').fontSize(11).fontColor('#64748b')
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.orders.length === 0) {
        Text('暂无订单')
          .fontSize(12)
          .fontColor('#94a3b8')
          .layoutWeight(1)
          .width('100%')
          .textAlign(TextAlign.Center)
      } else {
        List({ space: 6 }) {
          ForEach(this.orders, (o: OrdRow) => {
            ListItem() {
              Row() {
                Column({ space: 3 }) {
                  Text(o.title)
                    .fontSize(12)
                    .fontWeight(FontWeight.Medium)
                    .maxLines(2)
                  Text(o.statusLabel)
                    .fontSize(10)
                    .fontColor(this.statusColor(o.status))
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              .width('100%')
              .padding(8)
              .backgroundColor(o.status === 'accepted' || o.status === 'in-progress' ? '#eff6ff' : '#ffffff')
              .borderRadius(8)
              .onClick(() => {
                this.openOrder(o.orderId);
              })
            }
          }, (o: OrdRow) => o.orderId)
        }
        .layoutWeight(1)
        .width('100%')
      }

      WatchButton({
        text: 'xxx',
        buttonType: 'secondary',
        buttonSize: 'small',
        buttonWidth: '100%'
      })
        .onClick(() => {
          this.xxx();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f8fafc')
    .padding({ top: 30, bottom: 30, left: 12, right: 12 })
  }

  xxx() {
    throw new Error('Method not implemented.');
  }
}
