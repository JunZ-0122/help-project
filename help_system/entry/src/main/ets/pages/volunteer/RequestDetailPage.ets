import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { DateUtil } from '../../utils/DateUtil';
import { getCurrentPosition } from '../../utils/LocationUtil';
import { OrderApi, RequestApi } from '../../services/ApiService';
import type { HelpRequest } from '../../models/Request';

interface RequesterInfo {
  name: string;
  phone: string;
}

interface RequestInfo {
  id: string;
  typeLabel: string;
  description: string;
  location: string;
  timeAgo: string;
  requester: RequesterInfo;
  status: string;
  statusLabel: string;
  acceptEnabled: boolean;
  distanceKm?: number;
}

@Entry
@Component
struct RequestDetailPage {
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  @State requestId: string = '';
  @State isLoading: boolean = true;
  @State isAccepting: boolean = false;
  @State request: RequestInfo = {
    id: '',
    typeLabel: '',
    description: '',
    location: '',
    timeAgo: '',
    requester: {
      name: '',
      phone: ''
    },
    status: 'pending',
    statusLabel: '\u5f85\u63a5\u5355',
    acceptEnabled: false
  };

  aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    if (params && params['id']) {
      this.requestId = params['id'] as string;
    }
    this.loadRequestDetail();
  }

  private async loadRequestDetail(): Promise<void> {
    if (!this.requestId) {
      this.isLoading = false;
      return;
    }

    this.isLoading = true;

    try {
      const raw: HelpRequest = await RequestApi.getRequestDetail(this.requestId);
      let info: RequestInfo = this.mapRequestInfo(raw);
      const pos = await getCurrentPosition();
      if (pos && raw.latitude !== undefined && raw.longitude !== undefined &&
        raw.latitude !== null && raw.longitude !== null) {
        info.distanceKm = RequestDetailPage.haversineKm(
          pos.latitude, pos.longitude, raw.latitude, raw.longitude
        );
      }
      this.request = info;
    } catch (err) {
      const error = err as Error;
      console.error('load volunteer request detail failed:', error);
      promptAction.showToast({
        message: error.message ? error.message : '\u52a0\u8f7d\u6c42\u52a9\u8be6\u60c5\u5931\u8d25',
        duration: 1500
      });
    } finally {
      this.isLoading = false;
    }
  }

  private mapRequestInfo(request: HelpRequest): RequestInfo {
    const desc: string = request.description && request.description.trim().length > 0 ?
      request.description :
      (request.title && request.title.trim().length > 0 ? request.title : '\u2014');
    return {
      id: request.id,
      typeLabel: this.getTypeLabel(request.type),
      description: desc,
      location: request.location,
      timeAgo: DateUtil.getRelativeTime(request.createdAt),
      requester: {
        name: request.userName ? request.userName : '\u6c42\u52a9\u8005',
        phone: request.userPhone ? request.userPhone : '\u6682\u65e0\u7535\u8bdd'
      },
      status: request.status,
      statusLabel: this.getStatusLabel(request.status),
      acceptEnabled: request.status === 'pending'
    };
  }

  private static avatarChar(name: string): string {
    if (!name || name.length === 0) {
      return 'U';
    }
    return name.substring(0, 1);
  }

  /** \u5730\u7403\u534a\u5f84 km */
  private static haversineKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R: number = 6371;
    const toRad = (d: number): number => d * Math.PI / 180;
    const dLat: number = toRad(lat2 - lat1);
    const dLon: number = toRad(lon2 - lon1);
    const a: number = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c: number = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  private getTypeLabel(type: string): string {
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

  private getStatusLabel(status: string): string {
    switch (status) {
      case 'pending':
        return '\u5f85\u63a5\u5355';
      case 'assigned':
        return '\u5df2\u88ab\u63a5\u5355';
      case 'in-progress':
        return '\u8fdb\u884c\u4e2d';
      case 'completed':
        return '\u5df2\u5b8c\u6210';
      case 'cancelled':
        return '\u5df2\u53d6\u6d88';
      default:
        return '\u5904\u7406\u4e2d';
    }
  }

  goBack() {
    router.back();
  }

  handleAccept() {
    if (!this.request.acceptEnabled || this.isAccepting) {
      return;
    }

    this.isAccepting = true;

    OrderApi.acceptOrder(this.requestId).then(() => {
      console.info('[RequestDetailPage] 接单成功');
      router.replaceUrl({
        url: 'pages/volunteer/MyOrdersPage'
      }).catch((err: Error) => {
        console.error('navigation failed:', err);
      });
    }).catch((err: Error) => {
      console.error('accept order failed:', err);
    }).finally(() => {
      this.isAccepting = false;
      this.loadRequestDetail();
    });
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        NavBackButton()

        Text('\u6c42\u52a9\u8be6\u60c5')
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

      if (this.isLoading) {
        Column({ space: 16 }) {
          LoadingProgress()
            .width(36)
            .height(36)
          Text('\u52a0\u8f7d\u4e2d...')
            .fontSize(this.largeFontEnabled ? 20 : 16)
            .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#f9fafb')
      } else {
        Scroll() {
          Column({ space: 12 }) {
            Column({ space: 14 }) {
              Row({ space: 8 }) {
                Circle({ width: 8, height: 8 })
                  .fill(this.highContrastEnabled ? '#000000' : '#2563eb')
                Text('\u6c42\u52a9\u7c7b\u578b')
                  .fontSize(this.largeFontEnabled ? 17 : 15)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#374151')
                  .fontWeight(FontWeight.Medium)
              }

              Text(this.request.typeLabel)
                .fontSize(this.largeFontEnabled ? 20 : 17)
                .fontColor(this.highContrastEnabled ? '#000000' : '#111827')
                .fontWeight(FontWeight.Medium)
                .width('100%')
            }
            .width('100%')
            .padding(16)
            .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
            .borderRadius(12)
            .alignItems(HorizontalAlign.Start)
            .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
            .shadow(this.highContrastEnabled ? undefined : {
              radius: 6,
              color: '#0f000000',
              offsetX: 0,
              offsetY: 2
            })

            Column({ space: 10 }) {
              Text('\u6c42\u52a9\u8bf4\u660e')
                .fontSize(this.largeFontEnabled ? 17 : 15)
                .fontColor(this.highContrastEnabled ? '#000000' : '#374151')
                .fontWeight(FontWeight.Medium)
                .width('100%')

              Text(this.request.description)
                .fontSize(this.largeFontEnabled ? 18 : 15)
                .fontColor(this.highContrastEnabled ? '#000000' : '#1f2937')
                .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
                .lineHeight(this.largeFontEnabled ? 26 : 22)
                .width('100%')

              Text(`\u53d1\u5e03\u65f6\u95f4\uff1a${this.request.timeAgo}`)
                .fontSize(this.largeFontEnabled ? 14 : 12)
                .fontColor(this.highContrastEnabled ? '#000000' : '#9ca3af')
                .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
                .margin({ top: 4 })
            }
            .width('100%')
            .padding(16)
            .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
            .borderRadius(12)
            .alignItems(HorizontalAlign.Start)
            .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
            .shadow(this.highContrastEnabled ? undefined : {
              radius: 6,
              color: '#0f000000',
              offsetX: 0,
              offsetY: 2
            })

            Column({ space: 12 }) {
              Text('\u6c42\u52a9\u5730\u70b9')
                .fontSize(this.largeFontEnabled ? 17 : 15)
                .fontColor(this.highContrastEnabled ? '#000000' : '#374151')
                .fontWeight(FontWeight.Medium)
                .width('100%')

              Row({ space: 8 }) {
                Text('\u25CF')
                  .fontSize(this.largeFontEnabled ? 12 : 10)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#2563eb')
                Text(this.request.location)
                  .fontSize(this.largeFontEnabled ? 16 : 14)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#111827')
                  .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
                  .lineHeight(this.largeFontEnabled ? 24 : 20)
                  .layoutWeight(1)
              }
              .width('100%')
              .alignItems(VerticalAlign.Top)

              if (this.request.distanceKm !== undefined && this.request.distanceKm !== null) {
                Text(`\u8ddd\u79bb\u60a8 ${this.request.distanceKm.toFixed(1)}\u516c\u91cc`)
                  .fontSize(this.largeFontEnabled ? 15 : 13)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#2563eb')
                  .fontWeight(FontWeight.Medium)
                  .width('100%')
              }

              Column({ space: 6 }) {
                Text('\u25CF')
                  .fontSize(28)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#cbd5e1')
                Text('\u5730\u56fe\u89c6\u56fe')
                  .fontSize(this.largeFontEnabled ? 14 : 12)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#94a3b8')
              }
              .width('100%')
              .height(120)
              .justifyContent(FlexAlign.Center)
              .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#e0f2fe')
              .borderRadius(10)
              .border(this.highContrastEnabled ? { width: 2, color: '#000000' } : undefined)
            }
            .width('100%')
            .padding(16)
            .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
            .borderRadius(12)
            .alignItems(HorizontalAlign.Start)
            .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
            .shadow(this.highContrastEnabled ? undefined : {
              radius: 6,
              color: '#0f000000',
              offsetX: 0,
              offsetY: 2
            })

            Column({ space: 12 }) {
              Text('\u6c42\u52a9\u4eba\u4fe1\u606f')
                .fontSize(this.largeFontEnabled ? 17 : 15)
                .fontColor(this.highContrastEnabled ? '#000000' : '#374151')
                .fontWeight(FontWeight.Medium)
                .width('100%')

              Row({ space: 12 }) {
                Row() {
                  Text(RequestDetailPage.avatarChar(this.request.requester.name))
                    .fontSize(this.largeFontEnabled ? 22 : 18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
                }
                .width(this.largeFontEnabled ? 52 : 44)
                .height(this.largeFontEnabled ? 52 : 44)
                .backgroundColor(this.highContrastEnabled ? '#000000' : '#9ca3af')
                .borderRadius(this.largeFontEnabled ? 26 : 22)
                .justifyContent(FlexAlign.Center)

                Column({ space: 4 }) {
                  Text(this.request.requester.name)
                    .fontSize(this.largeFontEnabled ? 18 : 15)
                    .fontColor(this.highContrastEnabled ? '#000000' : '#111827')
                    .fontWeight(FontWeight.Medium)

                  Text(this.request.requester.phone)
                    .fontSize(this.largeFontEnabled ? 15 : 13)
                    .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
                    .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
                }
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
            }
            .width('100%')
            .padding(16)
            .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
            .borderRadius(12)
            .alignItems(HorizontalAlign.Start)
            .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
            .shadow(this.highContrastEnabled ? undefined : {
              radius: 6,
              color: '#0f000000',
              offsetX: 0,
              offsetY: 2
            })

            Row()
              .height(20)
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 16, right: 16, top: 12, bottom: 24 })
        }
        .layoutWeight(1)
        .align(Alignment.TopStart)
        .scrollBar(BarState.Off)
        .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#f3f4f6')

        Column() {
          Button() {
            Text(this.isAccepting
              ? '\u63a5\u5355\u4e2d...'
              : (this.request.acceptEnabled ? '\u786e\u8ba4\u63a5\u5355' : '\u5f53\u524d\u4e0d\u53ef\u63a5\u5355'))
              .fontSize(this.largeFontEnabled ? 22.5 : 18)
              .fontColor(this.highContrastEnabled ? '#000000' : '#ffffff')
              .fontWeight(FontWeight.Bold)
          }
          .width('100%')
          .height(this.largeFontEnabled ? 64 : 56)
          .backgroundColor(this.highContrastEnabled ? '#ffff00' : (this.request.acceptEnabled ? '#2563eb' : '#d1d5db'))
          .borderRadius(16)
          .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
          .enabled(this.request.acceptEnabled && !this.isAccepting)
          .onClick(() => {
            this.handleAccept();
          })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
        .border(this.highContrastEnabled ?
          { width: 3, color: '#000000' } :
          { width: { top: 1 }, color: '#e5e7eb' }
        )
      }
    }
    .width('100%')
    .height('100%')
  }
}


