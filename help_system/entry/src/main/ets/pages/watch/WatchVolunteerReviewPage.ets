import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { WatchButton } from '../../components/WatchButton';
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
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 8 }) {
            Text(this.seekerName.length > 0 ? `服务对象：${this.seekerName}` : '请为本次沟通打分')
              .fontSize(12)
              .width('100%')

            Row({ space: 6 }) {
              WatchButton({
                text: '满意',
                type: this.selectedScore === 5 ? 'primary' : 'secondary',
                size: 'small',
                enabled: this.existing === null,
                onClick: () => { this.selectedScore = 5; }
              })
              WatchButton({
                text: '一般',
                type: this.selectedScore === 3 ? 'primary' : 'secondary',
                size: 'small',
                enabled: this.existing === null,
                onClick: () => { this.selectedScore = 3; }
              })
              WatchButton({
                text: '不满',
                type: this.selectedScore === 1 ? 'emergency' : 'secondary',
                size: 'small',
                enabled: this.existing === null,
                onClick: () => { this.selectedScore = 1; }
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)

            TextInput({ placeholder: '补充说明（可选）' })
              .height(56)
              .fontSize(11)
              .enabled(this.existing === null)
              .onChange((v: string) => {
                this.feedback = v;
              })

            if (this.existing !== null) {
              Text('已提交评价')
                .fontSize(11)
                .fontColor('#64748b')
            } else {
              WatchButton({
                text: this.isSubmitting ? '提交中...' : '提交评价',
                type: 'primary',
                size: 'medium',
                width: '100%',
                enabled: this.selectedScore > 0 && !this.isSubmitting,
                onClick: () => { this.submit(); }
              })
            }
          }
          .width('100%')
          .padding(0)
        }
        .layoutWeight(1)
        .align(Alignment.TopStart)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f8fafc')
    .padding({ top: 30, bottom: 30, left: 12, right: 12 })
  }
}
