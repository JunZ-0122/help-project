import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { DateUtil } from '../../utils/DateUtil';
import { getCurrentPosition, requestLocationPermission } from '../../utils/LocationUtil';
import { HelpRequestWithDistance, OrderApi, RequestApi, UserApi } from '../../services/ApiService';
import { StorageUtil } from '../../utils/StorageUtil';
import type { HelpRequest } from '../../models/Request';
import type { UserProfile } from '../../models/User';
import type { VolunteerOrder } from '../../models/Order';

interface VolunteerRequestCard {
  id: string;
  title: string;
  description: string;
  location: string;
  time: string;
  urgencyLabel: string;
  urgencyColor: string;
  requesterName: string;
  distanceKm?: number;
  isEmergency: boolean;
}

interface HomeOrderCard {
  id: string;
  title: string;
  status: string;
  statusColor: string;
  time: string;
}

@Entry
@Component
struct VolunteerHomePage {
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  /** 志愿者姓名，用于头像首字；空串表示未加载或无姓名，头像显示 V */
  @State volunteerName: string = '';
  @State serviceScore: string = '--';
  @State completedCount: number = 0;
  @State activeOrderCount: number = 0;
  @State helpRequests: VolunteerRequestCard[] = [];
  @State pendingNearbyTotal: number = 0;
  @State myOrders: HomeOrderCard[] = [];
  @State isLoadingRequests: boolean = false;
  @State isLoadingOrders: boolean = false;
  @State acceptingRequestId: string = '';
  @State volunteerOnline: boolean = true;
  @State isTogglingStatus: boolean = false;

  aboutToAppear() {
    this.loadHomeData();
  }

  private async loadHomeData(): Promise<void> {
    await this.loadVolunteerProfile();
    await Promise.all([
      this.loadNearbyRequests(),
      this.loadMyOrders()
    ]);
  }

  private async loadVolunteerProfile(): Promise<void> {
    try {
      const profile: UserProfile = await UserApi.getCurrentProfile();
      if (profile.name) {
        this.volunteerName = profile.name;
      }
      if (profile.rating !== undefined && profile.rating !== null) {
        this.serviceScore = profile.rating.toFixed(1);
      }
      this.volunteerOnline = profile.status === 'online' || profile.status === 'busy';
      await StorageUtil.set('user', profile);
    } catch (err) {
      console.error('load volunteer profile failed:', err);
      try {
        const user: UserProfile | null = await StorageUtil.get<UserProfile>('user');
        if (!user) {
          return;
        }
        if (user.name) {
          this.volunteerName = user.name;
        }
        if (user.rating !== undefined && user.rating !== null) {
          this.serviceScore = user.rating.toFixed(1);
        }
        this.volunteerOnline = user.status === 'online' || user.status === 'busy';
      } catch (_) {
        // ignore
      }
    }
  }

  /** 与 ProfilePage.getAvatarText 一致：有姓名取首字，否则 V */
  private getVolunteerAvatarText(): string {
    const n = this.volunteerName.trim();
    if (!n) {
      return 'V';
    }
    return n.substring(0, 1);
  }

  private async toggleVolunteerStatus(): Promise<void> {
    if (this.isTogglingStatus) {
      return;
    }
    this.isTogglingStatus = true;
    const nextOnline: boolean = !this.volunteerOnline;
    const nextStatus: 'online' | 'offline' = nextOnline ? 'online' : 'offline';
    try {
      const updated: UserProfile = await UserApi.updateUserProfile({ status: nextStatus });
      this.volunteerOnline = updated.status === 'online' || updated.status === 'busy';
      await StorageUtil.set('user', updated);
      promptAction.showToast({
        message: this.volunteerOnline ?
          '\u5df2\u5207\u6362\u4e3a\u5728\u7ebf\u63a5\u5355' :
          '\u5df2\u5207\u6362\u4e3a\u4f11\u606f\u4e2d',
        duration: 1500
      });
    } catch (e) {
      const err = e as Error;
      promptAction.showToast({
        message: err.message ? err.message : '\u72b6\u6001\u5207\u6362\u5931\u8d25',
        duration: 2000
      });
    } finally {
      this.isTogglingStatus = false;
    }
  }

  private async loadNearbyRequests(): Promise<void> {
    this.isLoadingRequests = true;

    try {
      await requestLocationPermission();
      let pos = await getCurrentPosition();
      if (!pos) {
        // 与后端演示求助坐标一致（北京）；无 GPS / 模拟器未注入位置时使用
        pos = { latitude: 39.9042, longitude: 116.4074 };
      }
      try {
        await UserApi.reportLocation(pos.latitude, pos.longitude, undefined, 'app');
      } catch (_) {
        // 上报失败时仍用本次经纬度调附近接口（query 传参不依赖库）
      }

      try {
        const response =
          await RequestApi.getNearbyRequests(1, 6, pos.latitude, pos.longitude);
        this.pendingNearbyTotal = response.total;
        this.helpRequests = response.items.map((item: HelpRequestWithDistance) =>
          this.mapRequestCard(item.request, item.distance)
        );
      } catch (_) {
        const response = await RequestApi.getRequests(1, 6, { status: 'pending' });
        this.pendingNearbyTotal = response.total;
        this.helpRequests = response.items.map((request: HelpRequest) => this.mapRequestCard(request));
      }
    } catch (err) {
      const error = err as Error;
      console.error('load nearby requests failed:', error);
      promptAction.showToast({
        message: error.message ? error.message : '\u52a0\u8f7d\u9644\u8fd1\u6c42\u52a9\u5931\u8d25',
        duration: 1500
      });
    } finally {
      this.isLoadingRequests = false;
    }
  }

  private async loadMyOrders(): Promise<void> {
    this.isLoadingOrders = true;

    try {
      const orders: VolunteerOrder[] = await OrderApi.getMyOrders();
      this.completedCount = orders.filter((order: VolunteerOrder) => order.status === 'completed').length;
      this.activeOrderCount = orders.filter((order: VolunteerOrder) =>
        order.status === 'accepted' || order.status === 'in-progress'
      ).length;
      this.myOrders = orders.slice(0, 3).map((order: VolunteerOrder) => this.mapOrderCard(order));
    } catch (err) {
      const error = err as Error;
      console.error('load my orders failed:', error);
      promptAction.showToast({
        message: error.message ? error.message : '\u52a0\u8f7d\u6211\u7684\u8ba2\u5355\u5931\u8d25',
        duration: 1500
      });
    } finally {
      this.isLoadingOrders = false;
    }
  }

  private mapRequestCard(request: HelpRequest, distanceKm?: number): VolunteerRequestCard {
    const emergency: boolean = request.urgency === 'emergency' || request.type === 'emergency';
    const card: VolunteerRequestCard = {
      id: request.id,
      title: request.title ? request.title : this.getRequestTypeLabel(request.type),
      description: request.description,
      location: request.location,
      time: DateUtil.getRelativeTime(request.createdAt),
      urgencyLabel: this.getUrgencyLabel(request.urgency),
      urgencyColor: this.getUrgencyColor(request.urgency),
      requesterName: request.userName ? request.userName : '\u6c42\u52a9\u8005',
      isEmergency: emergency
    };
    if (distanceKm !== undefined) {
      card.distanceKm = distanceKm;
    }
    return card;
  }

  private mapOrderCard(order: VolunteerOrder): HomeOrderCard {
    const timeSource: string = order.completedAt ? order.completedAt : order.acceptedAt;
    return {
      id: order.id,
      title: order.title ? order.title : this.getRequestTypeLabel(order.type),
      status: this.getOrderStatusLabel(order.status),
      statusColor: this.getOrderStatusColor(order.status),
      time: DateUtil.format(timeSource, 'MM-DD HH:mm')
    };
  }

  private getRequestTypeLabel(type: string): string {
    switch (type) {
      case 'medical':
        return '\u5c31\u533b\u534f\u52a9';
      case 'shopping':
        return '\u751f\u6d3b\u4ee3\u8d2d';
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

  private getUrgencyLabel(urgency: string): string {
    switch (urgency) {
      case 'emergency':
        return '\u7d27\u6025';
      case 'high':
        return '\u8f83\u6025';
      case 'medium':
        return '\u666e\u901a';
      default:
        return '\u4f4e\u4f18\u5148';
    }
  }

  private getUrgencyColor(urgency: string): string {
    switch (urgency) {
      case 'emergency':
        return '#dc2626';
      case 'high':
        return '#f97316';
      case 'medium':
        return '#2563eb';
      default:
        return '#6b7280';
    }
  }

  private getOrderStatusLabel(status: string): string {
    switch (status) {
      case 'accepted':
        return '\u5df2\u63a5\u5355';
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

  private getOrderStatusColor(status: string): string {
    switch (status) {
      case 'accepted':
        return '#2563eb';
      case 'in-progress':
        return '#f59e0b';
      case 'completed':
        return '#10b981';
      case 'cancelled':
        return '#ef4444';
      default:
        return '#6b7280';
    }
  }

  navigateToPage(path: string) {
    router.pushUrl({
      url: path
    }).catch((err: Error) => {
      console.error('navigation failed:', err);
    });
  }

  openRequestDetail(requestId: string) {
    router.pushUrl({
      url: 'pages/volunteer/RequestDetailPage',
      params: {
        id: requestId
      }
    }).catch((err: Error) => {
      console.error('navigation failed:', err);
    });
  }

  acceptRequest(request: VolunteerRequestCard) {
    if (this.acceptingRequestId) {
      return;
    }

    promptAction.showDialog({
      title: '\u63a5\u53d7\u6c42\u52a9',
      message: `\u786e\u5b9a\u8981\u63a5\u5355\u201c${request.title}\u201d\u5417\uff1f`,
      buttons: [
        {
          text: '\u53d6\u6d88',
          color: '#666666'
        },
        {
          text: '\u786e\u5b9a\u63a5\u5355',
          color: '#2563eb'
        }
      ]
    }).then((result) => {
      if (result.index !== 1) {
        return;
      }

      this.acceptingRequestId = request.id;
      OrderApi.acceptOrder(request.id).then(() => {
        console.info('[VolunteerHomePage] 接单成功');
        this.loadNearbyRequests();
        this.loadMyOrders();
      }).catch((err: Error) => {
        console.error('accept request failed:', err);
      }).finally(() => {
        this.acceptingRequestId = '';
      });
    });
  }

  @Builder
  StatCardBuilder(value: string, label: string, color: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(this.largeFontEnabled ? 30 : 24)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.highContrastEnabled ? '#000000' : color)

      Text(label)
        .fontSize(this.largeFontEnabled ? 15 : 12)
        .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
        .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
    }
    .layoutWeight(1)
    .padding(16)
    .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
    .borderRadius(12)
    .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
    .shadow(this.highContrastEnabled ? undefined : {
      radius: 4,
      color: '#0f000000',
      offsetX: 0,
      offsetY: 1
    })
  }

  @Builder
  RequestCard(request: VolunteerRequestCard) {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        Text(request.title)
          .fontSize(this.largeFontEnabled ? 20 : 17)
          .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.highContrastEnabled ? '#000000' : '#111827')
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (request.isEmergency) {
          Text('\u7d27\u6025')
            .fontSize(this.largeFontEnabled ? 14 : 11)
            .fontColor(this.highContrastEnabled ? '#000000' : '#ffffff')
            .fontWeight(FontWeight.Medium)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#dc2626')
            .borderRadius(10)
            .border(this.highContrastEnabled ? { width: 2, color: '#000000' } : undefined)
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row({ space: 20 }) {
        if (request.distanceKm !== undefined && request.distanceKm !== null) {
          Row({ space: 6 }) {
            Text('\u25CF')
              .fontSize(this.largeFontEnabled ? 10 : 8)
              .fontColor(this.highContrastEnabled ? '#000000' :
                (request.isEmergency ? '#dc2626' : '#2563eb'))
            Text(`${request.distanceKm.toFixed(1)}\u516c\u91cc`)
              .fontSize(this.largeFontEnabled ? 15 : 13)
              .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
              .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
          }
        }

        Row({ space: 6 }) {
          Text('\u231A')
            .fontSize(this.largeFontEnabled ? 16 : 13)
            .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
          Text(request.time)
            .fontSize(this.largeFontEnabled ? 15 : 13)
            .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
            .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
        }
      }
      .width('100%')

      if (request.description && request.description.length > 0) {
        Text(request.description)
          .fontSize(this.largeFontEnabled ? 16 : 14)
          .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
          .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
          .width('100%')
          .lineHeight(this.largeFontEnabled ? 24 : 20)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }

      Row({ space: 12 }) {
        Button('\u67e5\u770b\u8be6\u60c5')
          .fontSize(this.largeFontEnabled ? 16 : 14)
          .fontColor(this.highContrastEnabled ? '#000000' :
            (request.isEmergency ? '#991b1b' : '#4b5563'))
          .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)
          .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
          .borderRadius(10)
          .border(this.highContrastEnabled ? { width: 3, color: '#000000' } :
            { width: 1, color: request.isEmergency ? '#f87171' : '#d1d5db' })
          .layoutWeight(1)
          .onClick(() => {
            this.openRequestDetail(request.id);
          })

        Button(this.acceptingRequestId === request.id ?
          '\u63a5\u5355\u4e2d...' :
          '\u7acb\u5373\u63a5\u5355 \u2192')
          .fontSize(this.largeFontEnabled ? 16 : 14)
          .fontColor(this.highContrastEnabled ? '#000000' : '#ffffff')
          .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)
          .backgroundColor(this.highContrastEnabled ? '#ffff00' :
            (request.isEmergency ? '#b91c1c' : '#2563eb'))
          .borderRadius(10)
          .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
          .layoutWeight(1)
          .enabled(this.acceptingRequestId === '' || this.acceptingRequestId === request.id)
          .onClick(() => {
            this.acceptRequest(request);
          })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.highContrastEnabled ? '#ffff00' :
      (request.isEmergency ? '#fff5f5' : '#ffffff'))
    .borderRadius(14)
    .border(this.highContrastEnabled ? { width: 3, color: '#000000' } :
      (request.isEmergency ? { width: 2, color: '#dc2626' } : undefined))
    .shadow(this.highContrastEnabled ? undefined : (request.isEmergency ? {
      radius: 10,
      color: '#dc262640',
      offsetX: 0,
      offsetY: 3
    } : {
      radius: 8,
      color: '#0f000000',
      offsetX: 0,
      offsetY: 2
    }))
  }

  @Builder
  OrderItem(order: HomeOrderCard) {
    Row({ space: 12 }) {
      Column({ space: 4 }) {
        Text(order.title)
          .fontSize(this.largeFontEnabled ? 17.5 : 14)
          .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(order.time)
          .fontSize(this.largeFontEnabled ? 15 : 12)
          .fontColor(this.highContrastEnabled ? '#000000' : '#9ca3af')
          .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(order.status)
        .fontSize(this.largeFontEnabled ? 15 : 12)
        .fontColor(this.highContrastEnabled ? '#000000' : '#ffffff')
        .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .backgroundColor(this.highContrastEnabled ? '#ffff00' : order.statusColor)
        .borderRadius(8)
        .border(this.highContrastEnabled ? { width: 2, color: '#000000' } : undefined)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#f9fafb')
    .borderRadius(8)
    .border(this.highContrastEnabled ? { width: 2, color: '#000000' } : undefined)
    .onClick(() => {
      router.pushUrl({
        url: 'pages/volunteer/MyOrdersPage'
      }).catch((err: Error) => {
        console.error('navigation failed:', err);
      });
    })
  }

  build() {
    Column() {
      Column({ space: 16 }) {
        Row() {
          Text('\u5fd7\u613f\u8005\u670d\u52a1')
            .fontSize(this.largeFontEnabled ? 28 : 22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.highContrastEnabled ? '#000000' : '#ffffff')
            .layoutWeight(1)

          Button() {
            Text(this.getVolunteerAvatarText())
              .fontSize(this.largeFontEnabled ? 22 : 18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.highContrastEnabled ? '#000000' : '#1e3a8a')
          }
          .width(this.largeFontEnabled ? 44 : 40)
          .height(this.largeFontEnabled ? 44 : 40)
          .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
          .borderRadius(20)
          .border(this.highContrastEnabled ? { width: 2, color: '#000000' } : undefined)
          .onClick(() => {
            this.navigateToPage('pages/volunteer/ProfilePage');
          })
        }
        .width('100%')

        Column({ space: 10 }) {
          Row() {
            Column({ space: 6 }) {
              Text('\u5f53\u524d\u72b6\u6001')
                .fontSize(this.largeFontEnabled ? 14 : 11)
                .fontColor(this.highContrastEnabled ? '#000000' : '#e0e7ff')

              Row({ space: 8 }) {
                Circle({ width: this.largeFontEnabled ? 10 : 8, height: this.largeFontEnabled ? 10 : 8 })
                  .fill(this.highContrastEnabled ? '#000000' :
                    (this.volunteerOnline ? '#22c55e' : '#9ca3af'))

                Text(this.volunteerOnline ? '\u5728\u7ebf\u63a5\u5355' : '\u4f11\u606f\u4e2d')
                  .fontSize(this.largeFontEnabled ? 20 : 17)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#111827')
              }
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Button(this.isTogglingStatus ?
              '...' :
              (this.volunteerOnline ? '\u5207\u6362\u4e3a\u4f11\u606f\u4e2d' : '\u5207\u6362\u4e3a\u5728\u7ebf\u63a5\u5355'))
              .fontSize(this.largeFontEnabled ? 14 : 12)
              .fontColor(this.highContrastEnabled ? '#000000' : '#ffffff')
              .fontWeight(FontWeight.Medium)
              .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#3b82f6')
              .borderRadius(10)
              .border(this.highContrastEnabled ? { width: 2, color: '#000000' } : undefined)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .enabled(!this.isTogglingStatus)
              .onClick(() => {
                this.toggleVolunteerStatus();
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .padding(16)
        .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#b3ffffff')
        .borderRadius(14)
        .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 20 })
      .linearGradient(this.highContrastEnabled ? undefined : {
        angle: 180,
        colors: [[0x2563eb, 0.0], [0x1e3a8a, 1.0]]
      })
      .backgroundColor(this.highContrastEnabled ? '#ffff00' : undefined)
      .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)

      Scroll() {
        Column({ space: 20 }) {
          Row({ space: 12 }) {
            this.StatCardBuilder(this.completedCount.toString(), '\u5df2\u5b8c\u6210', '#3b82f6')
            this.StatCardBuilder(this.serviceScore, '\u8bc4\u5206', '#10b981')
            this.StatCardBuilder(this.activeOrderCount.toString(), '\u8fdb\u884c\u4e2d', '#f59e0b')
          }
          .width('100%')

          Column({ space: 14 }) {
            Row() {
              Text('\u9644\u8fd1\u6c42\u52a9')
                .fontSize(this.largeFontEnabled ? 21 : 18)
                .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)
                .fontColor(this.highContrastEnabled ? '#000000' : '#111827')

              Blank()

              Text(this.isLoadingRequests ? '--' : `${this.pendingNearbyTotal}`)
                .fontSize(this.largeFontEnabled ? 15 : 13)
                .fontColor(this.highContrastEnabled ? '#000000' : '#9ca3af')
                .margin({ right: 4 })

              Text('\u6761\u5f85\u63a5\u5355')
                .fontSize(this.largeFontEnabled ? 15 : 13)
                .fontColor(this.highContrastEnabled ? '#000000' : '#9ca3af')

              Button('\u5237\u65b0')
                .fontSize(this.largeFontEnabled ? 15 : 13)
                .fontColor(this.highContrastEnabled ? '#000000' : '#2563eb')
                .fontWeight(FontWeight.Medium)
                .backgroundColor(Color.Transparent)
                .margin({ left: 12 })
                .onClick(() => {
                  this.loadNearbyRequests();
                })
            }
            .width('100%')

            Column({ space: 12 }) {
              if (this.isLoadingRequests) {
                Text('\u52a0\u8f7d\u4e2d...')
                  .fontSize(this.largeFontEnabled ? 16 : 14)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#9ca3af')
              } else if (this.helpRequests.length === 0) {
                Text('\u6682\u65e0\u5f85\u63a5\u5355\u6c42\u52a9')
                  .fontSize(this.largeFontEnabled ? 16 : 14)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#9ca3af')
              } else {
                ForEach(this.helpRequests, (request: VolunteerRequestCard) => {
                  this.RequestCard(request)
                }, (request: VolunteerRequestCard) => request.id)
              }
            }
          }

          Column({ space: 14 }) {
            Row() {
              Text('\u6211\u7684\u63a5\u5355')
                .fontSize(this.largeFontEnabled ? 21 : 18)
                .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)
                .fontColor(this.highContrastEnabled ? '#000000' : '#111827')

              Blank()

              Button('\u67e5\u770b\u5168\u90e8')
                .fontSize(this.largeFontEnabled ? 15 : 13)
                .fontColor(this.highContrastEnabled ? '#000000' : '#2563eb')
                .fontWeight(FontWeight.Medium)
                .backgroundColor(Color.Transparent)
                .onClick(() => {
                  this.navigateToPage('pages/volunteer/MyOrdersPage');
                })
            }
            .width('100%')

            Column({ space: 8 }) {
              if (this.isLoadingOrders) {
                Text('\u52a0\u8f7d\u4e2d...')
                  .fontSize(this.largeFontEnabled ? 16 : 14)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#9ca3af')
              } else if (this.myOrders.length === 0) {
                Text('\u6682\u65e0\u8ba2\u5355')
                  .fontSize(this.largeFontEnabled ? 16 : 14)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#9ca3af')
              } else {
                ForEach(this.myOrders, (order: HomeOrderCard) => {
                  this.OrderItem(order)
                }, (order: HomeOrderCard) => order.id)
              }
            }
          }

          Row()
            .height(88)
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 16, bottom: 20 })
      }
      .layoutWeight(1)
      .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#f3f4f6')

      Row() {
        Button() {
          Column({ space: 4 }) {
            Text('\u2302')
              .fontSize(this.largeFontEnabled ? 24 : 20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.highContrastEnabled ? '#000000' : '#2563eb')
            Text('\u9996\u9875')
              .fontSize(this.largeFontEnabled ? 14 : 12)
              .fontColor(this.highContrastEnabled ? '#000000' : '#2563eb')
              .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)
          }
        }
        .layoutWeight(1)
        .backgroundColor(Color.Transparent)

        Button() {
          Column({ space: 4 }) {
            Text('\u2630')
              .fontSize(this.largeFontEnabled ? 24 : 20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.highContrastEnabled ? '#000000' : '#9ca3af')
            Text('\u6211\u7684\u63a5\u5355')
              .fontSize(this.largeFontEnabled ? 14 : 12)
              .fontColor(this.highContrastEnabled ? '#000000' : '#9ca3af')
              .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
          }
        }
        .layoutWeight(1)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.navigateToPage('pages/volunteer/MyOrdersPage');
        })

        Button() {
          Column({ space: 4 }) {
            Text('\u25C9')
              .fontSize(this.largeFontEnabled ? 24 : 20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.highContrastEnabled ? '#000000' : '#9ca3af')
            Text('\u4e2a\u4eba\u4e2d\u5fc3')
              .fontSize(this.largeFontEnabled ? 14 : 12)
              .fontColor(this.highContrastEnabled ? '#000000' : '#9ca3af')
              .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
          }
        }
        .layoutWeight(1)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.navigateToPage('pages/volunteer/ProfilePage');
        })
      }
      .width('100%')
      .height(76)
      .padding({ bottom: 8 })
      .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
      .border(this.highContrastEnabled ?
        { width: 3, color: '#000000' } :
        { width: { top: 1 }, color: '#e5e7eb' }
      )
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#f3f4f6')
  }
}


