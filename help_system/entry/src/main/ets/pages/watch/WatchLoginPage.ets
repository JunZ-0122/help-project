import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { AuthService } from '../../services/AuthService';
import type { LoginRequest, LoginResponse } from '../../models/Auth';

/**
 * 手表专用登录页：分步输入，适配圆形屏幕
 * 步骤1：输入手机号
 * 步骤2：获取并输入验证码
 * 步骤3：登录中（过渡状态）
 */
@Entry
@Component
struct WatchLoginPage {
  // 当前步骤：1=手机号, 2=验证码
  @State step: number = 1;
  @State phone: string = '';
  @State code: string = '';
  @State countdown: number = 0;
  @State isLoading: boolean = false;
  @State @Watch('onLoginSuccess') loginSuccessful: boolean = false;
  @State loginUserData: LoginResponse | null = null;
  private countdownTimer: number = -1;

  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  aboutToDisappear() {
    if (this.countdownTimer !== -1) {
      clearInterval(this.countdownTimer);
    }
  }

  onLoginSuccess(): void {
    if (!this.loginSuccessful || !this.loginUserData) return;
    const role = this.loginUserData.user.role as string | undefined;

    promptAction.showToast({ message: '登录成功', duration: 1500 });

    if (role === 'help-seeker') {
      router.replaceUrl({ url: 'pages/watch/WatchSeekerHomePage' }).catch((e: Error) => {});
    } else if (role === 'volunteer') {
      router.replaceUrl({ url: 'pages/watch/WatchVolunteerHomePage' }).catch((e: Error) => {});
    } else {
      router.replaceUrl({
        url: 'pages/watch/WatchAccountUnsupportedPage',
        params: { reason: role ? 'community' : 'no-role' }
      }).catch((e: Error) => {});
    }
  }

  private appendDigit(digit: string): void {
    if (this.step === 1) {
      if (this.phone.length < 11) this.phone += digit;
    } else {
      if (this.code.length < 6) this.code += digit;
    }
  }

  private deleteOne(): void {
    if (this.step === 1) {
      this.phone = this.phone.slice(0, -1);
    } else {
      this.code = this.code.slice(0, -1);
    }
  }

  private handleNext(): void {
    if (this.phone.length !== 11) {
      promptAction.showToast({ message: '请输入11位手机号', duration: 2000 });
      return;
    }
    // 发送验证码
    AuthService.sendVerificationCode({ phone: this.phone, type: 'login' }).then((ok: boolean) => {
      if (ok) {
        this.step = 2;
        this.countdown = 60;
        promptAction.showToast({ message: '验证码已发送（测试：123456）', duration: 3000 });
        this.countdownTimer = setInterval(() => {
          this.countdown--;
          if (this.countdown <= 0) {
            clearInterval(this.countdownTimer);
            this.countdownTimer = -1;
            this.countdown = 0;
          }
        }, 1000);
      } else {
        promptAction.showToast({ message: '发送失败，请重试', duration: 2000 });
      }
    }).catch((e: Error) => {
      promptAction.showToast({ message: e.message || '发送失败', duration: 2000 });
    });
  }

  private handleResend(): void {
    if (this.countdown > 0) return;
    this.handleNext();
  }

  private handleLogin(): void {
    if (this.code.length < 4) {
      promptAction.showToast({ message: '请输入验证码', duration: 2000 });
      return;
    }
    this.isLoading = true;
    const req: LoginRequest = {
      phone: this.phone,
      password: this.code,
      verificationCode: this.code,
      loginType: 'sms'
    };
    AuthService.login(req).then((res: LoginResponse) => {
      this.isLoading = false;
      this.loginUserData = res;
      this.loginSuccessful = true;
    }).catch((e: Error) => {
      this.isLoading = false;
      promptAction.showToast({ message: e.message || '登录失败', duration: 2000 });
    });
  }

  // 数字键盘（3列3行，极致压缩）
  @Builder
  buildKeypad() {
    Column({ space: 2 }) {
      ForEach(['1,2,3', '4,5,6', '7,8,9'], (row: string) => {
        Row({ space: 2 }) {
          ForEach(row.split(','), (d: string) => {
            Button(d)
              .layoutWeight(1)
              .height(22)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .backgroundColor(this.highContrastEnabled ? '#000000' : '#ffffff')
              .fontColor(this.highContrastEnabled ? '#ffff00' : '#1e293b')
              .borderRadius(5)
              .border({ width: 1, color: '#e2e8f0' })
              .shadow({ radius: 2, color: '#00000008', offsetY: 1 })
              .onClick(() => { this.appendDigit(d); })
          })
        }
      })
    }
    .width('100%')
  }

  // 步骤1：输入手机号
  @Builder
  buildStep1() {
    Column({ space: 6 }) {
      // 标题区（压缩字体和间距）
      Column({ space: 2 }) {
        Text('登录')
          .fontSize(this.largeFontEnabled ? 14 : 12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.highContrastEnabled ? '#000000' : '#1e293b')
        Text('输入手机号')
          .fontSize(8)
          .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      // 手机号显示框 + 删除键
      Row({ space: 3 }) {
        Text(this.phone.length > 0 ? this.phone : '请输入手机号')
          .fontSize(this.largeFontEnabled ? 13 : 11)
          .fontColor(this.phone.length > 0
            ? (this.highContrastEnabled ? '#000000' : '#1e293b')
            : '#94a3b8')
          .layoutWeight(1)
          .height(24)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
          .borderRadius(5)
          .border({ width: 1.5, color: this.highContrastEnabled ? '#000000' : '#3b82f6' })
          .shadow({ radius: 2, color: '#00000010', offsetY: 1 })
        Button('删除')
          .width(34)
          .height(24)
          .fontSize(9)
          .padding(0)
          .backgroundColor(this.highContrastEnabled ? '#000000' : '#f1f5f9')
          .fontColor(this.highContrastEnabled ? '#ffff00' : '#64748b')
          .borderRadius(5)
          .onClick(() => { this.deleteOne(); })
      }
      .width('100%')

      // 键盘
      this.buildKeypad()

      // 底部操作区：0、下一步
      Row({ space: 3 }) {
        Button('0')
          .layoutWeight(1)
          .height(24)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(this.highContrastEnabled ? '#000000' : '#ffffff')
          .fontColor(this.highContrastEnabled ? '#ffff00' : '#1e293b')
          .borderRadius(5)
          .border({ width: 1, color: '#e2e8f0' })
          .shadow({ radius: 2, color: '#00000008', offsetY: 1 })
          .onClick(() => { this.appendDigit('0'); })
        Button('下一步')
          .layoutWeight(2)
          .height(24)
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(this.phone.length === 11
            ? (this.highContrastEnabled ? '#000000' : '#3b82f6')
            : '#cbd5e1')
          .fontColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
          .borderRadius(5)
          .enabled(this.phone.length === 11)
          .shadow({ radius: 4, color: this.phone.length === 11 ? '#3b82f620' : '#00000000', offsetY: 2 })
          .onClick(() => { this.handleNext(); })
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 6 })
  }

  // 步骤2：输入验证码
  @Builder
  buildStep2() {
    Column({ space: 6 }) {
      // 标题区（压缩字体和间距）
      Column({ space: 2 }) {
        Text('验证码')
          .fontSize(this.largeFontEnabled ? 14 : 12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.highContrastEnabled ? '#000000' : '#1e293b')
        Text(this.phone)
          .fontSize(8)
          .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      // 验证码输入区：返回按钮 + 验证码显示框 + 删除键
      Row({ space: 3 }) {
        Button('返回')
          .width(30)
          .height(24)
          .fontSize(8)
          .padding(0)
          .backgroundColor(this.highContrastEnabled ? '#000000' : '#f1f5f9')
          .fontColor(this.highContrastEnabled ? '#ffff00' : '#64748b')
          .borderRadius(5)
          .onClick(() => {
            this.step = 1;
            this.code = '';
            if (this.countdownTimer !== -1) {
              clearInterval(this.countdownTimer);
              this.countdownTimer = -1;
            }
            this.countdown = 0;
          })
        Text(this.code.length > 0 ? this.code : '------')
          .fontSize(this.largeFontEnabled ? 14 : 12)
          .fontColor(this.code.length > 0
            ? (this.highContrastEnabled ? '#000000' : '#1e293b')
            : '#cbd5e1')
          .letterSpacing(2)
          .layoutWeight(1)
          .height(24)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
          .borderRadius(5)
          .border({ width: 1.5, color: this.highContrastEnabled ? '#000000' : '#3b82f6' })
          .shadow({ radius: 2, color: '#00000010', offsetY: 1 })
        Button('删除')
          .width(34)
          .height(24)
          .fontSize(9)
          .padding(0)
          .backgroundColor(this.highContrastEnabled ? '#000000' : '#f1f5f9')
          .fontColor(this.highContrastEnabled ? '#ffff00' : '#64748b')
          .borderRadius(5)
          .onClick(() => { this.deleteOne(); })
      }
      .width('100%')

      // 键盘
      this.buildKeypad()

      // 底部操作区：0、重发、登录
      Column({ space: 3 }) {
        // 第一行：0、重发
        Row({ space: 3 }) {
          Button('0')
            .layoutWeight(1)
            .height(24)
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .backgroundColor(this.highContrastEnabled ? '#000000' : '#ffffff')
            .fontColor(this.highContrastEnabled ? '#ffff00' : '#1e293b')
            .borderRadius(5)
            .border({ width: 1, color: '#e2e8f0' })
            .shadow({ radius: 2, color: '#00000008', offsetY: 1 })
            .onClick(() => { this.appendDigit('0'); })
          Button(this.countdown > 0 ? `${this.countdown}s` : '重发')
            .layoutWeight(1)
            .height(24)
            .fontSize(9)
            .backgroundColor(this.highContrastEnabled ? '#000000' : '#f1f5f9')
            .fontColor(this.highContrastEnabled ? '#ffff00' : '#64748b')
            .borderRadius(5)
            .enabled(this.countdown === 0)
            .onClick(() => { this.handleResend(); })
        }
        // 第二行：登录按钮
        Button(this.isLoading ? '登录中...' : '登录')
          .width('100%')
          .height(26)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(this.code.length >= 4 && !this.isLoading
            ? (this.highContrastEnabled ? '#000000' : '#3b82f6')
            : '#cbd5e1')
          .fontColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
          .borderRadius(5)
          .enabled(this.code.length >= 4 && !this.isLoading)
          .shadow({ radius: 4, color: this.code.length >= 4 ? '#3b82f620' : '#00000000', offsetY: 2 })
          .onClick(() => { this.handleLogin(); })
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 6 })
  }

  build() {
    Stack() {
      // 背景
      Circle()
        .width('100%')
        .height('100%')
        .fill(this.highContrastEnabled ? '#ffff00' : '#ffffff')

      // 内容区（圆形内切正方形，约70%宽度）
      Scroll() {
        if (this.step === 1) {
          this.buildStep1()
        } else {
          this.buildStep2()
        }
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#f0f4ff')
  }
}
