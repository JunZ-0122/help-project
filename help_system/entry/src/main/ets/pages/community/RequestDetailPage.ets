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

interface VolunteerView {
  id: string;
  name: string;
  phone: string;
}

interface RequestDetailView {
  id: string;
  title: string;
  description: string;
  location: string;
  status: string;
  statusLabel: string;
  createdAt: string;
  requesterName: string;
  requesterPhone: string;
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
    requesterName: '',
    requesterPhone: '',
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
      const volunteer = await this.loadVolunteer(request);
      this.request = this.mapRequest(request, volunteer);
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

  private async loadVolunteer(request: HelpRequest): Promise<VolunteerView | undefined> {
    if (!request.volunteerId) {
      return undefined;
    }

    try {
      const profile: UserProfile = await UserApi.getUserProfile(request.volunteerId);
      return {
        id: request.volunteerId,
        name: profile.name ? profile.name : (request.volunteerName ? request.volunteerName : '\u5fd7\u613f\u8005'),
        phone: profile.phone ? profile.phone : ''
      };
    } catch (err) {
      console.error('load community volunteer failed:', err);
      return {
        id: request.volunteerId,
        name: request.volunteerName ? request.volunteerName : '\u5fd7\u613f\u8005',
        phone: ''
      };
    }
  }

  private mapRequest(request: HelpRequest, volunteer?: VolunteerView): RequestDetailView {
    const updatedSource: string = request.updatedAt ? request.updatedAt : request.createdAt;
    return {
      id: request.id,
      title: request.title,
      description: request.description,
      location: request.location,
      status: request.status,
      statusLabel: this.getStatusLabel(request.status),
      createdAt: DateUtil.format(request.createdAt, 'YYYY-MM-DD HH:mm'),
      requesterName: request.userName,
      requesterPhone: request.userPhone,
      volunteer: volunteer,
      timeline: this.buildTimeline(request.status, updatedSource)
    };
  }

  private buildTimeline(status: string, updatedSource: string): TimelineItem[] {
    const updatedAt = DateUtil.format(updatedSource, 'HH:mm');
    const items: TimelineItem[] = [
      { time: updatedAt, label: '\u6c42\u52a9\u5df2\u53d1\u5e03' }
    ];

    if (status === 'assigned' || status === 'in-progress' || status === 'completed') {
      items.push({ time: updatedAt, label: '\u5df2\u5206\u914d\u5fd7\u613f\u8005' });
    }
    if (status === 'in-progress' || status === 'completed') {
      items.push({ time: updatedAt, label: '\u670d\u52a1\u8fdb\u884c\u4e2d' });
    }
    if (status === 'completed') {
      items.push({ time: updatedAt, label: '\u670d\u52a1\u5df2\u5b8c\u6210' });
    }
    if (status === 'cancelled') {
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
        return '#3b82f6';
      case 'in-progress':
        return '#f59e0b';
      case 'completed':
        return '#10b981';
      case 'cancelled':
      case 'rejected':
        return '#ef4444';
      case 'approved':
        return '#10b981';
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
      router.back();
    } catch (err) {
      const e = err as Error;
      promptAction.showToast({ message: e.message ? e.message : '\u53d6\u6d88\u5931\u8d25', duration: 2000 });
    } finally {
      this.actionLoading = false;
    }
  }

  @Builder
  TimelineItemBuilder(item: TimelineItem, isLast: boolean) {
    Row({ space: this.largeFontEnabled ? 16 : 12 }) {
      Column() {
        // 时间线圆点 - 参考设计使用更大的圆点
        Row()
          .width(this.largeFontEnabled ? 18 : 16)
          .height(this.largeFontEnabled ? 18 : 16)
          .backgroundColor(this.highContrastEnabled ? '#000000' : '#10b981') // 使用绿色
          .borderRadius(this.largeFontEnabled ? 9 : 8)
          .border(this.highContrastEnabled ? { width: 2, color: '#000000' } : { width: 3, color: '#ffffff' })
          .shadow(this.highContrastEnabled ? undefined : {
            radius: 4,
            color: '#10b98140',
            offsetX: 0,
            offsetY: 2
          })

        if (!isLast) {
          Row()
            .width(this.largeFontEnabled ? 3 : 2)
            .height(this.largeFontEnabled ? 50 : 40)
            .backgroundColor(this.highContrastEnabled ? '#000000' : '#e5e7eb')
            .margin({ top: 8 })
        }
      }
      .alignItems(HorizontalAlign.Center)

      Column({ space: this.largeFontEnabled ? 8 : 6 }) {
        Text(item.label)
          .fontSize(this.largeFontEnabled ? 17 : 15)
          .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
          .fontWeight(FontWeight.Medium)
        Text(item.time)
          .fontSize(this.largeFontEnabled ? 15 : 13)
          .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .padding({ bottom: this.largeFontEnabled ? 20 : 16 })
    }
    .alignItems(VerticalAlign.Top)
  }

  build() {
    Column() {
      // 顶部导航栏 - 增强样式
      Row({ space: this.largeFontEnabled ? 15 : 12 }) {
        NavBackButton()

        Text('\u6c42\u52a9\u8be6\u60c5')
          .fontSize(this.largeFontEnabled ? 22.5 : 18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
          .layoutWeight(1)
      }
      .width('100%')
      .padding(this.largeFontEnabled ? 20 : 16)
      .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
      .border({ width: { bottom: this.highContrastEnabled ? 3 : 1 }, color: this.highContrastEnabled ? '#000000' : '#e5e7eb' })
      .shadow(this.highContrastEnabled ? undefined : {
        radius: 4,
        color: '#0f00000a',
        offsetX: 0,
        offsetY: 2
      })

      if (this.isLoading) {
        Column({ space: 16 }) {
          LoadingProgress()
            .width(this.largeFontEnabled ? 45 : 36)
            .height(this.largeFontEnabled ? 45 : 36)
            .color(this.highContrastEnabled ? '#000000' : '#3b82f6')
          Text('\u52a0\u8f7d\u4e2d...')
            .fontSize(this.largeFontEnabled ? 20 : 16)
            .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(this.highContrastEnabled ? '#ffffff' : '#f9fafb')
      } else {
        Scroll() {
          Column({ space: this.largeFontEnabled ? 20 : 16 }) {
            // 状态和标题卡片 - 增强样式
            Column({ space: this.largeFontEnabled ? 16 : 12 }) {
              // 状态徽章 - 使用动态颜色
              Text(this.request.statusLabel)
                .fontSize(this.largeFontEnabled ? 17 : 14)
                .fontColor(this.highContrastEnabled ? '#000000' : this.getStatusColor(this.request.status))
                .fontWeight(FontWeight.Bold)
                .padding({ 
                  left: this.largeFontEnabled ? 20 : 16, 
                  right: this.largeFontEnabled ? 20 : 16, 
                  top: this.largeFontEnabled ? 10 : 8, 
                  bottom: this.largeFontEnabled ? 10 : 8 
                })
                .backgroundColor(this.highContrastEnabled ? '#ffff00' : this.getStatusBgColor(this.request.status))
                .borderRadius(this.largeFontEnabled ? 25 : 20)
                .border(this.highContrastEnabled ? { width: 2, color: '#000000' } : undefined)
                .shadow(this.highContrastEnabled ? undefined : {
                  radius: 4,
                  color: this.getStatusColor(this.request.status) + '30',
                  offsetX: 0,
                  offsetY: 2
                })

              Text(this.request.title)
                .fontSize(this.largeFontEnabled ? 25 : 20)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')

              Text(this.request.createdAt)
                .fontSize(this.largeFontEnabled ? 15 : 12)
                .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
            }
            .width('100%')
            .padding(this.largeFontEnabled ? 25 : 20)
            .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
            .borderRadius(16)
            .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
            .shadow(this.highContrastEnabled ? undefined : {
              radius: 8,
              color: '#0f00001a',
              offsetX: 0,
              offsetY: 4
            })

            // 求助信息卡片 - 增强样式
            Column({ space: this.largeFontEnabled ? 16 : 12 }) {
              Row({ space: 8 }) {
                Text('📝')
                  .fontSize(this.largeFontEnabled ? 22 : 18)
                Text('\u6c42\u52a9\u4fe1\u606f')
                  .fontSize(this.largeFontEnabled ? 20 : 16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
              }
              
              Text(this.request.description)
                .fontSize(this.largeFontEnabled ? 17 : 14)
                .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
                .lineHeight(this.largeFontEnabled ? 26 : 22)
                
              Row({ space: 8 }) {
                Text('📍')
                  .fontSize(this.largeFontEnabled ? 18 : 16)
                Text(`${this.request.location}`)
                  .fontSize(this.largeFontEnabled ? 17 : 14)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
              }
              .alignItems(VerticalAlign.Center)
            }
            .width('100%')
            .padding(this.largeFontEnabled ? 25 : 20)
            .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
            .borderRadius(16)
            .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
            .shadow(this.highContrastEnabled ? undefined : {
              radius: 8,
              color: '#0f00001a',
              offsetX: 0,
              offsetY: 4
            })
            .alignItems(HorizontalAlign.Start)

            // 求助人信息卡片 - 参考设计优化
            Column({ space: this.largeFontEnabled ? 20 : 16 }) {
              Text('\u6c42\u52a9\u4eba\u4fe1\u606f')
                .fontSize(this.largeFontEnabled ? 20 : 16)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
              
              // 用户头像和基本信息
              Row({ space: this.largeFontEnabled ? 16 : 12 }) {
                // 圆形头像容器
                Row() {
                  Text('👤')
                    .fontSize(this.largeFontEnabled ? 28 : 24)
                    .fontColor('#ffffff')
                }
                .width(this.largeFontEnabled ? 65 : 60)
                .height(this.largeFontEnabled ? 65 : 60)
                .backgroundColor(this.highContrastEnabled ? '#000000' : '#9ca3af')
                .borderRadius(this.largeFontEnabled ? 32.5 : 30)
                .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
                .justifyContent(FlexAlign.Center)
                .shadow(this.highContrastEnabled ? undefined : {
                  radius: 6,
                  color: '#0f00001a',
                  offsetX: 0,
                  offsetY: 2
                })

                Column({ space: 6 }) {
                  Text(this.request.requesterName)
                    .fontSize(this.largeFontEnabled ? 20 : 18)
                    .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
                    .fontWeight(FontWeight.Bold)
                  
                  Text('年龄：68岁') // 可以从后端获取年龄信息
                    .fontSize(this.largeFontEnabled ? 16 : 14)
                    .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              
              // 联系方式标题
              Text('联系方式')
                .fontSize(this.largeFontEnabled ? 17 : 14)
                .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
                .margin({ top: this.largeFontEnabled ? 8 : 4 })
              
              // 电话号码
              Text(this.request.requesterPhone)
                .fontSize(this.largeFontEnabled ? 18 : 16)
                .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
                .fontWeight(FontWeight.Medium)
              
              // 操作按钮
              Row({ space: this.largeFontEnabled ? 12 : 10 }) {
                Button() {
                  Row({ space: 8 }) {
                    Text('📞')
                      .fontSize(this.largeFontEnabled ? 18 : 16)
                    Text('拨打电话')
                      .fontSize(this.largeFontEnabled ? 16 : 14)
                      .fontColor('#ffffff')
                      .fontWeight(FontWeight.Medium)
                  }
                }
                .layoutWeight(1)
                .height(this.largeFontEnabled ? 48 : 44)
                .backgroundColor(this.highContrastEnabled ? '#000000' : '#10b981')
                .borderRadius(this.largeFontEnabled ? 24 : 22)
                .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
                .shadow(this.highContrastEnabled ? undefined : {
                  radius: 6,
                  color: '#10b98130',
                  offsetX: 0,
                  offsetY: 2
                })

                Button() {
                  Row({ space: 8 }) {
                    Text('💬')
                      .fontSize(this.largeFontEnabled ? 18 : 16)
                    Text('发送消息')
                      .fontSize(this.largeFontEnabled ? 16 : 14)
                      .fontColor('#ffffff')
                      .fontWeight(FontWeight.Medium)
                  }
                }
                .layoutWeight(1)
                .height(this.largeFontEnabled ? 48 : 44)
                .backgroundColor(this.highContrastEnabled ? '#000000' : '#3b82f6')
                .borderRadius(this.largeFontEnabled ? 24 : 22)
                .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
                .shadow(this.highContrastEnabled ? undefined : {
                  radius: 6,
                  color: '#3b82f630',
                  offsetX: 0,
                  offsetY: 2
                })
              }
              .margin({ top: this.largeFontEnabled ? 16 : 12 })
            }
            .width('100%')
            .padding(this.largeFontEnabled ? 25 : 20)
            .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
            .borderRadius(16)
            .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
            .shadow(this.highContrastEnabled ? undefined : {
              radius: 8,
              color: '#0f00001a',
              offsetX: 0,
              offsetY: 4
            })
            .alignItems(HorizontalAlign.Start)

            // 志愿者信息卡片 - 参考设计优化
            if (this.request.volunteer) {
              Column({ space: this.largeFontEnabled ? 20 : 16 }) {
                Text('\u5df2\u5206\u914d\u5fd7\u613f\u8005')
                  .fontSize(this.largeFontEnabled ? 20 : 16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
                
                // 志愿者头像和基本信息
                Row({ space: this.largeFontEnabled ? 16 : 12 }) {
                  // 圆形头像容器 - 蓝色主题
                  Row() {
                    Text('👨‍⚕️')
                      .fontSize(this.largeFontEnabled ? 28 : 24)
                  }
                  .width(this.largeFontEnabled ? 65 : 60)
                  .height(this.largeFontEnabled ? 65 : 60)
                  .backgroundColor(this.highContrastEnabled ? '#000000' : '#3b82f6')
                  .borderRadius(this.largeFontEnabled ? 32.5 : 30)
                  .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
                  .justifyContent(FlexAlign.Center)
                  .shadow(this.highContrastEnabled ? undefined : {
                    radius: 6,
                    color: '#3b82f630',
                    offsetX: 0,
                    offsetY: 2
                  })

                  Column({ space: 6 }) {
                    Text(this.request.volunteer.name)
                      .fontSize(this.largeFontEnabled ? 20 : 18)
                      .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
                      .fontWeight(FontWeight.Bold)
                    
                    Row({ space: 6 }) {
                      Text('📍')
                        .fontSize(this.largeFontEnabled ? 14 : 12)
                      Text('距离 2.1公里') // 可以从后端获取距离信息
                        .fontSize(this.largeFontEnabled ? 15 : 13)
                        .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
                    }
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                }
                
                // 联系方式标题
                Text('联系方式')
                  .fontSize(this.largeFontEnabled ? 17 : 14)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
                  .margin({ top: this.largeFontEnabled ? 8 : 4 })
                
                // 电话号码
                Text(this.request.volunteer.phone ? this.request.volunteer.phone : '\u6682\u65e0\u7535\u8bdd')
                  .fontSize(this.largeFontEnabled ? 18 : 16)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
                  .fontWeight(FontWeight.Medium)
              }
              .width('100%')
              .padding(this.largeFontEnabled ? 25 : 20)
              .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
              .borderRadius(16)
              .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
              .shadow(this.highContrastEnabled ? undefined : {
                radius: 8,
                color: '#0f00001a',
                offsetX: 0,
                offsetY: 4
              })
              .alignItems(HorizontalAlign.Start)
            }

            // 进度跟踪卡片 - 参考设计优化
            Column({ space: this.largeFontEnabled ? 20 : 16 }) {
              Text('\u5904\u7406\u8fdb\u5ea6')
                .fontSize(this.largeFontEnabled ? 20 : 16)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
              
              Column({ space: this.largeFontEnabled ? 4 : 2 }) {
                ForEach(this.request.timeline, (item: TimelineItem, index: number) => {
                  this.TimelineItemBuilder(item, index === this.request.timeline.length - 1)
                })
              }
            }
            .width('100%')
            .padding(this.largeFontEnabled ? 25 : 20)
            .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
            .borderRadius(16)
            .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
            .shadow(this.highContrastEnabled ? undefined : {
              radius: 8,
              color: '#0f00001a',
              offsetX: 0,
              offsetY: 4
            })
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding(this.largeFontEnabled ? 20 : 16)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .backgroundColor(this.highContrastEnabled ? '#ffffff' : '#f9fafb')

        // 底部操作按钮 - 审核/重分配/取消
        if (this.request.status === 'pending' || this.request.status === 'assigned') {
          Column({ space: this.largeFontEnabled ? 12 : 10 }) {
            if (this.request.status === 'pending') {
              Row({ space: this.largeFontEnabled ? 12 : 10 }) {
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
    .backgroundColor(this.highContrastEnabled ? '#ffffff' : '#f9fafb')
  }
}


