import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { OrderApi, ReviewApi } from '../../services/ApiService';
import type { Review, VolunteerOrder } from '../../models';

interface RatingOption {
  id: string;
  label: string;
  emoji: string;
  color: string[];
  score: number;
}

@Entry
@Component
struct ReviewPage {
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  @State orderId: string = '';
  @State selectedRating: string = '';
  @State feedback: string = '';
  @State isSubmitting: boolean = false;
  @State isLoading: boolean = true;
  @State revieweeId: string = '';
  @State revieweeName: string = '';
  @State orderTitle: string = '';
  @State existingReview: Review | null = null;

  private ratingOptions: RatingOption[] = [
    { id: 'satisfied', label: '\u6ee1\u610f', emoji: 'S', color: ['#10b981', '#059669'], score: 5 },
    { id: 'neutral', label: '\u4e00\u822c', emoji: 'N', color: ['#f59e0b', '#f97316'], score: 3 },
    { id: 'dissatisfied', label: '\u4e0d\u6ee1\u610f', emoji: 'D', color: ['#ef4444', '#dc2626'], score: 1 }
  ];

  aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    if (params && params['id']) {
      this.orderId = params['id'] as string;
    }
    this.loadReviewContext();
  }

  private async loadReviewContext(): Promise<void> {
    if (!this.orderId) {
      this.isLoading = false;
      return;
    }

    this.isLoading = true;

    try {
      const order: VolunteerOrder = await OrderApi.getOrderDetail(this.orderId);
      this.revieweeId = order.helpSeekerId;
      this.revieweeName = order.helpSeekerName;
      this.orderTitle = order.title;

      const existingReview = await ReviewApi.getOrderReview(this.orderId);
      this.existingReview = existingReview;
      if (existingReview) {
        this.feedback = existingReview.content ? existingReview.content : '';
      }
    } catch (err) {
      const error = err as Error;
      console.error('load review context failed:', error);
      promptAction.showToast({
        message: error.message ? error.message : '\u52a0\u8f7d\u8bc4\u4ef7\u4fe1\u606f\u5931\u8d25',
        duration: 1500
      });
    } finally {
      this.isLoading = false;
    }
  }

  goBack() {
    router.back();
  }

  /** 志愿者评价服务对象（求助者）：与 revieweeId=helpSeekerId 一致 */
  private getVolunteerReviewQuestion(): string {
    const name = this.revieweeName.trim();
    if (name.length > 0) {
      return `\u60a8\u5bf9\u6c42\u52a9\u8005\u300c${name}\u300d\u7684\u6c9f\u901a\u4e0e\u914d\u5408\u662f\u5426\u6ee1\u610f\uff1f`;
    }
    return '\u60a8\u5bf9\u672c\u6b21\u6c42\u52a9\u8005\u7684\u6c9f\u901a\u4e0e\u914d\u5408\u662f\u5426\u6ee1\u610f\uff1f';
  }

  async handleSubmit() {
    if (!this.selectedRating || !this.revieweeId || this.isSubmitting || this.existingReview) {
      return;
    }

    const selectedOption: RatingOption | undefined = this.ratingOptions.find((option: RatingOption) => option.id === this.selectedRating);
    if (!selectedOption) {
      return;
    }

    this.isSubmitting = true;

    ReviewApi.createReview(
      this.orderId,
      this.revieweeId,
      selectedOption.score,
      this.feedback.trim(),
      [],
      false
    ).then(() => {
      promptAction.showToast({
        message: '\u8bc4\u4ef7\u63d0\u4ea4\u6210\u529f',
        duration: 1500
      });
      router.replaceUrl({
        url: 'pages/volunteer/OrderDetailPage',
        params: { id: this.orderId }
      }).catch((err: Error) => {
        console.error('navigation failed:', err);
      });
    }).catch((err: Error) => {
      console.error('submit review failed:', err);
      promptAction.showToast({
        message: err.message ? err.message : '\u8bc4\u4ef7\u63d0\u4ea4\u5931\u8d25',
        duration: 1500
      });
    }).finally(() => {
      this.isSubmitting = false;
    });
  }

  @Builder
  RatingCard(option: RatingOption) {
    Column() {
      Row({ space: this.largeFontEnabled ? 20 : 16 }) {
        Row() {
          Text(option.emoji)
            .fontSize(this.largeFontEnabled ? 36 : 28)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.highContrastEnabled ? '#000000' : '#ffffff')
        }
        .width(this.largeFontEnabled ? 80 : 64)
        .height(this.largeFontEnabled ? 80 : 64)
        .linearGradient(this.highContrastEnabled ? undefined : {
          angle: 135,
          colors: [[option.color[0], 0.0], [option.color[1], 1.0]]
        })
        .backgroundColor(this.highContrastEnabled ? '#ffff00' : undefined)
        .borderRadius(this.largeFontEnabled ? 20 : 16)
        .justifyContent(FlexAlign.Center)
        .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)

        Text(option.label)
          .fontSize(this.largeFontEnabled ? 25 : 20)
          .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
          .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
          .layoutWeight(1)

        if (this.selectedRating === option.id) {
          Row() {
            Text('OK')
              .fontSize(this.largeFontEnabled ? 14 : 12)
              .fontColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
              .fontWeight(FontWeight.Bold)
          }
          .width(this.largeFontEnabled ? 40 : 32)
          .height(this.largeFontEnabled ? 30 : 24)
          .backgroundColor(this.highContrastEnabled ? '#000000' : '#2563eb')
          .borderRadius(this.largeFontEnabled ? 15 : 12)
          .justifyContent(FlexAlign.Center)
        }
      }
      .width('100%')
      .padding(this.largeFontEnabled ? 25 : 20)
    }
    .width('100%')
    .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
    .borderRadius(16)
    .border({
      width: this.selectedRating === option.id ? (this.highContrastEnabled ? 3 : 2) : (this.highContrastEnabled ? 3 : 0),
      color: this.highContrastEnabled ? '#000000' : '#2563eb'
    })
    .shadow(this.highContrastEnabled ? undefined : {
      radius: this.selectedRating === option.id ? 8 : 4,
      color: this.selectedRating === option.id ? '#2563eb40' : '#0f00000a',
      offsetX: 0,
      offsetY: this.selectedRating === option.id ? 4 : 2
    })
    .onClick(() => {
      if (!this.existingReview) {
        this.selectedRating = option.id;
      }
    })
  }

  build() {
    Column() {
      Row({ space: this.largeFontEnabled ? 15 : 12 }) {
        NavBackButton()

        Text('\u5fd7\u613f\u8005\u8bc4\u4ef7')
          .fontSize(this.largeFontEnabled ? 22.5 : 18)
          .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
          .layoutWeight(1)
      }
      .width('100%')
      .padding(this.largeFontEnabled ? 20 : 16)
      .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
      .border({
        width: { bottom: this.highContrastEnabled ? 3 : 1 },
        color: this.highContrastEnabled ? '#000000' : '#e5e7eb'
      })

      if (this.isLoading) {
        Column({ space: 12 }) {
          LoadingProgress()
            .width(36)
            .height(36)
          Text('\u52a0\u8f7d\u4e2d...')
            .fontSize(this.largeFontEnabled ? 20 : 16)
            .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column({ space: 24 }) {
            Column({ space: this.largeFontEnabled ? 20 : 16 }) {
              Row() {
                Text('\u2713')
                  .fontSize(this.largeFontEnabled ? 40 : 32)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#10b981')
              }
              .width(this.largeFontEnabled ? 100 : 80)
              .height(this.largeFontEnabled ? 100 : 80)
              .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#d1fae5')
              .borderRadius(this.largeFontEnabled ? 50 : 40)
              .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
              .justifyContent(FlexAlign.Center)

              Text(this.getVolunteerReviewQuestion())
                .fontSize(this.largeFontEnabled ? 24 : 20)
                .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
                .fontWeight(FontWeight.Bold)
                .textAlign(TextAlign.Center)

              Text('\u60a8\u7684\u53cd\u9988\u5c06\u5e2e\u52a9\u5e73\u53f0\u4f18\u5316\u670d\u52a1\u5339\u914d\u4e0e\u8ddf\u8fdb')
                .fontSize(this.largeFontEnabled ? 17.5 : 14)
                .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
                .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
                .textAlign(TextAlign.Center)

              Text(this.orderTitle ? `\u8ba2\u5355\uff1a${this.orderTitle}` : '')
                .fontSize(this.largeFontEnabled ? 16 : 13)
                .fontColor(this.highContrastEnabled ? '#000000' : '#9ca3af')
                .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
                .textAlign(TextAlign.Center)
                .visibility(this.orderTitle ? Visibility.Visible : Visibility.None)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)

            if (this.existingReview) {
              Column({ space: 12 }) {
                Text('\u8be5\u8ba2\u5355\u5df2\u63d0\u4ea4\u8bc4\u4ef7')
                  .fontSize(this.largeFontEnabled ? 20 : 16)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#065f46')
                  .fontWeight(FontWeight.Bold)

                Text(this.existingReview.content ? this.existingReview.content : '\u5df2\u63d0\u4ea4\u8bc4\u4ef7')
                  .fontSize(this.largeFontEnabled ? 17.5 : 14)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#374151')
                  .lineHeight(this.largeFontEnabled ? 28 : 22)
              }
              .width('100%')
              .padding(20)
              .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
              .borderRadius(16)
              .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
              .alignItems(HorizontalAlign.Start)
            } else {
              Column({ space: this.largeFontEnabled ? 15 : 12 }) {
                ForEach(this.ratingOptions, (option: RatingOption) => {
                  this.RatingCard(option)
                })
              }

              if (this.selectedRating) {
                Column({ space: this.largeFontEnabled ? 15 : 12 }) {
                  Text('\u8865\u5145\u8bf4\u660e\uff08\u53ef\u9009\uff09')
                    .fontSize(this.largeFontEnabled ? 20 : 16)
                    .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
                    .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)

                  Column() {
                    TextArea({
                      placeholder:
                        '\u9009\u586b\uff1a\u53ef\u8865\u5145\u8bf4\u660e\u6c9f\u901a\u3001\u5230\u8fbe\u7b49\u60c5\u51b5\uff08\u5fd7\u613f\u8005\u89c6\u89d2\uff09',
                      text: this.feedback
                    })
                      .width('100%')
                      .height(this.largeFontEnabled ? 150 : 120)
                      .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#f9fafb')
                      .borderRadius(12)
                      .padding(this.largeFontEnabled ? 15 : 12)
                      .fontSize(this.largeFontEnabled ? 18.75 : 15)
                      .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
                      .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
                      .placeholderColor(this.highContrastEnabled ? '#000000' : '#9ca3af')
                      .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
                      .maxLength(200)
                      .onChange((value: string) => {
                        this.feedback = value;
                      })

                    Row() {
                      Blank()
                      Text(`${this.feedback.length}/200`)
                        .fontSize(this.largeFontEnabled ? 15 : 12)
                        .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
                        .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
                    }
                    .width('100%')
                    .padding({ right: 8, bottom: 4 })
                  }
                  .width('100%')
                  .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
                  .borderRadius(16)
                  .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)
              }
            }
          }
          .width('100%')
          .padding(this.largeFontEnabled ? 30 : 24)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#f9fafb')

        Column() {
          Button() {
            Text(this.existingReview
              ? '\u8fd4\u56de\u8ba2\u5355'
              : (this.isSubmitting ? '\u63d0\u4ea4\u4e2d...' : '\u63d0\u4ea4\u8bc4\u4ef7'))
              .fontSize(this.largeFontEnabled ? 22.5 : 18)
              .fontColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
              .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
          }
          .width('100%')
          .height(this.largeFontEnabled ? 70 : 56)
          .linearGradient(this.highContrastEnabled ? undefined : {
            angle: 90,
            colors: (!this.selectedRating && !this.existingReview) || this.isSubmitting
              ? [[0xd1d5db, 0.0], [0xd1d5db, 1.0]]
              : [[0x2563eb, 0.0], [0x6366f1, 1.0]]
          })
          .backgroundColor(this.highContrastEnabled ? '#000000' : undefined)
          .borderRadius(16)
          .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
          .enabled(this.existingReview ? true : (!!this.selectedRating && !this.isSubmitting))
          .onClick(() => {
            if (this.existingReview) {
              router.replaceUrl({
                url: 'pages/volunteer/OrderDetailPage',
                params: { id: this.orderId }
              }).catch((err: Error) => {
                console.error('navigation failed:', err);
              });
              return;
            }
            this.handleSubmit();
          })
        }
        .width('100%')
        .padding(this.largeFontEnabled ? 20 : 16)
        .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
        .border({
          width: { top: this.highContrastEnabled ? 3 : 1 },
          color: this.highContrastEnabled ? '#000000' : '#e5e7eb'
        })
      }
    }
    .width('100%')
    .height('100%')
  }
}


