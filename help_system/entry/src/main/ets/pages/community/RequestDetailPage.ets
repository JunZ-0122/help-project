import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { CommunityApi, RequestApi, UserApi } from '../../services/ApiService';
import { DateUtil } from '../../utils/DateUtil';
import type { HelpRequest, UserProfile } from '../../models';

interface TimelineItem {
  time: string;
  label: string;
}

interface RequesterView {
  name: string;
  phone: string;
  ageText?: string;
  address?: string;
}

interface VolunteerView {
  id: string;
  name: string;
  phone: string;
  address?: string;
}

interface RequestDetailView {
  id: string;
  title: string;
  description: string;
  location: string;
  status: string;
  statusLabel: string;
  createdAt: string;
  requester: RequesterView;
  volunteer?: VolunteerView;
  timeline: TimelineItem[];
}

@Entry
@Component
struct RequestDetailPage {
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  @State requestId: string = '';
  @State isLoading: boolean = true;
  @State actionLoading: boolean = false;
  @State request: RequestDetailView = {
    id: '',
    title: '',
    description: '',
    location: '',
    status: 'pending',
    statusLabel: '\u5f85\u5206\u914d',
    createdAt: '',
    requester: {
      name: '',
      phone: ''
    },
    timeline: []
  };

  private skipNextPageShow: boolean = true;

  aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    if (params && params['id']) {
      this.requestId = params['id'] as string;
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

  private async loadRequestDetail(): Promise<void> {
    if (!this.requestId) {
      this.isLoading = false;
      return;
    }

    this.isLoading = true;

    try {
      const request: HelpRequest = await RequestApi.getRequestDetail(this.requestId);
      const requester = await this.loadRequester(request);
      const volunteer = await this.loadVolunteer(request);
      this.request = this.mapRequest(request, requester, volunteer);
    } catch (err) {
      const error = err as Error;
      console.error('load community request detail failed:', error);
      promptAction.showToast({
        message: error.message ? error.message : '\u52a0\u8f7d\u6c42\u52a9\u8be6\u60c5\u5931\u8d25',
        duration: 1500
      });
    } finally {
      this.isLoading = false;
    }
  }

  private async loadRequester(request: HelpRequest): Promise<RequesterView> {
    try {
      const profile: UserProfile = await UserApi.getUserProfile(request.userId);
      const ageText = profile.age !== undefined && profile.age !== null ? `${profile.age}\u5c81` : undefined;
      return {
        name: profile.name ? profile.name : request.userName,
        phone: profile.phone ? profile.phone : request.userPhone,
        ageText: ageText,
        address: profile.address ? profile.address : request.location
      };
    } catch (_err) {
      return {
        name: request.userName,
        phone: request.userPhone,
        address: request.location
      };
    }
  }

  private async loadVolunteer(request: HelpRequest): Promise<VolunteerView | undefined> {
    if (!request.volunteerId) {
      return undefined;
    }

    try {
      const profile: UserProfile = await UserApi.getUserProfile(request.volunteerId);
      return {
        id: request.volunteerId,
        name: profile.name ? profile.name : (request.volunteerName ? request.volunteerName : '\u5fd7\u613f\u8005'),
        phone: profile.phone ? profile.phone : '',
        address: profile.address ? profile.address : ''
      };
    } catch (_err) {
      return {
        id: request.volunteerId,
        name: request.volunteerName ? request.volunteerName : '\u5fd7\u613f\u8005',
        phone: ''
      };
    }
  }

  private mapRequest(request: HelpRequest, requester: RequesterView, volunteer?: VolunteerView): RequestDetailView {
    return {
      id: request.id,
      title: request.title,
      description: request.description,
      location: request.location,
      status: request.status,
      statusLabel: this.getStatusLabel(request.status),
      createdAt: DateUtil.format(request.createdAt, 'YYYY-MM-DD HH:mm'),
      requester: requester,
      volunteer: volunteer,
      timeline: this.buildTimeline(request)
    };
  }

  private buildTimeline(request: HelpRequest): TimelineItem[] {
    const createdAt = DateUtil.format(request.createdAt, 'HH:mm');
    const updatedAt = DateUtil.format(request.updatedAt ? request.updatedAt : request.createdAt, 'HH:mm');
    const items: TimelineItem[] = [{ time: createdAt, label: '\u6c42\u52a9\u5df2\u53d1\u5e03' }];

    if (request.status === 'assigned' || request.status === 'in-progress' || request.status === 'completed') {
      items.push({ time: updatedAt, label: '\u5df2\u5206\u914d\u5fd7\u613f\u8005' });
    }
    if (request.status === 'in-progress' || request.status === 'completed') {
      items.push({ time: updatedAt, label: '\u670d\u52a1\u8fdb\u884c\u4e2d' });
    }
    if (request.status === 'completed') {
      const completedTimeSource = request.completedAt ? request.completedAt : (request.updatedAt ? request.updatedAt : request.createdAt);
      items.push({ time: DateUtil.format(completedTimeSource, 'HH:mm'), label: '\u670d\u52a1\u5df2\u5b8c\u6210' });
    }
    if (request.status === 'cancelled') {
      items.push({ time: updatedAt, label: '\u6c42\u52a9\u5df2\u53d6\u6d88' });
    }
    return items;
  }

  private getStatusLabel(status: string): string {
    switch (status) {
      case 'assigned':
        return '\u5df2\u5206\u914d';
      case 'in-progress':
        return '\u8fdb\u884c\u4e2d';
      case 'completed':
        return '\u5df2\u5b8c\u6210';
      case 'cancelled':
        return '\u5df2\u53d6\u6d88';
      case 'approved':
        return '\u5df2\u901a\u8fc7\u5ba1\u6838';
      case 'rejected':
        return '\u5df2\u62d2\u7edd';
      default:
        return '\u5f85\u5206\u914d';
    }
  }

  private getStatusColor(status: string): string {
    switch (status) {
      case 'assigned':
        return '#2563eb';
      case 'in-progress':
        return '#d97706';
      case 'completed':
      case 'approved':
        return '#059669';
      case 'cancelled':
      case 'rejected':
        return '#dc2626';
      default:
        return '#6b7280';
    }
  }

  private getStatusBgColor(status: string): string {
    switch (status) {
      case 'assigned':
        return '#dbeafe';
      case 'in-progress':
        return '#fef3c7';
      case 'completed':
      case 'approved':
        return '#d1fae5';
      case 'cancelled':
      case 'rejected':
        return '#fee2e2';
      default:
        return '#f3f4f6';
    }
  }

  goBack() {
    router.back();
  }

  handleReassign() {
    router.pushUrl({
      url: 'pages/community/AssignPage',
      params: { id: this.requestId }
    }).catch((err: Error) => {
      console.error('navigation failed:', err);
    });
  }

  async handleReview(approved: boolean) {
    if (this.actionLoading) {
      return;
    }
    this.actionLoading = true;
    try {
      await CommunityApi.reviewRequest(this.requestId, approved ? 'approved' : 'rejected');
      promptAction.showToast({
        message: approved ? '\u5df2\u901a\u8fc7\u5ba1\u6838' : '\u5df2\u62d2\u7edd',
        duration: 1500
      });
      await this.loadRequestDetail();
    } catch (err) {
      const e = err as Error;
      promptAction.showToast({ message: e.message ? e.message : '\u64cd\u4f5c\u5931\u8d25', duration: 2000 });
    } finally {
      this.actionLoading = false;
    }
  }

  async handleCancelRequest() {
    if (this.actionLoading) {
      return;
    }
    this.actionLoading = true;
    try {
      await RequestApi.cancelRequest(this.requestId);
      promptAction.showToast({ message: '\u5df2\u53d6\u6d88\u6c42\u52a9', duration: 1500 });
      await this.loadRequestDetail();
    } catch (err) {
      const e = err as Error;
      promptAction.showToast({ message: e.message ? e.message : '\u53d6\u6d88\u5931\u8d25', duration: 2000 });
    } finally {
      this.actionLoading = false;
    }
  }

  @Builder
  InfoRow(label: string, value: string) {
    Row({ space: 12 }) {
      Text(label)
        .fontSize(this.largeFontEnabled ? 16 : 13)
        .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
        .width(this.largeFontEnabled ? 110 : 92)

      Text(value && value.trim().length > 0 ? value : '--')
        .fontSize(this.largeFontEnabled ? 17 : 14)
        .fontColor(this.highContrastEnabled ? '#000000' : '#111827')
        .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        NavBackButton()
        Text('\u6c42\u52a9\u8be6\u60c5')
          .fontSize(this.largeFontEnabled ? 22.5 : 18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.highContrastEnabled ? '#000000' : '#111827')
          .layoutWeight(1)
      }
      .width('100%')
      .padding(this.largeFontEnabled ? 20 : 16)
      .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
      .border({ width: { bottom: this.highContrastEnabled ? 3 : 1 }, color: this.highContrastEnabled ? '#000000' : '#e5e7eb' })

      if (this.isLoading) {
        Column({ space: 16 }) {
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
          Column({ space: 16 }) {
            Column({ space: 12 }) {
              Text(this.request.statusLabel)
                .fontSize(this.largeFontEnabled ? 16 : 13)
                .fontColor(this.highContrastEnabled ? '#000000' : this.getStatusColor(this.request.status))
                .fontWeight(FontWeight.Bold)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .backgroundColor(this.highContrastEnabled ? '#ffffff' : this.getStatusBgColor(this.request.status))
                .borderRadius(999)

              Text(this.request.title)
                .fontSize(this.largeFontEnabled ? 24 : 20)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.highContrastEnabled ? '#000000' : '#111827')

              Text(this.request.createdAt)
                .fontSize(this.largeFontEnabled ? 15 : 12)
                .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .padding(this.largeFontEnabled ? 22 : 18)
            .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
            .borderRadius(16)
            .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : { width: 1, color: '#e5e7eb' })

            Column({ space: 12 }) {
              Text('\u6c42\u52a9\u4fe1\u606f')
                .fontSize(this.largeFontEnabled ? 20 : 16)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.highContrastEnabled ? '#000000' : '#111827')
                .width('100%')
              Text(this.request.description)
                .fontSize(this.largeFontEnabled ? 17 : 14)
                .fontColor(this.highContrastEnabled ? '#000000' : '#111827')
                .lineHeight(this.largeFontEnabled ? 28 : 22)
              this.InfoRow('\u53d1\u751f\u5730\u70b9', this.request.location)
            }
            .width('100%')
            .padding(this.largeFontEnabled ? 22 : 18)
            .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
            .borderRadius(16)
            .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : { width: 1, color: '#e5e7eb' })

            Column({ space: 12 }) {
              Text('\u6c42\u52a9\u4eba\u4fe1\u606f')
                .fontSize(this.largeFontEnabled ? 20 : 16)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.highContrastEnabled ? '#000000' : '#111827')
                .width('100%')
              this.InfoRow('\u59d3\u540d', this.request.requester.name)
              if (this.request.requester.ageText) {
                this.InfoRow('\u5e74\u9f84', this.request.requester.ageText!)
              }
              this.InfoRow('\u8054\u7cfb\u7535\u8bdd', this.request.requester.phone)
              if (this.request.requester.address) {
                this.InfoRow('\u5e38\u7528\u5730\u5740', this.request.requester.address!)
              }
            }
            .width('100%')
            .padding(this.largeFontEnabled ? 22 : 18)
            .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
            .borderRadius(16)
            .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : { width: 1, color: '#e5e7eb' })

            if (this.request.volunteer) {
              Column({ space: 12 }) {
                Text('\u5df2\u5206\u914d\u5fd7\u613f\u8005')
                  .fontSize(this.largeFontEnabled ? 20 : 16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#111827')
                  .width('100%')
                this.InfoRow('\u59d3\u540d', this.request.volunteer.name)
                this.InfoRow('\u8054\u7cfb\u7535\u8bdd', this.request.volunteer.phone)
                if (this.request.volunteer.address) {
                  this.InfoRow('\u5e38\u7528\u5730\u5740', this.request.volunteer.address!)
                }
              }
              .width('100%')
              .padding(this.largeFontEnabled ? 22 : 18)
              .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
              .borderRadius(16)
              .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : { width: 1, color: '#e5e7eb' })
            }

            Column({ space: 12 }) {
              Text('\u5904\u7406\u8fdb\u5ea6')
                .fontSize(this.largeFontEnabled ? 20 : 16)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.highContrastEnabled ? '#000000' : '#111827')
                .width('100%')
              ForEach(this.request.timeline, (item: TimelineItem) => {
                Row({ space: 10 }) {
                  Text(item.time)
                    .fontSize(this.largeFontEnabled ? 15 : 12)
                    .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
                    .width(this.largeFontEnabled ? 70 : 58)
                  Text(item.label)
                    .fontSize(this.largeFontEnabled ? 17 : 14)
                    .fontColor(this.highContrastEnabled ? '#000000' : '#111827')
                    .layoutWeight(1)
                }
                .width('100%')
              })
            }
            .width('100%')
            .padding(this.largeFontEnabled ? 22 : 18)
            .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
            .borderRadius(16)
            .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : { width: 1, color: '#e5e7eb' })
          }
          .width('100%')
          .padding(this.largeFontEnabled ? 20 : 16)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .backgroundColor(this.highContrastEnabled ? '#ffffff' : '#f8fafc')

        if (this.request.status === 'pending' || this.request.status === 'assigned') {
          Column({ space: 10 }) {
            if (this.request.status === 'pending') {
              Row({ space: 10 }) {
                Button('\u5ba1\u6838\u901a\u8fc7')
                  .layoutWeight(1)
                  .height(this.largeFontEnabled ? 50 : 44)
                  .fontSize(this.largeFontEnabled ? 17 : 14)
                  .fontWeight(FontWeight.Medium)
                  .backgroundColor(this.highContrastEnabled ? '#000000' : '#10b981')
                  .fontColor('#ffffff')
                  .borderRadius(10)
                  .enabled(!this.actionLoading)
                  .onClick(() => this.handleReview(true))
                Button('\u5ba1\u6838\u62d2\u7edd')
                  .layoutWeight(1)
                  .height(this.largeFontEnabled ? 50 : 44)
                  .fontSize(this.largeFontEnabled ? 17 : 14)
                  .fontWeight(FontWeight.Medium)
                  .backgroundColor(this.highContrastEnabled ? '#000000' : '#6b7280')
                  .fontColor('#ffffff')
                  .borderRadius(10)
                  .enabled(!this.actionLoading)
                  .onClick(() => this.handleReview(false))
              }
              .width('100%')
            }
            if (this.request.status === 'assigned') {
              Button('\u91cd\u65b0\u5206\u914d\u5fd7\u613f\u8005')
                .width('100%')
                .height(this.largeFontEnabled ? 50 : 44)
                .fontSize(this.largeFontEnabled ? 17 : 14)
                .fontWeight(FontWeight.Medium)
                .backgroundColor(this.highContrastEnabled ? '#000000' : '#2563eb')
                .fontColor('#ffffff')
                .borderRadius(10)
                .enabled(!this.actionLoading)
                .onClick(() => this.handleReassign())
            }
            Button('\u53d6\u6d88\u6c42\u52a9')
              .width('100%')
              .height(this.largeFontEnabled ? 50 : 44)
              .fontSize(this.largeFontEnabled ? 17 : 14)
              .fontWeight(FontWeight.Medium)
              .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#fef2f2')
              .fontColor(this.highContrastEnabled ? '#000000' : '#b91c1c')
              .borderRadius(10)
              .enabled(!this.actionLoading)
              .onClick(() => this.handleCancelRequest())
          }
          .width('100%')
          .padding(this.largeFontEnabled ? 20 : 16)
          .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
          .border({ width: { top: this.highContrastEnabled ? 3 : 1 }, color: this.highContrastEnabled ? '#000000' : '#e5e7eb' })
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.highContrastEnabled ? '#ffffff' : '#f8fafc')
  }
}
