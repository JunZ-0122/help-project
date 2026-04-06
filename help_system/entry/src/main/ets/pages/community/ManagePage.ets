import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { DateUtil } from '../../utils/DateUtil';
import { CommunityApi } from '../../services/ApiService';
import type { CommunityRequest } from '../../models';

interface RequestItem {
  id: string;
  categoryLabel: string;
  titleLine: string;
  location: string;
  status: string;
  statusTagLabel: string;
  timeLine: string;
  requester: string;
  volunteer?: string;
  urgent: boolean;
  canAssign: boolean;
}

@Entry
@Component
struct ManagePage {
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  @State filter: 'all' | 'pending' | 'assigned' = 'all';
  @State list: RequestItem[] = [];
  @State listTotal: number = 0;
  @State isLoading: boolean = false;

  private skipNextPageShow: boolean = true;

  aboutToAppear() {
    this.loadRequests();
  }

  onPageShow() {
    if (this.skipNextPageShow) {
      this.skipNextPageShow = false;
      return;
    }
    this.loadRequests();
  }

  private async loadRequests(): Promise<void> {
    this.isLoading = true;
    try {
      const page = await CommunityApi.getRequestsPage({
        status: this.filter,
        page: 1,
        pageSize: 100
      });
      this.listTotal = page.total;
      this.list = page.items.map((r: CommunityRequest) => this.mapRequest(r));
    } catch (err) {
      const error = err as Error;
      console.error('load community requests failed:', error);
      promptAction.showToast({
        message: error.message ? error.message : '\u52a0\u8f7d\u6c42\u52a9\u5217\u8868\u5931\u8d25',
        duration: 1500
      });
    } finally {
      this.isLoading = false;
    }
  }

  private mapRequest(request: CommunityRequest): RequestItem {
    const pending = request.status === 'pending';
    const assignedLike = request.status === 'assigned' || request.status === 'in-progress';
    const completed = request.status === 'completed';
    let tagLabel = this.getStatusLabel(request.status);
    if (pending) {
      tagLabel = '\u5f85\u5206\u914d';
    } else if (assignedLike) {
      tagLabel = '\u5df2\u5206\u914d';
    } else if (completed) {
      tagLabel = '\u5df2\u5b8c\u6210';
    }
    return {
      id: request.id,
      categoryLabel: this.getCategoryLabel(request.type),
      titleLine: request.title ? request.title : this.getTypeLabel(request.type),
      location: request.location ? request.location : '\u2014',
      status: request.status,
      statusTagLabel: tagLabel,
      timeLine: DateUtil.formatCnMonthDayTime(request.createdAt),
      requester: request.userName ? request.userName : '\u2014',
      volunteer: request.volunteerName,
      urgent: request.urgency === 'emergency',
      canAssign: pending
    };
  }

  private getCategoryLabel(type: string): string {
    switch (type) {
      case 'medical':
      case 'emergency':
        return '\u5c31\u533b\u534f\u52a9';
      case 'companion':
        return '\u51fa\u884c\u534f\u52a9';
      case 'shopping':
      case 'repair':
      case 'other':
      default:
        return '\u751f\u6d3b\u5e2e\u6276';
    }
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
      case 'pending':
        return '\u5f85\u5206\u914d';
      case 'assigned':
        return '\u5df2\u5206\u914d';
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

  private statusTagFg(tag: string): string {
    if (tag === '\u5f85\u5206\u914d') {
      return '#c2410c';
    }
    if (tag === '\u5df2\u5b8c\u6210') {
      return '#475569';
    }
    return '#1d4ed8';
  }

  private statusTagBg(tag: string): string {
    if (tag === '\u5f85\u5206\u914d') {
      return '#ffedd5';
    }
    if (tag === '\u5df2\u5b8c\u6210') {
      return '#f1f5f9';
    }
    return '#dbeafe';
  }

  private setFilter(next: 'all' | 'pending' | 'assigned'): void {
    if (this.filter === next) {
      return;
    }
    this.filter = next;
    this.loadRequests();
  }

  @Builder
  FilterChip(label: string, value: 'all' | 'pending' | 'assigned') {
    Button(label)
      .height(this.largeFontEnabled ? 40 : 34)
      .padding({ left: 16, right: 16 })
      .backgroundColor(this.filter === value
        ? (this.highContrastEnabled ? '#000000' : '#2563eb')
        : (this.highContrastEnabled ? '#ffff00' : '#f1f5f9'))
      .fontColor(this.filter === value
        ? '#ffffff'
        : (this.highContrastEnabled ? '#000000' : '#475569'))
      .fontSize(this.largeFontEnabled ? 16 : 14)
      .fontWeight(this.filter === value ? FontWeight.Medium : FontWeight.Normal)
      .border(this.highContrastEnabled ? { width: 2, color: '#000000' } : undefined)
      .borderRadius(20)
      .onClick(() => {
        this.setFilter(value);
      })
  }

  @Builder
  RequestCard(request: RequestItem) {
    Column({ space: 14 }) {
      Row({ space: 8 }) {
        Text(request.categoryLabel)
          .fontSize(this.largeFontEnabled ? 14 : 12)
          .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
          .fontWeight(FontWeight.Medium)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#f1f5f9')
          .borderRadius(8)
          .border(this.highContrastEnabled ? { width: 2, color: '#000000' } : undefined)

        Text(request.statusTagLabel)
          .fontSize(this.largeFontEnabled ? 14 : 12)
          .fontColor(this.highContrastEnabled ? '#000000' : this.statusTagFg(request.statusTagLabel))
          .fontWeight(FontWeight.Medium)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor(this.highContrastEnabled ? '#ffff00' : this.statusTagBg(request.statusTagLabel))
          .borderRadius(8)
          .border(this.highContrastEnabled ? { width: 2, color: '#000000' } : undefined)

        if (request.urgent) {
          Text('\u7d27\u6025')
            .fontSize(this.largeFontEnabled ? 14 : 12)
            .fontColor('#ffffff')
            .fontWeight(FontWeight.Bold)
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .backgroundColor(this.highContrastEnabled ? '#dc2626' : '#ef4444')
            .borderRadius(8)
        }
      }
      .width('100%')

      Text(request.titleLine)
        .fontSize(this.largeFontEnabled ? 18 : 16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.highContrastEnabled ? '#000000' : '#0f172a')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Column({ space: 8 }) {
        Row({ space: 8 }) {
          Text('\u23f0')
            .fontSize(this.largeFontEnabled ? 16 : 14)
          Text(request.timeLine)
            .fontSize(this.largeFontEnabled ? 15 : 13)
            .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
            .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Row({ space: 8 }) {
          Text('📍')
            .fontSize(this.largeFontEnabled ? 16 : 14)
          Text(request.location)
            .fontSize(this.largeFontEnabled ? 15 : 13)
            .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
            .layoutWeight(1)
            .maxLines(2)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)

        Row({ space: 8 }) {
          Text('👤')
            .fontSize(this.largeFontEnabled ? 16 : 14)
          Text(`\u6c42\u52a9\u4eba\uff1a${request.requester}`)
            .fontSize(this.largeFontEnabled ? 15 : 13)
            .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
            .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      if (request.volunteer && !request.canAssign) {
        Text(`\u5df2\u5206\u914d\u7ed9\uff1a${request.volunteer}`)
          .fontSize(this.largeFontEnabled ? 15 : 13)
          .fontColor(this.highContrastEnabled ? '#000000' : '#2563eb')
          .fontWeight(FontWeight.Medium)
          .width('100%')
      }

      Row({ space: 10 }) {
        Button() {
          Row({ space: 6 }) {
            Text('👁')
              .fontSize(this.largeFontEnabled ? 16 : 14)
            Text('\u67e5\u770b\u8be6\u60c5')
              .fontSize(this.largeFontEnabled ? 16 : 14)
              .fontColor(this.highContrastEnabled ? '#000000' : '#475569')
              .fontWeight(FontWeight.Medium)
          }
        }
        .layoutWeight(1)
        .height(this.largeFontEnabled ? 48 : 44)
        .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
        .border({
          width: this.highContrastEnabled ? 3 : 1,
          color: this.highContrastEnabled ? '#000000' : '#e2e8f0'
        })
        .borderRadius(12)
        .onClick(() => {
          router.pushUrl({
            url: 'pages/community/RequestDetailPage',
            params: { id: request.id }
          }).catch((err: Error) => {
            console.error('navigation failed:', err);
          });
        })

        if (request.canAssign) {
          Button() {
            Row({ space: 6 }) {
              Text('👥')
                .fontSize(this.largeFontEnabled ? 16 : 14)
              Text('\u5206\u914d\u5fd7\u613f\u8005')
                .fontSize(this.largeFontEnabled ? 16 : 14)
                .fontColor('#ffffff')
                .fontWeight(FontWeight.Medium)
            }
          }
          .layoutWeight(1)
          .height(this.largeFontEnabled ? 48 : 44)
          .backgroundColor(this.highContrastEnabled ? '#000000' :
            (request.urgent ? '#dc2626' : '#2563eb'))
          .borderRadius(12)
          .onClick(() => {
            router.pushUrl({
              url: 'pages/community/AssignPage',
              params: { id: request.id }
            }).catch((err: Error) => {
              console.error('navigation failed:', err);
            });
          })
        }
      }
      .width('100%')
    }
    .width('100%')
    .padding(this.largeFontEnabled ? 18 : 16)
    .backgroundColor(this.highContrastEnabled ? '#ffff00' :
      (request.urgent ? '#fef2f2' : '#ffffff'))
    .borderRadius(14)
    .border(this.highContrastEnabled ?
      { width: 3, color: '#000000' } :
      (request.urgent ? { width: 1, color: '#fecaca' } : { width: 1, color: '#f1f5f9' }))
    .shadow(this.highContrastEnabled || request.urgent ? undefined : {
      radius: 10,
      color: '#0f172a0a',
      offsetX: 0,
      offsetY: 3
    })
  }

  build() {
    Column() {
      Row({ space: this.largeFontEnabled ? 12 : 10 }) {
        NavBackButton()

        Text('\u6c42\u52a9\u7ba1\u7406')
          .fontSize(this.largeFontEnabled ? 22 : 18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.highContrastEnabled ? '#000000' : '#0f172a')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank()
          .width(this.largeFontEnabled ? 44 : 40)
      }
      .width('100%')
      .padding({
        left: this.largeFontEnabled ? 16 : 12,
        right: this.largeFontEnabled ? 16 : 12,
        top: this.largeFontEnabled ? 14 : 10,
        bottom: this.largeFontEnabled ? 14 : 10
      })
      .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
      .border({
        width: { bottom: this.highContrastEnabled ? 3 : 1 },
        color: this.highContrastEnabled ? '#000000' : '#e2e8f0'
      })

      Row({ space: 8 }) {
        Row({ space: 8 }) {
          this.FilterChip('\u5168\u90e8', 'all')
          this.FilterChip('\u5f85\u5206\u914d', 'pending')
          this.FilterChip('\u5df2\u5206\u914d', 'assigned')
        }
        .layoutWeight(1)
      }
      .width('100%')
      .padding({
        left: this.largeFontEnabled ? 16 : 12,
        right: this.largeFontEnabled ? 16 : 12,
        top: this.largeFontEnabled ? 12 : 10,
        bottom: this.largeFontEnabled ? 10 : 8
      })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
      .border({
        width: { bottom: this.highContrastEnabled ? 3 : 1 },
        color: this.highContrastEnabled ? '#000000' : '#e2e8f0'
      })

      Scroll() {
        Column({ space: 14 }) {
          if (this.isLoading) {
            Column({ space: 12 }) {
              LoadingProgress()
                .width(36)
                .height(36)
                .color(this.highContrastEnabled ? '#000000' : '#2563eb')
              Text('\u52a0\u8f7d\u4e2d...')
                .fontSize(this.largeFontEnabled ? 16 : 14)
                .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
            }
            .width('100%')
            .padding(40)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          } else {
            Text(`${this.listTotal} \u6761\u6c42\u52a9`)
              .fontSize(this.largeFontEnabled ? 15 : 13)
              .fontColor(this.highContrastEnabled ? '#000000' : '#94a3b8')
              .width('100%')

            if (this.list.length === 0) {
              Column({ space: 12 }) {
                Text('\u2630')
                  .fontSize(44)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#cbd5e1')
                Text('\u6682\u65e0\u6c42\u52a9\u8bb0\u5f55')
                  .fontSize(this.largeFontEnabled ? 16 : 14)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
              }
              .width('100%')
              .padding(48)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
            } else {
              ForEach(this.list, (request: RequestItem) => {
                this.RequestCard(request)
              }, (request: RequestItem) => request.id)
            }
          }
        }
        .width('100%')
        .padding({
          left: this.largeFontEnabled ? 16 : 14,
          right: this.largeFontEnabled ? 16 : 14,
          top: 14,
          bottom: 24
        })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#f1f5f9')
    }
    .width('100%')
    .height('100%')
  }
}
