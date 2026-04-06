import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { DateUtil } from '../../utils/DateUtil';
import { OrderApi, ReviewApi } from '../../services/ApiService';
import type { Review, VolunteerOrder } from '../../models';

interface TimelineItem {
  time: string;
  label: string;
}

interface OrderDetailView {
  id: string;
  title: string;
  description: string;
  location: string;
  statusLabel: string;
  helpSeekerName: string;
  helpSeekerPhone: string;
  acceptedAt: string;
  startedAt: string;
  completedAt: string;
  feedback: string;
  reviewLabel: string;
  reviewContent: string;
  timeline: TimelineItem[];
}

@Entry
@Component
struct OrderDetailPage {
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  @State orderId: string = '';
  @State isLoading: boolean = true;
  @State order: OrderDetailView = {
    id: '',
    title: '',
    description: '',
    location: '',
    statusLabel: '',
    helpSeekerName: '',
    helpSeekerPhone: '',
    acceptedAt: '',
    startedAt: '',
    completedAt: '',
    feedback: '',
    reviewLabel: '',
    reviewContent: '',
    timeline: []
  };

  private skipNextPageShow: boolean = true;

  aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    if (params && params['id']) {
      this.orderId = params['id'] as string;
    }
    this.loadOrderDetail();
  }

  onPageShow() {
    if (this.skipNextPageShow) {
      this.skipNextPageShow = false;
      return;
    }
    if (this.orderId) {
      this.loadOrderDetail();
    }
  }

  private async loadOrderDetail(): Promise<void> {
    if (!this.orderId) {
      this.isLoading = false;
      return;
    }

    this.isLoading = true;

    try {
      const order: VolunteerOrder = await OrderApi.getOrderDetail(this.orderId);
      const review: Review | null = await ReviewApi.getReviewReceived(this.orderId);
      this.order = this.mapOrder(order, review);
    } catch (err) {
      const error = err as Error;
      console.error('load order detail failed:', error);
      promptAction.showToast({
        message: error.message ? error.message : '\u52a0\u8f7d\u8ba2\u5355\u8be6\u60c5\u5931\u8d25',
        duration: 1500
      });
    } finally {
      this.isLoading = false;
    }
  }

  private mapOrder(order: VolunteerOrder, review: Review | null): OrderDetailView {
    return {
      id: order.id,
      title: order.title ? order.title : this.getTypeLabel(order.type),
      description: order.description,
      location: order.location,
      statusLabel: this.getStatusLabel(order.status),
      helpSeekerName: order.helpSeekerName,
      helpSeekerPhone: order.helpSeekerPhone,
      acceptedAt: this.formatTime(order.acceptedAt),
      startedAt: this.formatTime(order.startedAt),
      completedAt: this.formatTime(order.completedAt),
      feedback: order.feedback ? order.feedback : '',
      reviewLabel: review ? this.getReviewLabel(review.rating) : '',
      reviewContent: review && review.content ? review.content : '',
      timeline: this.buildTimeline(order)
    };
  }

  private buildTimeline(order: VolunteerOrder): TimelineItem[] {
    const items: TimelineItem[] = [
      { time: this.formatTime(order.acceptedAt), label: '\u5df2\u63a5\u5355' }
    ];

    if (order.startedAt) {
      items.push({ time: this.formatTime(order.startedAt), label: '\u5f00\u59cb\u670d\u52a1' });
    }

    if (order.completedAt) {
      items.push({ time: this.formatTime(order.completedAt), label: '\u670d\u52a1\u5b8c\u6210' });
    }

    return items;
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

  private getReviewLabel(rating?: number): string {
    if (rating === undefined || rating === null) {
      return '';
    }
    if (rating >= 5) {
      return '\u6ee1\u610f';
    }
    if (rating >= 3) {
      return '\u4e00\u822c';
    }
    return '\u4e0d\u6ee1\u610f';
  }

  goBack() {
    router.back();
  }

  @Builder
  TimelineItemBuilder(item: TimelineItem, isLast: boolean) {
    Row({ space: 12 }) {
      Column() {
        Row()
          .width(this.largeFontEnabled ? 15 : 12)
          .height(this.largeFontEnabled ? 15 : 12)
          .backgroundColor(this.highContrastEnabled ? '#000000' : '#10b981')
          .borderRadius(this.largeFontEnabled ? 7.5 : 6)

        if (!isLast) {
          Row()
            .width(this.highContrastEnabled ? 3 : 2)
            .height(this.largeFontEnabled ? 40 : 32)
            .backgroundColor(this.highContrastEnabled ? '#000000' : '#bbf7d0')
            .margin({ top: 8 })
        }
      }
      .alignItems(HorizontalAlign.Center)

      Column({ space: 4 }) {
        Text(item.label)
          .fontSize(this.largeFontEnabled ? 17.5 : 14)
          .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
          .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)

        Text(item.time)
          .fontSize(this.largeFontEnabled ? 15 : 12)
          .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
          .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
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

        Text('\u63a5\u5355\u8be6\u60c5')
          .fontSize(this.largeFontEnabled ? 22.5 : 18)
          .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
          .layoutWeight(1)
      }
      .width('100%')
      .padding(16)
      .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
      .border({
        width: { bottom: this.highContrastEnabled ? 3 : 1 },
        color: this.highContrastEnabled ? '#000000' : '#e5e7eb'
      })

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
            Column({ space: 8 }) {
              Text(this.order.statusLabel)
                .fontSize(this.largeFontEnabled ? 20 : 16)
                .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
                .fontWeight(FontWeight.Bold)

              Text(this.order.title)
                .fontSize(this.largeFontEnabled ? 25 : 20)
                .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
                .fontWeight(FontWeight.Bold)
            }
            .width('100%')
            .padding(20)
            .linearGradient(this.highContrastEnabled ? undefined : {
              angle: 90,
              colors: [[0xd1fae5, 0.0], [0xa7f3d0, 1.0]]
            })
            .backgroundColor(this.highContrastEnabled ? '#ffff00' : undefined)
            .borderRadius(16)
            .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
            .alignItems(HorizontalAlign.Start)

            Column({ space: 16 }) {
              Text('\u670d\u52a1\u4fe1\u606f')
                .fontSize(this.largeFontEnabled ? 20 : 16)
                .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
                .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)

              Text(this.order.description)
                .fontSize(this.largeFontEnabled ? 17.5 : 14)
                .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
                .lineHeight(this.largeFontEnabled ? 28 : 22)

              Text(`\u670d\u52a1\u5730\u70b9\uff1a${this.order.location}`)
                .fontSize(this.largeFontEnabled ? 17.5 : 14)
                .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
            }
            .width('100%')
            .padding(20)
            .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
            .borderRadius(16)
            .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
            .alignItems(HorizontalAlign.Start)

            Column({ space: 12 }) {
              Text('\u670d\u52a1\u5bf9\u8c61')
                .fontSize(this.largeFontEnabled ? 20 : 16)
                .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
                .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)

              Text(this.order.helpSeekerName)
                .fontSize(this.largeFontEnabled ? 18.75 : 15)
                .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
                .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)

              Text(this.order.helpSeekerPhone)
                .fontSize(this.largeFontEnabled ? 17.5 : 14)
                .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
            }
            .width('100%')
            .padding(20)
            .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
            .borderRadius(16)
            .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
            .alignItems(HorizontalAlign.Start)

            Column({ space: 16 }) {
              Text('\u670d\u52a1\u8bb0\u5f55')
                .fontSize(this.largeFontEnabled ? 20 : 16)
                .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
                .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)

              Column() {
                ForEach(this.order.timeline, (item: TimelineItem, index: number) => {
                  this.TimelineItemBuilder(item, index === this.order.timeline.length - 1)
                })
              }
            }
            .width('100%')
            .padding(20)
            .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
            .borderRadius(16)
            .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
            .alignItems(HorizontalAlign.Start)

            if (this.order.reviewLabel || this.order.reviewContent || this.order.feedback) {
              Column({ space: 12 }) {
                Text('\u8bc4\u4ef7\u4e0e\u5907\u6ce8')
                  .fontSize(this.largeFontEnabled ? 20 : 16)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
                  .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)

                if (this.order.reviewLabel) {
                  Text(`\u8bc4\u4ef7\u7ed3\u679c\uff1a${this.order.reviewLabel}`)
                    .fontSize(this.largeFontEnabled ? 17.5 : 14)
                    .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
                    .fontWeight(FontWeight.Bold)
                }

                if (this.order.reviewContent) {
                  Text(this.order.reviewContent)
                    .fontSize(this.largeFontEnabled ? 17.5 : 14)
                    .fontColor(this.highContrastEnabled ? '#000000' : '#374151')
                    .lineHeight(this.largeFontEnabled ? 28 : 22)
                }

                if (this.order.feedback) {
                  Text(`\u670d\u52a1\u5907\u6ce8\uff1a${this.order.feedback}`)
                    .fontSize(this.largeFontEnabled ? 17.5 : 14)
                    .fontColor(this.highContrastEnabled ? '#000000' : '#374151')
                    .lineHeight(this.largeFontEnabled ? 28 : 22)
                }
              }
              .width('100%')
              .padding(20)
              .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
              .borderRadius(16)
              .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
              .alignItems(HorizontalAlign.Start)
            }

            Column({ space: 8 }) {
              Text(`\u63a5\u5355\u65f6\u95f4\uff1a${this.order.acceptedAt}`)
                .fontSize(this.largeFontEnabled ? 17.5 : 14)
                .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
              if (this.order.startedAt) {
                Text(`\u5f00\u59cb\u670d\u52a1\uff1a${this.order.startedAt}`)
                  .fontSize(this.largeFontEnabled ? 17.5 : 14)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
              }
              if (this.order.completedAt) {
                Text(`\u5b8c\u6210\u65f6\u95f4\uff1a${this.order.completedAt}`)
                  .fontSize(this.largeFontEnabled ? 17.5 : 14)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#f9fafb')
            .borderRadius(12)
            .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding(16)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#f9fafb')
      }
    }
    .width('100%')
    .height('100%')
  }
}


