import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { MessageApi, RequestApi } from '../../services/ApiService';
import { WebSocketService } from '../../services/WebSocketService';
import { StorageUtil } from '../../utils/StorageUtil';
import { ElderHighContrastTheme } from '../../utils/AccessibilityTheme';
import type { ChatMessage, SeekerRequestDetail, SeekerTimelineItem, SeekerVolunteerBlock } from '../../models';

interface RequestDetailRouteParams {
  id?: string;
}

@Entry
@Component
struct RequestDetailPage {
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  @State requestId: string = '';
  @State isLoading: boolean = true;
  @State loadError: string = '';
  @State unreadCount: number = 0;
  @State detail: SeekerRequestDetail | null = null;

  private webSocketService = WebSocketService.getInstance();
  private skipNextPageShow: boolean = true;

  aboutToAppear() {
    const params = router.getParams() as RequestDetailRouteParams;
    if (params && params.id) {
      this.requestId = params.id;
    }
    this.loadRequestDetail();
  }

  onPageShow() {
    if (this.skipNextPageShow) {
      this.skipNextPageShow = false;
      return;
    }

    if (this.requestId) {
      this.loadRequestDetail();
    }
  }

  aboutToDisappear() {
    if (this.requestId) {
      this.webSocketService.offMessage(this.requestId);
    }
    this.webSocketService.disconnect();
  }

  async loadRequestDetail() {
    if (!this.requestId) {
      this.isLoading = false;
      this.loadError = '';
      return;
    }

    this.isLoading = true;
    this.loadError = '';

    try {
      const data: SeekerRequestDetail = await RequestApi.getSeekerRequestDetail(this.requestId);
      this.detail = data;
      await this.refreshUnreadCount();
      await this.connectRealtimeChannel();
    } catch (err) {
      const error = err as Error;
      console.error('load request detail failed:', error);
      this.loadError = error.message ? error.message : '\u52a0\u8f7d\u6c42\u52a9\u8be6\u60c5\u5931\u8d25';
      promptAction.showToast({
        message: this.loadError,
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  private async refreshUnreadCount(): Promise<void> {
    try {
      this.unreadCount = await MessageApi.countUnread(this.requestId);
    } catch (err) {
      console.error('load unread count failed:', err);
      this.unreadCount = 0;
    }
  }

  private async connectRealtimeChannel(): Promise<void> {
    const token = await StorageUtil.getString('token');
    if (!token) {
      return;
    }

    const connected = await this.webSocketService.connect(token);
    if (!connected) {
      return;
    }

    this.webSocketService.onMessage(this.requestId, (_message: ChatMessage) => {
      this.refreshUnreadCount();
    });
  }

  private getCategoryLabel(type: string): string {
    switch (type) {
      case 'medical':
        return '\u533b\u7597';
      case 'shopping':
        return '\u751f\u6d3b';
      case 'repair':
        return '\u751f\u6d3b';
      case 'companion':
        return '\u51fa\u884c';
      case 'emergency':
        return '\u7d27\u6025';
      default:
        return '\u5176\u4ed6';
    }
  }

  private getVolunteerInitial(vol: SeekerVolunteerBlock): string {
    const n = vol.name;
    if (!n || n.length === 0) {
      return 'V';
    }
    return n.substring(0, 1);
  }

  private timelineDotColor(item: SeekerTimelineItem): string {
    if (this.highContrastEnabled) {
      if (item.state === 'done') {
        return ElderHighContrastTheme.accentOn;
      }
      if (item.state === 'current') {
        return ElderHighContrastTheme.accentBlue;
      }
      return ElderHighContrastTheme.divider;
    }
    if (item.state === 'done') {
      return '#10b981';
    }
    if (item.state === 'current') {
      return '#2563eb';
    }
    return '#d1d5db';
  }

  /**
   * 步骤下方的竖线：与当前节点状态一致。
   * 「已完成」步骤向下的线段用绿色；「进行中」用蓝色；未到步骤保持灰线。
   */
  private timelineLineColorAfterItem(item: SeekerTimelineItem): string {
    if (this.highContrastEnabled) {
      if (item.state === 'done') {
        return ElderHighContrastTheme.accentOn;
      }
      if (item.state === 'current') {
        return ElderHighContrastTheme.accentBlue;
      }
      return '#e5e7eb';
    }
    if (item.state === 'done') {
      return '#10b981';
    }
    if (item.state === 'current') {
      return '#2563eb';
    }
    return '#e5e7eb';
  }

  private isLastTimelineIndex(index: number): boolean {
    const d = this.detail;
    if (d === null || d.timeline === undefined) {
      return false;
    }
    return index === d.timeline.length - 1;
  }

  goBack() {
    router.back();
  }

  showVolunteerPhone() {
    if (!this.detail || !this.detail.volunteer || !this.detail.volunteer.phone) {
      promptAction.showToast({
        message: '\u6682\u65e0\u8054\u7cfb\u7535\u8bdd',
        duration: 1500
      });
      return;
    }

    promptAction.showToast({
      message: `\u8054\u7cfb\u7535\u8bdd\uff1a${this.detail.volunteer.phone}`,
      duration: 2000
    });
  }

  openChat() {
    if (!this.detail || !this.detail.volunteer || !this.detail.volunteer.id) {
      promptAction.showToast({
        message: '\u5f53\u524d\u6682\u65e0\u53ef\u7528\u804a\u5929\u5bf9\u8c61',
        duration: 1500
      });
      return;
    }

    router.pushUrl({
      url: 'pages/volunteer/ChatPage',
      params: {
        volunteerId: this.detail.volunteer.id,
        volunteerName: this.detail.volunteer.name,
        requestId: this.requestId
      }
    }).catch((err: Error) => {
      console.error('navigation failed:', err);
    });
  }

  @Builder
  StatusBadge() {
    if (!this.detail) {
      Blank();
    } else {
      Row({ space: 6 }) {
        Row()
          .width(this.largeFontEnabled ? 8 : 6)
          .height(this.largeFontEnabled ? 8 : 6)
          .borderRadius(99)
          .backgroundColor(this.badgeDotColor(this.detail.badgeTone))

        Text(this.detail.badgeLabel)
          .fontSize(this.largeFontEnabled ? 15 : 13)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.badgeTextColor(this.detail.badgeTone))
      }
      .padding({
        left: 12,
        right: 12,
        top: 6,
        bottom: 6
      })
      .backgroundColor(this.badgeBgColor(this.detail.badgeTone))
      .borderRadius(99)
      .border(this.highContrastEnabled ? ElderHighContrastTheme.cardBorder() : undefined)
    }
  }

  private badgeBgColor(tone: string): string {
    if (this.highContrastEnabled) {
      return ElderHighContrastTheme.tagBg;
    }
    switch (tone) {
      case 'published':
        return '#dbeafe';
      case 'accepted':
        return '#d1fae5';
      case 'departed':
        return '#ffedd5';
      case 'completed':
        return '#f3f4f6';
      case 'cancelled':
        return '#fee2e2';
      default:
        return '#dbeafe';
    }
  }

  private badgeTextColor(tone: string): string {
    if (this.highContrastEnabled) {
      return ElderHighContrastTheme.textPrimary;
    }
    switch (tone) {
      case 'published':
        return '#1d4ed8';
      case 'accepted':
        return '#047857';
      case 'departed':
        return '#c2410c';
      case 'completed':
        return '#4b5563';
      case 'cancelled':
        return '#b91c1c';
      default:
        return '#1d4ed8';
    }
  }

  private badgeDotColor(tone: string): string {
    if (this.highContrastEnabled) {
      switch (tone) {
        case 'published':
          return ElderHighContrastTheme.accentBlue;
        case 'accepted':
          return ElderHighContrastTheme.accentOn;
        case 'departed':
          return '#e65100';
        case 'completed':
          return ElderHighContrastTheme.textTertiary;
        case 'cancelled':
          return ElderHighContrastTheme.accentDanger;
        default:
          return ElderHighContrastTheme.accentBlue;
      }
    }
    switch (tone) {
      case 'published':
        return '#3b82f6';
      case 'accepted':
        return '#10b981';
      case 'departed':
        return '#f97316';
      case 'completed':
        return '#9ca3af';
      case 'cancelled':
        return '#ef4444';
      default:
        return '#3b82f6';
    }
  }

  @Builder
  BannerBlock() {
    if (this.detail && this.detail.banner) {
      Column({ space: 6 }) {
        Row({ space: 8 }) {
          Text('\u23f0')
            .fontSize(this.largeFontEnabled ? 22 : 18)
          Text(this.detail.banner.title)
            .fontSize(this.largeFontEnabled ? 18 : 15)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#111827')
            .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Text(this.detail.banner.subtitle)
          .fontSize(this.largeFontEnabled ? 16 : 13)
          .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary :
            (this.detail.banner.tone === 'orange' ? '#ea580c' : '#1d4ed8'))
      }
      .width('100%')
      .padding(14)
      .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.tagBg :
        (this.detail.banner.tone === 'orange' ? '#fff7ed' : '#eff6ff'))
      .borderRadius(12)
      .border(this.highContrastEnabled ? ElderHighContrastTheme.cardBorder() : undefined)
    }
  }

  @Builder
  VolunteerCard() {
    if (this.detail && this.detail.volunteer) {
      Column({ space: 14 }) {
        Text('\u5fd7\u613f\u8005\u4fe1\u606f')
          .fontSize(this.largeFontEnabled ? 22 : 17)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#111827')
          .width('100%')

        Row({ space: 12 }) {
          Row() {
            Text(this.getVolunteerInitial(this.detail.volunteer))
              .fontSize(this.largeFontEnabled ? 26 : 20)
              .fontColor('#ffffff')
              .fontWeight(FontWeight.Bold)
          }
          .width(this.largeFontEnabled ? 56 : 48)
          .height(this.largeFontEnabled ? 56 : 48)
          .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.avatarBg : '#3b82f6')
          .borderRadius(this.largeFontEnabled ? 28 : 24)
          .justifyContent(FlexAlign.Center)

          Column({ space: 6 }) {
            Row({ space: 8 }) {
              Text(this.detail.volunteer.name)
                .fontSize(this.largeFontEnabled ? 20 : 16)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#111827')

              Text('\u5fd7\u613f\u8005')
                .fontSize(this.largeFontEnabled ? 13 : 11)
                .fontColor('#1d4ed8')
                .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                .backgroundColor('#dbeafe')
                .borderRadius(99)
            }

            if (this.detail.volunteer.distanceKm !== undefined && this.detail.volunteer.distanceKm !== null) {
              Row({ space: 4 }) {
                Text('\ud83d\udccd')
                  .fontSize(this.largeFontEnabled ? 15 : 12)
                Text(`\u8ddd\u79bb ${this.detail.volunteer.distanceKm}\u516c\u91cc`)
                  .fontSize(this.largeFontEnabled ? 16 : 13)
                  .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#6b7280')
              }
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')

        Row({ space: 12 }) {
          Button() {
            Row({ space: 6 }) {
              Text('\u260e')
                .fontColor('#ffffff')
              Text('\u62e8\u6253\u7535\u8bdd')
                .fontColor('#ffffff')
                .fontSize(this.largeFontEnabled ? 16 : 14)
            }
          }
          .layoutWeight(1)
          .height(this.largeFontEnabled ? 52 : 44)
          .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.accentOn : '#22c55e')
          .borderRadius(12)
          .border(this.highContrastEnabled ? { width: ElderHighContrastTheme.borderWidth, color: ElderHighContrastTheme.borderStrong } : undefined)
          .onClick(() => this.showVolunteerPhone())

          Button() {
            Row({ space: 6 }) {
              Text('\u2709')
                .fontColor('#ffffff')
              Text(this.unreadCount > 0
                ? `\u53d1\u9001\u6d88\u606f (${this.unreadCount})`
                : '\u53d1\u9001\u6d88\u606f')
                .fontColor('#ffffff')
                .fontSize(this.largeFontEnabled ? 16 : 14)
            }
          }
          .layoutWeight(1)
          .height(this.largeFontEnabled ? 52 : 44)
          .borderRadius(12)
          .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.accentBlue : '#6366f1')
          .border(this.highContrastEnabled ? { width: ElderHighContrastTheme.borderWidth, color: ElderHighContrastTheme.borderStrong } : undefined)
          .onClick(() => this.openChat())
        }

        Row() {
          Text('\u8054\u7cfb\u65b9\u5f0f')
            .fontSize(this.largeFontEnabled ? 18 : 14)
            .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#6b7280')
          Blank()
          Text(this.detail.volunteer.phoneMasked ? this.detail.volunteer.phoneMasked : '--')
            .fontSize(this.largeFontEnabled ? 18 : 14)
            .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#111827')
        }
        .width('100%')
        .padding({ top: 4 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.surface : '#ffffff')
      .borderRadius(16)
      .shadow(this.highContrastEnabled ? undefined : {
        radius: 8,
        color: '#18000000',
        offsetX: 0,
        offsetY: 2
      })
      .border(this.highContrastEnabled ? ElderHighContrastTheme.cardBorder() : undefined)
    }
  }

  @Builder
  DetailInfoCard() {
    if (this.detail) {
      Column({ space: 12 }) {
        Text('\u6c42\u52a9\u8be6\u60c5')
          .fontSize(this.largeFontEnabled ? 22 : 17)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#111827')
          .width('100%')

        Column({ space: 4 }) {
          Text('\u6c42\u52a9\u7c7b\u578b')
            .fontSize(this.largeFontEnabled ? 15 : 12)
            .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#6b7280')
          Text(this.getCategoryLabel(this.detail.request.type))
            .fontSize(this.largeFontEnabled ? 18 : 15)
            .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#111827')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')

        Column({ space: 4 }) {
          Text('\u8be6\u7ec6\u8bf4\u660e')
            .fontSize(this.largeFontEnabled ? 15 : 12)
            .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#6b7280')
          Text(this.detail.request.description)
            .fontSize(this.largeFontEnabled ? 18 : 15)
            .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#111827')
            .lineHeight(this.largeFontEnabled ? 28 : 22)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')

        Column({ space: 4 }) {
          Text('\u4f4d\u7f6e')
            .fontSize(this.largeFontEnabled ? 15 : 12)
            .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#6b7280')
          Row({ space: 6 }) {
            Text('\ud83d\udccd')
              .fontSize(this.largeFontEnabled ? 16 : 13)
            Text(this.detail.request.location)
              .fontSize(this.largeFontEnabled ? 18 : 15)
              .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#111827')
              .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
      .width('100%')
      .padding(16)
      .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.surface : '#ffffff')
      .borderRadius(16)
      .shadow(this.highContrastEnabled ? undefined : {
        radius: 8,
        color: '#18000000',
        offsetX: 0,
        offsetY: 2
      })
      .border(this.highContrastEnabled ? ElderHighContrastTheme.cardBorder() : undefined)
    }
  }

  @Builder
  TimelineItemBuilder(item: SeekerTimelineItem, isLast: boolean) {
    Row({ space: 12 }) {
      Column() {
        Row()
          .width(this.largeFontEnabled ? 14 : 12)
          .height(this.largeFontEnabled ? 14 : 12)
          .backgroundColor(this.timelineDotColor(item))
          .borderRadius(99)
          .border(this.highContrastEnabled ? ElderHighContrastTheme.cardBorder() : undefined)

        if (!isLast) {
          Row()
            .width(this.highContrastEnabled ? 3 : 2)
            .height(this.largeFontEnabled ? 40 : 32)
            .backgroundColor(this.timelineLineColorAfterItem(item))
            .margin({ top: 8 })
        }
      }
      .alignItems(HorizontalAlign.Center)

      Column({ space: 4 }) {
        Text(item.label)
          .fontSize(this.largeFontEnabled ? 17.5 : 14)
          .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#111827')
          .fontWeight(item.state === 'current' ? FontWeight.Medium : FontWeight.Normal)

        if (item.time && item.time.length > 0) {
          Text(item.time)
            .fontSize(this.largeFontEnabled ? 15 : 12)
            .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#6b7280')
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .padding({ bottom: 16 })
    }
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  ProgressCard() {
    if (this.detail && this.detail.timeline && this.detail.timeline.length > 0) {
      Column({ space: 14 }) {
        Text('\u8fdb\u5ea6\u8ddf\u8e2a')
          .fontSize(this.largeFontEnabled ? 22 : 17)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#111827')
          .width('100%')

        Column() {
          ForEach(this.detail.timeline, (item: SeekerTimelineItem, index: number) => {
            this.TimelineItemBuilder(item, this.isLastTimelineIndex(index))
          })
        }
      }
      .width('100%')
      .padding(16)
      .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.surface : '#ffffff')
      .borderRadius(16)
      .shadow(this.highContrastEnabled ? undefined : {
        radius: 8,
        color: '#18000000',
        offsetX: 0,
        offsetY: 2
      })
      .border(this.highContrastEnabled ? ElderHighContrastTheme.cardBorder() : undefined)
    }
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        NavBackButton()

        Text('\u6c42\u52a9\u8be6\u60c5')
          .fontSize(this.largeFontEnabled ? 22.5 : 18)
          .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#111827')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Row()
          .width(this.largeFontEnabled ? 50 : 40)
      }
      .width('100%')
      .padding(16)
      .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.pageBg : '#ffffff')
      .border(this.highContrastEnabled ?
        { width: { bottom: ElderHighContrastTheme.borderWidth }, color: ElderHighContrastTheme.borderStrong } :
        { width: { bottom: 1 }, color: '#e5e7eb' }
      )

      if (!this.requestId) {
        Column({ space: 20 }) {
          Text('\u2731')
            .fontSize(48)
            .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#9ca3af')
          Text('\u65e0\u6709\u6548\u6c42\u52a9\u4fe1\u606f')
            .fontSize(this.largeFontEnabled ? 18 : 16)
            .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#6b7280')
          Button('\u8fd4\u56de')
            .onClick(() => this.goBack())
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.pageBg : '#f5f5f5')
      } else if (this.isLoading) {
        Column({ space: 16 }) {
          LoadingProgress()
            .width(36)
            .height(36)
          Text('\u52a0\u8f7d\u4e2d...')
            .fontSize(this.largeFontEnabled ? 20 : 16)
            .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#6b7280')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.pageBg : '#f5f5f5')
      } else if (this.loadError) {
        Column({ space: 20 }) {
          Text(this.loadError)
            .fontSize(this.largeFontEnabled ? 16 : 14)
            .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#6b7280')
            .textAlign(TextAlign.Center)
          Button('\u91cd\u8bd5')
            .onClick(() => this.loadRequestDetail())
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.pageBg : '#f5f5f5')
      } else if (this.detail) {
        Scroll() {
          Column({ space: 12 }) {
            Column({ space: 12 }) {
              Row() {
                this.StatusBadge()
                Blank()
                Row({ space: 6 }) {
                  Text('\u23f0')
                    .fontSize(this.largeFontEnabled ? 17 : 14)
                  Text(this.detail.headerTimeDisplay)
                    .fontSize(this.largeFontEnabled ? 16 : 13)
                    .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#6b7280')
                }
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)

              this.BannerBlock()
            }
            .width('100%')
            .padding(16)
            .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.surface : '#ffffff')
            .borderRadius(16)
            .shadow(this.highContrastEnabled ? undefined : {
              radius: 8,
              color: '#18000000',
              offsetX: 0,
              offsetY: 2
            })
            .border(this.highContrastEnabled ? ElderHighContrastTheme.cardBorder() : undefined)

            this.VolunteerCard()

            this.DetailInfoCard()
            this.ProgressCard()
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 12, right: 12, top: 0, bottom: 20 })
        }
        .layoutWeight(1)
        .align(Alignment.TopStart)
        .scrollBar(BarState.Auto)
        .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.pageBg : '#f5f5f5')
      }
    }
    .width('100%')
    .height('100%')
  }
}
