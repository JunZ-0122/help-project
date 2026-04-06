import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { CommunityApi } from '../../services/ApiService';
import type { CommunityStatistics, RequestTypeStat, WeeklyTrendItem, TopVolunteerItem } from '../../models';

interface StatItem {
  icon: string;
  label: string;
  value: string;
  trend: string;
  g0: number;
  g1: number;
}

@Entry
@Component
struct StatisticsPage {
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  @State isLoading: boolean = true;
  @State stats: CommunityStatistics = {
    totalRequests: 0,
    pendingRequests: 0,
    inProgressRequests: 0,
    completedRequests: 0,
    totalVolunteers: 0,
    availableVolunteers: 0,
    busyVolunteers: 0,
    todayRequests: 0,
    todayCompleted: 0,
    averageResponseTime: 0,
    averageCompletionTime: 0,
    satisfactionRate: 0,
    monthlyHelpCount: 0,
    monthlyHelpTrendPercent: 0,
    monthlySatisfactionPercent: 0,
    monthlySatisfactionDeltaPoints: 0,
    activeVolunteersMonth: 0,
    activeVolunteersTrendPercent: 0,
    activeVolunteersMomDelta: 0
  };

  private skipNextPageShow: boolean = true;

  aboutToAppear() {
    this.loadStatistics();
  }

  onPageShow() {
    if (this.skipNextPageShow) {
      this.skipNextPageShow = false;
      return;
    }
    this.loadStatistics();
  }

  private async loadStatistics(): Promise<void> {
    this.isLoading = true;
    try {
      this.stats = await CommunityApi.getStatistics();
    } catch (err) {
      const error = err as Error;
      console.error('load statistics failed:', error);
      promptAction.showToast({
        message: error.message ? error.message : '\u52a0\u8f7d\u7edf\u8ba1\u5931\u8d25',
        duration: 1500
      });
    } finally {
      this.isLoading = false;
    }
  }

  private formatPctChange(n: number): string {
    if (n >= 0) {
      return `+${n}%`;
    }
    return `${n}%`;
  }

  private formatDeltaPoints(n: number): string {
    if (n >= 0) {
      return `+${n}%`;
    }
    return `${n}%`;
  }

  private formatVolunteerDelta(n: number): string {
    if (n >= 0) {
      return `+${n}`;
    }
    return `${n}`;
  }

  private buildTopStats(): StatItem[] {
    const h = this.stats.monthlyHelpCount !== undefined ? this.stats.monthlyHelpCount : 0;
    const sat = this.stats.monthlySatisfactionPercent !== undefined ? this.stats.monthlySatisfactionPercent : 0;
    const av = this.stats.activeVolunteersMonth !== undefined ? this.stats.activeVolunteersMonth : 0;
    const tHelp = this.stats.monthlyHelpTrendPercent !== undefined ? this.stats.monthlyHelpTrendPercent : 0;
    const tSat = this.stats.monthlySatisfactionDeltaPoints !== undefined ? this.stats.monthlySatisfactionDeltaPoints : 0;
    const tVolDelta = this.stats.activeVolunteersMomDelta !== undefined ? this.stats.activeVolunteersMomDelta : 0;
    const tVolPct = this.stats.activeVolunteersTrendPercent !== undefined ? this.stats.activeVolunteersTrendPercent : 0;

    return [
      {
        icon: '📈',
        label: '\u672c\u6708\u5e2e\u6276\u6b21\u6570',
        value: `${h}`,
        trend: this.formatPctChange(tHelp),
        g0: 0x2563eb,
        g1: 0x6366f1
      },
      {
        icon: '👍',
        label: '\u670d\u52a1\u6ee1\u610f\u5ea6',
        value: `${sat}%`,
        trend: this.formatDeltaPoints(tSat),
        g0: 0x10b981,
        g1: 0x059669
      },
      {
        icon: '👥',
        label: '\u6d3b\u8dc3\u5fd7\u613f\u8005',
        value: `${av}`,
        trend: tVolDelta !== 0 ? this.formatVolunteerDelta(tVolDelta) : this.formatPctChange(tVolPct),
        g0: 0xa855f7,
        g1: 0x6d28d9
      }
    ];
  }

  private getRankColor(rank: number): string {
    switch (rank) {
      case 1:
        return '#f59e0b';
      case 2:
        return '#9ca3af';
      case 3:
        return '#ea580c';
      default:
        return '#6b7280';
    }
  }

  private getWeeklyTrendHeight(count: number): number {
    const arr = this.stats.weeklyTrend?.map((item: WeeklyTrendItem) => item.count) || [];
    const maxCount = Math.max(...arr, 1);
    return 36 + (count / maxCount) * 72;
  }

  @Builder
  StatCard(stat: StatItem) {
    Column({ space: this.largeFontEnabled ? 10 : 8 }) {
      Text(stat.icon)
        .fontSize(this.largeFontEnabled ? 40 : 34)
        .margin({ top: 4 })

      Text(stat.value)
        .fontSize(this.largeFontEnabled ? 32 : 28)
        .fontColor('#ffffff')
        .fontWeight(FontWeight.Bold)
        .margin({ top: 4 })

      Text(stat.label)
        .fontSize(this.largeFontEnabled ? 15 : 13)
        .fontColor('#ffffff')
        .opacity(0.95)

      Text(stat.trend)
        .fontSize(this.largeFontEnabled ? 14 : 12)
        .fontColor('#ffffff')
        .fontWeight(FontWeight.Medium)
        .opacity(0.88)
    }
    .layoutWeight(1)
    .padding(this.largeFontEnabled ? 18 : 16)
    .linearGradient({
      angle: 135,
      colors: [[stat.g0, 0.0], [stat.g1, 1.0]]
    })
    .borderRadius(16)
    .shadow({
      radius: 10,
      color: '#0f172a18',
      offsetX: 0,
      offsetY: 4
    })
  }

  @Builder
  RequestTypeItem(item: RequestTypeStat) {
    Row({ space: 12 }) {
      Row() {
        Text(item.rank.toString())
          .fontSize(this.largeFontEnabled ? 15 : 13)
          .fontColor('#2563eb')
          .fontWeight(FontWeight.Bold)
      }
      .width(this.largeFontEnabled ? 30 : 26)
      .height(this.largeFontEnabled ? 30 : 26)
      .borderRadius(99)
      .backgroundColor('#dbeafe')
      .justifyContent(FlexAlign.Center)

      Column({ space: 8 }) {
        Row() {
          Text(item.name)
            .fontSize(this.largeFontEnabled ? 16 : 14)
            .fontColor('#0f172a')
            .layoutWeight(1)

          Text(`${item.count} \u6b21`)
            .fontSize(this.largeFontEnabled ? 15 : 13)
            .fontColor('#64748b')
            .margin({ right: 8 })

          Text(`${item.percentage}%`)
            .fontSize(this.largeFontEnabled ? 15 : 13)
            .fontColor('#2563eb')
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')

        Row() {
          Row()
            .width(`${item.percentage}%`)
            .height(this.largeFontEnabled ? 8 : 6)
            .linearGradient({
              angle: 90,
              colors: [[0x2563eb, 0.0], [0x60a5fa, 1.0]]
            })
            .borderRadius(4)
        }
        .width('100%')
        .height(this.largeFontEnabled ? 8 : 6)
        .backgroundColor('#f1f5f9')
        .borderRadius(4)
        .clip(true)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 12, bottom: 12 })
  }

  @Builder
  VolunteerRankItem(item: TopVolunteerItem) {
    Row({ space: 12 }) {
      Row() {
        Text(item.rank.toString())
          .fontSize(this.largeFontEnabled ? 18 : 16)
          .fontColor('#ffffff')
          .fontWeight(FontWeight.Bold)
      }
      .width(this.largeFontEnabled ? 42 : 38)
      .height(this.largeFontEnabled ? 42 : 38)
      .borderRadius(this.largeFontEnabled ? 21 : 19)
      .backgroundColor(this.getRankColor(item.rank))
      .justifyContent(FlexAlign.Center)

      Column({ space: 4 }) {
        Text(item.name)
          .fontSize(this.largeFontEnabled ? 17 : 15)
          .fontColor('#0f172a')
          .fontWeight(FontWeight.Medium)

        Text(`\u670d\u52a1 ${item.serviceCount} \u6b21 \u00b7 \u6ee1\u610f\u5ea6 ${item.satisfaction}%`)
          .fontSize(this.largeFontEnabled ? 14 : 12)
          .fontColor('#64748b')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(this.largeFontEnabled ? 14 : 12)
    .backgroundColor('#ffffff')
    .borderRadius(12)
    .border({ width: 1, color: '#f1f5f9' })
    .shadow({
      radius: 8,
      color: '#0f172a0d',
      offsetY: 2
    })
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        NavBackButton()

        Text('\u6570\u636e\u7edf\u8ba1')
          .fontSize(this.largeFontEnabled ? 22 : 18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#0f172a')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank().width(this.largeFontEnabled ? 44 : 40)
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#ffffff')
      .border({ width: { bottom: 1 }, color: '#e2e8f0' })

      if (this.isLoading) {
        Column({ space: 16 }) {
          LoadingProgress()
            .width(36)
            .height(36)
            .color('#2563eb')
          Text('\u52a0\u8f7d\u4e2d...')
            .fontSize(this.largeFontEnabled ? 18 : 15)
            .fontColor('#64748b')
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column({ space: 20 }) {
            Column({ space: 12 }) {
              Text('\u672c\u6708\u6982\u89c8')
                .fontSize(this.largeFontEnabled ? 19 : 16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#0f172a')
                .width('100%')

              Row({ space: 10 }) {
                ForEach(this.buildTopStats(), (stat: StatItem, idx: number) => {
                  this.StatCard(stat)
                }, (stat: StatItem, idx: number) => `stat-${idx}`)
              }
              .width('100%')
            }
            .width('100%')

            Column({ space: 12 }) {
              Row({ space: 8 }) {
                Text('ℹ️')
                  .fontSize(this.largeFontEnabled ? 20 : 18)
                Text('\u9ad8\u9891\u6c42\u52a9\u7c7b\u578b')
                  .fontSize(this.largeFontEnabled ? 19 : 16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#0f172a')
              }
              .width('100%')

              Column() {
                if (this.stats.requestTypes && this.stats.requestTypes.length > 0) {
                  ForEach(this.stats.requestTypes, (item: RequestTypeStat, index: number) => {
                    Column() {
                      this.RequestTypeItem(item)
                      if (index < this.stats.requestTypes!.length - 1) {
                        Divider()
                          .color('#f1f5f9')
                      }
                    }
                  }, (item: RequestTypeStat) => `${item.rank}-${item.type}`)
                } else {
                  Text('\u6682\u65e0\u6570\u636e')
                    .fontSize(this.largeFontEnabled ? 16 : 14)
                    .fontColor('#94a3b8')
                    .padding(20)
                }
              }
              .width('100%')
              .backgroundColor('#ffffff')
              .borderRadius(16)
              .border({ width: 1, color: '#f1f5f9' })
              .shadow({
                radius: 10,
                color: '#0f172a0d',
                offsetY: 3
              })
            }
            .width('100%')

            Column({ space: 12 }) {
              Text('\u672c\u5468\u670d\u52a1\u8d8b\u52bf')
                .fontSize(this.largeFontEnabled ? 19 : 16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#0f172a')
                .width('100%')

              Row({ space: 8 }) {
                if (this.stats.weeklyTrend && this.stats.weeklyTrend.length > 0) {
                  ForEach(this.stats.weeklyTrend, (item: WeeklyTrendItem, index: number) => {
                    Column({ space: 6 }) {
                      Row()
                        .width(this.largeFontEnabled ? 36 : 30)
                        .height(this.getWeeklyTrendHeight(item.count))
                        .linearGradient({
                          angle: 180,
                          colors: [[0x3b82f6, 0.0], [0x93c5fd, 1.0]]
                        })
                        .borderRadius(6)
                      Text(item.dayOfWeek)
                        .fontSize(this.largeFontEnabled ? 13 : 11)
                        .fontColor('#64748b')
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Center)
                  }, (item: WeeklyTrendItem, index: number) => `${item.date}-${index}`)
                }
              }
              .width('100%')
              .height(168)
              .padding(16)
              .backgroundColor('#ffffff')
              .borderRadius(16)
              .border({ width: 1, color: '#f1f5f9' })
              .alignItems(VerticalAlign.Bottom)
              .shadow({
                radius: 10,
                color: '#0f172a0d',
                offsetY: 3
              })
            }
            .width('100%')

            Column({ space: 12 }) {
              Text('\u4f18\u79c0\u5fd7\u613f\u8005')
                .fontSize(this.largeFontEnabled ? 19 : 16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#0f172a')
                .width('100%')

              Column({ space: 12 }) {
                if (this.stats.topVolunteers && this.stats.topVolunteers.length > 0) {
                  ForEach(this.stats.topVolunteers, (item: TopVolunteerItem) => {
                    this.VolunteerRankItem(item)
                  }, (item: TopVolunteerItem) => item.id)
                } else {
                  Text('\u6682\u65e0\u6570\u636e')
                    .fontSize(this.largeFontEnabled ? 16 : 14)
                    .fontColor('#94a3b8')
                    .padding(20)
                    .width('100%')
                    .textAlign(TextAlign.Center)
                }
              }
              .width('100%')
            }
            .width('100%')
          }
          .width('100%')
          .padding(16)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .backgroundColor('#f1f5f9')
      }
    }
    .width('100%')
    .height('100%')
  }
}
