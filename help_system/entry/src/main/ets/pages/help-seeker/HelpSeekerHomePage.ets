import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { RequestApi } from '../../services/ApiService';
import { SeekerPersonalCenterPane } from './SeekerPersonalCenterPane';
import { DateUtil } from '../../utils/DateUtil';
import { StorageUtil } from '../../utils/StorageUtil';
import { ElderHighContrastTheme } from '../../utils/AccessibilityTheme';
import type { HelpRequest, UserProfile } from '../../models';

/** 与 ArkUI TouchType 枚举取值一致（当前 SDK 未从 @kit.ArkUI 导出 TouchType） */
const TOUCH_DOWN = 0;
const TOUCH_UP = 1;
const TOUCH_CANCEL = 3;

interface CategoryAction {
  id: string;
  title: string;
  path: string;
  requestType: string;
  iconText: string;
  iconBg: string;
}

interface RecentRequest {
  id: string;
  title: string;
  status: string;
  time: string;
  statusColor: string;
}

interface MyRequestItem {
  id: string;
  title: string;
  description: string;
  type: string;
  statusKey: string;
  statusLabel: string;
  statusColor: string;
  createTime: string;
  updateTime: string;
  volunteerName?: string;
}

@Entry
@Component
struct HelpSeekerHomePage {
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  @State currentTabIndex: number = 0;
  /** 切换到「个人中心」Tab 时递增，驱动 SeekerPersonalCenterPane 刷新资料 */
  @State seekerCenterRefreshSig: number = 0;
  @State userName: string = '用户';
  @State locationDisplay: string = '';
  @State recentRequests: RecentRequest[] = [];
  @State isLoading: boolean = false;
  /** 长按紧急卡片进度 0–100，用于底部长条进度 */
  @State emergencyPressProgress: number = 0;
  private emergencyLongPressTimer: number = -1;
  private emergencyProgressInterval: number = -1;
  
  // 我的求助页面状态
  @State myRequests: MyRequestItem[] = [];
  @State isLoadingRequests: boolean = false;
  
  /** 设计稿「常用求助类型」：类型与后端 type 字段对应（出行协助→companion） */
  private categoryActions: CategoryAction[] = [
    { id: 'medical', title: '就医求助', path: 'pages/help-seeker/RequestTypePage', requestType: 'medical', iconText: '\u533b', iconBg: '#ef4444' },
    { id: 'travel', title: '出行协助', path: 'pages/help-seeker/RequestTypePage', requestType: 'companion', iconText: '\u884c', iconBg: '#3b82f6' },
    { id: 'life', title: '生活帮扶', path: 'pages/help-seeker/RequestTypePage', requestType: 'shopping', iconText: '\u5e2e', iconBg: '#10b981' },
    { id: 'other', title: '其他帮助', path: 'pages/help-seeker/RequestTypePage', requestType: 'other', iconText: '\u2026', iconBg: '#8b5cf6' }
  ];

  aboutToAppear() {
    this.loadHomeData();
  }

  aboutToDisappear() {
    this.clearEmergencyLongPressAll();
  }

  private clearEmergencyLongPressAll(): void {
    if (this.emergencyLongPressTimer !== -1) {
      clearTimeout(this.emergencyLongPressTimer);
      this.emergencyLongPressTimer = -1;
    }
    if (this.emergencyProgressInterval !== -1) {
      clearInterval(this.emergencyProgressInterval);
      this.emergencyProgressInterval = -1;
    }
    this.emergencyPressProgress = 0;
  }

  private onEmergencyCardTouch(event: TouchEvent): void {
    const t = event.type as number;
    if (t === TOUCH_DOWN) {
      this.clearEmergencyLongPressAll();
      this.emergencyPressProgress = 0;
      const STEP_MS = 30;
      const totalMs = 3000;
      const tickCount = Math.floor(totalMs / STEP_MS);
      const delta = 100 / tickCount;

      this.emergencyProgressInterval = setInterval(() => {
        this.emergencyPressProgress = Math.min(100, this.emergencyPressProgress + delta);
      }, STEP_MS);

      this.emergencyLongPressTimer = setTimeout(() => {
        if (this.emergencyProgressInterval !== -1) {
          clearInterval(this.emergencyProgressInterval);
          this.emergencyProgressInterval = -1;
        }
        this.emergencyLongPressTimer = -1;
        this.emergencyPressProgress = 100;
        router.pushUrl({ url: 'pages/help-seeker/EmergencyRequestPage' }).catch((err: Error) => {
          console.error('navigation failed:', err);
        });
        promptAction.showToast({ message: '\u5df2\u8fdb\u5165\u7d27\u6025\u6c42\u52a9', duration: 1500 });
        setTimeout(() => {
          this.emergencyPressProgress = 0;
        }, 400);
      }, totalMs);
    } else if (t === TOUCH_UP || t === TOUCH_CANCEL) {
      this.clearEmergencyLongPressAll();
    }
  }

  private navigateToCategory(action: CategoryAction): void {
    router.pushUrl({
      url: action.path,
      params: {
        type: action.requestType
      }
    }).catch((err: Error) => {
      console.error('navigation failed:', err);
    });
  }

  private showToast(message: string): void {
    promptAction.showToast({
      message: message,
      duration: 1500
    });
  }

  async loadHomeData() {
    this.isLoading = true;

    try {
      const userString: string = await StorageUtil.getString('user');
      if (userString) {
        const user: UserProfile = JSON.parse(userString) as UserProfile;
        if (user.name) {
          this.userName = user.name;
        }
        this.locationDisplay = user.address && user.address.length > 0
          ? user.address
          : '\u672a\u8bbe\u7f6e\u5730\u5740\uff0c\u53ef\u5728\u4e2a\u4eba\u4e2d\u5fc3\u8865\u5145';
      } else {
        this.locationDisplay = '\u672a\u767b\u5f55\u6216\u6682\u65e0\u5730\u5740';
      }

      try {
        const recentList: HelpRequest[] = await RequestApi.getRecentMyRequests(3);
        this.recentRequests = recentList.map((request: HelpRequest) => this.mapRecentRequest(request));
      } catch (recentErr) {
        console.warn('getRecentMyRequests failed, fallback to paged list', recentErr);
        const response = await RequestApi.getMyRequests(1, 3);
        this.recentRequests = response.items.map((request: HelpRequest) => this.mapRecentRequest(request));
      }
    } catch (err) {
      console.error('load home data failed:', err);
    } finally {
      this.isLoading = false;
    }
  }

  async loadMyRequests() {
    if (this.myRequests.length > 0) {
      return; // 已加载过
    }

    this.isLoadingRequests = true;
    try {
      const response = await RequestApi.getMyRequests(1, 50);
      this.myRequests = response.items.map((request: HelpRequest) => this.mapMyRequest(request));
    } catch (err) {
      console.error('load my requests failed:', err);
    } finally {
      this.isLoadingRequests = false;
    }
  }

  private mapMyRequest(request: HelpRequest): MyRequestItem {
    const updatedSource: string = request.updatedAt ? request.updatedAt : request.createdAt;
    return {
      id: request.id,
      title: request.title ? request.title : this.getRequestTypeLabel(request.type),
      description: request.description,
      type: request.type,
      statusKey: request.status,
      statusLabel: this.getStatusLabel(request.status),
      statusColor: this.getStatusColor(request.status),
      createTime: DateUtil.format(request.createdAt, 'YYYY-MM-DD HH:mm'),
      updateTime: DateUtil.getRelativeTime(updatedSource),
      volunteerName: request.volunteerName
    };
  }

  private mapRecentRequest(request: HelpRequest): RecentRequest {
    const title: string = request.title ? request.title : this.getRequestTypeLabel(request.type);
    const timeSource: string = request.updatedAt ? request.updatedAt : request.createdAt;

    return {
      id: request.id,
      title: title,
      status: this.getStatusLabel(request.status),
      time: DateUtil.getRelativeTime(timeSource),
      statusColor: this.getStatusColor(request.status)
    };
  }

  private getRequestTypeLabel(type: string): string {
    switch (type) {
      case 'medical':
        return '\u5c31\u533b\u6c42\u52a9';
      case 'shopping':
        return '\u751f\u6d3b\u5e2e\u6276';
      case 'repair':
        return '\u7ef4\u4fee\u5e2e\u52a9';
      case 'companion':
        return '\u51fa\u884c\u534f\u52a9';
      case 'emergency':
        return '\u7d27\u6025\u6c42\u52a9';
      default:
        return '\u5176\u4ed6\u5e2e\u52a9';
    }
  }

  private getStatusLabel(status: string): string {
    switch (status) {
      case 'pending':
        return '等待中';
      case 'assigned':
        return '已分配';
      case 'in-progress':
        return '进行中';
      case 'completed':
        return '已完成';
      case 'cancelled':
        return '已取消';
      default:
        return '处理中';
    }
  }

  private getStatusColor(status: string): string {
    switch (status) {
      case 'pending':
        return '#6b7280';
      case 'assigned':
        return '#3b82f6';
      case 'in-progress':
        return '#f59e0b';
      case 'completed':
        return '#10b981';
      case 'cancelled':
        return '#ef4444';
      default:
        return '#3b82f6';
    }
  }

  navigateToPage(path: string) {
    router.pushUrl({
      url: path
    }).catch((err: Error) => {
      console.error('navigation failed:', err);
    });
  }

  @Builder
  CategoryGridCard(action: CategoryAction) {
    Button() {
      Column({ space: 14 }) {
        Row() {
          Text(action.iconText)
            .fontSize(this.largeFontEnabled ? 22 : 18)
            .fontColor('#ffffff')
            .fontWeight(FontWeight.Bold)
        }
        .width(48)
        .height(48)
        .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.avatarBg : action.iconBg)
        .borderRadius(12)
        .justifyContent(FlexAlign.Center)
        .border(this.highContrastEnabled ? { width: 2, color: ElderHighContrastTheme.borderStrong } : undefined)

        Text(action.title)
          .fontSize(this.largeFontEnabled ? 16 : 13)
          .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#1a1a1a')
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .padding(12)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.surface : '#ffffff')
    .borderRadius(16)
    .shadow(this.highContrastEnabled ? undefined : {
      radius: 8,
      color: '#0f000014',
      offsetX: 0,
      offsetY: 3
    })
    .border(this.highContrastEnabled ? ElderHighContrastTheme.cardBorder() : undefined)
    .onClick(() => {
      this.navigateToCategory(action);
    })
  }

  @Builder
  EmergencyLongPressCard() {
    Column({ space: 0 }) {
      Column({ space: 14 }) {
        Row() {
          Text('!')
            .fontSize(this.largeFontEnabled ? 36 : 30)
            .fontColor('#ef4444')
            .fontWeight(FontWeight.Bold)
        }
        .width(this.largeFontEnabled ? 72 : 64)
        .height(this.largeFontEnabled ? 72 : 64)
        .backgroundColor('#ffffff')
        .borderRadius(200)
        .justifyContent(FlexAlign.Center)

        Text('\u4e00\u952e\u7d27\u6025\u6c42\u52a9')
          .fontSize(this.largeFontEnabled ? 22 : 18)
          .fontColor('#ffffff')
          .fontWeight(FontWeight.Bold)

        Text('\u957f\u6309 3 \u79d2\u89e6\u53d1')
          .fontSize(this.largeFontEnabled ? 16 : 13)
          .fontColor('#fecaca')

        Text('\u7ee7\u7eed\u6309\u4f4f...')
          .fontSize(this.largeFontEnabled ? 14 : 12)
          .fontColor('#fde68a')
          .visibility(this.emergencyPressProgress > 0 && this.emergencyPressProgress < 100
            ? Visibility.Visible
            : Visibility.None)
      }
      .width('100%')
      .padding({ top: 24, left: 20, right: 20, bottom: 12 })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Stack({ alignContent: Alignment.Start }) {
        Row()
          .width('100%')
          .height(6)
          .backgroundColor(this.highContrastEnabled ? '#444444' : '#991b1b')

        Row()
          .width(`${this.emergencyPressProgress}%`)
          .height(6)
          .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.surface : '#ffffff')
      }
      .width('100%')
      .height(6)
    }
    .width('100%')
    .clip(true)
    .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.accentDanger : '#ef4444')
    .borderRadius(20)
    .border(this.highContrastEnabled ? { width: 3, color: ElderHighContrastTheme.borderStrong } : undefined)
    .shadow(this.highContrastEnabled ? undefined : {
      radius: 16,
      color: '#ef444440',
      offsetX: 0,
      offsetY: 8
    })
    .onTouch((event: TouchEvent) => {
      this.onEmergencyCardTouch(event);
    })
  }

  @Builder
  RequestItem(request: RecentRequest) {
    Row({ space: 12 }) {
      Column({ space: 4 }) {
        Text(request.title)
          .fontSize(this.largeFontEnabled ? 18 : 14)
          .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#1a1a1a')
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(request.time)
          .fontSize(this.largeFontEnabled ? 15 : 12)
          .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#9ca3af')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(request.status)
        .fontSize(this.largeFontEnabled ? 15 : 12)
        .fontColor('#ffffff')
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : request.statusColor)
        .borderRadius(8)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.surface : '#ffffff')
    .borderRadius(12)
    .border(this.highContrastEnabled ? ElderHighContrastTheme.cardBorder() : undefined)
    .onClick(() => {
      router.pushUrl({
        url: 'pages/help-seeker/RequestDetailPage',
        params: {
          id: request.id
        }
      }).catch((err: Error) => {
        console.error('navigation failed:', err);
      });
    })
  }

  @Builder
  MyRequestCard(request: MyRequestItem) {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        Text(request.statusLabel)
          .fontSize(this.largeFontEnabled ? 15 : 12)
          .fontColor('#ffffff')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : request.statusColor)
          .borderRadius(8)

        Blank()

        Text(request.updateTime)
          .fontSize(this.largeFontEnabled ? 15 : 12)
          .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#9ca3af')
      }

      Text(request.title)
        .fontSize(this.largeFontEnabled ? 20 : 16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#1a1a1a')
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(request.description)
        .fontSize(this.largeFontEnabled ? 17.5 : 14)
        .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textSecondary : '#6b7280')
        .width('100%')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      if (request.volunteerName) {
        Text('志愿者：' + request.volunteerName)
          .fontSize(this.largeFontEnabled ? 15 : 12)
          .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.accentBlue : '#2563eb')
          .width('100%')
      }

      Button('查看详情')
        .width('100%')
        .height(this.largeFontEnabled ? 48 : 40)
        .fontSize(this.largeFontEnabled ? 17.5 : 14)
        .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.accentBlue : '#3b82f6')
        .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.tagBg : '#eff6ff')
        .borderRadius(8)
        .border(this.highContrastEnabled ? ElderHighContrastTheme.cardBorder() : undefined)
        .onClick(() => {
          router.pushUrl({
            url: 'pages/help-seeker/RequestDetailPage',
            params: {
              id: request.id
            }
          }).catch((err: Error) => {
            console.error('navigation failed:', err);
          });
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.surface : '#ffffff')
    .borderRadius(12)
    .border(this.highContrastEnabled ? ElderHighContrastTheme.cardBorder() : undefined)
  }

  @Builder
  HomeTabContent() {
    Column() {
      Column({ space: 10 }) {
        Text('\u60a8\u597d\uff0c' + this.userName)
          .fontSize(this.largeFontEnabled ? 26 : 22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#ffffff')
          .width('100%')

        Row({ space: 8 }) {
          Text('\uD83D\uDCCD')
            .fontSize(this.largeFontEnabled ? 17 : 14)
          Text('\u5f53\u524d\u4f4d\u7f6e\uff1a' + this.locationDisplay)
            .fontSize(this.largeFontEnabled ? 16 : 13)
            .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#e0e7ff')
            .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 28, bottom: 24 })
      .borderRadius({ bottomLeft: 24, bottomRight: 24 })
      .linearGradient({
        angle: 135,
        colors: this.highContrastEnabled
          ? [[0xf2ebe0, 0.0], [0xe8dcc8, 1.0]]
          : [[0x4f46e5, 0.0], [0x3b82f6, 0.45], [0xa78bfa, 1.0]]
      })

      Scroll() {
        Column({ space: 20 }) {
          Column({ space: 8 }) {
            this.EmergencyLongPressCard()
          }
          .width('100%')
          .margin({ top: -6 })

          Column({ space: 14 }) {
            Text('\u5e38\u7528\u6c42\u52a9\u7c7b\u578b')
              .fontSize(this.largeFontEnabled ? 20 : 16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#1a1a1a')
              .alignSelf(ItemAlign.Start)

            Grid() {
              ForEach(this.categoryActions, (action: CategoryAction) => {
                GridItem() {
                  this.CategoryGridCard(action)
                }
              })
            }
            .columnsTemplate('1fr 1fr')
            .rowsTemplate('1fr 1fr')
            .columnsGap(12)
            .rowsGap(12)
            .width('100%')
            .height(this.largeFontEnabled ? 220 : 200)
          }
          .width('100%')

          Column({ space: 16 }) {
            Row() {
              Text('\u6700\u8fd1\u6c42\u52a9')
                .fontSize(this.largeFontEnabled ? 20 : 16)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#1a1a1a')

              Blank()

              Button('\u67e5\u770b\u5168\u90e8')
                .fontSize(this.largeFontEnabled ? 16 : 13)
                .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.accentBlue : '#3b82f6')
                .backgroundColor(Color.Transparent)
                .onClick(() => {
                  this.currentTabIndex = 1;
                })
            }
            .width('100%')

            Column({ space: 12 }) {
              if (this.isLoading) {
                Text('\u52a0\u8f7d\u4e2d...')
                  .fontSize(this.largeFontEnabled ? 16 : 13)
                  .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textSecondary : '#6b7280')
              } else if (this.recentRequests.length === 0) {
                Column({ space: 8 }) {
                  Text('\u2630')
                    .fontSize(36)
                    .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#9ca3af')
                  Text('\u6682\u65e0\u6c42\u52a9\u8bb0\u5f55')
                    .fontSize(this.largeFontEnabled ? 16 : 13)
                    .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textSecondary : '#6b7280')
                }
                .padding({ top: 12, bottom: 12 })
              } else {
                ForEach(this.recentRequests, (request: RecentRequest) => {
                  this.RequestItem(request)
                })
              }
            }
          }
          .width('100%')

          Row()
            .height(72)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 8 })
      }
      .layoutWeight(1)
      .align(Alignment.TopStart)
      .scrollBar(BarState.Off)
      .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.pageBg : '#f9fafb')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.pageBg : '#f3f4f6')
  }

  build() {
    Tabs({ index: this.currentTabIndex }) {
      TabContent() {
        this.HomeTabContent()
      }
      .tabBar(this.TabBuilder(0, '首页', '🏠'))

      TabContent() {
        Column() {
          Row({ space: 16 }) {
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
                this.navigateToPage('pages/help-seeker/RequestTypePage');
              })
          }
          .width('100%')
          .padding(16)
          .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.surface : '#ffffff')

          if (this.isLoadingRequests) {
            Column({ space: 16 }) {
              LoadingProgress()
                .width(32)
                .height(32)
              Text('正在加载求助记录...')
                .fontSize(this.largeFontEnabled ? 20 : 16)
                .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textSecondary : '#6b7280')
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.pageBg : '#f9fafb')
          } else if (this.myRequests.length > 0) {
            Scroll() {
              Column({ space: 12 }) {
                ForEach(this.myRequests, (request: MyRequestItem) => {
                  this.MyRequestCard(request)
                })
                Row().height(20)
              }
              .width('100%')
              .padding(16)
            }
            .layoutWeight(1)
            .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.pageBg : '#f9fafb')
          } else {
            Column({ space: 16 }) {
              Text('暂无求助记录')
                .fontSize(this.largeFontEnabled ? 20 : 16)
                .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textSecondary : '#6b7280')

              Button('发布新求助')
                .fontSize(this.largeFontEnabled ? 17.5 : 14)
                .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.accentBlue : '#3b82f6')
                .fontColor('#ffffff')
                .borderRadius(20)
                .border(this.highContrastEnabled ? ElderHighContrastTheme.cardBorder() : undefined)
                .onClick(() => {
                  this.navigateToPage('pages/help-seeker/RequestTypePage');
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
      }
      .tabBar(this.TabBuilder(1, '我的求助', '📋'))
      .onWillShow(() => {
        this.loadMyRequests();
      })

      TabContent() {
        Column() {
          Row({ space: 16 }) {
            Text('个人中心')
              .fontSize(this.largeFontEnabled ? 25 : 20)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#1a1a1a')
              .layoutWeight(1)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.surface : '#ffffff')

          SeekerPersonalCenterPane({ refreshSig: this.seekerCenterRefreshSig })
            .layoutWeight(1)
        }
        .width('100%')
        .height('100%')
      }
      .tabBar(this.TabBuilder(2, '\u4e2a\u4eba\u4e2d\u5fc3', '👤'))
    }
    .barPosition(BarPosition.End)
    .barMode(BarMode.Fixed)
    .barHeight(this.largeFontEnabled ? 70 : 56)
    .onChange((index: number) => {
      this.currentTabIndex = index;
      if (index === 2) {
        this.seekerCenterRefreshSig++;
      }
    })
    .width('100%')
    .height('100%')
    .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.pageBg : '#f9fafb')
  }

  @Builder
  TabBuilder(index: number, title: string, icon: string) {
    Column({ space: 4 }) {
      Text(icon)
        .fontSize(this.largeFontEnabled ? 28 : 24)

      Text(title)
        .fontSize(this.largeFontEnabled ? 13 : 10)
        .fontColor(this.currentTabIndex === index
          ? (this.highContrastEnabled ? ElderHighContrastTheme.accentBlue : '#3b82f6')
          : (this.highContrastEnabled ? ElderHighContrastTheme.textPrimary : '#9ca3af'))
        .fontWeight(this.currentTabIndex === index ? FontWeight.Medium : FontWeight.Normal)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.highContrastEnabled ? ElderHighContrastTheme.surface : '#ffffff')
    .border(this.highContrastEnabled ? ElderHighContrastTheme.cardBorder() : undefined)
  }
}
