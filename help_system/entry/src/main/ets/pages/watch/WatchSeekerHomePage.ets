import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { AuthService } from '../../services/AuthService';
import { RequestApi, GeocodeApi } from '../../services/ApiService';
import { getCurrentPosition, requestLocationPermission } from '../../utils/LocationUtil';
import type { HelpRequest } from '../../models/Request';

/**
 * 求助者手表首页：圆形网格布局（可滚动）
 */
@Entry
@Component
struct WatchSeekerHomePage {
  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;
  @State isSubmitting: boolean = false;
  @State showConfirmDialog: boolean = false;
  @State pendingRequestType: 'medical' | 'companion' | 'shopping' | 'other' | '' = '';
  @State pendingLocation: string = '正在获取位置...';
  @State pendingLatitude: number | undefined = undefined;
  @State pendingLongitude: number | undefined = undefined;
  @State isRefreshingLocation: boolean = false;
  @State pendingDescription: string = '';

  private goEmergency(): void {
    router.pushUrl({ url: 'pages/watch/WatchSeekerEmergencyPage' }).catch((err: Error) => {
      console.error('nav emergency failed:', err);
    });
  }

  private goMyRequests(): void {
    router.pushUrl({ url: 'pages/watch/WatchMyRequestsPage' }).catch((err: Error) => {
      console.error('nav my requests failed:', err);
    });
  }

  private async logout(): Promise<void> {
    await AuthService.logout();
    promptAction.showToast({ message: '已退出', duration: 1500 });
    router.replaceUrl({ url: 'pages/watch/WatchLoginPage' }).catch((err: Error) => {
      console.error('nav login failed:', err);
    });
  }

  private goSettings(): void {
    router.pushUrl({ url: 'pages/watch/WatchSettingsPage' }).catch((err: Error) => {
      console.error('nav settings failed:', err);
    });
  }

  // 获取类型名称
  private getTypeName(type: string): string {
    const typeNames: Record<string, string> = {
      'medical': '就医求助',
      'companion': '出行协助',
      'shopping': '生活帮扶',
      'other': '其他求助'
    };
    return typeNames[type] || '其他求助';
  }

  // 显示确认对话框
  private async showConfirm(type: 'medical' | 'companion' | 'shopping' | 'other'): Promise<void> {
    this.pendingRequestType = type;
    this.pendingLocation = '正在获取位置...';
    this.showConfirmDialog = true;

    // 异步获取位置信息
    await this.refreshLocation();
  }

  // 刷新位置信息
  private async refreshLocation(): Promise<void> {
    if (this.isRefreshingLocation) {
      return;
    }

    this.isRefreshingLocation = true;
    this.pendingLocation = '正在获取位置...';

    try {
      const granted = await requestLocationPermission();
      if (granted) {
        const pos = await getCurrentPosition();
        if (pos) {
          this.pendingLatitude = pos.latitude;
          this.pendingLongitude = pos.longitude;
          const address = await GeocodeApi.getAddressFromCoordinates(pos.latitude, pos.longitude);
          this.pendingLocation = address && address.length > 0
            ? address
            : `${pos.latitude.toFixed(5)}, ${pos.longitude.toFixed(5)}`;
        } else {
          this.pendingLocation = '未知位置（手表端发起）';
        }
      } else {
        this.pendingLocation = '未知位置（手表端发起）';
      }
    } catch (e) {
      console.error('locate failed:', e);
      this.pendingLocation = '未知位置（手表端发起）';
    } finally {
      this.isRefreshingLocation = false;
    }
  }

  // 确认提交求助
  private async confirmSubmit(): Promise<void> {
    if (this.isSubmitting || !this.pendingRequestType) {
      return;
    }

    this.isSubmitting = true;
    this.showConfirmDialog = false;

    try {
      const typeNames: Record<string, string> = {
        'medical': '就医求助',
        'companion': '出行协助',
        'shopping': '生活帮扶',
        'other': '其他求助'
      };

      const urgencyLevels: Record<string, 'low' | 'medium' | 'high' | 'emergency'> = {
        'medical': 'high',
        'companion': 'medium',
        'shopping': 'medium',
        'other': 'medium'
      };

      // 构建描述信息：如果用户输入了描述，使用用户输入；否则使用默认描述
      const userDescription = this.pendingDescription.trim();
      const finalDescription = userDescription.length > 0
        ? `【手表端快速求助】${typeNames[this.pendingRequestType]} - ${userDescription}`
        : `【手表端快速求助】${typeNames[this.pendingRequestType]}`;

      const payload: Partial<HelpRequest> = {
        type: this.pendingRequestType,
        title: typeNames[this.pendingRequestType],
        description: finalDescription,
        location: this.pendingLocation,
        urgency: urgencyLevels[this.pendingRequestType]
      };

      if (this.pendingLatitude !== undefined && this.pendingLongitude !== undefined) {
        payload.latitude = this.pendingLatitude;
        payload.longitude = this.pendingLongitude;
      }

      await RequestApi.createRequest(payload);
      promptAction.showToast({ message: '已发起求助', duration: 1500 });

      // 跳转到我的求助页面
      router.pushUrl({ url: 'pages/watch/WatchMyRequestsPage' }).catch((err: Error) => {
        console.error('nav failed:', err);
      });
    } catch (e) {
      const err = e as Error;
      promptAction.showToast({ message: err.message || '提交失败', duration: 2000 });
    } finally {
      this.isSubmitting = false;
      this.pendingRequestType = '';
      this.pendingLocation = '';
      this.pendingLatitude = undefined;
      this.pendingLongitude = undefined;
      this.pendingDescription = '';
    }
  }

  // 取消提交
  private cancelSubmit(): void {
    this.showConfirmDialog = false;
    this.pendingRequestType = '';
    this.pendingLocation = '';
    this.pendingLatitude = undefined;
    this.pendingLongitude = undefined;
    this.pendingDescription = '';
  }

  // 构建圆形卡片按钮
  @Builder
  buildCircleCard(label: string, icon: string, bgColor: string, onClick: () => void) {
    Column({ space: 2 }) {
      // 圆形背景 + 图标
      Stack() {
        Circle()
          .width(55)
          .height(55)
          .fill(bgColor)

        // 图标文字
        Text(icon)
          .fontSize(20)
          .fontColor('#ffffff')
          .fontWeight(FontWeight.Medium)
      }

      // 标签文字
      Text(label)
        .fontSize(this.largeFontEnabled ? 11 : 10)
        .fontColor(this.highContrastEnabled ? '#000000' : '#1e293b')
        .fontWeight(FontWeight.Medium)
    }
    .width('45%')
    .onClick(onClick)
  }

  // 确认对话框
  @Builder
  buildConfirmDialog() {
    if (this.showConfirmDialog) {
      Stack() {
        // 半透明背景
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.5)')
          .onClick(() => {
            this.cancelSubmit();
          })

        // 对话框内容
        Column({ space: 6 }) {
          Row() {
            Stack() {
              Circle()
                .width(22)
                .height(22)
                .fill('#f1f5f9')

              Text('←')
                .fontSize(14)
                .fontColor('#64748b')
            }
            .onClick(() => {
              this.cancelSubmit();
            })

            Blank()

            Text(this.getTypeName(this.pendingRequestType))
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1e293b')

            Blank()

            Stack() {
              Circle()
                .width(22)
                .height(22)
                .fill('transparent')
            }
          }
          .width('100%')

          Text(this.pendingLocation)
            .fontSize(9)
            .fontColor('#64748b')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ bottom: 2 })

          TextInput({ placeholder: '需求描述（可选）', text: this.pendingDescription })
            .width('100%')
            .height(32)
            .fontSize(10)
            .placeholderFont({ size: 8 })
            .fontColor('#1e293b')
            .backgroundColor('#f8fafc')
            .borderRadius(8)
            .padding({ left: 8, right: 8 })
            .placeholderColor('#94a3b8')
            .border({ width: 1, color: '#e2e8f0' })
            .onChange((value: string) => {
              this.pendingDescription = value;
            })

          Button(this.isSubmitting ? '提交中...' : '发送求助')
            .width('100%')
            .height(44)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .backgroundColor('#dc2626')
            .fontColor('#ffffff')
            .borderRadius(12)
            .enabled(!this.isSubmitting)
            .onClick(() => {
              this.confirmSubmit();
            })

          Button(this.isRefreshingLocation ? '刷新中...' : '刷新位置')
            .width('100%')
            .height(30)
            .fontSize(10)
            .backgroundColor('#eef2f7')
            .fontColor('#475569')
            .borderRadius(10)
            .border({ width: 1, color: '#dbe3ee' })
            .enabled(!this.isRefreshingLocation)
            .onClick(() => {
              this.refreshLocation();
            })
        }
        .width('80%')
        .padding(12)
        .backgroundColor('#ffffff')
        .borderRadius(16)
        .shadow({ radius: 8, color: '#00000030', offsetY: 3 })
      }
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
      .zIndex(1000)
    }
  }

  build() {
    Stack() {
      // 背景圆形 - 保持原来的浅色
      Circle()
        .width('100%')
        .height('100%')
        .fill(this.highContrastEnabled ? '#ffff00' : '#ffffff')

      // 可滚动内容区
      Scroll() {
        Column({ space: 10 }) {
          // 顶部标题
          Text('快速求助')
            .fontSize(this.largeFontEnabled ? 15 : 13)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.highContrastEnabled ? '#000000' : '#1e293b')
            .margin({ top: 4, bottom: 2 })

          // 紧急求助按钮（首页主视觉）
          Column({ space: 4 }) {
            Stack() {
              Circle()
                .width(28)
                .height(28)
                .fill('#ffffff')

              Text('!')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#dc2626')
            }

            Text('紧急求助')
              .fontSize(this.largeFontEnabled ? 13 : 12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#ffffff')

            Text('一键发起紧急求助')
              .fontSize(this.largeFontEnabled ? 10 : 9)
              .fontColor('rgba(255,255,255,0.9)')
          }
          .width('82%')
          .height(72)
          .backgroundColor(this.highContrastEnabled ? '#ff0000' : '#dc2626')
          .borderRadius(36)
          .justifyContent(FlexAlign.Center)
          .shadow({ radius: 8, color: '#dc262640', offsetY: 3 })
          .onClick(() => { this.goEmergency(); })

          // 2x2 网格卡片
          Column({ space: 6 }) {
            // 第一行:就医 + 出行
            Row({ space: 8 }) {
              this.buildCircleCard('就医', '♥', this.highContrastEnabled ? '#ff0000' : '#ef4444', () => {
                this.showConfirm('medical');
              })

              this.buildCircleCard('出行', '☎', this.highContrastEnabled ? '#0000ff' : '#3b82f6', () => {
                this.showConfirm('companion');
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceEvenly)

            // 第二行:购物 + 其他
            Row({ space: 8 }) {
              this.buildCircleCard('购物', '🛒', this.highContrastEnabled ? '#00ff00' : '#10b981', () => {
                this.showConfirm('shopping');
              })

              this.buildCircleCard('其他', '📋', this.highContrastEnabled ? '#ff8800' : '#f97316', () => {
                this.goMyRequests();
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceEvenly)
          }
          .width('88%')
          .margin({ top: 2 })

          // 底部按钮：设置、退出
          Row({ space: 5 }) {
            Button('设置')
              .layoutWeight(1)
              .height(24)
              .fontSize(9)
              .backgroundColor(this.highContrastEnabled ? '#ffffff' : '#64748b')
              .fontColor(this.highContrastEnabled ? '#000000' : '#ffffff')
              .borderRadius(12)
              .border(this.highContrastEnabled ? { width: 2, color: '#000000' } : undefined)
              .onClick(() => { this.goSettings(); })

            Button('退出')
              .layoutWeight(1)
              .height(24)
              .fontSize(9)
              .backgroundColor(this.highContrastEnabled ? '#ffffff' : '#64748b')
              .fontColor(this.highContrastEnabled ? '#000000' : '#ffffff')
              .borderRadius(12)
              .border(this.highContrastEnabled ? { width: 2, color: '#000000' } : undefined)
              .onClick(() => { this.logout(); })
          }
          .width('76%')
          .margin({ bottom: 6 })
        }
        .width('100%')
        .padding({ left: 10, right: 10 })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      // 确认对话框
      this.buildConfirmDialog()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#f0f4ff')
  }
}
