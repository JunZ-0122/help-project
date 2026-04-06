import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { CommunityApi, GetAvailableVolunteersOptions, RequestApi } from '../../services/ApiService';
import type { HelpRequest, VolunteerInfo } from '../../models';

interface VolunteerItem {
  id: string;
  name: string;
  phone: string;
  completedOrders: number;
  rating: number;
  avatar: string;
  location: string;
  distanceKm?: number;
}

/** 设为 false 可关闭：仅用真实接口数据 */
const MOCK_ASSIGN_PREVIEW: boolean = false;

@Entry
@Component
struct AssignPage {
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  @State requestId: string = '';
  @State selectedVolunteer: string = '';
  @State isAssigning: boolean = false;
  @State isLoading: boolean = true;
  @State requestTitle: string = '';
  @State requestLocation: string = '';
  @State requestDescription: string = '';
  @State volunteers: VolunteerItem[] = [];
  /** 当前列表是否含预览志愿者（仅界面演示，提交时需拦截） */
  @State previewVolunteersInjected: boolean = false;

  aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    if (params && params['id']) {
      this.requestId = params['id'] as string;
    }
    this.loadAssignData();
  }

  private isPlaceholderText(value: string): boolean {
    const t = value.trim();
    if (t.length === 0) {
      return true;
    }
    return /^[\s\?]+$/.test(t);
  }

  private getMockVolunteers(): VolunteerItem[] {
    return [
      {
        id: 'mock-v1',
        name: '\u738b\u5fd7\u8fdc',
        phone: '138****1201',
        completedOrders: 28,
        rating: 4.9,
        avatar: '\u738b',
        location: '\u9633\u5149\u5c0f\u533a\u9644\u8fd1',
        distanceKm: 1.2
      },
      {
        id: 'mock-v2',
        name: '\u674e\u6653\u9716',
        phone: '139****8830',
        completedOrders: 15,
        rating: 4.7,
        avatar: '\u674e',
        location: '\u548c\u5e73\u8def\u793e\u533a\u670d\u52a1\u4e2d\u5fc3',
        distanceKm: 2.6
      },
      {
        id: 'mock-v3',
        name: '\u9648\u96e8',
        phone: '136****5566',
        completedOrders: 42,
        rating: 5.0,
        avatar: '\u9648',
        location: '\u57ce\u4e1c\u8857\u9053',
        distanceKm: 3.1
      }
    ];
  }

  /** 接口无数据或占位符时填充示例，便于看版式 */
  private applyMockPreviewIfNeeded(): void {
    if (!MOCK_ASSIGN_PREVIEW) {
      return;
    }
    this.previewVolunteersInjected = false;
    if (this.isPlaceholderText(this.requestTitle)) {
      this.requestTitle = '\u533b\u8d2d\u534f\u52a9\u00b7\u966a\u540c\u5c31\u533b';
    }
    if (this.isPlaceholderText(this.requestDescription)) {
      this.requestDescription =
        '\u9700\u8981\u534f\u52a9\u6302\u53f7\u3001\u53d6\u836f\uff0c\u9884\u8ba1\u4e0a\u5348 2 \u5c0f\u65f6\u3002\u8001\u4eba\u884c\u52a8\u8f83\u6162\uff0c\u5e0c\u671b\u5fd7\u613f\u8005\u63d0\u524d 10 \u5206\u949f\u5230\u8fbe\u3002';
    }
    if (this.isPlaceholderText(this.requestLocation)) {
      this.requestLocation = '\u9633\u5149\u5c0f\u533a 3 \u680b 1 \u5355\u5143';
    }
    if (this.volunteers.length === 0) {
      this.volunteers = this.getMockVolunteers();
      this.previewVolunteersInjected = true;
    }
  }

  private async loadAssignData(): Promise<void> {
    if (!this.requestId) {
      this.isLoading = false;
      if (MOCK_ASSIGN_PREVIEW) {
        this.applyMockPreviewIfNeeded();
      }
      return;
    }

    this.isLoading = true;

    try {
      const request: HelpRequest = await RequestApi.getRequestDetail(this.requestId);
      const opts: GetAvailableVolunteersOptions = { requestId: this.requestId };
      const volunteers: VolunteerInfo[] = await CommunityApi.getAvailableVolunteers(opts);

      this.requestTitle = request.title ? request.title : this.getTypeLabel(request.type);
      this.requestLocation = request.location;
      this.requestDescription = request.description;
      this.selectedVolunteer = request.volunteerId ? request.volunteerId : '';
      this.volunteers = volunteers.map((volunteer: VolunteerInfo) => this.mapVolunteer(volunteer));
      this.applyMockPreviewIfNeeded();
    } catch (err) {
      const error = err as Error;
      console.error('load assign data failed:', error);
      promptAction.showToast({
        message: error.message ? error.message : '\u52a0\u8f7d\u5206\u914d\u6570\u636e\u5931\u8d25',
        duration: 1500
      });
      if (MOCK_ASSIGN_PREVIEW) {
        this.applyMockPreviewIfNeeded();
      }
    } finally {
      this.isLoading = false;
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

  private mapVolunteer(volunteer: VolunteerInfo): VolunteerItem {
    const item: VolunteerItem = {
      id: volunteer.id,
      name: volunteer.name,
      phone: volunteer.phone,
      completedOrders: volunteer.completedOrders,
      rating: volunteer.rating,
      avatar: volunteer.avatar ? volunteer.avatar : 'V',
      location: volunteer.location ? volunteer.location : '\u6682\u65e0\u5730\u5740'
    };
    if (volunteer.distance !== undefined && volunteer.distance !== null) {
      item.distanceKm = volunteer.distance;
    }
    return item;
  }

  goBack() {
    router.back();
  }

  handleAssign() {
    if (!this.selectedVolunteer || this.isAssigning) {
      promptAction.showToast({
        message: '\u8bf7\u9009\u62e9\u5fd7\u613f\u8005',
        duration: 1500
      });
      return;
    }

    if (this.previewVolunteersInjected && this.selectedVolunteer.indexOf('mock-') === 0) {
      promptAction.showToast({
        message: '\u9884\u89c8\u6570\u636e\u4ec5\u7528\u4e8e\u754c\u9762\u6f14\u793a\uff0c\u8bf7\u5173\u95ed MOCK_ASSIGN_PREVIEW \u540e\u4f7f\u7528\u771f\u5b9e\u63a5\u53e3',
        duration: 2500
      });
      return;
    }

    if (!this.requestId) {
      promptAction.showToast({
        message: '\u7f3a\u5c11\u6c42\u52a9\u5355\u6807\u8bc6',
        duration: 1500
      });
      return;
    }

    this.isAssigning = true;

    CommunityApi.assignVolunteer(this.requestId, this.selectedVolunteer).then(() => {
      promptAction.showToast({
        message: '\u5206\u914d\u6210\u529f',
        duration: 1500
      });
      router.back();
    }).catch((err: Error) => {
      console.error('assign volunteer failed:', err);
      promptAction.showToast({
        message: err.message ? err.message : '\u5206\u914d\u5931\u8d25',
        duration: 1500
      });
    }).finally(() => {
      this.isAssigning = false;
    });
  }

  @Builder
  VolunteerCard(volunteer: VolunteerItem) {
    Column() {
      Row({ space: 12 }) {
        Row() {
          Text(volunteer.avatar)
            .fontSize(this.largeFontEnabled ? 24 : 18)
            .fontColor(this.highContrastEnabled ? '#000000' : '#ffffff')
            .fontWeight(FontWeight.Bold)
        }
        .width(this.largeFontEnabled ? 70 : 56)
        .height(this.largeFontEnabled ? 70 : 56)
        .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#3b82f6')
        .borderRadius(this.largeFontEnabled ? 35 : 28)
        .justifyContent(FlexAlign.Center)
        .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)

        Column({ space: 4 }) {
          Text(volunteer.name)
            .fontSize(this.largeFontEnabled ? 20 : 16)
            .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
            .fontWeight(FontWeight.Medium)

          Text(volunteer.phone)
            .fontSize(this.largeFontEnabled ? 15 : 12)
            .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')

          Text(`\u5df2\u5b8c\u6210 ${volunteer.completedOrders} \u5355 / \u8bc4\u5206 ${volunteer.rating}`)
            .fontSize(this.largeFontEnabled ? 15 : 12)
            .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')

          Text(volunteer.location)
            .fontSize(this.largeFontEnabled ? 15 : 12)
            .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          if (volunteer.distanceKm !== undefined && volunteer.distanceKm !== null) {
            Text(`\u8ddd\u79bb ${volunteer.distanceKm.toFixed(1)} km`)
              .fontSize(this.largeFontEnabled ? 15 : 12)
              .fontColor(this.highContrastEnabled ? '#000000' : '#059669')
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        if (this.selectedVolunteer === volunteer.id) {
          Row() {
            Text('已选')
              .fontSize(this.largeFontEnabled ? 13 : 11)
              .fontColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
              .fontWeight(FontWeight.Bold)
          }
          .padding({
            left: this.largeFontEnabled ? 10 : 8,
            right: this.largeFontEnabled ? 10 : 8,
            top: this.largeFontEnabled ? 6 : 4,
            bottom: this.largeFontEnabled ? 6 : 4
          })
          .backgroundColor(this.highContrastEnabled ? '#000000' : '#2563eb')
          .borderRadius(999)
          .justifyContent(FlexAlign.Center)
        }
      }
      .width('100%')
      .padding({
        left: this.largeFontEnabled ? 20 : 16,
        right: this.largeFontEnabled ? 20 : 16,
        top: this.largeFontEnabled ? 16 : 12,
        bottom: this.largeFontEnabled ? 16 : 12
      })
    }
    .width('100%')
    .backgroundColor(this.highContrastEnabled ? '#ffff00'
      : (this.selectedVolunteer === volunteer.id ? '#f0f7ff' : '#ffffff'))
    .borderRadius(14)
    .border({
      width: this.highContrastEnabled ? 3 : (this.selectedVolunteer === volunteer.id ? 2 : 1),
      color: this.highContrastEnabled ? '#000000'
        : (this.selectedVolunteer === volunteer.id ? '#3b82f6' : '#e5e7eb')
    })
    .shadow(this.highContrastEnabled ? undefined : {
      radius: this.selectedVolunteer === volunteer.id ? 10 : 6,
      color: this.selectedVolunteer === volunteer.id ? '#3b82f61f' : '#0f172a0a',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      this.selectedVolunteer = volunteer.id;
    })
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        NavBackButton()

        Text('\u5206\u914d\u5fd7\u613f\u8005')
          .fontSize(this.largeFontEnabled ? 22.5 : 18)
          .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank()
          .width(this.largeFontEnabled ? 44 : 40)
      }
      .width('100%')
      .padding(this.largeFontEnabled ? 20 : 16)
      .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
      .border({
        width: { bottom: this.highContrastEnabled ? 3 : 1 },
        color: this.highContrastEnabled ? '#000000' : '#e5e7eb'
      })

      if (this.isLoading) {
        Column({ space: 12 }) {
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
        Column({ space: 12 }) {
          Column({ space: 12 }) {
            Row({ space: 8 }) {
              Text('\u6c42\u52a9\u4fe1\u606f')
                .fontSize(this.largeFontEnabled ? 20 : 16)
                .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
                .fontWeight(FontWeight.Bold)

              Text('\u5f85\u5206\u914d')
                .fontSize(this.largeFontEnabled ? 12 : 10)
                .fontColor(this.highContrastEnabled ? '#000000' : '#b45309')
                .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                .backgroundColor(this.highContrastEnabled ? '#ffffff' : '#fef3c7')
                .borderRadius(999)
            }
            .alignItems(VerticalAlign.Center)

            Text(this.requestTitle)
              .fontSize(this.largeFontEnabled ? 18.75 : 15)
              .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
              .fontWeight(FontWeight.Medium)

            Text(this.requestDescription)
              .fontSize(this.largeFontEnabled ? 17.5 : 14)
              .fontColor(this.highContrastEnabled ? '#000000' : '#374151')
              .lineHeight(this.largeFontEnabled ? 28 : 22)

            Text(`\u5730\u70b9\uff1a${this.requestLocation}`)
              .fontSize(this.largeFontEnabled ? 15 : 12)
              .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
          }
          .width('100%')
          .padding(this.largeFontEnabled ? 20 : 16)
          .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
          .borderRadius(16)
          .border(this.highContrastEnabled
            ? { width: 3, color: '#000000' }
            : { width: 1, color: '#e5e7eb' })
          .shadow(this.highContrastEnabled ? undefined : {
            radius: 8,
            color: '#0f172a0a',
            offsetX: 0,
            offsetY: 2
          })
          .alignItems(HorizontalAlign.Start)

          Row() {
            Text('\u53ef\u7528\u5fd7\u613f\u8005')
              .fontSize(this.largeFontEnabled ? 20 : 16)
              .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1)

            Text(this.volunteers.length === 0
              ? '\u5171 0 \u4eba'
              : `\u5df2\u9009 ${this.selectedVolunteer ? 1 : 0}/${this.volunteers.length} \u4eba`)
              .fontSize(this.largeFontEnabled ? 14 : 12)
              .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .backgroundColor(this.highContrastEnabled ? '#ffffff' : '#f1f5f9')
              .borderRadius(999)
              .border(this.highContrastEnabled ? { width: 1, color: '#000000' } : undefined)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          if (this.volunteers.length === 0) {
            Row() {
              Text('\u6682\u65e0\u53ef\u5206\u914d\u5fd7\u613f\u8005')
                .fontSize(this.largeFontEnabled ? 17.5 : 14)
                .fontColor(this.highContrastEnabled ? '#000000' : '#9ca3af')
            }
            .width('100%')
            .padding(this.largeFontEnabled ? 20 : 16)
            .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
            .borderRadius(12)
            .border(this.highContrastEnabled
              ? { width: 3, color: '#000000' }
              : { width: 1, color: '#e5e7eb' })
          } else {
            Scroll() {
              Column({ space: 12 }) {
                ForEach(this.volunteers, (volunteer: VolunteerItem) => {
                  this.VolunteerCard(volunteer)
                })
              }
              .width('100%')
            }
            .layoutWeight(1)
            .scrollBar(BarState.Off)
          }
        }
        .width('100%')
        .layoutWeight(1)
        .padding({
          left: this.largeFontEnabled ? 20 : 16,
          right: this.largeFontEnabled ? 20 : 16,
          top: this.largeFontEnabled ? 10 : 8,
          bottom: this.largeFontEnabled ? 20 : 16
        })
        .backgroundColor(this.highContrastEnabled ? '#ffffff' : '#f3f4f6')

        Column() {
          Button(this.isAssigning ? '\u5206\u914d\u4e2d...' : '\u786e\u8ba4\u5206\u914d')
            .width('100%')
            .height(this.largeFontEnabled ? 70 : 56)
            .backgroundColor(this.highContrastEnabled
              ? '#000000'
              : (!this.selectedVolunteer || this.isAssigning ? '#d1d5db' : '#10b981'))
            .fontColor('#ffffff')
            .fontSize(this.largeFontEnabled ? 22.5 : 18)
            .fontWeight(FontWeight.Bold)
            .borderRadius(16)
            .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
            .enabled(!!this.selectedVolunteer && !this.isAssigning)
            .onClick(() => {
              this.handleAssign();
            })
        }
        .width('100%')
        .padding({
          left: this.largeFontEnabled ? 20 : 16,
          right: this.largeFontEnabled ? 20 : 16,
          top: this.largeFontEnabled ? 14 : 10,
          bottom: this.largeFontEnabled ? 16 : 12
        })
        .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
        .border({
          width: { top: this.highContrastEnabled ? 3 : 1 },
          color: this.highContrastEnabled ? '#000000' : '#e5e7eb'
        })
      }
    }
    .width('100%')
    .height('100%')
  }
}


