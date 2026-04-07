import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { WatchButton } from '../../components/WatchButton';
import call from '@ohos.telephony.call';
import { RequestApi } from '../../services/ApiService';
import type { SeekerRequestDetail, SeekerTimelineItem } from '../../models';

/** �?SeekerTimelineItem.state 一致，避免索引访问类型（ArkTS 不支持） */
type SeekerTimelineState = 'done' | 'current' | 'upcoming';

/**
 * 手表：求助详情（seeker-detail 聚合接口）�?
 */
@Entry
@Component
struct WatchSeekerRequestDetailPage {
  @State requestId: string = '';
  @State isLoading: boolean = true;
  @State detail: SeekerRequestDetail | null = null;
  @State isCancelling: boolean = false;

  aboutToAppear(): void {
    const p = router.getParams() as Record<string, string>;
    if (p && p['id']) {
      this.requestId = p['id'] as string;
    }
    this.load();
  }

  private async load(): Promise<void> {
    if (!this.requestId) {
      this.isLoading = false;
      return;
    }
    this.isLoading = true;
    try {
      this.detail = await RequestApi.getSeekerRequestDetail(this.requestId);
    } catch (e) {
      const err = e as Error;
      promptAction.showToast({ message: err.message || '加载失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  private canCancel(): boolean {
    if (!this.detail) {
      return false;
    }
    const s = this.detail.request.status;
    return s === 'pending' || s === 'assigned';
  }

  private cancel(): void {
    if (!this.detail || this.isCancelling) {
      return;
    }
    promptAction.showDialog({
      title: '取消求助',
      message: '确定取消该求助吗�?,
      buttons: [
        { text: '保留', color: '#666666' },
        { text: '确认取消', color: '#ef4444' }
      ]
    }).then(async (result) => {
      if (result.index !== 1) {
        return;
      }
      this.isCancelling = true;
      try {
        await RequestApi.cancelRequest(this.requestId);
        promptAction.showToast({ message: '已取�?, duration: 1500 });
        await this.load();
      } catch (e) {
        const err = e as Error;
        promptAction.showToast({ message: err.message || '取消失败', duration: 2000 });
      } finally {
        this.isCancelling = false;
      }
    });
  }

  private timelineStateColor(st: SeekerTimelineState): string {
    if (st === 'done') {
      return '#10b981';
    }
    if (st === 'current') {
      return '#2563eb';
    }
    return '#94a3b8';
  }

  private safeText(value: string | undefined, fallback: string): string {
    if (!value) {
      return fallback;
    }
    const t = value.trim();
    if (t.length === 0) {
      return fallback;
    }
    if (/^[\?？�]+$/.test(t)) {
      return fallback;
    }
    return t;
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        NavBackButton()
        Text('求助详情')
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
          Text('加载�?..').fontSize(13).fontColor('#64748b')
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else if (!this.detail) {
        Text('暂无数据')
          .layoutWeight(1)
          .fontColor('#94a3b8')
      } else {
        Scroll() {
          Column({ space: 10 }) {
            Text(this.safeText(this.detail.request.title, '求助'))
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .width('100%')

            Text(this.safeText(this.detail.request.location, '位置未填�?))
              .fontSize(11)
              .fontColor('#64748b')
              .width('100%')

            if (this.detail.volunteer) {
              Column({ space: 4 }) {
                Text('志愿�?)
                  .fontSize(10)
                  .fontColor('#64748b')
                Text(`${this.safeText(this.detail.volunteer.name, '志愿�?)} ${this.safeText(this.detail.volunteer.phoneMasked, '')}`)
                  .fontSize(11)
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .padding(10)
              .backgroundColor('#f1f5f9')
              .borderRadius(10)

              if (this.detail.volunteer && this.detail.volunteer.phone) {
                WatchButton({
                  text: '拨打志愿者电�?,
                  buttonType: 'primary',
                  buttonSize: 'medium',
                  buttonWidth: '100%',
                  accessibilityLabel: '拨打志愿者电�?,
                  onClick: () => {
                    try {
                      call.makeCall(this.detail!.volunteer!.phone!);
                    } catch (e) {
                      promptAction.showToast({
                        message: `电话�?{this.detail!.volunteer!.phoneMasked}`,
                        duration: 3000
                      });
                    }
                  }
                })
              }
            }

            Text('进度')
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
            ForEach(this.detail.timeline, (it: SeekerTimelineItem, idx: number) => {
              Row({ space: 8 }) {
                Text(`${idx + 1}`)
                  .fontSize(12)
                  .fontColor('#ffffff')
                  .width(18)
                  .height(18)
                  .textAlign(TextAlign.Center)
                  .borderRadius(9)
                  .backgroundColor(this.timelineStateColor(it.state))
                Column({ space: 2 }) {
                  Text(this.safeText(it.label, `进度${idx + 1}`)).fontSize(11)
                  Text(this.safeText(it.time, '--')).fontSize(10).fontColor('#94a3b8')
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              .width('100%')
            }, (it: SeekerTimelineItem, idx: number) => `tl-${idx}-${it.label}-${it.time}`)

            if (this.canCancel()) {
              WatchButton({
                text: this.isCancelling ? '处理�?..' : '取消求助',
                buttonType: 'emergency',
                buttonSize: 'medium',
                buttonWidth: '100%',
                buttonEnabled: !this.isCancelling,
                onClick: () => { this.cancel(); }
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
