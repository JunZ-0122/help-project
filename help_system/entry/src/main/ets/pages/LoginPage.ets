import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { AuthService } from '../services/AuthService';
import { isWearableDevice } from '../utils/DeviceFormUtil';
import type { LoginRequest, LoginResponse } from '../models/Auth';

@Entry
@Component
struct LoginPage {
  @State phone: string = '';
  @State code: string = '';
  @State loginMode: 'sms' | 'password' = 'sms';
  @State showPassword: boolean = false;
  @State codeSent: boolean = false;
  @State countdown: number = 0;
  @State isLoading: boolean = false;
  @State formOpacity: number = 0;
  @State logoScale: number = 0.8;
  @State isWatchLayout: boolean = false;
  private countdownTimer: number = -1;

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
  }

  private t(key: string): string {
    switch (key) {
      case 'welcome':
        return '\u6b22\u8fce\u4f7f\u7528\u4e92\u52a9\u5e2e\u6276';
      case 'subtitle':
        return '\u8ba9\u7231\u5fc3\u89e6\u624b\u53ef\u53ca';
      case 'smsLogin':
        return '\u9a8c\u8bc1\u7801\u767b\u5f55';
      case 'passwordLogin':
        return '\u5bc6\u7801\u767b\u5f55';
      case 'phone':
        return '\u624b\u673a\u53f7';
      case 'phonePlaceholder':
        return '\u8bf7\u8f93\u5165\u624b\u673a\u53f7';
      case 'code':
        return '\u9a8c\u8bc1\u7801';
      case 'codePlaceholder':
        return '\u8bf7\u8f93\u5165\u9a8c\u8bc1\u7801';
      case 'password':
        return '\u5bc6\u7801';
      case 'passwordPlaceholder':
        return '\u8bf7\u8f93\u5165\u5bc6\u7801';
      case 'show':
        return '\u663e\u793a';
      case 'hide':
        return '\u9690\u85cf';
      case 'forgot':
        return '\u5fd8\u8bb0\u5bc6\u7801?';
      case 'loggingIn':
        return '\u767b\u5f55\u4e2d...';
      case 'login':
        return '\u767b\u5f55';
      case 'or':
        return '\u6216';
      case 'register':
        return '\u6ce8\u518c\u65b0\u8d26\u53f7';
      case 'badPhone':
        return '\u8bf7\u8f93\u5165\u6b63\u786e\u7684\u624b\u673a\u53f7';
      case 'missing':
        return '\u8bf7\u586b\u5199\u5b8c\u6574\u4fe1\u606f';
      case 'badCode':
        return '\u8bf7\u8f93\u5165\u6b63\u786e\u7684\u9a8c\u8bc1\u7801';
      case 'badPassword':
        return '\u8bf7\u8f93\u51656\u4f4d\u53ca\u4ee5\u4e0a\u5bc6\u7801';
      case 'sendCodeSuccess':
        return '\u9a8c\u8bc1\u7801\u5df2\u53d1\u9001\uff08\u6d4b\u8bd5\u73af\u5883\u53ef\u4f7f\u7528123456\uff09';
      case 'sendCodeFail':
        return '\u53d1\u9001\u9a8c\u8bc1\u7801\u5931\u8d25\uff0c\u8bf7\u91cd\u8bd5';
      case 'resend':
        return '\u91cd\u65b0\u53d1\u9001';
      case 'getCode':
        return '\u83b7\u53d6\u9a8c\u8bc1\u7801';
      case 'chooseRole':
        return '\u6b22\u8fce\uff01\u8bf7\u9009\u62e9\u60a8\u7684\u8eab\u4efd';
      case 'seekerHome':
        return '\u6b22\u8fce\u56de\u6765\uff0c\u6c42\u52a9\u8005';
      case 'volunteerHome':
        return '\u6b22\u8fce\u56de\u6765\uff0c\u5fd7\u613f\u8005';
      case 'communityHome':
        return '\u6b22\u8fce\u56de\u6765\uff0c\u7ba1\u7406\u5458';
      case 'routeFail':
        return '\u9875\u9762\u8df3\u8f6c\u5931\u8d25';
      case 'loginFail':
        return '\u767b\u5f55\u5931\u8d25\uff0c\u8bf7\u91cd\u8bd5';
      case 'openRegisterFail':
        return '\u65e0\u6cd5\u6253\u5f00\u6ce8\u518c\u9875';
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
      return `${this.countdown}\u79d2`;
    }
    return this.codeSent ? this.t('resend') : this.t('getCode');
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
      params: {
        user: user
      }
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
    }).then((success: boolean) => {
      if (!success) {
        this.showToast(this.t('sendCodeFail'));
        return;
      }

      this.codeSent = true;
      this.countdown = 60;
      this.showToast(this.t('sendCodeSuccess'), 3000);

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

    if (this.loginMode === 'sms' && this.code.length < 4) {
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
