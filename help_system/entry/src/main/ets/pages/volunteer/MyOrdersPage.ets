import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { MessageApi, OrderApi } from '../../services/ApiService';
import type { VolunteerOrder } from '../../models/Order';

interface OrderCardItem {
  id: string;
  requestId: string;
  categoryLabel: string;
  titleText: string;
  location: string;
  locationShort: string;
  status: string;
  statusLabel: string;
  timeDisplay: string;
  completedTimeDisplay?: string;
  statusColor: string;
  statusBgColor: string;
  hasSeekerReview: boolean;
  unreadCount: number;
}

interface OrderStatusInfo {
  label: string;
  bgColor: string;
  textColor: string;
}

@Entry
@Component
struct MyOrdersPage {
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  @State orders: OrderCardItem[] = [];
  @State isLoading: boolean = false;

  private skipNextPageShow: boolean = true;

  aboutToAppear() {
    this.loadOrders();
  }

  onPageShow() {
    if (this.skipNextPageShow) {
      this.skipNextPageShow = false;
      return;
    }
    this.loadOrders();
  }

  async loadOrders(): Promise<void> {
    this.isLoading = true;

    try {
      const orders: VolunteerOrder[] = await OrderApi.getMyOrders();
      const items: OrderCardItem[] = orders.map((order: VolunteerOrder) => this.mapOrder(order));
      this.orders = items;
      this.loadUnreadCounts();
    } catch (err) {
      const error = err as Error;
      console.error('load orders failed:', error);
      promptAction.showToast({
        message: error.message ? error.message : '\u52a0\u8f7d\u8ba2\u5355\u5931\u8d25',
        duration: 1500
      });
    } finally {
      this.isLoading = false;
    }
  }

  private async loadUnreadCounts(): Promise<void> {
    if (this.orders.length === 0) {
      return;
    }
    const list = this.orders.slice();
    const maxFetch = 20;
    for (let i = 0; i < list.length && i < maxFetch; i++) {
      const item = list[i];
      try {
        const count: number = await MessageApi.countUnread(item.requestId);
        list[i] = {
          id: item.id,
          requestId: item.requestId,
          categoryLabel: item.categoryLabel,
          titleText: item.titleText,
          location: item.location,
          locationShort: item.locationShort,
          status: item.status,
          statusLabel: item.statusLabel,
          timeDisplay: item.timeDisplay,
          completedTimeDisplay: item.completedTimeDisplay,
          statusColor: item.statusColor,
          statusBgColor: item.statusBgColor,
          hasSeekerReview: item.hasSeekerReview,
          unreadCount: count
        };
      } catch (err) {
        list[i] = {
          id: item.id,
          requestId: item.requestId,
          categoryLabel: item.categoryLabel,
          titleText: item.titleText,
          location: item.location,
          locationShort: item.locationShort,
          status: item.status,
          statusLabel: item.statusLabel,
          timeDisplay: item.timeDisplay,
          completedTimeDisplay: item.completedTimeDisplay,
          statusColor: item.statusColor,
          statusBgColor: item.statusBgColor,
          hasSeekerReview: item.hasSeekerReview,
          unreadCount: 0
        };
      }
    }
    this.orders = list;
  }

  private mapOrder(order: VolunteerOrder): OrderCardItem {
    const statusInfo = this.getStatusInfo(order.status);
    const titleRaw: string = order.title && order.title.trim().length > 0 ? order.title : order.description;
    const titleText: string = titleRaw && titleRaw.trim().length > 0 ? titleRaw : '\u2014';
    const hasReview: boolean = order.status === 'completed' &&
      (order.seekerReviewed === true ||
        (order.rating !== undefined && order.rating !== null));
    return {
      id: order.id,
      requestId: order.requestId ? order.requestId : '',
      categoryLabel: this.getCategoryLabel(order.type),
      titleText: titleText,
      location: order.location,
      locationShort: MyOrdersPage.shortenLocation(order.location),
      status: order.status,
      statusLabel: statusInfo.label,
      timeDisplay: MyOrdersPage.formatChineseDateTime(order.acceptedAt),
      completedTimeDisplay: order.completedAt ? MyOrdersPage.formatChineseDateTime(order.completedAt) : undefined,
      statusColor: statusInfo.textColor,
      statusBgColor: statusInfo.bgColor,
      hasSeekerReview: hasReview,
      unreadCount: 0
    };
  }

  private getCategoryLabel(type: string): string {
    switch (type) {
      case 'medical':
        return '\u5c31\u533b\u534f\u52a9';
      case 'shopping':
        return '\u751f\u6d3b\u5e2e\u6276';
      case 'repair':
        return '\u7ef4\u4fee\u5e2e\u52a9';
      case 'companion':
        return '\u51fa\u884c\u534f\u52a9';
      case 'emergency':
        return '\u7d27\u6025\u6c42\u52a9';
      default:
        return '\u5176\u4ed6\u6c42\u52a9';
    }
  }

  private static formatChineseDateTime(iso: string): string {
    const d: Date = new Date(iso);
    const m: number = d.getMonth() + 1;
    const day: number = d.getDate();
    const hh: string = d.getHours().toString().padStart(2, '0');
    const mm: string = d.getMinutes().toString().padStart(2, '0');
    return `${m}\u6708${day}\u65e5 ${hh}:${mm}`;
  }

  /** \u6458\u8981\u663e\u793a\u8857\u9053/\u533a\u57df\uff0c\u8fc7\u957f\u5219\u622a\u65ad */
  private static shortenLocation(addr: string): string {
    if (!addr || addr.length === 0) {
      return '\u2014';
    }
    const streetMatch: RegExpMatchArray | null = addr.match(/([\u4e00-\u9fa5]{1,8}\u8857\u9053)/);
    if (streetMatch) {
      return streetMatch[1];
    }
    const areaMatch: RegExpMatchArray | null = addr.match(/([\u4e00-\u9fa5]{2,12}\u533a)/);
    if (areaMatch) {
      return areaMatch[1];
    }
    if (addr.length <= 10) {
      return addr;
    }
    return addr.substring(0, 10) + '\u2026';
  }

  private getStatusInfo(status: string): OrderStatusInfo {
    switch (status) {
      case 'accepted':
      case 'in-progress':
        return { label: '\u8fdb\u884c\u4e2d', bgColor: '#dbeafe', textColor: '#1d4ed8' };
      case 'completed':
        return { label: '\u5df2\u5b8c\u6210', bgColor: '#d1fae5', textColor: '#047857' };
      case 'cancelled':
        return { label: '\u5df2\u53d6\u6d88', bgColor: '#fee2e2', textColor: '#b91c1c' };
      default:
        return { label: '\u5904\u7406\u4e2d', bgColor: '#e5e7eb', textColor: '#374151' };
    }
  }

  goBack() {
    router.back();
  }

  handleOrderClick(order: OrderCardItem) {
    if (order.status === 'accepted' || order.status === 'in-progress') {
      router.pushUrl({
        url: 'pages/volunteer/ProgressPage',
        params: { id: order.id }
      }).catch((err: Error) => {
        console.error('navigation failed:', err);
      });
      return;
    }

    router.pushUrl({
      url: 'pages/volunteer/OrderDetailPage',
      params: { id: order.id }
    }).catch((err: Error) => {
      console.error('navigation failed:', err);
    });
  }

  @Builder
  OrderCard(order: OrderCardItem) {
    Column({ space: 14 }) {
      Row() {
        Row({ space: 8 }) {
          Text(order.categoryLabel)
            .fontSize(this.largeFontEnabled ? 14 : 12)
            .fontColor(this.highContrastEnabled ? '#000000' : '#4b5563')
            .fontWeight(FontWeight.Medium)
            .padding({ left: 8, right: 8, top: 5, bottom: 5 })
            .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#f3f4f6')
            .borderRadius(6)
            .border(this.highContrastEnabled ? { width: 2, color: '#000000' } : undefined)

          Row({ space: 6 }) {
            Circle({
              width: this.largeFontEnabled ? 8 : 6,
              height: this.largeFontEnabled ? 8 : 6
            })
              .fill(this.highContrastEnabled ? '#000000' : order.statusColor)

            Text(order.statusLabel)
              .fontSize(this.largeFontEnabled ? 14 : 12)
              .fontColor(this.highContrastEnabled ? '#000000' : order.statusColor)
              .fontWeight(FontWeight.Medium)
          }
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor(this.highContrastEnabled ? '#ffff00' : order.statusBgColor)
          .borderRadius(20)
          .border(this.highContrastEnabled ? { width: 2, color: '#000000' } : undefined)

          if (order.unreadCount > 0) {
            Text(order.unreadCount > 99 ? '99+' : `${order.unreadCount}\u672a\u8bfb`)
              .fontSize(this.largeFontEnabled ? 13 : 11)
              .fontColor('#ffffff')
              .fontWeight(FontWeight.Medium)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .backgroundColor('#ef4444')
              .borderRadius(10)
          }
        }
        .layoutWeight(1)

        Text('\u203A')
          .fontSize(this.largeFontEnabled ? 28 : 22)
          .fontColor(this.highContrastEnabled ? '#000000' : '#d1d5db')
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(order.titleText)
        .fontSize(this.largeFontEnabled ? 19 : 16)
        .fontColor(this.highContrastEnabled ? '#000000' : '#111827')
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .lineHeight(this.largeFontEnabled ? 28 : 24)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Row({ space: 16 }) {
        Row({ space: 6 }) {
          Text('\u231A')
            .fontSize(this.largeFontEnabled ? 15 : 13)
            .fontColor(this.highContrastEnabled ? '#000000' : '#9ca3af')
          Text(order.timeDisplay)
            .fontSize(this.largeFontEnabled ? 14 : 12)
            .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
            .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
        }

        Row({ space: 6 }) {
          Text('\u25CF')
            .fontSize(this.largeFontEnabled ? 8 : 6)
            .fontColor(this.highContrastEnabled ? '#000000' : '#2563eb')
          Text(order.locationShort)
            .fontSize(this.largeFontEnabled ? 14 : 12)
            .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
            .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
      }
      .width('100%')

      if (order.status === 'completed' && order.hasSeekerReview) {
        Row({ space: 6 }) {
          Text('\u2713')
            .fontSize(this.largeFontEnabled ? 15 : 13)
            .fontColor(this.highContrastEnabled ? '#000000' : '#059669')
            .fontWeight(FontWeight.Bold)
          Text('\u5bf9\u65b9\u5df2\u8bc4\u4ef7')
            .fontSize(this.largeFontEnabled ? 14 : 12)
            .fontColor(this.highContrastEnabled ? '#000000' : '#059669')
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
      }

      if (order.completedTimeDisplay !== undefined && order.completedTimeDisplay.length > 0) {
        Column() {
          Text(`\u5b8c\u6210\u65f6\u95f4\uff1a${order.completedTimeDisplay}`)
            .fontSize(this.largeFontEnabled ? 14 : 12)
            .fontColor(this.highContrastEnabled ? '#000000' : '#9ca3af')
            .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
            .width('100%')
        }
        .width('100%')
        .padding({ top: 12 })
        .border(this.highContrastEnabled ?
          { width: { top: 2 }, color: '#000000' } :
          { width: { top: 1 }, color: '#f3f4f6' }
        )
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
    .borderRadius(14)
    .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
    .shadow(this.highContrastEnabled ? undefined : {
      radius: 8,
      color: '#0f000000',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      this.handleOrderClick(order);
    })
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        NavBackButton()

        Text('\u6211\u7684\u63a5\u5355\u8bb0\u5f55')
          .fontSize(this.largeFontEnabled ? 22.5 : 18)
          .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
          .layoutWeight(1)
      }
      .width('100%')
      .padding(16)
      .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
      .border(this.highContrastEnabled ?
        { width: 3, color: '#000000' } :
        { width: { bottom: 1 }, color: '#e5e7eb' }
      )

      Scroll() {
        Column({ space: 12 }) {
          if (this.isLoading) {
            Text('\u52a0\u8f7d\u4e2d...')
              .fontSize(this.largeFontEnabled ? 17.5 : 14)
              .fontColor(this.highContrastEnabled ? '#000000' : '#9ca3af')
          } else if (this.orders.length === 0) {
            Column({ space: 12 }) {
              Text('\u2630')
                .fontSize(40)
                .fontColor(this.highContrastEnabled ? '#000000' : '#9ca3af')
              Text('\u6682\u65e0\u8ba2\u5355')
                .fontSize(this.largeFontEnabled ? 17.5 : 14)
                .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
            }
            .padding(24)
          } else {
            ForEach(this.orders, (order: OrderCardItem) => {
              this.OrderCard(order)
            }, (order: OrderCardItem) => order.id)
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 16, right: 16, top: 12, bottom: 16 })
      }
      .layoutWeight(1)
      .align(Alignment.TopStart)
      .scrollBar(BarState.Off)
      .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#f9fafb')
    }
    .width('100%')
    .height('100%')
  }
}


