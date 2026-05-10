import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { AuthService } from '../../services/AuthService';
import { extractVerificationCode } from '../../utils';
import type { LoginRequest, LoginResponse, SendVerificationCodeResponse } from '../../models/Auth';

@Entry
@Component
struct WatchLoginPage {
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
    if (!this.loginSuccessful || !this.loginUserData) {
      return;
    }
    const role = this.loginUserData.user.role as string | undefined;
    promptAction.showToast({ message: '登录成功', duration: 1500 });

    if (role === 'help-seeker') {
      router.replaceUrl({ url: 'pages/watch/WatchSeekerHomePage' }).catch(() => {});
    } else if (role === 'volunteer') {
      router.replaceUrl({ url: 'pages/watch/WatchVolunteerHomePage' }).catch(() => {});
    } else {
      router.replaceUrl({
        url: 'pages/watch/WatchAccountUnsupportedPage',
        params: { reason: role ? 'community' : 'no-role' }
      }).catch(() => {});
    }
  }

  private appendDigit(digit: string): void {
    if (this.step === 1) {
      if (this.phone.length < 11) {
        this.phone += digit;
      }
      return;
    }
    if (this.code.length < 6) {
      this.code += digit;
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
      promptAction.showToast({ message: '请输入 11 位手机号', duration: 2000 });
      return;
    }
    AuthService.sendVerificationCode({ phone: this.phone, type: 'login' }).then((response: SendVerificationCodeResponse) => {
      this.step = 2;
      this.countdown = response.cooldownSeconds > 0 ? response.cooldownSeconds : 60;
      const code = extractVerificationCode(response.mockMessage, response.debugCode);
      promptAction.showToast({
        message: code ? `模拟短信验证码：${code}` : '验证码已发送',
        duration: 3000
      });
      this.countdownTimer = setInterval(() => {
        this.countdown--;
        if (this.countdown <= 0) {
          clearInterval(this.countdownTimer);
          this.countdownTimer = -1;
          this.countdown = 0;
        }
      }, 1000);
    }).catch((e: Error) => {
      promptAction.showToast({ message: e.message || '发送失败', duration: 2000 });
    });
  }

  private handleResend(): void {
    if (this.countdown > 0) {
      return;
    }
    this.handleNext();
  }

  private getStepLabel(): string {
    return this.step === 1 ? '1/2 输入手机号' : '2/2 验证码登录';
  }

  private getStepHint(): string {
    return this.step === 1 ? '请先输入 11 位手机号' : '验证码发送后请输入 6 位数字';
  }

  private handleLogin(): void {
    if (this.code.length !== 6) {
      promptAction.showToast({ message: '请输入 6 位验证码', duration: 2000 });
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

  @Builder
  buildKeypad() {
    Column({ space: 2 }) {
      ForEach(['1,2,3', '4,5,6', '7,8,9'], (row: string) => {
        Row({ space: 2 }) {
          ForEach(row.split(','), (digit: string) => {
            Button(digit)
              .layoutWeight(1)
              .height(22)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .backgroundColor(this.highContrastEnabled ? '#000000' : '#ffffff')
              .fontColor(this.highContrastEnabled ? '#ffff00' : '#1e293b')
              .borderRadius(5)
              .border({ width: 1, color: '#e2e8f0' })
              .shadow({ radius: 2, color: '#00000008', offsetY: 1 })
              .onClick(() => {
                this.appendDigit(digit);
              })
          })
        }
      })
    }
    .width('100%')
  }

  @Builder
  buildStep1() {
    Column({ space: 6 }) {
      Column({ space: 2 }) {
        Text(this.getStepLabel())
          .fontSize(this.largeFontEnabled ? 14 : 12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.highContrastEnabled ? '#000000' : '#1e293b')
        Text(this.getStepHint())
          .fontSize(8)
          .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

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
        Button('删除')
          .width(34)
          .height(24)
          .fontSize(9)
          .padding(0)
          .backgroundColor(this.highContrastEnabled ? '#000000' : '#f1f5f9')
          .fontColor(this.highContrastEnabled ? '#ffff00' : '#64748b')
          .borderRadius(5)
          .onClick(() => {
            this.deleteOne();
          })
      }
      .width('100%')

      this.buildKeypad()

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
          .onClick(() => {
            this.appendDigit('0');
          })

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
          .onClick(() => {
            this.handleNext();
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 6 })
  }

  @Builder
  buildStep2() {
    Column({ space: 6 }) {
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
        Button('删除')
          .width(34)
          .height(24)
          .fontSize(9)
          .padding(0)
          .backgroundColor(this.highContrastEnabled ? '#000000' : '#f1f5f9')
          .fontColor(this.highContrastEnabled ? '#ffff00' : '#64748b')
          .borderRadius(5)
          .onClick(() => {
            this.deleteOne();
          })
      }
      .width('100%')

      this.buildKeypad()

      Column({ space: 3 }) {
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
            .onClick(() => {
              this.appendDigit('0');
            })
          Button(this.countdown > 0 ? `${this.countdown}s` : '重发')
            .layoutWeight(1)
            .height(24)
            .fontSize(9)
            .backgroundColor(this.highContrastEnabled ? '#000000' : '#f1f5f9')
            .fontColor(this.highContrastEnabled ? '#ffff00' : '#64748b')
            .borderRadius(5)
            .enabled(this.countdown === 0)
            .onClick(() => {
              this.handleResend();
            })
        }
        Button(this.isLoading ? '登录中...' : '登录')
          .width('100%')
          .height(28)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(this.code.length === 6 && !this.isLoading
            ? (this.highContrastEnabled ? '#000000' : '#3b82f6')
            : '#cbd5e1')
          .fontColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
          .borderRadius(5)
          .enabled(this.code.length === 6 && !this.isLoading)
          .onClick(() => {
            this.handleLogin();
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 6 })
  }

  build() {
    Stack() {
      Circle()
        .width('100%')
        .height('100%')
        .fill(this.highContrastEnabled ? '#ffff00' : '#ffffff')

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
