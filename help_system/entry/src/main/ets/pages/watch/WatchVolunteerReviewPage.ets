import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { OrderApi, ReviewApi } from '../../services/ApiService';
import type { Review } from '../../models';
import type { VolunteerOrder } from '../../models/Order';

/**
 * 手表：志愿者评价求助者（与手机 ReviewPage 同一接口）。
 */
@Entry
@Component
struct WatchVolunteerReviewPage {
  @State orderId: string = '';
  @State isLoading: boolean = true;
  @State isSubmitting: boolean = false;
  @State revieweeId: string = '';
  @State seekerName: string = '';
  @State selectedScore: number = 0;
  @State feedback: string = '';
  @State existing: Review | null = null;

  aboutToAppear(): void {
    const p = router.getParams() as Record<string, string>;
    if (p && p['id']) {
      this.orderId = p['id'] as string;
    }
    this.loadCtx();
  }

  private async loadCtx(): Promise<void> {
    if (!this.orderId) {
      this.isLoading = false;
      return;
    }
    this.isLoading = true;
    try {
      const order: VolunteerOrder = await OrderApi.getOrderDetail(this.orderId);
      this.revieweeId = order.helpSeekerId;
      this.seekerName = order.helpSeekerName || '';
      const ex = await ReviewApi.getOrderReview(this.orderId);
      this.existing = ex;
      if (ex && ex.content) {
        this.feedback = ex.content;
      }
    } catch (e) {
      const err = e as Error;
      promptAction.showToast({ message: err.message || '加载失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  private submit(): void {
    if (!this.orderId || !this.revieweeId || this.selectedScore === 0 || this.isSubmitting || this.existing) {
      return;
    }
    this.isSubmitting = true;
    ReviewApi.createReview(this.orderId, this.revieweeId, this.selectedScore, this.feedback.trim(), [], false)
      .then(() => {
        promptAction.showToast({ message: '评价已提交', duration: 1500 });
        router.replaceUrl({ url: 'pages/watch/WatchVolunteerHomePage' }).catch((err: Error) => {
          console.error('nav home failed:', err);
        });
      })
      .catch((err: Error) => {
        promptAction.showToast({ message: err.message || '提交失败', duration: 2000 });
      })
      .finally(() => {
        this.isSubmitting = false;
      });
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        NavBackButton()
        Text('评价求助者')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#ffffff')

      if (this.isLoading) {
        Column({ space: 8 }) {
          LoadingProgress().width(32).height(32)
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 12 }) {
            Text(this.seekerName.length > 0 ? `服务对象：${this.seekerName}` : '请为本次沟通打分')
              .fontSize(14)
              .width('100%')

            Row({ space: 8 }) {
              Button('满意')
                .layoutWeight(1)
                .height(40)
                .fontSize(13)
                .backgroundColor(this.selectedScore === 5 ? '#10b981' : '#e2e8f0')
                .fontColor(this.selectedScore === 5 ? '#ffffff' : '#334155')
                .enabled(this.existing === null)
                .onClick(() => {
                  this.selectedScore = 5;
                })
              Button('一般')
                .layoutWeight(1)
                .height(40)
                .fontSize(13)
                .backgroundColor(this.selectedScore === 3 ? '#f59e0b' : '#e2e8f0')
                .fontColor(this.selectedScore === 3 ? '#ffffff' : '#334155')
                .enabled(this.existing === null)
                .onClick(() => {
                  this.selectedScore = 3;
                })
              Button('不满')
                .layoutWeight(1)
                .height(40)
                .fontSize(13)
                .backgroundColor(this.selectedScore === 1 ? '#ef4444' : '#e2e8f0')
                .fontColor(this.selectedScore === 1 ? '#ffffff' : '#334155')
                .enabled(this.existing === null)
                .onClick(() => {
                  this.selectedScore = 1;
                })
            }
            .width('100%')

            TextInput({ placeholder: '补充说明（可选）' })
              .height(72)
              .fontSize(13)
              .enabled(this.existing === null)
              .onChange((v: string) => {
                this.feedback = v;
              })

            if (this.existing !== null) {
              Text('已提交评价')
                .fontSize(13)
                .fontColor('#64748b')
            } else {
              Button(this.isSubmitting ? '提交中...' : '提交评价')
                .width('100%')
                .height(42)
                .enabled(this.selectedScore > 0 && !this.isSubmitting)
                .onClick(() => {
                  this.submit();
                })
            }
          }
          .width('100%')
          .padding(12)
        }
        .layoutWeight(1)
        .align(Alignment.TopStart)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f8fafc')
  }
}
