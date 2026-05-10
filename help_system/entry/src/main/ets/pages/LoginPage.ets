import router from '@ohos.router';
import pasteboard from '@ohos.pasteboard';
import { promptAction } from '@kit.ArkUI';
import { AuthService } from '../services/AuthService';
import { isWearableDevice } from '../utils/DeviceFormUtil';
import { extractVerificationCode, shouldShowMockMessage } from '../utils';
import type { LoginRequest, LoginResponse, SendVerificationCodeResponse } from '../models/Auth';

@Entry
@Component
struct LoginPage {
  @State phone: string = '';
  @State code: string = '';
  @State loginMode: 'sms' | 'password' = 'sms';
  @State showPassword: boolean = false;
  @State codeSent: boolean = false;
  @State countdown: number = 0;
  @State mockSmsVisible: boolean = false;
  @State mockSmsMessage: string = '';
  @State mockSmsCode: string = '';
  @State isLoading: boolean = false;
  @State formOpacity: number = 0;
  @State logoScale: number = 0.8;
  @State isWatchLayout: boolean = false;
  private countdownTimer: number = -1;
  private mockSmsTimer: number = -1;

  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  aboutToAppear() {
    this.isWatchLayout = isWearableDevice();
    if (this.isWatchLayout) {
      this.logoScale = 1.0;
      this.formOpacity = 1;
      return;
    }
    animateTo({
      duration: 600,
      curve: Curve.EaseOut
    }, () => {
      this.logoScale = 1.0;
      this.formOpacity = 1;
    });
  }

  aboutToDisappear() {
    if (this.countdownTimer !== -1) {
      clearInterval(this.countdownTimer);
    }
    if (this.mockSmsTimer !== -1) {
      clearTimeout(this.mockSmsTimer);
    }
  }

  private t(key: string): string {
    switch (key) {
      case 'welcome':
        return '欢迎使用互助帮扶';
      case 'subtitle':
        return '让爱心触手可及';
      case 'smsLogin':
        return '验证码登录';
      case 'passwordLogin':
        return '密码登录';
      case 'phone':
        return '手机号';
      case 'phonePlaceholder':
        return '请输入手机号';
      case 'code':
        return '验证码';
      case 'codePlaceholder':
        return '请输入验证码';
      case 'password':
        return '密码';
      case 'passwordPlaceholder':
        return '请输入密码';
      case 'show':
        return '显示';
      case 'hide':
        return '隐藏';
      case 'forgot':
        return '忘记密码?';
      case 'loggingIn':
        return '登录中...';
      case 'login':
        return '登录';
      case 'or':
        return '或';
      case 'register':
        return '注册新账号';
      case 'badPhone':
        return '请输入正确的手机号';
      case 'missing':
        return '请填写完整信息';
      case 'badCode':
        return '请输入6位验证码';
      case 'badPassword':
        return '请输入6位及以上密码';
      case 'sendCodeSuccess':
        return '验证码已发送';
      case 'sendCodeFail':
        return '发送验证码失败，请重试';
      case 'resend':
        return '重新发送';
      case 'getCode':
        return '获取验证码';
      case 'chooseRole':
        return '欢迎！请选择您的身份';
      case 'seekerHome':
        return '欢迎回来，求助者';
      case 'volunteerHome':
        return '欢迎回来，志愿者';
      case 'communityHome':
        return '欢迎回来，管理员';
      case 'routeFail':
        return '页面跳转失败';
      case 'loginFail':
        return '登录失败，请重试';
      case 'openRegisterFail':
        return '无法打开注册页';
      default:
        return '';
    }
  }

  private showToast(message: string, duration: number = 2000): void {
    promptAction.showToast({
      message: message,
      duration: duration
    });
  }

  private getCodeButtonText(): string {
    if (this.countdown > 0) {
      return `${this.countdown}秒`;
    }
    return this.codeSent ? this.t('resend') : this.t('getCode');
  }

  private hideMockSms(): void {
    this.mockSmsVisible = false;
    this.mockSmsMessage = '';
    this.mockSmsCode = '';
    if (this.mockSmsTimer !== -1) {
      clearTimeout(this.mockSmsTimer);
      this.mockSmsTimer = -1;
    }
  }

  private showMockSms(mockMessage?: string, debugCode?: string): void {
    if (!shouldShowMockMessage(mockMessage, debugCode)) {
      this.hideMockSms();
      return;
    }

    const code = extractVerificationCode(mockMessage, debugCode);
    this.mockSmsCode = code;
    this.mockSmsMessage = mockMessage && mockMessage.trim().length > 0
      ? mockMessage
      : `您的验证码是 ${code}，5 分钟内有效。`;
    this.mockSmsVisible = true;

    if (this.mockSmsTimer !== -1) {
      clearTimeout(this.mockSmsTimer);
    }
    this.mockSmsTimer = setTimeout(() => {
      this.hideMockSms();
    }, 8000);
  }

  private getMockSmsBody(): string {
    if (this.mockSmsCode) {
      return `您的验证码是 ${this.mockSmsCode}，5 分钟内有效。`;
    }
    return this.mockSmsMessage.replace('模拟短信：', '').trim();
  }

  private copyMockSmsCode(): void {
    if (!this.mockSmsCode) {
      this.showToast('暂无可复制的验证码');
      return;
    }
    const board = pasteboard.getSystemPasteboard();
    board.setDataSync(pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.mockSmsCode));
    this.showToast('验证码已复制');
    this.hideMockSms();
  }

  private navigateAfterLogin(response: LoginResponse): void {
    const user = response.user;
    const role = user.role;
    let targetUrl = 'pages/RoleSelectPage';
    let message = this.t('chooseRole');

    if (role === 'help-seeker') {
      targetUrl = 'pages/help-seeker/HelpSeekerHomePage';
      message = this.t('seekerHome');
    } else if (role === 'volunteer') {
      targetUrl = 'pages/volunteer/VolunteerHomePage';
      message = this.t('volunteerHome');
    } else if (role === 'community') {
      targetUrl = 'pages/community/CommunityHomePage';
      message = this.t('communityHome');
    }

    this.showToast(message);
    router.pushUrl({
      url: targetUrl,
      params: { user: user }
    }).catch((err: Error) => {
      this.showToast(`${this.t('routeFail')}: ${err.message}`);
    });
  }

  handleSendCode() {
    if (this.phone.length !== 11) {
      this.showToast(this.t('badPhone'));
      return;
    }

    AuthService.sendVerificationCode({
      phone: this.phone,
      type: 'login'
    }).then((response: SendVerificationCodeResponse) => {
      this.codeSent = true;
      this.countdown = response.cooldownSeconds > 0 ? response.cooldownSeconds : 60;
      this.showMockSms(response.mockMessage, response.debugCode);
      this.showToast(this.t('sendCodeSuccess'), 3000);

      if (this.countdownTimer !== -1) {
        clearInterval(this.countdownTimer);
      }
      this.countdownTimer = setInterval(() => {
        this.countdown--;
        if (this.countdown <= 0) {
          clearInterval(this.countdownTimer);
          this.countdown = 0;
        }
      }, 1000);
    }).catch((err: Error) => {
      this.showToast(err.message || this.t('sendCodeFail'));
    });
  }

  handleLogin() {
    if (!this.phone || !this.code) {
      this.showToast(this.t('missing'));
      return;
    }

    if (this.phone.length !== 11) {
      this.showToast(this.t('badPhone'));
      return;
    }

    if (this.loginMode === 'sms' && this.code.length !== 6) {
      this.showToast(this.t('badCode'));
      return;
    }

    if (this.loginMode === 'password' && this.code.length < 6) {
      this.showToast(this.t('badPassword'));
      return;
    }

    const loginRequest: LoginRequest = {
      phone: this.phone,
      password: this.code,
      verificationCode: this.loginMode === 'sms' ? this.code : undefined,
      loginType: this.loginMode
    };

    this.isLoading = true;
    AuthService.login(loginRequest).then((response: LoginResponse) => {
      this.isLoading = false;
      this.navigateAfterLogin(response);
    }).catch((err: Error) => {
      this.isLoading = false;
      this.showToast(err.message || this.t('loginFail'));
    });
  }

  formatPhoneInput(value: string): string {
    return value.replace(/\D/g, '').slice(0, 11);
  }

  formatCodeInput(value: string): string {
    return value.replace(/\D/g, '').slice(0, 6);
  }

  build() {
    Stack() {
      Column() {
        this.LoginContentColumn();
      }
      .width('100%')
      .height('100%')
      .linearGradient({
        angle: 135,
        colors: [[0xdbeafe, 0.0], [0xe0e7ff, 1.0]]
      })
      .padding(this.isWatchLayout ? 10 : 24)
      .justifyContent(this.isWatchLayout ? FlexAlign.Start : FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      if (this.mockSmsVisible && !this.isWatchLayout) {
        Column() {
          this.MockSmsFloatingBanner()
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 2 })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  MockSmsFloatingBanner() {
    Row({ space: 10 }) {
      Row() {
        Image($r('app.media.startIcon'))
          .width(18)
          .height(18)
          .borderRadius(5)
      }
      .width(30)
      .height(30)
      .backgroundColor('#dbeafe')
      .borderRadius(10)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      Column({ space: 2 }) {
        Row() {
          Text('互助帮扶服务')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111827')
          Blank()
          Text('刚刚')
            .fontSize(10)
            .fontColor('#94a3b8')
        }
        .width('100%')

        Text('短信')
          .fontSize(10)
          .fontColor('#64748b')

        Text(this.getMockSmsBody())
          .fontSize(12)
          .fontColor('#1f2937')
          .width('100%')
          .textAlign(TextAlign.Start)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: 8 }) {
          Button('复制验证码')
            .layoutWeight(1)
            .height(28)
            .fontSize(11)
            .backgroundColor('#f5f9ff')
            .fontColor('#2563eb')
            .borderRadius(14)
            .onClick(() => {
              this.copyMockSmsCode();
            })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('88%')
    .padding({ left: 12, right: 12, top: 12, bottom: 12 })
    .backgroundColor('#ffffff')
    .borderRadius(20)
    .shadow({ radius: 18, color: '#0f172a20', offsetX: 0, offsetY: 8 })
    .zIndex(99)
  }

  @Builder
  LoginContentColumn() {
    Column({ space: this.isWatchLayout ? 14 : 28 }) {
      Column({ space: 8 }) {
        Row() {
          Image($r('app.media.startIcon'))
            .width(this.isWatchLayout ? 38 : 64)
            .height(this.isWatchLayout ? 38 : 64)
            .borderRadius(this.isWatchLayout ? 10 : 18)
        }
        .width(this.isWatchLayout ? 50 : 84)
        .height(this.isWatchLayout ? 50 : 84)
        .linearGradient({
          angle: 135,
          colors: [[0x3b82f6, 0.0], [0x2563eb, 1.0]]
        })
        .borderRadius(this.isWatchLayout ? 14 : 22)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .scale({ x: this.logoScale, y: this.logoScale })
        .shadow({ radius: 18, color: '#3b82f640', offsetX: 0, offsetY: 6 })

        Text(this.t('welcome'))
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111827')

        Text(this.t('subtitle'))
          .fontSize(this.isWatchLayout ? 13 : 18)
          .fontColor('#64748b')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      Scroll() {
        Column({ space: this.isWatchLayout ? 14 : 20 }) {
          Row({ space: 8 }) {
            Button(this.t('smsLogin'))
              .layoutWeight(1)
              .height(this.isWatchLayout ? 36 : 46)
              .fontSize(this.largeFontEnabled ? 16 : 14)
              .fontWeight(FontWeight.Medium)
              .backgroundColor(this.loginMode === 'sms' ? '#3b82f6' : '#ececec')
              .fontColor(this.loginMode === 'sms' ? '#ffffff' : '#374151')
              .borderRadius(12)
              .shadow(this.loginMode === 'sms' ? { radius: 10, color: '#3b82f633', offsetX: 0, offsetY: 3 } : undefined)
              .onClick(() => {
                this.loginMode = 'sms';
                this.code = '';
                this.showPassword = false;
              })

            Button(this.t('passwordLogin'))
              .layoutWeight(1)
              .height(this.isWatchLayout ? 36 : 46)
              .fontSize(this.largeFontEnabled ? 16 : 14)
              .fontWeight(FontWeight.Medium)
              .backgroundColor(this.loginMode === 'password' ? '#3b82f6' : '#ececec')
              .fontColor(this.loginMode === 'password' ? '#ffffff' : '#374151')
              .borderRadius(12)
              .shadow(this.loginMode === 'password' ? { radius: 10, color: '#3b82f633', offsetX: 0, offsetY: 3 } : undefined)
              .onClick(() => {
                this.loginMode = 'password';
                this.code = '';
              })
          }
          .padding(6)
          .backgroundColor('#f3f4f6')
          .borderRadius(14)

          Column({ space: 8 }) {
            Text(this.t('phone'))
              .fontSize(14)
              .fontColor('#111827')
              .alignSelf(ItemAlign.Start)

            TextInput({ placeholder: this.t('phonePlaceholder'), text: this.phone })
              .height(this.isWatchLayout ? 42 : 52)
              .fontSize(this.largeFontEnabled ? 18 : 16)
              .type(InputType.PhoneNumber)
              .maxLength(11)
              .onChange((value: string) => {
                this.phone = this.formatPhoneInput(value);
              })
              .borderRadius(12)
              .backgroundColor('#f8fafc')
              .fontColor('#111827')
              .border({ width: 1, color: '#d1d5db', radius: 12 })
              .padding({ left: 14, right: 14 })
          }

          Column({ space: 8 }) {
            Text(this.loginMode === 'sms' ? this.t('code') : this.t('password'))
              .fontSize(14)
              .fontColor('#111827')
              .alignSelf(ItemAlign.Start)

            if (this.loginMode === 'sms') {
              Row({ space: 10 }) {
                TextInput({ placeholder: this.t('codePlaceholder'), text: this.code })
                  .layoutWeight(1)
                  .height(this.isWatchLayout ? 42 : 52)
                  .fontSize(this.largeFontEnabled ? 18 : 16)
                  .type(InputType.Number)
                  .maxLength(6)
                  .onChange((value: string) => {
                    this.code = this.formatCodeInput(value);
                  })
                  .borderRadius(12)
                  .backgroundColor('#f8fafc')
                  .fontColor('#111827')
                  .border({ width: 1, color: '#d1d5db', radius: 12 })
                  .padding({ left: 14, right: 14 })

                Button(this.getCodeButtonText())
                  .height(this.isWatchLayout ? 42 : 52)
                  .fontSize(13)
                  .backgroundColor(this.phone.length === 11 && this.countdown === 0 ? '#e8efff' : '#eef2f7')
                  .fontColor(this.phone.length === 11 && this.countdown === 0 ? '#2563eb' : '#9ca3af')
                  .borderRadius(12)
                  .enabled(this.phone.length === 11 && this.countdown === 0)
                  .onClick(() => {
                    this.handleSendCode();
                  })
              }
            } else {
              Row({ space: 8 }) {
                TextInput({ placeholder: this.t('passwordPlaceholder'), text: this.code })
                  .layoutWeight(1)
                  .height(this.isWatchLayout ? 42 : 52)
                  .fontSize(this.largeFontEnabled ? 18 : 16)
                  .type(this.showPassword ? InputType.Normal : InputType.Password)
                  .maxLength(20)
                  .onChange((value: string) => {
                    this.code = value;
                  })
                  .borderRadius(12)
                  .backgroundColor('#f8fafc')
                  .fontColor('#111827')
                  .border({ width: 1, color: '#d1d5db', radius: 12 })
                  .padding({ left: 14, right: 14 })

                Button(this.showPassword ? this.t('hide') : this.t('show'))
                  .height(this.isWatchLayout ? 42 : 52)
                  .fontSize(12)
                  .backgroundColor('#eef2f7')
                  .fontColor('#64748b')
                  .borderRadius(12)
                  .onClick(() => {
                    this.showPassword = !this.showPassword;
                  })
              }
            }
          }

          if (this.loginMode === 'password') {
            Row() {
              Blank()
              Text(this.t('forgot'))
                .fontSize(13)
                .fontColor('#2563eb')
            }
            .width('100%')
          }

          Button(this.isLoading ? this.t('loggingIn') : this.t('login'))
            .width('100%')
            .height(this.isWatchLayout ? 44 : 56)
            .fontSize(this.isWatchLayout ? 18 : 22)
            .fontWeight(FontWeight.Medium)
            .fontColor('#ffffff')
            .backgroundColor(this.phone.length === 11 && this.code.length > 0 && !this.isLoading ? '#3b82f6' : '#a5b4c7')
            .borderRadius(14)
            .shadow({ radius: 14, color: '#3b82f640', offsetX: 0, offsetY: 6 })
            .enabled(this.phone.length === 11 && this.code.length > 0 && !this.isLoading)
            .onClick(() => {
              this.handleLogin();
            })

          Row() {
            Divider().layoutWeight(1).color('#d1d5db')
            Text(this.t('or'))
              .fontSize(14)
              .fontColor('#6b7280')
              .margin({ left: 14, right: 14 })
            Divider().layoutWeight(1).color('#d1d5db')
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Button(this.t('register'))
            .width('100%')
            .height(this.isWatchLayout ? 42 : 54)
            .fontSize(this.isWatchLayout ? 17 : 20)
            .fontColor('#2563eb')
            .backgroundColor('#ffffff')
            .borderRadius(14)
            .border({ width: 2, color: '#3b82f6', radius: 14 })
            .onClick(() => {
              router.pushUrl({
                url: 'pages/RegisterPage'
              }).catch((err: Error) => {
                this.showToast(err.message || this.t('openRegisterFail'));
              });
            })
        }
        .width('100%')
        .padding(this.isWatchLayout ? 14 : 26)
        .backgroundColor('#f8fafc')
        .borderRadius(this.isWatchLayout ? 18 : 28)
        .shadow({ radius: 28, color: '#0f172a1a', offsetX: 0, offsetY: 10 })
        .opacity(this.formOpacity)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.TopStart)
    }
    .width('100%')
    .constraintSize({ maxWidth: 420 })
    .padding({ top: this.isWatchLayout ? 0 : 16, bottom: this.isWatchLayout ? 12 : 24 })
  }
}
