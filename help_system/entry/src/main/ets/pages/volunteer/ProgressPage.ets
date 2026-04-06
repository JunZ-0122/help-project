import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { DateUtil } from '../../utils/DateUtil';
import { MessageApi, OrderApi } from '../../services/ApiService';
import { WebSocketService } from '../../services/WebSocketService';
import { StorageUtil } from '../../utils/StorageUtil';
import type { VolunteerOrder } from '../../models/Order';
import type { ChatMessage } from '../../models';

interface ProgressStep {
  id: number;
  label: string;
  status: 'completed' | 'active' | 'pending';
  time: string;
}

interface ProgressView {
  id: string;
  requestId: string;
  title: string;
  status: string;
  statusLabel: string;
  helpSeekerName: string;
  helpSeekerPhone: string;
  location: string;
  acceptedAt: string;
  steps: ProgressStep[];
}

@Entry
@Component
struct ProgressPage {
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  @State orderId: string = '';
  @State isLoading: boolean = true;
  @State isUpdating: boolean = false;
  @State unreadCount: number = 0;
  @State progress: ProgressView = {
    id: '',
    requestId: '',
    title: '',
    status: 'accepted',
    statusLabel: '\u5df2\u63a5\u5355',
    helpSeekerName: '',
    helpSeekerPhone: '',
    location: '',
    acceptedAt: '',
    steps: []
  };

  private webSocketService = WebSocketService.getInstance();
  private skipNextPageShow: boolean = true;

  aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    if (params && params['id']) {
      this.orderId = params['id'] as string;
    }
    this.loadProgress();
  }

  onPageShow() {
    if (this.skipNextPageShow) {
      this.skipNextPageShow = false;
      return;
    }

    if (this.orderId) {
      this.loadProgress();
    }
  }

  aboutToDisappear() {
    if (this.progress.requestId) {
      this.webSocketService.offMessage(this.progress.requestId);
    }
    this.webSocketService.disconnect();
  }

  private async loadProgress(): Promise<void> {
    if (!this.orderId) {
      this.isLoading = false;
      return;
    }

    this.isLoading = true;

    try {
      const order: VolunteerOrder = await OrderApi.getOrderDetail(this.orderId);
      this.progress = this.mapProgress(order);
      await this.refreshUnreadCount();
      await this.connectRealtimeChannel();
    } catch (err) {
      const error = err as Error;
      console.error('load progress failed:', error);
      promptAction.showToast({
        message: error.message ? error.message : '\u52a0\u8f7d\u8fdb\u5ea6\u5931\u8d25',
        duration: 1500
      });
    } finally {
      this.isLoading = false;
    }
  }

  private mapProgress(order: VolunteerOrder): ProgressView {
    return {
      id: order.id,
      requestId: order.requestId,
      title: order.title ? order.title : this.getTypeLabel(order.type),
      status: order.status,
      statusLabel: this.getStatusLabel(order.status),
      helpSeekerName: order.helpSeekerName,
      helpSeekerPhone: order.helpSeekerPhone,
      location: order.location,
      acceptedAt: this.formatTime(order.acceptedAt),
      steps: this.buildSteps(order)
    };
  }

  private buildSteps(order: VolunteerOrder): ProgressStep[] {
    const steps: ProgressStep[] = [
      {
        id: 1,
        label: '\u5df2\u63a5\u5355',
        status: 'completed',
        time: this.formatTime(order.acceptedAt)
      },
      {
        id: 2,
        label: order.status === 'accepted' ? '\u7b49\u5f85\u5f00\u59cb\u670d\u52a1' : '\u670d\u52a1\u8fdb\u884c\u4e2d',
        status: order.status === 'accepted'
          ? 'active'
          : (order.status === 'in-progress' || order.status === 'completed' ? 'completed' : 'pending'),
        time: order.startedAt ? this.formatTime(order.startedAt) : ''
      },
      {
        id: 3,
        label: order.status === 'cancelled' ? '\u8ba2\u5355\u5df2\u53d6\u6d88' : '\u670d\u52a1\u5b8c\u6210',
        status: order.status === 'completed' ? 'completed' : 'pending',
        time: order.completedAt ? this.formatTime(order.completedAt) : ''
      }
    ];

    if (order.status === 'in-progress') {
      steps[1].status = 'active';
    }

    return steps;
  }

  private getTypeLabel(type: string): string {
    switch (type) {
      case 'medical':
        return '\u533b\u7597\u6c42\u52a9';
      case 'shopping':
        return '\u751f\u6d3b\u4ee3\u8d2d';
      case 'repair':
        return '\u7ef4\u4fee\u5e2e\u52a9';
      case 'companion':
        return '\u966a\u540c\u5e2e\u52a9';
      case 'emergency':
        return '\u7d27\u6025\u6c42\u52a9';
      default:
        return '\u5176\u4ed6\u6c42\u52a9';
    }
  }

  private getStatusLabel(status: string): string {
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

  private formatTime(value?: string): string {
    if (!value) {
      return '';
    }
    return DateUtil.format(value, 'MM-DD HH:mm');
  }

  private async refreshUnreadCount(): Promise<void> {
    if (!this.progress.requestId) {
      this.unreadCount = 0;
      return;
    }

    try {
      this.unreadCount = await MessageApi.countUnread(this.progress.requestId);
    } catch (err) {
      console.error('load unread count failed:', err);
      this.unreadCount = 0;
    }
  }

  private async connectRealtimeChannel(): Promise<void> {
    if (!this.progress.requestId) {
      return;
    }

    const token = await StorageUtil.getString('token');
    if (!token) {
      return;
    }

    const connected = await this.webSocketService.connect(token);
    if (!connected) {
      return;
    }

    this.webSocketService.onMessage(this.progress.requestId, (_message: ChatMessage) => {
      this.refreshUnreadCount();
    });
  }

  goBack() {
    router.back();
  }

  handleUpdateProgress() {
    if (this.progress.status !== 'accepted' || this.isUpdating) {
      return;
    }

    this.isUpdating = true;
    OrderApi.updateOrderStatus(this.orderId, 'in-progress').then(() => {
      promptAction.showToast({
        message: '\u8fdb\u5ea6\u5df2\u66f4\u65b0',
        duration: 1500
      });
      this.loadProgress();
    }).catch((err: Error) => {
      console.error('update progress failed:', err);
      promptAction.showToast({
        message: err.message ? err.message : '\u66f4\u65b0\u8fdb\u5ea6\u5931\u8d25',
        duration: 1500
      });
    }).finally(() => {
      this.isUpdating = false;
    });
  }

  handleComplete() {
    if (this.progress.status !== 'in-progress' || this.isUpdating) {
      return;
    }

    promptAction.showDialog({
      title: '\u5b8c\u6210\u670d\u52a1',
      message: '\u786e\u5b9a\u8981\u6807\u8bb0\u4e3a\u670d\u52a1\u5df2\u5b8c\u6210\u5417\uff1f',
      buttons: [
        { text: '\u53d6\u6d88', color: '#666666' },
        { text: '\u786e\u5b9a', color: '#10b981' }
      ]
    }).then((result) => {
      if (result.index !== 1) {
        return;
      }

      this.isUpdating = true;
      OrderApi.completeOrder(this.orderId).then(() => {
        promptAction.showToast({
          message: '\u670d\u52a1\u5df2\u5b8c\u6210',
          duration: 1500
        });
        router.replaceUrl({
          url: 'pages/volunteer/ReviewPage',
          params: { id: this.orderId }
        }).catch((err: Error) => {
          console.error('navigation failed:', err);
        });
      }).catch((err: Error) => {
        console.error('complete order failed:', err);
        promptAction.showToast({
          message: err.message ? err.message : '\u5b8c\u6210\u670d\u52a1\u5931\u8d25',
          duration: 1500
        });
      }).finally(() => {
        this.isUpdating = false;
      });
    });
  }

  handleChat() {
    router.pushUrl({
      url: 'pages/volunteer/ChatPage',
      params: {
        id: this.progress.requestId
      }
    }).catch((err: Error) => {
      console.error('navigation failed:', err);
    });
  }

  handleCall() {
    promptAction.showToast({
      message: this.progress.helpSeekerPhone ? this.progress.helpSeekerPhone : '\u6682\u65e0\u8054\u7cfb\u7535\u8bdd',
      duration: 1500
    });
  }

  @Builder
  TimelineStep(step: ProgressStep, isLast: boolean) {
    Row({ space: 12 }) {
      Column() {
        Row() {
          Text(step.status === 'completed' ? 'C' : (step.status === 'active' ? 'A' : 'P'))
            .fontSize(this.largeFontEnabled ? 16 : 12)
            .fontColor(this.highContrastEnabled ? '#000000' : '#ffffff')
            .fontWeight(FontWeight.Bold)
        }
        .width(this.largeFontEnabled ? 40 : 32)
        .height(this.largeFontEnabled ? 40 : 32)
        .backgroundColor(
          this.highContrastEnabled
            ? '#ffff00'
            : (step.status === 'completed' ? '#10b981' : (step.status === 'active' ? '#2563eb' : '#d1d5db'))
        )
        .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
        .borderRadius(this.largeFontEnabled ? 20 : 16)
        .justifyContent(FlexAlign.Center)

        if (!isLast) {
          Row()
            .width(this.highContrastEnabled ? 3 : 2)
            .height(this.largeFontEnabled ? 50 : 40)
            .backgroundColor(this.highContrastEnabled ? '#000000' : '#e5e7eb')
            .margin({ top: 8 })
        }
      }
      .alignItems(HorizontalAlign.Center)

      Column({ space: 4 }) {
        Text(step.label)
          .fontSize(this.largeFontEnabled ? 18.75 : 15)
          .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
          .fontWeight(step.status === 'active' || this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)

        if (step.time) {
          Text(step.time)
            .fontSize(this.largeFontEnabled ? 17.5 : 14)
            .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
            .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .padding({ bottom: 16 })
    }
    .alignItems(VerticalAlign.Top)
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        NavBackButton()

        Text('\u5e2e\u6276\u8fdb\u5ea6')
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
          Column({ space: 16 }) {
            Column({ space: 12 }) {
              Text(this.progress.statusLabel)
                .fontSize(this.largeFontEnabled ? 20 : 16)
                .fontColor(this.highContrastEnabled ? '#000000' : '#ffffff')
                .fontWeight(FontWeight.Bold)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .backgroundColor(this.highContrastEnabled ? '#000000' : '#2563eb')
                .borderRadius(12)

              Text(this.progress.title)
                .fontSize(this.largeFontEnabled ? 25 : 20)
                .fontColor(this.highContrastEnabled ? '#000000' : '#ffffff')
                .fontWeight(FontWeight.Bold)

              Text(`\u63a5\u5355\u65f6\u95f4\uff1a${this.progress.acceptedAt}`)
                .fontSize(this.largeFontEnabled ? 17.5 : 14)
                .fontColor(this.highContrastEnabled ? '#000000' : '#dbeafe')
                .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
            }
            .width('100%')
            .padding(20)
            .linearGradient(this.highContrastEnabled ? undefined : {
              angle: 90,
              colors: [[0x3b82f6, 0.0], [0x6366f1, 1.0]]
            })
            .backgroundColor(this.highContrastEnabled ? '#ffff00' : undefined)
            .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
            .borderRadius(16)
            .alignItems(HorizontalAlign.Start)

            Column({ space: 16 }) {
              Text('\u670d\u52a1\u8fdb\u5ea6')
                .fontSize(this.largeFontEnabled ? 20 : 16)
                .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
                .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)

              Column() {
                ForEach(this.progress.steps, (step: ProgressStep, index: number) => {
                  this.TimelineStep(step, index === this.progress.steps.length - 1)
                })
              }
            }
            .width('100%')
            .padding(20)
            .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
            .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
            .borderRadius(16)
            .alignItems(HorizontalAlign.Start)

            Column({ space: 12 }) {
              Text('\u670d\u52a1\u4fe1\u606f')
                .fontSize(this.largeFontEnabled ? 20 : 16)
                .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
                .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)

              Row() {
                Text('\u6c42\u52a9\u4eba')
                  .fontSize(this.largeFontEnabled ? 17.5 : 14)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
                Blank()
                Text(this.progress.helpSeekerName)
                  .fontSize(this.largeFontEnabled ? 17.5 : 14)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
                  .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
              }
              .width('100%')

              Row() {
                Text('\u670d\u52a1\u5730\u70b9')
                  .fontSize(this.largeFontEnabled ? 17.5 : 14)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
                Blank()
                Text(this.progress.location)
                  .fontSize(this.largeFontEnabled ? 17.5 : 14)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
                  .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
                  .textAlign(TextAlign.End)
              }
              .width('100%')
            }
            .width('100%')
            .padding(20)
            .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
            .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
            .borderRadius(16)
            .alignItems(HorizontalAlign.Start)

            Row({ space: 12 }) {
              Button(this.unreadCount > 0
                ? `\u53d1\u9001\u6d88\u606f (${this.unreadCount})`
                : '\u53d1\u9001\u6d88\u606f')
                .layoutWeight(1)
                .height(this.largeFontEnabled ? 60 : 48)
                .fontSize(this.largeFontEnabled ? 17.5 : 14)
                .fontColor(this.highContrastEnabled ? '#000000' : '#1e40af')
                .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
                .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#dbeafe')
                .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
                .borderRadius(12)
                .onClick(() => {
                  this.handleChat();
                })

              Button('\u67e5\u770b\u7535\u8bdd')
                .layoutWeight(1)
                .height(this.largeFontEnabled ? 60 : 48)
                .fontSize(this.largeFontEnabled ? 17.5 : 14)
                .fontColor(this.highContrastEnabled ? '#000000' : '#065f46')
                .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
                .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#d1fae5')
                .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
                .borderRadius(12)
                .onClick(() => {
                  this.handleCall();
                })
            }
            .width('100%')
          }
          .width('100%')
          .padding(16)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .backgroundColor(this.highContrastEnabled ? '#ffffff' : '#f9fafb')

        Column({ space: 8 }) {
          if (this.progress.status === 'accepted') {
            Button(this.isUpdating ? '\u66f4\u65b0\u4e2d...' : '\u5f00\u59cb\u670d\u52a1')
              .width('100%')
              .height(this.largeFontEnabled ? 60 : 48)
              .fontSize(this.largeFontEnabled ? 20 : 16)
              .fontColor(this.highContrastEnabled ? '#000000' : '#ffffff')
              .fontWeight(FontWeight.Bold)
              .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#2563eb')
              .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
              .borderRadius(12)
              .enabled(!this.isUpdating)
              .onClick(() => {
                this.handleUpdateProgress();
              })
          }

          if (this.progress.status === 'in-progress') {
            Button(this.isUpdating ? '\u63d0\u4ea4\u4e2d...' : '\u6807\u8bb0\u4e3a\u5df2\u5b8c\u6210')
              .width('100%')
              .height(this.largeFontEnabled ? 60 : 48)
              .fontSize(this.largeFontEnabled ? 20 : 16)
              .fontColor(this.highContrastEnabled ? '#000000' : '#ffffff')
              .fontWeight(FontWeight.Bold)
              .linearGradient(this.highContrastEnabled ? undefined : {
                angle: 90,
                colors: [[0x10b981, 0.0], [0x059669, 1.0]]
              })
              .backgroundColor(this.highContrastEnabled ? '#ffff00' : undefined)
              .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
              .borderRadius(12)
              .enabled(!this.isUpdating)
              .onClick(() => {
                this.handleComplete();
              })
          }
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
