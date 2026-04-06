import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { CommunityApi } from '../../services/ApiService';
import type { VolunteerMgmtRow, VolunteerMgmtSummary, VolunteerSkillTag } from '../../models';

/** 志愿者管理页配色：深蓝灰 + 青绿点缀 */
class VmTheme {
  static readonly pageBg: string = '#f4f6f9';
  static readonly headerGrad: Array<[number, number]> =
    [[0x1e293b, 0.0], [0x334155, 0.55], [0x3f4f63, 1.0]];
  static readonly statPillBg: string = '#ffffff22';
  static readonly accent: string = '#0d9488';
  static readonly accentMuted: string = '#0f766e';
  static readonly cardBorder: string = '#e2e8f0';
  static readonly avatarGrad: Array<[number, number]> = [[0x64748b, 0.0], [0x475569, 1.0]];
  static readonly tagText: string = '#334155';
  static readonly tagBorder: string = '#cbd5e1';
  static readonly tagBg: string = '#f8fafc';
  static readonly shadow: string = '#0f172a10';
  static readonly navActive: string = '#0d9488';
}

@Entry
@Component
struct VolunteerManagementPage {
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  @State summary: VolunteerMgmtSummary | null = null;
  @State volunteers: VolunteerMgmtRow[] = [];
  @State searchText: string = '';
  @State isLoading: boolean = false;

  aboutToAppear() {
    this.loadData();
  }

  onPageShow() {
    this.loadData();
  }

  private async loadData(): Promise<void> {
    this.isLoading = true;
    try {
      const payload = await CommunityApi.getVolunteerManagement();
      this.summary = payload.summary;
      this.volunteers = payload.volunteers ? payload.volunteers : [];
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

  /** 有搜索关键字时收起顶部大标题与汇总区，列表顶格展示 */
  private isSearchActive(): boolean {
    return this.searchText.trim().length > 0;
  }

  private getFilteredVolunteers(): VolunteerMgmtRow[] {
    const q = this.searchText.trim().toLowerCase();
    if (q.length === 0) {
      return this.volunteers;
    }
    const out: VolunteerMgmtRow[] = [];
    for (let i = 0; i < this.volunteers.length; i++) {
      const v = this.volunteers[i];
      if (v.name.toLowerCase().includes(q)) {
        out.push(v);
        continue;
      }
      let hit = false;
      const skills = v.skills ? v.skills : [];
      for (let j = 0; j < skills.length; j++) {
        const t = skills[j];
        if (t.label.toLowerCase().includes(q) || t.code.toLowerCase().includes(q)) {
          hit = true;
          break;
        }
      }
      if (hit) {
        out.push(v);
      }
    }
    return out;
  }

  private statusLabel(status: string): string {
    switch (status) {
      case 'online':
        return '\u5728\u7ebf';
      case 'in_service':
        return '\u670d\u52a1\u4e2d';
      default:
        return '\u79bb\u7ebf';
    }
  }

  private statusDotColor(status: string): string {
    if (this.highContrastEnabled) {
      return '#000000';
    }
    switch (status) {
      case 'online':
        return '#22c55e';
      case 'in_service':
        return '#3b82f6';
      default:
        return '#94a3b8';
    }
  }

  navigateTo(path: string) {
    router.pushUrl({ url: path }).catch((e: Error) => {
      console.error(e.message != null ? e.message : 'navigate failed');
    });
  }

  openQuickDispatch(v: VolunteerMgmtRow) {
    router.pushUrl({
      url: 'pages/community/QuickDispatchPage',
      params: { volunteerId: v.id }
    }).catch((e: Error) => {
      console.error(e.message != null ? e.message : 'quick dispatch navigate failed');
    });
  }

  @Builder
  BottomNav() {
    Row() {
      Column({ space: 4 }) {
        Text('\u{1F3E0}')
          .fontSize(this.largeFontEnabled ? 26 : 22)
        Text('\u9996\u9875')
          .fontSize(this.largeFontEnabled ? 14 : 11)
          .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
      }
      .layoutWeight(1)
      .onClick(() => this.navigateTo('pages/community/CommunityHomePage'))

      Column({ space: 4 }) {
        Text('\u{1F465}')
          .fontSize(this.largeFontEnabled ? 26 : 22)
        Text('\u5fd7\u613f\u8005')
          .fontSize(this.largeFontEnabled ? 14 : 11)
          .fontColor(this.highContrastEnabled ? '#000000' : VmTheme.navActive)
          .fontWeight(FontWeight.Medium)
      }
      .layoutWeight(1)

      Column({ space: 4 }) {
        Text('\u{1F464}')
          .fontSize(this.largeFontEnabled ? 26 : 22)
        Text('\u6211\u7684')
          .fontSize(this.largeFontEnabled ? 14 : 11)
          .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
      }
      .layoutWeight(1)
      .onClick(() => this.navigateTo('pages/community/ProfilePage'))
    }
    .width('100%')
    .height(this.largeFontEnabled ? 80 : 70)
    .padding({ top: 4 })
    .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
    .border(this.highContrastEnabled ?
      { width: { top: 3 }, color: '#000000' } :
      { width: { top: 1 }, color: '#e2e8f0' })
  }

  @Builder
  VolunteerCard(v: VolunteerMgmtRow) {
    Column({ space: 10 }) {
      Row({ space: 12 }) {
        Row() {
          Text(v.name.length > 0 ? v.name.substring(0, 1) : '\u5fd7')
            .fontSize(this.largeFontEnabled ? 20 : 18)
            .fontColor('#ffffff')
            .fontWeight(FontWeight.Bold)
        }
        .width(this.largeFontEnabled ? 52 : 48)
        .height(this.largeFontEnabled ? 52 : 48)
        .borderRadius(99)
        .linearGradient({ angle: 135, colors: VmTheme.avatarGrad })
        .justifyContent(FlexAlign.Center)

        Column({ space: 6 }) {
          Row({ space: 8 }) {
            Text(v.name)
              .fontSize(this.largeFontEnabled ? 18 : 16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.highContrastEnabled ? '#000000' : '#0f172a')
            Row({ space: 4 }) {
              Row()
                .width(8)
                .height(8)
                .borderRadius(4)
                .backgroundColor(this.statusDotColor(v.uiStatus))
              Text(this.statusLabel(v.uiStatus))
                .fontSize(this.largeFontEnabled ? 14 : 12)
                .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
            }
          }
          .alignItems(VerticalAlign.Center)

          Row({ space: 6 }) {
            Text('\u{1F4DE}')
              .fontSize(this.largeFontEnabled ? 14 : 12)
            Text(v.phoneMasked)
              .fontSize(this.largeFontEnabled ? 14 : 12)
              .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
          }
          Row({ space: 6 }) {
            Text('\u{1F4CD}')
              .fontSize(this.largeFontEnabled ? 14 : 12)
            Text(v.location ? v.location : '\u2014')
              .fontSize(this.largeFontEnabled ? 14 : 12)
              .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Start }) {
        ForEach(v.skills ? v.skills : [], (t: VolunteerSkillTag) => {
          Text(t.label)
            .fontSize(this.largeFontEnabled ? 13 : 11)
            .fontColor(this.highContrastEnabled ? '#000000' : VmTheme.tagText)
            .backgroundColor(this.highContrastEnabled ? undefined : VmTheme.tagBg)
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .margin({ right: 8, bottom: 6 })
            .borderRadius(999)
            .border({ width: 1, color: this.highContrastEnabled ? '#000000' : VmTheme.tagBorder })
        }, (t: VolunteerSkillTag) => `${v.id}-${t.code}`)
      }
      .width('100%')

      Row() {
        Text(`\u5b8c\u6210 ${v.serviceCount} \u6b21`)
          .fontSize(this.largeFontEnabled ? 14 : 12)
          .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
        Text('  \u00b7  ')
          .fontSize(this.largeFontEnabled ? 14 : 12)
          .fontColor('#cbd5e1')
        Text('\u{1F3C6}')
          .fontSize(this.largeFontEnabled ? 14 : 12)
        Text(` \u6ee1\u610f\u5ea6 ${v.satisfaction}%`)
          .fontSize(this.largeFontEnabled ? 14 : 12)
          .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
      }
      .width('100%')

      if (v.quickDispatchEnabled) {
        Button('\u5feb\u901f\u6d3e\u5355')
          .width('100%')
          .height(this.largeFontEnabled ? 44 : 40)
          .fontSize(this.largeFontEnabled ? 16 : 14)
          .fontColor('#ffffff')
          .backgroundColor(this.highContrastEnabled ? '#000000' : VmTheme.accent)
          .borderRadius(12)
          .onClick(() => this.openQuickDispatch(v))
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
    .borderRadius(14)
    .border(this.highContrastEnabled ?
      { width: 3, color: '#000000' } :
      { width: 1, color: VmTheme.cardBorder })
    .shadow(this.highContrastEnabled ? undefined : {
      radius: 10,
      color: VmTheme.shadow,
      offsetY: 3
    })
  }

  build() {
    Column() {
      if (!this.isSearchActive()) {
        Column({ space: 6 }) {
          Text('\u5fd7\u613f\u8005\u7ba1\u7406')
            .fontSize(this.largeFontEnabled ? 24 : 20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.highContrastEnabled ? '#000000' : '#ffffff')
          Text('\u5b9e\u65f6\u72b6\u6001\u4e0e\u5feb\u901f\u6d3e\u5355')
            .fontSize(this.largeFontEnabled ? 14 : 12)
            .fontColor(this.highContrastEnabled ? '#000000' : '#ffffff')
            .opacity(this.highContrastEnabled ? 1 : 0.9)
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 24, bottom: 20 })
        .linearGradient(this.highContrastEnabled ? undefined : {
          angle: 160,
          colors: VmTheme.headerGrad
        })
        .backgroundColor(this.highContrastEnabled ? '#ffffff' : undefined)
        .border(this.highContrastEnabled ? { width: { bottom: 3 }, color: '#000000' } : undefined)

        if (this.summary !== null) {
          Row({ space: 10 }) {
            Column({ space: 4 }) {
              Text(`${this.summary!.totalVolunteers}`)
                .fontSize(this.largeFontEnabled ? 26 : 22)
                .fontWeight(FontWeight.Bold)
                .fontColor('#0f172a')
              Text('\u603b\u5fd7\u613f\u8005')
                .fontSize(this.largeFontEnabled ? 12 : 10)
                .fontColor('#64748b')
            }
            .layoutWeight(1)
            .padding(12)
            .backgroundColor('#ffffff')
            .border({ width: 1, color: '#dbe4ee' })
            .borderRadius(12)

            Column({ space: 4 }) {
              Text(`${this.summary!.onlineCount}`)
                .fontSize(this.largeFontEnabled ? 26 : 22)
                .fontWeight(FontWeight.Bold)
                .fontColor('#0f172a')
              Text('\u5728\u7ebf\u4eba\u6570')
                .fontSize(this.largeFontEnabled ? 12 : 10)
                .fontColor('#64748b')
            }
            .layoutWeight(1)
            .padding(12)
            .backgroundColor('#ffffff')
            .border({ width: 1, color: '#dbe4ee' })
            .borderRadius(12)

            Column({ space: 4 }) {
              Text(`${this.summary!.inServiceCount}`)
                .fontSize(this.largeFontEnabled ? 26 : 22)
                .fontWeight(FontWeight.Bold)
                .fontColor('#0f172a')
              Text('\u670d\u52a1\u4e2d')
                .fontSize(this.largeFontEnabled ? 12 : 10)
                .fontColor('#64748b')
            }
            .layoutWeight(1)
            .padding(12)
            .backgroundColor('#ffffff')
            .border({ width: 1, color: '#dbe4ee' })
            .borderRadius(12)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: -8, bottom: 12 })
          .linearGradient(this.highContrastEnabled ? undefined : {
            angle: 160,
            colors: VmTheme.headerGrad
          })
          .backgroundColor(this.highContrastEnabled ? '#ffffff' : undefined)
        }
      }

      Scroll() {
        Column({ space: this.isSearchActive() ? 10 : 14 }) {
          TextInput({ placeholder: '\u641c\u7d22\u5fd7\u613f\u8005\u59d3\u540d\u6216\u6280\u80fd...', text: this.searchText })
            .height(this.largeFontEnabled ? 48 : 44)
            .fontSize(this.largeFontEnabled ? 16 : 14)
            .backgroundColor(this.highContrastEnabled ? '#ffffff' : '#ffffff')
            .borderRadius(12)
            .border(this.highContrastEnabled ? { width: 2, color: '#000000' } : { width: 1, color: VmTheme.cardBorder })
            .padding({ left: 14, right: 14 })
            .onChange((val: string) => {
              this.searchText = val;
            })

          if (!this.isSearchActive() && this.summary !== null) {
            Row({ space: 10 }) {
              Column({ space: 6 }) {
                Row({ space: 8 }) {
                  Text('\u{1F4C8}')
                    .fontSize(this.largeFontEnabled ? 22 : 18)
                  Text('\u672c\u5468\u670d\u52a1')
                    .fontSize(this.largeFontEnabled ? 14 : 12)
                    .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
                }
                Text(`${this.summary!.weekServices}\u6b21`)
                  .fontSize(this.largeFontEnabled ? 22 : 18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.highContrastEnabled ? '#000000' : VmTheme.accentMuted)
              }
              .layoutWeight(1)
              .padding(14)
              .backgroundColor(this.highContrastEnabled ? '#ffffff' : '#ffffff')
              .borderRadius(14)
              .border(this.highContrastEnabled ?
                { width: 3, color: '#000000' } :
                { width: 1, color: VmTheme.cardBorder })

              Column({ space: 6 }) {
                Row({ space: 8 }) {
                  Text('\u{1F3C5}')
                    .fontSize(this.largeFontEnabled ? 22 : 18)
                  Text('\u5e73\u5747\u8bc4\u5206')
                    .fontSize(this.largeFontEnabled ? 14 : 12)
                    .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
                }
                Text(`${this.summary!.avgRating}\u5206`)
                  .fontSize(this.largeFontEnabled ? 22 : 18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.highContrastEnabled ? '#000000' : '#475569')
              }
              .layoutWeight(1)
              .padding(14)
              .backgroundColor(this.highContrastEnabled ? '#ffffff' : '#ffffff')
              .borderRadius(14)
              .border(this.highContrastEnabled ?
                { width: 3, color: '#000000' } :
                { width: 1, color: VmTheme.cardBorder })
            }
            .width('100%')
          }

          Row() {
            Text('\u5fd7\u613f\u8005\u5217\u8868')
              .fontSize(this.largeFontEnabled ? 18 : 16)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.highContrastEnabled ? '#000000' : '#0f172a')
            Blank()
            Text(`${this.getFilteredVolunteers().length}\u4eba`)
              .fontSize(this.largeFontEnabled ? 14 : 12)
              .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
          }
          .width('100%')

          if (this.isLoading) {
            Text('\u52a0\u8f7d\u4e2d...')
              .fontSize(this.largeFontEnabled ? 16 : 14)
              .fontColor('#94a3b8')
              .padding(24)
          } else {
            Column({ space: 12 }) {
              ForEach(this.getFilteredVolunteers(), (v: VolunteerMgmtRow) => {
                this.VolunteerCard(v)
              }, (v: VolunteerMgmtRow) => v.id)
            }
            .width('100%')
          }
        }
        .width('100%')
        .padding(this.isSearchActive()
          ? { left: 16, right: 16, top: 6, bottom: 24 }
          : { left: 16, right: 16, top: 12, bottom: 24 })
      }
      .layoutWeight(1)
      .align(Alignment.TopStart)
      .scrollBar(BarState.Off)
      .backgroundColor(this.highContrastEnabled ? '#ffffff' : VmTheme.pageBg)

      this.BottomNav()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.highContrastEnabled ? '#ffffff' : VmTheme.pageBg)
  }
}
