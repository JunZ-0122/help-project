import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { DateUtil } from '../../utils/DateUtil';
import { CommunityApi } from '../../services/ApiService';
import type { DispatchScoredRequest, QuickDispatchPayload, VolunteerSkillTag } from '../../models';

@Entry
@Component
struct QuickDispatchPage {
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  @State volunteerId: string = '';
  @State payload: QuickDispatchPayload | null = null;
  @State selectedRequestId: string = '';
  @State isLoading: boolean = false;
  @State isSubmitting: boolean = false;

  aboutToAppear() {
    const p = router.getParams() as Record<string, Object>;
    const raw = p['volunteerId'];
    this.volunteerId = raw !== undefined && raw !== null ? String(raw) : '';
    this.loadRecommendations();
  }

  private async loadRecommendations(): Promise<void> {
    if (!this.volunteerId) {
      promptAction.showToast({ message: '\u7f3a\u5c11\u5fd7\u613f\u8005\u53c2\u6570', duration: 2000 });
      return;
    }
    this.isLoading = true;
    try {
      const data = await CommunityApi.getQuickDispatchRecommendations(this.volunteerId);
      this.payload = data;
      this.pickDefaultSelection(data);
    } catch (err) {
      const error = err as Error;
      promptAction.showToast({
        message: error.message ? error.message : '\u52a0\u8f7d\u5931\u8d25',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  private pickDefaultSelection(data: QuickDispatchPayload): void {
    const smart = data.smartMatches ? data.smartMatches : [];
    const other = data.otherPending ? data.otherPending : [];
    if (smart.length > 0) {
      this.selectedRequestId = smart[0].requestId;
    } else if (other.length > 0) {
      this.selectedRequestId = other[0].requestId;
    } else {
      this.selectedRequestId = '';
    }
  }

  private distanceText(item: DispatchScoredRequest): string {
    if (item.distanceKm === undefined || item.distanceKm === null) {
      return '\u8ddd\u79bb\u672a\u77e5';
    }
    const km = item.distanceKm;
    if (km < 1) {
      return `${Math.round(km * 1000)}\u7c73`;
    }
    return `${km.toFixed(1)}\u516c\u91cc`;
  }

  private async confirmDispatch(): Promise<void> {
    if (!this.selectedRequestId || !this.volunteerId) {
      promptAction.showToast({ message: '\u8bf7\u9009\u62e9\u6c42\u52a9\u5355', duration: 2000 });
      return;
    }
    this.isSubmitting = true;
    try {
      const ok = await CommunityApi.assignVolunteer(this.selectedRequestId, this.volunteerId);
      if (ok) {
        promptAction.showToast({ message: '\u6d3e\u5355\u6210\u529f', duration: 2000 });
        router.back();
      } else {
        promptAction.showToast({ message: '\u6d3e\u5355\u5931\u8d25', duration: 2000 });
      }
    } catch (err) {
      const error = err as Error;
      promptAction.showToast({
        message: error.message ? error.message : '\u6d3e\u5355\u5931\u8d25',
        duration: 2000
      });
    } finally {
      this.isSubmitting = false;
    }
  }

  @Builder
  MatchBar(score: number) {
    Row() {
      Row()
        .width(`${Math.min(100, Math.max(0, score))}%`)
        .height(this.largeFontEnabled ? 8 : 6)
        .linearGradient({
          angle: 90,
          colors: [[0x6d28d9, 0.0], [0xa78bfa, 1.0]]
        })
        .borderRadius(4)
    }
    .width('100%')
    .height(this.largeFontEnabled ? 8 : 6)
    .backgroundColor(this.highContrastEnabled ? '#e5e5e5' : '#f1f5f9')
    .borderRadius(4)
    .clip(true)
  }

  @Builder
  RequestCard(item: DispatchScoredRequest) {
    Column({ space: 10 }) {
      Row() {
        Text(item.typeLabel)
          .fontSize(this.largeFontEnabled ? 17 : 15)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.highContrastEnabled ? '#000000' : '#0f172a')
          .layoutWeight(1)
        if (item.emergency) {
          Text('\u7d27\u6025')
            .fontSize(this.largeFontEnabled ? 12 : 10)
            .fontColor('#ffffff')
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .backgroundColor('#ef4444')
            .borderRadius(6)
        }
        if (this.selectedRequestId === item.requestId) {
          Text('\u2713')
            .fontSize(this.largeFontEnabled ? 18 : 16)
            .fontColor('#7c3aed')
            .fontWeight(FontWeight.Bold)
            .margin({ left: 8 })
        }
      }
      .width('100%')

      Text(item.description)
        .fontSize(this.largeFontEnabled ? 14 : 12)
        .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Row({ space: 10 }) {
        Text(`\u{1F464} ${item.seekerName}`)
          .fontSize(this.largeFontEnabled ? 12 : 11)
          .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      Row({ space: 10 }) {
        Text(`\u{1F4CD} ${item.location}`)
          .fontSize(this.largeFontEnabled ? 12 : 11)
          .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      Row({ space: 10 }) {
        Text(`\u{1F553} ${DateUtil.getRelativeTime(item.createdAt)}`)
          .fontSize(this.largeFontEnabled ? 12 : 11)
          .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
      }
      .width('100%')

      Row() {
        Text('\u5339\u914d\u5ea6')
          .fontSize(this.largeFontEnabled ? 13 : 12)
          .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
        Blank()
        Text(`${item.matchScore}%`)
          .fontSize(this.largeFontEnabled ? 14 : 12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#7c3aed')
      }
      .width('100%')

      this.MatchBar(item.matchScore)

      Text(`\u{1F4CD} ${this.distanceText(item)}`)
        .fontSize(this.largeFontEnabled ? 12 : 11)
        .fontColor(this.highContrastEnabled ? '#000000' : '#94a3b8')
    }
    .width('100%')
    .padding(14)
    .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
    .borderRadius(14)
    .border({
      width: this.selectedRequestId === item.requestId ? 2 : 1,
      color: this.selectedRequestId === item.requestId ?
        (this.highContrastEnabled ? '#000000' : '#7c3aed') :
        (this.highContrastEnabled ? '#000000' : '#e2e8f0')
    })
    .onClick(() => {
      this.selectedRequestId = item.requestId;
    })
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        NavBackButton()

        Row({ space: 6 }) {
          Text('\u26a1')
            .fontSize(this.largeFontEnabled ? 20 : 18)
          Text('\u5feb\u901f\u6d3e\u5355')
            .fontSize(this.largeFontEnabled ? 20 : 17)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.highContrastEnabled ? '#000000' : '#0f172a')
        }
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 8, right: 16, top: 8, bottom: 8 })
      .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')

      if (this.isLoading || this.payload === null) {
        Column() {
          Text(this.isLoading ? '\u52a0\u8f7d\u4e2d...' : '')
            .fontSize(this.largeFontEnabled ? 16 : 14)
            .fontColor('#94a3b8')
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 16 }) {
            Column({ space: 12 }) {
              Row({ space: 12 }) {
                Row() {
                  Text(this.payload!.volunteer.name.length > 0 ?
                    this.payload!.volunteer.name.substring(0, 1) : '\u5fd7')
                    .fontSize(this.largeFontEnabled ? 22 : 20)
                    .fontColor('#ffffff')
                    .fontWeight(FontWeight.Bold)
                }
                .width(this.largeFontEnabled ? 56 : 52)
                .height(this.largeFontEnabled ? 56 : 52)
                .borderRadius(99)
                .backgroundColor('#fbbf24')
                .justifyContent(FlexAlign.Center)

                Column({ space: 6 }) {
                  Text(this.payload!.volunteer.name)
                    .fontSize(this.largeFontEnabled ? 20 : 18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#ffffff')
                  Row({ space: 12 }) {
                    Text(`\u{1F4CD} ${this.payload!.volunteer.location}`)
                      .fontSize(this.largeFontEnabled ? 13 : 12)
                      .fontColor('#ffffff')
                      .opacity(0.95)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1)
                    Text(`\u{1F3C5} ${this.payload!.volunteer.satisfaction}%`)
                      .fontSize(this.largeFontEnabled ? 13 : 12)
                      .fontColor('#ffffff')
                  }
                  .width('100%')
                  Flex({ wrap: FlexWrap.Wrap }) {
                    ForEach(this.payload!.volunteer.skills, (t: VolunteerSkillTag) => {
                      Text(t.label)
                        .fontSize(this.largeFontEnabled ? 12 : 11)
                        .fontColor('#ffffff')
                        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                        .margin({ right: 8, top: 4 })
                        .borderRadius(999)
                        .border({ width: 1, color: '#ffffffaa' })
                    }, (t: VolunteerSkillTag) => `${this.volunteerId}-${t.code}`)
                  }
                  .width('100%')
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              .width('100%')
            }
            .width('100%')
            .padding(16)
            .borderRadius(16)
            .linearGradient({
              angle: 135,
              colors: [[0x5b21b6, 0.0], [0x7c3aed, 1.0]]
            })

            Row({ space: 6 }) {
              Text('\u26a1')
                .fontSize(this.largeFontEnabled ? 18 : 16)
              Text('\u667a\u80fd\u63a8\u8350')
                .fontSize(this.largeFontEnabled ? 17 : 15)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.highContrastEnabled ? '#000000' : '#0f172a')
              Text('\u5339\u914d\u6280\u80fd')
                .fontSize(this.largeFontEnabled ? 11 : 10)
                .fontColor('#7c3aed')
                .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                .backgroundColor('#ede9fe')
                .borderRadius(8)
            }
            .width('100%')

            if ((this.payload!.smartMatches ? this.payload!.smartMatches.length : 0) === 0) {
              Text('\u6682\u65e0\u4e0e\u6280\u80fd\u5339\u914d\u7684\u5f85\u6d3e\u5355\uff0c\u8bf7\u67e5\u770b\u4e0b\u65b9\u5176\u5b83\u5f85\u6d3e\u5355')
                .fontSize(this.largeFontEnabled ? 14 : 12)
                .fontColor('#94a3b8')
                .padding(8)
            } else {
              ForEach(this.payload!.smartMatches, (item: DispatchScoredRequest) => {
                this.RequestCard(item);
              }, (item: DispatchScoredRequest) => `s-${item.requestId}`)
            }

            Row({ space: 6 }) {
              Text('\u5176\u5b83\u5f85\u6d3e\u5355')
                .fontSize(this.largeFontEnabled ? 17 : 15)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.highContrastEnabled ? '#000000' : '#0f172a')
              Text(`(${(this.payload!.otherPending ? this.payload!.otherPending.length : 0)})`)
                .fontSize(this.largeFontEnabled ? 14 : 12)
                .fontColor('#64748b')
            }
            .width('100%')
            .margin({ top: 8 })

            if ((this.payload!.otherPending ? this.payload!.otherPending.length : 0) === 0) {
              Text('\u6682\u65e0')
                .fontSize(this.largeFontEnabled ? 14 : 12)
                .fontColor('#94a3b8')
            } else {
              ForEach(this.payload!.otherPending, (item: DispatchScoredRequest) => {
                this.RequestCard(item);
              }, (item: DispatchScoredRequest) => `o-${item.requestId}`)
            }

            Row({ space: 8 }) {
              Text('\u2139\ufe0f')
                .fontSize(this.largeFontEnabled ? 16 : 14)
              Text(
                `\u6d3e\u5355\u540e\uff0c${this.payload!.volunteer.name} \u5c06\u6536\u5230\u901a\u77e5\u5e76\u53ef\u67e5\u770b\u6c42\u52a9\u8be6\u60c5`
              )
                .fontSize(this.largeFontEnabled ? 13 : 12)
                .fontColor(this.highContrastEnabled ? '#000000' : '#6d28d9')
                .layoutWeight(1)
            }
            .width('100%')
            .padding(12)
            .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#f5f3ff')
            .borderRadius(12)

            Button() {
              Row({ space: 8 }) {
                Text('\u26a1')
                  .fontColor('#ffffff')
                Text(this.isSubmitting ? '\u5904\u7406\u4e2d...' : '\u786e\u8ba4\u6d3e\u5355')
                  .fontColor('#ffffff')
                  .fontSize(this.largeFontEnabled ? 17 : 15)
                  .fontWeight(FontWeight.Medium)
              }
            }
            .width('100%')
            .height(this.largeFontEnabled ? 52 : 48)
            .backgroundColor(this.highContrastEnabled ? '#000000' : '#7c3aed')
            .borderRadius(14)
            .enabled(!this.isSubmitting)
            .onClick(() => {
              this.confirmDispatch();
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 16, right: 16, top: 0, bottom: 32 })
        }
        .layoutWeight(1)
        .align(Alignment.TopStart)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.highContrastEnabled ? '#ffffff' : '#f1f5f9')
  }
}
