import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { DateUtil } from '../../utils/DateUtil';
import { StorageUtil } from '../../utils/StorageUtil';
import { CommunityApi } from '../../services/ApiService';
import type { CommunityRequest, CommunityStatistics, UserProfile } from '../../models';

interface StatCard {
  title: string;
  value: string;
  icon: string;
  color: string;
  iconBg: string;
}

interface PendingRequestView {
  id: string;
  title: string;
  requester: string;
  time: string;
  priority: string;
  priorityColor: string;
}

@Entry
@Component
struct CommunityHomePage {
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  @State adminName: string = '\u7ba1\u7406\u5458';
  @State statCards: StatCard[] = [];
  @State pendingRequests: PendingRequestView[] = [];
  @State isLoading: boolean = false;

  aboutToAppear() {
    this.loadHomeData();
  }

  onPageShow() {
    // 页面显示时刷新数据
    this.loadHomeData();
  }

  private async loadHomeData(): Promise<void> {
    this.isLoading = true;

    try {
      const user: UserProfile | null = await StorageUtil.get<UserProfile>('user');
      if (user && user.name) {
        this.adminName = user.name;
      }

      const stats: CommunityStatistics = await CommunityApi.getStatistics();
      const pendingRequests: CommunityRequest[] = await CommunityApi.getPendingRequests();

      this.statCards = this.buildStatCards(stats);
      this.pendingRequests = pendingRequests.slice(0, 3).map((request: CommunityRequest) => this.mapPendingRequest(request));
    } catch (err) {
      const error = err as Error;
      console.error('load community home data failed:', error);
      promptAction.showToast({
        message: error.message ? error.message : '\u52a0\u8f7d\u793e\u533a\u9996\u9875\u5931\u8d25',
        duration: 1500
      });
    } finally {
      this.isLoading = false;
    }
  }

  private buildStatCards(stats: CommunityStatistics): StatCard[] {
    return [
      {
        title: '\u4eca\u65e5\u6c42\u52a9\u6570',
        value: stats.todayRequests.toString(),
        icon: '!',
        color: '#2563eb',
        iconBg: '#dbeafe'
      },
      {
        title: '\u5f85\u5904\u7406\u6c42\u52a9',
        value: stats.pendingRequests.toString(),
        icon: '\u23f1',
        color: '#ea580c',
        iconBg: '#ffedd5'
      },
      {
        title: '\u5728\u7ebf\u5fd7\u613f\u8005',
        value: stats.availableVolunteers.toString(),
        icon: '👥',
        color: '#059669',
        iconBg: '#d1fae5'
      }
    ];
  }

  private mapPendingRequest(request: CommunityRequest): PendingRequestView {
    return {
      id: request.id,
      title: request.title ? request.title : this.getTypeLabel(request.type),
      requester: request.userName,
      time: DateUtil.getRelativeTime(request.createdAt),
      priority: this.getPriorityLabel(request.urgency),
      priorityColor: this.getPriorityColor(request.urgency)
    };
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

  private getPriorityLabel(urgency: string): string {
    switch (urgency) {
      case 'emergency':
        return '\u7d27\u6025';
      case 'high':
        return '\u8f83\u6025';
      case 'medium':
        return '\u666e\u901a';
      default:
        return '\u4f4e\u4f18\u5148';
    }
  }

  private getPriorityColor(urgency: string): string {
    switch (urgency) {
      case 'emergency':
        return '#ef4444';
      case 'high':
        return '#f97316';
      case 'medium':
        return '#3b82f6';
      default:
        return '#6b7280';
    }
  }

  navigateToPage(path: string) {
    router.pushUrl({
      url: path
    }).catch((err: Error) => {
      console.error('navigation failed:', err);
    });
  }

  assignRequest(requestId: string) {
    router.pushUrl({
      url: 'pages/community/AssignPage',
      params: {
        id: requestId
      }
    }).catch((err: Error) => {
      console.error('navigation failed:', err);
    });
  }

  @Builder
  StatCardBuilder(stat: StatCard) {
    Column({ space: this.largeFontEnabled ? 12 : 10 }) {
      Row() {
        Text(stat.icon)
          .fontSize(this.largeFontEnabled ? 22 : 18)
          .fontColor(this.highContrastEnabled ? '#000000' : stat.color)
          .fontWeight(stat.icon === '!' ? FontWeight.Bold : FontWeight.Medium)
      }
      .width(this.largeFontEnabled ? 48 : 44)
      .height(this.largeFontEnabled ? 48 : 44)
      .backgroundColor(this.highContrastEnabled ? '#ffff00' : stat.iconBg)
      .borderRadius(12)
      .justifyContent(FlexAlign.Center)
      .border(this.highContrastEnabled ? { width: 2, color: '#000000' } : undefined)

      Text(stat.value)
        .fontSize(this.largeFontEnabled ? 30 : 26)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.highContrastEnabled ? '#000000' : '#0f172a')

      Text(stat.title)
        .fontSize(this.largeFontEnabled ? 14 : 11)
        .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 16, bottom: 16 })
    .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
    .borderRadius(14)
    .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : { width: 1, color: '#f1f5f9' })
    .shadow(this.highContrastEnabled ? undefined : {
      radius: 12,
      color: '#5b21b614',
      offsetX: 0,
      offsetY: 4
    })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  PendingRequestItem(request: PendingRequestView, isLast: boolean) {
    Column() {
      Row({ space: 12 }) {
        Row()
          .width(this.largeFontEnabled ? 10 : 8)
          .height(this.largeFontEnabled ? 10 : 8)
          .backgroundColor(this.highContrastEnabled ? '#000000' : request.priorityColor)
          .borderRadius(this.largeFontEnabled ? 5 : 4)
          .border(this.highContrastEnabled ? { width: 2, color: '#000000' } : undefined)

        Column({ space: 6 }) {
          Text(`\u5fd7\u613f\u8005"${request.requester}"\u5b8c\u6210\u4e86${request.title}`)
            .fontSize(this.largeFontEnabled ? 17 : 14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.highContrastEnabled ? '#000000' : '#1e293b')
            .width('100%')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(request.time)
            .fontSize(this.largeFontEnabled ? 15 : 12)
            .fontColor(this.highContrastEnabled ? '#000000' : '#94a3b8')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
      .onClick(() => {
        this.assignRequest(request.id);
      })

      if (!isLast) {
        Divider()
          .color(this.highContrastEnabled ? '#000000' : '#f1f5f9')
          .strokeWidth(this.highContrastEnabled ? 2 : 1)
      }
    }
    .width('100%')
  }

  build() {
    Column() {
      // 顶部欢迎卡片
      Column({ space: 8 }) {
        Text('\u793e\u533a\u7ba1\u7406\u5e73\u53f0')
          .fontSize(this.largeFontEnabled ? 28 : 24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')

        Text('\u671b\u4eac\u8857\u9053\u793e\u533a\u670d\u52a1\u4e2d\u5fc3')
          .fontSize(this.largeFontEnabled ? 16 : 13)
          .fontColor('#ffffff')
          .opacity(0.92)
      }
      .width('100%')
      .padding({ left: 22, right: 22, top: 28, bottom: 26 })
      .linearGradient(this.highContrastEnabled ? undefined : {
        angle: 160,
        colors: [[0x4c1d95, 0.0], [0x6d28d9, 0.45], [0x7c3aed, 1.0]]
      })
      .backgroundColor(this.highContrastEnabled ? '#ffff00' : undefined)
      .borderRadius({ bottomLeft: 20, bottomRight: 20 })
      .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
      .alignItems(HorizontalAlign.Start)

      Scroll() {
        Column({ space: 20 }) {
          if (this.isLoading) {
            Text('\u52a0\u8f7d\u4e2d...')
              .fontSize(this.largeFontEnabled ? 17.5 : 14)
              .fontColor(this.highContrastEnabled ? '#000000' : '#9ca3af')
          } else {
            // 统计卡片网格
          Row({ space: 10 }) {
            ForEach(this.statCards, (stat: StatCard) => {
              Column() {
                this.StatCardBuilder(stat)
              }
              .layoutWeight(1)
            }, (stat: StatCard) => stat.title)
          }
          .width('100%')
          }

          // 快速操作
          Column({ space: 12 }) {
            Text('\u5feb\u6377\u64cd\u4f5c')
              .fontSize(this.largeFontEnabled ? 20 : 16)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.highContrastEnabled ? '#000000' : '#0f172a')
              .alignSelf(ItemAlign.Start)

            Column({ space: 10 }) {
              Button() {
                Row({ space: 14 }) {
                  Row() {
                    Text('📊')
                      .fontSize(this.largeFontEnabled ? 24 : 20)
                  }
                  .width(this.largeFontEnabled ? 48 : 44)
                  .height(this.largeFontEnabled ? 48 : 44)
                  .linearGradient(this.highContrastEnabled ? undefined : {
                    angle: 135,
                    colors: [[0xbfdbfe, 0.0], [0x93c5fd, 1.0]]
                  })
                  .backgroundColor(this.highContrastEnabled ? '#ffff00' : undefined)
                  .borderRadius(14)
                  .border(this.highContrastEnabled ? { width: 2, color: '#000000' } : undefined)
                  .justifyContent(FlexAlign.Center)

                  Text('\u6c42\u52a9\u7ba1\u7406')
                    .fontSize(this.largeFontEnabled ? 18 : 15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.highContrastEnabled ? '#000000' : '#1e293b')
                }
                .width('100%')
                .justifyContent(FlexAlign.Start)
              }
              .width('100%')
              .height(this.largeFontEnabled ? 72 : 64)
              .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
              .borderRadius(14)
              .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : { width: 1, color: '#f1f5f9' })
              .shadow(this.highContrastEnabled ? undefined : {
                radius: 10,
                color: '#5b21b610',
                offsetX: 0,
                offsetY: 3
              })
              .padding({ left: 16, right: 16 })
              .onClick(() => {
                this.navigateToPage('pages/community/ManagePage');
              })

              Button() {
                Row({ space: 14 }) {
                  Row() {
                    Text('📈')
                      .fontSize(this.largeFontEnabled ? 24 : 20)
                  }
                  .width(this.largeFontEnabled ? 48 : 44)
                  .height(this.largeFontEnabled ? 48 : 44)
                  .linearGradient(this.highContrastEnabled ? undefined : {
                    angle: 135,
                    colors: [[0xe9d5ff, 0.0], [0xc4b5fd, 1.0]]
                  })
                  .backgroundColor(this.highContrastEnabled ? '#ffff00' : undefined)
                  .borderRadius(14)
                  .border(this.highContrastEnabled ? { width: 2, color: '#000000' } : undefined)
                  .justifyContent(FlexAlign.Center)

                  Text('\u6570\u636e\u7edf\u8ba1')
                    .fontSize(this.largeFontEnabled ? 18 : 15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.highContrastEnabled ? '#000000' : '#1e293b')
                }
                .width('100%')
                .justifyContent(FlexAlign.Start)
              }
              .width('100%')
              .height(this.largeFontEnabled ? 72 : 64)
              .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
              .borderRadius(14)
              .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : { width: 1, color: '#f1f5f9' })
              .shadow(this.highContrastEnabled ? undefined : {
                radius: 10,
                color: '#5b21b610',
                offsetX: 0,
                offsetY: 3
              })
              .padding({ left: 16, right: 16 })
              .onClick(() => {
                this.navigateToPage('pages/community/StatisticsPage');
              })
            }
          }

          Column({ space: 12 }) {
            Row() {
              Text('\u6700\u8fd1\u6d3b\u52a8')
                .fontSize(this.largeFontEnabled ? 20 : 16)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.highContrastEnabled ? '#000000' : '#0f172a')

              Blank()

              Button('\u67e5\u770b\u5168\u90e8')
                .fontSize(this.largeFontEnabled ? 15 : 12)
                .fontColor(this.highContrastEnabled ? '#000000' : '#6d28d9')
                .fontWeight(FontWeight.Medium)
                .backgroundColor(Color.Transparent)
                .onClick(() => {
                  this.navigateToPage('pages/community/ManagePage');
                })
            }
            .width('100%')

            Column() {
              if (this.pendingRequests.length === 0) {
                Text('\u6682\u65e0\u6700\u8fd1\u6d3b\u52a8')
                  .fontSize(this.largeFontEnabled ? 17 : 14)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#94a3b8')
                  .padding(24)
                  .width('100%')
                  .textAlign(TextAlign.Center)
              } else {
                ForEach(this.pendingRequests, (request: PendingRequestView, index: number) => {
                  this.PendingRequestItem(request, index === this.pendingRequests.length - 1)
                }, (request: PendingRequestView) => request.id)
              }
            }
            .width('100%')
            .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
            .borderRadius(14)
            .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : { width: 1, color: '#f1f5f9' })
            .shadow(this.highContrastEnabled ? undefined : {
              radius: 12,
              color: '#5b21b612',
              offsetX: 0,
              offsetY: 4
            })
            .clip(true)
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 24 })
      }
      .layoutWeight(1)
      .backgroundColor(this.highContrastEnabled ? '#ffffff' : '#f1f5f9')

      // 底部导航栏（保留三 Tab 与跳转逻辑，仅微调配色与顶边）
      Row() {
        Column({ space: 4 }) {
          Text('🏠')
            .fontSize(this.largeFontEnabled ? 26 : 22)
          Text('\u9996\u9875')
            .fontSize(this.largeFontEnabled ? 14 : 11)
            .fontColor(this.highContrastEnabled ? '#000000' : '#6d28d9')
            .fontWeight(FontWeight.Medium)
        }
        .layoutWeight(1)
        .onClick(() => {
          // 当前页面，不需要跳转
        })

        Column({ space: 4 }) {
          Text('👥')
            .fontSize(this.largeFontEnabled ? 26 : 22)
          Text('\u5fd7\u613f\u8005')
            .fontSize(this.largeFontEnabled ? 14 : 11)
            .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
        }
        .layoutWeight(1)
        .onClick(() => {
          this.navigateToPage('pages/community/VolunteerManagementPage');
        })

        Column({ space: 4 }) {
          Text('👤')
            .fontSize(this.largeFontEnabled ? 26 : 22)
          Text('\u6211\u7684')
            .fontSize(this.largeFontEnabled ? 14 : 11)
            .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
        }
        .layoutWeight(1)
        .onClick(() => {
          this.navigateToPage('pages/community/ProfilePage');
        })
      }
      .width('100%')
      .height(this.largeFontEnabled ? 80 : 70)
      .padding({ top: 4 })
      .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
      .border(this.highContrastEnabled ?
        { width: { top: 3 }, color: '#000000' } :
        { width: { top: 1 }, color: '#e2e8f0' }
      )
      .shadow(this.highContrastEnabled ? undefined : {
        radius: 12,
        color: '#0f172a0f',
        offsetX: 0,
        offsetY: -3
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.highContrastEnabled ? '#ffffff' : '#f1f5f9')
  }
}


