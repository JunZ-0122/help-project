import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { MessageApi, RequestApi } from '../../services/ApiService';
import { DateUtil } from '../../utils/DateUtil';
import { ElderHighContrastTheme } from '../../utils/AccessibilityTheme';
import type { HelpRequest } from '../../models/Request';

interface MyRequestItem {
  id: string;
  title: string;
  description: string;
  type: string;
  categoryLabel: string;
  statusKey: string;
  statusLabel: string;
  statusBg: string;
  statusText: string;
  statusDot: string;
  timeShort: string;
  locationShort: string;
  volunteerId?: string;
  volunteerName?: string;
  unreadCount: number;
}

interface MyRequestsRouteParams {
  createdId?: string;
}

interface StatusPillColors {
  bg: string;
  text: string;
  dot: string;
}

@Entry
@Component
struct MyRequestsPage {
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  @State currentTab: number = 0;
  @State allRequests: MyRequestItem[] = [];
  @State isLoading: boolean = false;
  @State highlightRequestId: string = '';
  @State pageMessage: string = '';

  private tabTitles: string[] = ['全部', '处理中', '已完成', '等待中'];
  private skipNextPageShow: boolean = true;

  aboutToAppear() {
    const params = router.getParams() as MyRequestsRouteParams;
    if (params && params.createdId) {
      this.highlightRequestId = params.createdId;
      this.currentTab = 0;
      this.pageMessage = '已定位到新发布的求助';
    }
    this.loadRequests();
  }

  onPageShow() {
    if (this.skipNextPageShow) {
      this.skipNextPageShow = false;
      return;
    }
    this.loadRequests();
  }

  private showToast(message: string): void {
    promptAction.showToast({
      message: message,
      duration: 1500
    });
  }

  async loadRequests() {
    this.isLoading = true;

    try {
      const response = await RequestApi.getMyRequests(1, 50);
      const items: MyRequestItem[] = response.items.map((request: HelpRequest) => this.mapRequest(request));
      this.allRequests = items;
      this.loadUnreadCounts();
      if (this.pageMessage) {
        console.info('[MyRequestsPage] ' + this.pageMessage);
        this.pageMessage = '';
      }
    } catch (err) {
      console.error('load requests failed:', err);
    } finally {
      this.isLoading = false;
    }
  }

  private async loadUnreadCounts(): Promise<void> {
    if (this.allRequests.length === 0) {
      return;
    }
    const list = this.allRequests.slice();
    const maxFetch = 20;
    for (let i = 0; i < list.length && i < maxFetch; i++) {
      const item = list[i];
      try {
        const count: number = await MessageApi.countUnread(item.id);
        list[i] = {
          id: item.id,
          title: item.title,
          description: item.description,
          type: item.type,
          categoryLabel: item.categoryLabel,
          statusKey: item.statusKey,
          statusLabel: item.statusLabel,
          statusBg: item.statusBg,
          statusText: item.statusText,
          statusDot: item.statusDot,
          timeShort: item.timeShort,
          locationShort: item.locationShort,
          volunteerId: item.volunteerId,
          volunteerName: item.volunteerName,
          unreadCount: count
        };
      } catch (err) {
        list[i] = {
          id: item.id,
          title: item.title,
          description: item.description,
          type: item.type,
          categoryLabel: item.categoryLabel,
          statusKey: item.statusKey,
          statusLabel: item.statusLabel,
          statusBg: item.statusBg,
          statusText: item.statusText,
          statusDot: item.statusDot,
          timeShort: item.timeShort,
          locationShort: item.locationShort,
          volunteerId: item.volunteerId,
          volunteerName: item.volunteerName,
          unreadCount: 0
        };
      }
    }
    this.allRequests = list;
  }

  private mapRequest(request: HelpRequest): MyRequestItem {
    const colors = this.getStatusPillColors(request.status);
    return {
      id: request.id,
      title: request.title ? request.title : this.getTypeLabel(request.type),
      description: request.description,
      type: request.type,
      categoryLabel: this.getCategoryTag(request.type),
      statusKey: request.status,
      statusLabel: this.getListStatusLabel(request.status),
      statusBg: colors.bg,
      statusText: colors.text,
      statusDot: colors.dot,
      timeShort: DateUtil.format(request.createdAt, 'HH:mm'),
      locationShort: this.shortPlace(request.location),
      volunteerId: request.volunteerId,
      volunteerName: request.volunteerName,
      unreadCount: 0
    };
  }

  private shortPlace(loc: string): string {
    if (!loc || loc.length === 0) {
      return '\u672a\u586b\u5199\u4f4d\u7f6e';
    }
    const s = loc.trim();
    const idx = s.lastIndexOf('\u8857\u9053');
    if (idx > 0 && idx + 2 < s.length) {
      return s.substring(Math.max(0, idx - 6), Math.min(s.length, idx + 3));
    }
    if (s.length <= 16) {
      return s;
    }
    return s.substring(0, 16) + '\u2026';
  }

  private getCategoryTag(type: string): string {
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

  private getListStatusLabel(status: string): string {
    switch (status) {
      case 'pending':
        return '\u5df2\u53d1\u5e03';
      case 'assigned':
        return '\u5df2\u63a5\u5355';
      case 'in-progress':
        return '\u5fd7\u613f\u8005\u5df2\u51fa\u53d1';
      case 'completed':
        return '\u5df2\u5b8c\u6210';
      case 'cancelled':
        return '\u5df2\u53d6\u6d88';
      default:
        return '\u5904\u7406\u4e2d';
    }
  }

  private getStatusPillColors(status: string): StatusPillColors {
    const pillPending: StatusPillColors = { bg: '#dbeafe', text: '#1d4ed8', dot: '#3b82f6' };
    const pillAssigned: StatusPillColors = { bg: '#d1fae5', text: '#047857', dot: '#10b981' };
    const pillDeparted: StatusPillColors = { bg: '#ffedd5', text: '#c2410c', dot: '#f97316' };
    const pillCompleted: StatusPillColors = { bg: '#f3f4f6', text: '#4b5563', dot: '#9ca3af' };
    const pillCancelled: StatusPillColors = { bg: '#fee2e2', text: '#b91c1c', dot: '#ef4444' };
    switch (status) {
      case 'pending':
        return pillPending;
      case 'assigned':
        return pillAssigned;
      case 'in-progress':
        return pillDeparted;
      case 'completed':
        return pillCompleted;
      case 'cancelled':
        return pillCancelled;
      default:
        return pillPending;
    }
  }

  private canCancel(request: MyRequestItem): boolean {
    return request.statusKey === 'pending' || request.statusKey === 'assigned';
  }

  private canChat(request: MyRequestItem): boolean {
    return !!request.volunteerId && request.statusKey !== 'pending' && request.statusKey !== 'cancelled';
  }

  private isHighlighted(request: MyRequestItem): boolean {
    return this.highlightRequestId !== '' && request.id === this.highlightRequestId;
  }

  private getFilteredRequests(): MyRequestItem[] {
    switch (this.currentTab) {
      case 1:
        return this.allRequests.filter((request: MyRequestItem) =>
          request.statusKey === 'assigned' || request.statusKey === 'in-progress'
        );
      case 2:
        return this.allRequests.filter((request: MyRequestItem) => request.statusKey === 'completed');
      case 3:
        return this.allRequests.filter((request: MyRequestItem) => request.statusKey === 'pending');
      default:
        return this.allRequests;
    }
  }

  private viewRequestDetail(requestId: string) {
    router.pushUrl({
      url: 'pages/help-seeker/RequestDetailPage',
      params: {
        id: requestId
      }
    }).catch((err: Error) => {
      console.error('navigation failed:', err);
    });
  }

  private openChat(request: MyRequestItem) {
    if (!this.canChat(request) || !request.volunteerId) {
      this.showToast('当前暂无可用聊天对象');
      return;
    }

    router.pushUrl({
      url: 'pages/volunteer/ChatPage',
      params: {
        volunteerId: request.volunteerId,
        volunteerName: request.volunteerName ? request.volunteerName : '志愿者',
        requestId: request.id
      }
    }).catch((err: Error) => {
      console.error('navigation failed:', err);
    });
  }

  private openCreatePage() {
    router.pushUrl({
      url: 'pages/help-seeker/RequestTypePage'
    }).catch((err: Error) => {
      console.error('navigation failed:', err);
    });
  }

  private cancelRequest(request: MyRequestItem) {
    promptAction.showDialog({
      title: '取消求助',
      message: `确定要取消“${request.title}”吗？`,
      buttons: [
        { text: '保留', color: '#666666' },
        { text: '确认取消', color: '#ef4444' }
      ]
    }).then(async (result) => {
      if (result.index !== 1) {
        return;
      }

      try {
        await RequestApi.cancelRequest(request.id);
        console.info('[MyRequestsPage] 求助已取消');
        this.loadRequests();
      } catch (err) {
        console.error('cancel request failed:', err);
      }
    });
  }

  @Builder
  TabBar() {
    Row({ space: 8 }) {
      ForEach(this.tabTitles, (title: string, index: number) => {
        Button(title)
          .fontSize(this.largeFontEnabled ? 17.5 : 14)
          .fontColor(this.currentTab === index ? '#ffffff' : (this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#6b7280'))
          .backgroundColor(this.currentTab === index ? ElderHighContrastTheme.accentBlue : (this.highContrastEnabled ? ElderHighContrastTheme.surface : '#f3f4f6'))
          .borderRadius(20)
          .border(this.highContrastEnabled ? { width: ElderHighContrastTheme.borderWidth, color: ElderHighContrastTheme.borderStrong } : undefined)
          .onClick(() => {
            this.currentTab = index;
          })
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceEvenly)
    // 底边不留空，列表内容紧贴筛选栏
    .padding({ left: 12, right: 12, top: 10, bottom: 0 })
    .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.pageBg : '#ffffff')
  }

  @Builder
  RequestCard(request: MyRequestItem) {
    Column({ space: 12 }) {
      Row() {
        Text(request.categoryLabel)
          .fontSize(this.largeFontEnabled ? 14 : 12)
          .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#6b7280')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.iconBoxBg : '#f3f4f6')
          .borderRadius(6)
          .border(this.highContrastEnabled ? { width: ElderHighContrastTheme.borderWidth, color: ElderHighContrastTheme.borderStrong } : undefined)

        Row({ space: 6 }) {
          Row()
            .width(this.largeFontEnabled ? 7 : 6)
            .height(this.largeFontEnabled ? 7 : 6)
            .borderRadius(99)
            .backgroundColor(request.statusDot)

          Text(request.statusLabel)
            .fontSize(this.largeFontEnabled ? 14 : 12)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : request.statusText)
        }
        .padding({ left: 10, right: 10, top: 5, bottom: 5 })
        .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.tagBg : request.statusBg)
        .borderRadius(99)
        .border(this.highContrastEnabled ? { width: ElderHighContrastTheme.borderWidth, color: ElderHighContrastTheme.borderStrong } : undefined)
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)

        Row({ space: 6 }) {
          if (request.unreadCount > 0) {
            Text(request.unreadCount > 99 ? '99+' : `${request.unreadCount}`)
              .fontSize(10)
              .fontColor('#ffffff')
              .padding({ left: 5, right: 5, top: 2, bottom: 2 })
              .backgroundColor('#ef4444')
              .borderRadius(8)
          }

          Text('>')
            .fontSize(this.largeFontEnabled ? 20 : 16)
            .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#d1d5db')
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(request.description)
        .fontSize(this.largeFontEnabled ? 19 : 16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#111827')
        .width('100%')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Row() {
        Row({ space: 4 }) {
          Text('\u23f0')
            .fontSize(this.largeFontEnabled ? 15 : 13)
          Text(request.timeShort)
            .fontSize(this.largeFontEnabled ? 15 : 13)
            .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#6b7280')
        }

        Text('  ')
          .fontSize(12)

        Row({ space: 4 }) {
          Text('\u2022')
            .fontSize(this.largeFontEnabled ? 15 : 13)
            .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#9ca3af')
          Text(request.locationShort)
            .fontSize(this.largeFontEnabled ? 15 : 13)
            .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#6b7280')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (request.volunteerName && request.statusKey !== 'pending') {
        Row({ space: 10 }) {
          Text(`\u5fd7\u613f\u8005: ${request.volunteerName}`)
            .fontSize(this.largeFontEnabled ? 15 : 13)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.accentBlue : '#2563eb')

          Blank()

          if (this.canChat(request)) {
            Button(request.unreadCount > 0 ? `联系志愿者 (${request.unreadCount})` : '联系志愿者')
              .type(ButtonType.Normal)
              .height(this.largeFontEnabled ? 34 : 30)
              .fontSize(this.largeFontEnabled ? 14 : 12)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#2563eb')
              .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.tagBg : '#eff6ff')
              .borderRadius(99)
              .border(this.highContrastEnabled
                ? { width: ElderHighContrastTheme.borderWidth, color: ElderHighContrastTheme.borderStrong }
                : { width: 1, color: '#bfdbfe' })
              .padding({ left: 10, right: 10 })
              .onClick(() => {
                this.openChat(request);
              })
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }

      if (this.canCancel(request)) {
        Row() {
          Blank()
          Button('\u53d6\u6d88\u6c42\u52a9')
            .type(ButtonType.Normal)
            .fontSize(this.largeFontEnabled ? 15 : 13)
            .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.accentDanger : '#ef4444')
            .backgroundColor(Color.Transparent)
            .padding({ top: 4 })
            .onClick(() => {
              this.cancelRequest(request);
            })
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.surface : (this.isHighlighted(request) ? '#eff6ff' : '#ffffff'))
    .borderRadius(this.highContrastEnabled ? 12 : 14)
    .shadow(this.highContrastEnabled ? undefined : (this.isHighlighted(request) ? {
      radius: 12,
      color: '#2563eb22',
      offsetX: 0,
      offsetY: 4
    } : {
      radius: 10,
      color: '#0f000014',
      offsetX: 0,
      offsetY: 3
    }))
    .border(this.highContrastEnabled
      ? { width: ElderHighContrastTheme.borderWidth, color: ElderHighContrastTheme.borderStrong }
      : (this.isHighlighted(request)
        ? { width: 2, color: '#93c5fd' }
        : { width: 1, color: '#e8eaed' }))
    .onClick(() => {
      this.viewRequestDetail(request.id);
    })
  }

  build() {
    Column() {
      Row({ space: 16 }) {
        NavBackButton()

        Text('我的求助')
          .fontSize(this.largeFontEnabled ? 25 : 20)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#1a1a1a')
          .layoutWeight(1)

        Button('+')
          .width(this.largeFontEnabled ? 50 : 40)
          .height(this.largeFontEnabled ? 50 : 40)
          .fontSize(this.largeFontEnabled ? 22.5 : 18)
          .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.accentBlue : '#3b82f6')
          .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.tagBg : '#eff6ff')
          .borderRadius(this.largeFontEnabled ? 25 : 20)
          .border(this.highContrastEnabled ? ElderHighContrastTheme.cardBorder() : undefined)
          .onClick(() => {
            this.openCreatePage();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 0, bottom: 16 })
      .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.pageBg : '#ffffff')

      this.TabBar()

      if (this.isLoading) {
        Column({ space: 16 }) {
          LoadingProgress()
            .width(32)
            .height(32)
          Text('正在加载求助记录...')
            .fontSize(this.largeFontEnabled ? 20 : 16)
            .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#6b7280')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.pageBg : '#f9fafb')
      } else if (this.getFilteredRequests().length > 0) {
        Scroll() {
          Column({ space: 12 }) {
            ForEach(this.getFilteredRequests(), (request: MyRequestItem) => {
              this.RequestCard(request)
            })

            Row()
              .height(4)
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 12, bottom: 20 })
        }
        .layoutWeight(1)
        .align(Alignment.TopStart)
        .scrollBar(BarState.Off)
        .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.pageBg : '#f3f4f6')
      } else {
        Column({ space: 16 }) {
          Text('\u2630')
            .fontSize(48)
            .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#9ca3af')

          Text('\u6682\u65e0\u76f8\u5173\u6c42\u52a9')
            .fontSize(this.largeFontEnabled ? 20 : 16)
            .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#6b7280')

          Button('发布新求助')
            .fontSize(this.largeFontEnabled ? 17.5 : 14)
            .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.accentBlue : '#3b82f6')
            .fontColor('#ffffff')
            .borderRadius(20)
            .border(this.highContrastEnabled ? ElderHighContrastTheme.cardBorder() : undefined)
            .onClick(() => {
              this.openCreatePage();
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.pageBg : '#f9fafb')
      }
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }
}
