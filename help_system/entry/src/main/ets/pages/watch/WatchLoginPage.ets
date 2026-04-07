import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { AuthService } from '../../services/AuthService';
import { StorageUtil } from '../../utils/StorageUtil';
import type { LoginRequest, LoginResponse } from '../../models/Auth';
import { WatchButton } from '../../components/WatchButton';

/**
 * 手表专用登录：仅已有账号短信登录，不承载注册/选角（与手机 LoginPage 隔离）�?
 */
@Entry
@Component
struct WatchLoginPage {
  @State activeField: 'phone' | 'code' = 'phone';
  @State phone: string = '';
  @State code: string = '';
  @State codeSent: boolean = false;
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
    const user = this.loginUserData.user;
    const role: string | undefined = user.role as string | undefined;

    promptAction.showToast({
      message: '登录成功',
      duration: 1500
    });

    if (!role) {
      router.replaceUrl({
        url: 'pages/watch/WatchAccountUnsupportedPage',
        params: { reason: 'no-role' }
      }).catch((err: Error) => {
        console.error('nav unsupported failed:', err);
      });
      return;
    }

    if (role === 'help-seeker') {
      router.replaceUrl({ url: 'pages/watch/WatchSeekerHomePage' }).catch((err: Error) => {
        console.error('nav seeker home failed:', err);
      });
      return;
    }
    if (role === 'volunteer') {
      router.replaceUrl({ url: 'pages/watch/WatchVolunteerHomePage' }).catch((err: Error) => {
        console.error('nav volunteer home failed:', err);
      });
      return;
    }
    if (role === 'community') {
      router.replaceUrl({
        url: 'pages/watch/WatchAccountUnsupportedPage',
        params: { reason: 'community' }
      }).catch((err: Error) => {
        console.error('nav unsupported failed:', err);
      });
      return;
    }

    router.replaceUrl({
      url: 'pages/watch/WatchAccountUnsupportedPage',
      params: { reason: 'no-role' }
    }).catch((err: Error) => {
      console.error('nav unsupported failed:', err);
    });
  }

  private handleSendCode(): void {
    if (this.phone.length !== 11) {
      promptAction.showToast({ message: '请输入正确的手机号', duration: 2000 });
      return;
    }
    AuthService.sendVerificationCode({ phone: this.phone, type: 'login' }).then((success: boolean) => {
      if (success) {
        this.codeSent = true;
        this.countdown = 60;
        promptAction.showToast({
          message: '验证码已发送（测试环境请使用：123456）',
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
      } else {
        promptAction.showToast({ message: '发送验证码失败，请重试', duration: 2000 });
      }
    }).catch((err: Error) => {
      promptAction.showToast({ message: err.message || '发送失败', duration: 2000 });
    });
  }

  private handleLogin(): void {
    if (!this.phone || !this.code) {
      promptAction.showToast({ message: '请填写完整信息', duration: 2000 });
      return;
    }
    if (this.phone.length !== 11) {
      promptAction.showToast({ message: '请输入正确的手机号', duration: 2000 });
      return;
    }
    if (this.code.length < 4) {
      promptAction.showToast({ message: '请输入正确的验证码', duration: 2000 });
      return;
    }

    this.isLoading = true;
    const loginRequest: LoginRequest = {
      phone: this.phone,
      password: this.code,
      verificationCode: this.code,
      loginType: 'sms'
    };

    AuthService.login(loginRequest).then((response: LoginResponse) => {
      this.isLoading = false;
      this.loginUserData = response;
      this.loginSuccessful = true;
    }).catch((err: Error) => {
      this.isLoading = false;
      promptAction.showToast({ message: err.message || '登录失败', duration: 2000 });
    });
  }

  private formatPhoneInput(value: string): string {
    return value.replace(/\D/g, '').slice(0, 11);
  }

  private formatCodeInput(value: string): string {
    return value.replace(/\D/g, '').slice(0, 6);
  }

  private appendDigit(digit: string): void {
    if (this.activeField === 'phone') {
      if (this.phone.length >= 11) {
        return;
      }
      this.phone = this.phone + digit;
      return;
    }
    if (this.code.length >= 6) {
      return;
    }
    this.code = this.code + digit;
  }

  private deleteOne(): void {
    if (this.activeField === 'phone') {
      if (this.phone.length === 0) {
        return;
      }
      this.phone = this.phone.substring(0, this.phone.length - 1);
      return;
    }
    if (this.code.length === 0) {
      return;
    }
    this.code = this.code.substring(0, this.code.length - 1);
  }

  private clearActiveField(): void {
    if (this.activeField === 'phone') {
      this.phone = '';
      return;
    }
    this.code = '';
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 10 }) {
          Text('登录')
            .fontSize(this.largeFontEnabled ? 16 : 14)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.highContrastEnabled ? '#000000' : '#0f172a')
            .width('100%')
            .textAlign(TextAlign.Center)

          Text('请使用已在手机端注册的账号')
            .fontSize(10)
            .fontColor(this.highContrastEnabled ? '#000000' : '#475569')
            .width('100%')
            .textAlign(TextAlign.Center)

          Column({ space: 6 }) {
            Text('手机号')
              .fontSize(12)
              .fontColor(this.highContrastEnabled ? '#000000' : '#334155')
              .alignSelf(ItemAlign.Start)
            TextInput({ text: this.phone, placeholder: '请输入手机号' })
              .height(32)
              .maxLength(11)
              .type(InputType.PhoneNumber)
              .fontSize(14)
              .fontColor(this.highContrastEnabled ? '#000000' : '#0f172a')
              .placeholderColor('#94a3b8')
              .onChange((v: string) => {
                this.phone = this.formatPhoneInput(v);
              })
              .onFocus(() => {
                this.activeField = 'phone';
              })
              .borderRadius(12)
              .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
              .border(this.highContrastEnabled
                ? { width: 2, color: '#000000' }
                : { width: this.activeField === 'phone' ? 2 : 1, color: this.activeField === 'phone' ? '#2563eb' : '#cbd5e1' })
          }
          .width('100%')
          .onClick(() => {
            this.activeField = 'phone';
          })

          Column({ space: 6 }) {
            Text('验证码')
              .fontSize(12)
              .fontColor(this.highContrastEnabled ? '#000000' : '#334155')
              .alignSelf(ItemAlign.Start)
            Row({ space: 8 }) {
              TextInput({ text: this.code, placeholder: '验证码' })
                .layoutWeight(1)
                .height(32)
                .maxLength(6)
                .type(InputType.Number)
                .fontSize(14)
                .fontColor(this.highContrastEnabled ? '#000000' : '#0f172a')
                .placeholderColor('#94a3b8')
                .onChange((v: string) => {
                  this.code = this.formatCodeInput(v);
                })
                .onFocus(() => {
                  this.activeField = 'code';
                })
                .borderRadius(12)
                .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
                .border(this.highContrastEnabled
                  ? { width: 2, color: '#000000' }
                  : { width: this.activeField === 'code' ? 2 : 1, color: this.activeField === 'code' ? '#2563eb' : '#cbd5e1' })
              WatchButton({
                text: this.countdown > 0 ? `${this.countdown}秒` : '获取验证码',
                buttonType: 'secondary',
                buttonSize: 'small',
                buttonEnabled: this.phone.length === 11 && this.countdown === 0
              })
              .onClick(() => {
                this.handleSendCode();
              })
            }
          }
          .width('100%')
          .onClick(() => {
            this.activeField = 'code';
          })

          Column({ space: 4 }) {
            Row({ space: 4 }) {
              Button('1').layoutWeight(1).height(28).onClick(() => { this.appendDigit('1'); })
              Button('2').layoutWeight(1).height(28).onClick(() => { this.appendDigit('2'); })
              Button('3').layoutWeight(1).height(28).onClick(() => { this.appendDigit('3'); })
            }
            Row({ space: 4 }) {
              Button('4').layoutWeight(1).height(28).onClick(() => { this.appendDigit('4'); })
              Button('5').layoutWeight(1).height(28).onClick(() => { this.appendDigit('5'); })
              Button('6').layoutWeight(1).height(28).onClick(() => { this.appendDigit('6'); })
            }
            Row({ space: 4 }) {
              Button('7').layoutWeight(1).height(28).onClick(() => { this.appendDigit('7'); })
              Button('8').layoutWeight(1).height(28).onClick(() => { this.appendDigit('8'); })
              Button('9').layoutWeight(1).height(28).onClick(() => { this.appendDigit('9'); })
            }
            Row({ space: 4 }) {
              Button('清空')
                .layoutWeight(1)
                .height(28)
                .fontSize(12)
                .backgroundColor('#e2e8f0')
                .fontColor('#334155')
                .onClick(() => { this.clearActiveField(); })
              Button('0').layoutWeight(1).height(28).onClick(() => { this.appendDigit('0'); })
              Button('删除')
                .layoutWeight(1)
                .height(28)
                .fontSize(12)
                .backgroundColor('#e2e8f0')
                .fontColor('#334155')
                .onClick(() => { this.deleteOne(); })
            }
          }
          .width('100%')

          WatchButton({
            text: this.isLoading ? '登录中...' : '登录',
            buttonType: 'primary',
            buttonSize: 'medium',
            buttonWidth: '100%',
            buttonEnabled: this.phone.length === 11 && this.code.length > 0 && !this.isLoading
          })
          .onClick(() => {
            this.handleLogin();
          })
        }
        .width('100%')
        .padding(12)
        .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
        .borderRadius(14)
        .border(this.highContrastEnabled ?
          { width: 2, color: '#000000' } :
          { width: 1, color: '#e2e8f0' })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.TopStart)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f8fafc')
    .padding({ left: 12, right: 12, top: 30, bottom: 30 })
  }
}
