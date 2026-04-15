import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { WatchButton } from '../../components/WatchButton';
import call from '@ohos.telephony.call';
import { RequestApi } from '../../services/ApiService';
import type { SeekerRequestDetail, SeekerTimelineItem } from '../../models';

type SeekerTimelineState = 'done' | 'current' | 'upcoming';

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
      message: '确定取消该求助吗？',
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
        promptAction.showToast({ message: '已取消', duration: 1500 });
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
    if (/^[\?？\uFFFD]+$/.test(t)) {
      return fallback;
    }
    return t;
  }

  private statusTitle(): string {
    if (!this.detail) {
      return '进度列表';
    }
    const s = this.detail.request.status;
    if (s === 'pending') {
      return '正在匹配';
    }
    if (s === 'assigned') {
      return '匹配成功';
    }
    if (s === 'in-progress') {
      return '服务进度';
    }
    if (s === 'completed') {
      return '已完成';
    }
    if (s === 'cancelled') {
      return '已取消';
    }
    return '进度列表';
  }

  private statusSubtitle(): string {
    if (!this.detail) {
      return '';
    }
    if (this.detail.banner && this.detail.banner.title) {
      return this.safeText(this.detail.banner.title, '正在为您处理');
    }
    return this.safeText(this.detail.request.location, '位置未填写');
  }

  build() {
    Column() {
      Row({ space: 6 }) {
        NavBackButton()
        Text('进度列表')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 0, right: 0, top: 0, bottom: 4 })
      .backgroundColor('#ffffff')

      if (this.isLoading) {
        Column({ space: 8 }) {
          LoadingProgress().width(32).height(32)
          Text('加载中...').fontSize(13).fontColor('#64748b')
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
            Column({ space: 6 }) {
              Text(this.statusTitle())
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor('#0f172a')
                .width('100%')
                .textAlign(TextAlign.Center)

              Text(this.statusSubtitle())
                .fontSize(10)
                .fontColor('#64748b')
                .width('100%')
                .textAlign(TextAlign.Center)
                .maxLines(2)
            }
            .width('100%')
            .padding({ top: 0, bottom: 2 })

            Column({ space: 8 }) {
              Text(this.safeText(this.detail.request.title, '求助'))
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .fontColor('#0f172a')
                .width('100%')
                .textAlign(TextAlign.Center)

              if (this.detail.volunteer) {
                Column({ space: 4 }) {
                  Stack() {
                    Circle()
                      .width(28)
                      .height(28)
                      .fill('#e0e7ff')
                    Text('👤')
                      .fontSize(15)
                      .fontColor('#4f46e5')
                  }
                  .width(28)
                  .height(28)

                  Text(this.safeText(this.detail.volunteer.name, '志愿者'))
                    .fontSize(13)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#1f2937')

                  Text(this.safeText(this.detail.volunteer.phoneMasked, ''))
                    .fontSize(9)
                    .fontColor('#64748b')

                  Row({ space: 6 }) {
                    Text(`距离 ${this.detail.volunteer.distanceKm !== undefined && this.detail.volunteer.distanceKm !== null ? this.detail.volunteer.distanceKm.toFixed(1) + '公里' : '0.5公里'}`)
                      .fontSize(9)
                      .fontColor('#64748b')
                    Text(`预计 ${this.detail.etaMinutes !== undefined && this.detail.etaMinutes !== null ? this.detail.etaMinutes + '分钟' : '5分钟'}`)
                      .fontSize(9)
                      .fontColor('#64748b')
                  }
                }
                .width('100%')
                .alignItems(HorizontalAlign.Center)
                .padding(8)
                .backgroundColor('#f8fafc')
                .borderRadius(14)
              } else {
                Column({ space: 4 }) {
                  Stack() {
                    Circle()
                      .width(28)
                      .height(28)
                      .fill('#dbeafe')
                    Text('👤')
                      .fontSize(15)
                      .fontColor('#94a3b8')
                  }
                  .width(28)
                  .height(28)

                  Text('正在匹配中')
                    .fontSize(10)
                    .fontColor('#64748b')
                }
                .width('100%')
                .alignItems(HorizontalAlign.Center)
                .padding(8)
                .backgroundColor('#f8fafc')
                .borderRadius(14)
              }
            }
            .width('100%')
            .padding(8)
            .backgroundColor('#ffffff')
            .borderRadius(16)
            .shadow({ radius: 5, color: '#00000010', offsetY: 2 })

            Column({ space: 8 }) {
              Text('进度')
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor('#0f172a')
                .width('100%')

              ForEach(this.detail.timeline, (it: SeekerTimelineItem, idx: number) => {
                Row({ space: 8 }) {
                  Column() {
                    Text(it.state === 'done' ? '✓' : `${idx + 1}`)
                      .fontSize(11)
                      .fontColor('#ffffff')
                      .width(20)
                      .height(20)
                      .textAlign(TextAlign.Center)
                      .borderRadius(10)
                      .backgroundColor(this.timelineStateColor(it.state as SeekerTimelineState))
                  }
                  .width(20)
                  .height(20)

                  Column({ space: 2 }) {
                    Text(this.safeText(it.label, `进度${idx + 1}`))
                      .fontSize(11)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#1f2937')
                      .maxLines(2)
                    Text(this.safeText(it.time, '--'))
                      .fontSize(9)
                      .fontColor('#94a3b8')
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                }
                .width('100%')
                .padding({ top: 2, bottom: 2 })
              }, (it: SeekerTimelineItem, idx: number) => `tl-${idx}-${it.label}-${it.time}`)
            }
            .width('100%')
            .padding(10)
            .backgroundColor('#ffffff')
            .borderRadius(16)
            .shadow({ radius: 5, color: '#00000010', offsetY: 2 })

            if (this.canCancel()) {
              WatchButton({
                text: this.isCancelling ? '处理中...' : '取消求助',
                buttonType: 'emergency',
                buttonSize: 'small',
                buttonWidth: '100%',
                buttonEnabled: !this.isCancelling
              })
              .onClick(() => { this.cancel(); })
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
