import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../components/NavBackButton';
import { AuthService } from '../services/AuthService';
import { isWearableDevice } from '../utils/DeviceFormUtil';
import type { LoginResponse, RegisterRequest } from '../models/Auth';

@Entry
@Component
struct RegisterPage {
  @State name: string = '';
  @State phone: string = '';
  @State verificationCode: string = '';
  @State password: string = '';
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
      case 'title':
        return '\u521b\u5efa\u60a8\u7684\u8d26\u53f7';
      case 'subtitle':
        return '\u5148\u5b8c\u6210\u6ce8\u518c\uff0c\u518d\u9009\u62e9\u60a8\u7684\u8eab\u4efd';
      case 'name':
        return '\u59d3\u540d';
      case 'namePlaceholder':
        return '\u8bf7\u8f93\u5165\u60a8\u7684\u59d3\u540d';
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
      case 'registering':
        return '\u6ce8\u518c\u4e2d...';
      case 'register':
        return '\u6ce8\u518c';
      case 'or':
        return '\u6216';
      case 'back':
        return '\u8fd4\u56de\u767b\u5f55';
      case 'guide':
        return '\u6ce8\u518c\u540e\u5c06\u5148\u8fdb\u5165\u8eab\u4efd\u9009\u62e9\u9875\u9762';
      case 'codeSent':
        return '\u9a8c\u8bc1\u7801\u5df2\u53d1\u9001\uff0c\u8bf7\u6ce8\u610f\u67e5\u6536';
      case 'sendCodeFail':
        return '\u9a8c\u8bc1\u7801\u53d1\u9001\u5931\u8d25\uff0c\u8bf7\u91cd\u8bd5';
      case 'badPhone':
        return '\u8bf7\u8f93\u5165\u6b63\u786e\u7684\u624b\u673a\u53f7';
      case 'missing':
        return '\u8bf7\u586b\u5199\u5b8c\u6574\u4fe1\u606f';
      case 'badCode':
        return '\u8bf7\u8f93\u5165\u6b63\u786e\u7684\u9a8c\u8bc1\u7801';
      case 'badPassword':
        return '\u8bf7\u8f93\u51656\u4f4d\u53ca\u4ee5\u4e0a\u5bc6\u7801';
      case 'registerSuccess':
        return '\u6ce8\u518c\u6210\u529f';
      case 'registerAndChooseRole':
        return '\u6ce8\u518c\u6210\u529f\uff0c\u8bf7\u5148\u9009\u62e9\u8eab\u4efd';
      case 'openRoleSelectFail':
        return '\u65e0\u6cd5\u6253\u5f00\u89d2\u8272\u9009\u62e9\u9875';
      case 'openHomeFail':
        return '\u65e0\u6cd5\u6253\u5f00\u9996\u9875';
      case 'registerFail':
        return '\u6ce8\u518c\u5931\u8d25\uff0c\u8bf7\u91cd\u8bd5';
      case 'resend':
        return '\u91cd\u65b0\u53d1\u9001';
      case 'getCode':
        return '\u83b7\u53d6\u9a8c\u8bc1\u7801';
      default:
        return '';
    }
  }

  private showToast(message: string): void {
    promptAction.showToast({
      message: message,
      duration: 2000
    });
  }

  private getCodeButtonText(): string {
    if (this.countdown > 0) {
      return `${this.countdown}\u79d2`;
    }
    return this.codeSent ? this.t('resend') : this.t('getCode');
  }

  private navigateAfterRegister(response: LoginResponse): void {
    const role = response.user.role;
    if (!role || role === 'default') {
      this.showToast(this.t('registerAndChooseRole'));
      router.replaceUrl({
        url: 'pages/RoleSelectPage',
        params: {
          user: response.user
        }
      }).catch((err: Error) => {
        this.showToast(err.message || this.t('openRoleSelectFail'));
      });
      return;
    }

    let targetUrl = 'pages/RoleSelectPage';
    if (role === 'help-seeker') {
      targetUrl = 'pages/help-seeker/HelpSeekerHomePage';
    } else if (role === 'volunteer') {
      targetUrl = 'pages/volunteer/VolunteerHomePage';
    } else if (role === 'community') {
      targetUrl = 'pages/community/CommunityHomePage';
    }

    this.showToast(this.t('registerSuccess'));
    router.replaceUrl({
      url: targetUrl,
      params: {
        user: response.user
      }
    }).catch((err: Error) => {
      this.showToast(err.message || this.t('openHomeFail'));
    });
  }

  handleSendCode() {
    if (this.phone.length !== 11) {
      this.showToast(this.t('badPhone'));
      return;
    }

    AuthService.sendVerificationCode({
      phone: this.phone,
      type: 'register'
    }).then((success: boolean) => {
      if (!success) {
        this.showToast(this.t('sendCodeFail'));
        return;
      }

      this.codeSent = true;
      this.countdown = 60;
      this.showToast(this.t('codeSent'));

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

  handleRegister() {
    if (!this.name.trim() || !this.phone || !this.verificationCode || !this.password) {
      this.showToast(this.t('missing'));
      return;
    }

    if (this.phone.length !== 11) {
      this.showToast(this.t('badPhone'));
      return;
    }

    if (this.verificationCode.length < 4) {
      this.showToast(this.t('badCode'));
      return;
    }

    if (this.password.length < 6) {
      this.showToast(this.t('badPassword'));
      return;
    }

    const request: RegisterRequest = {
      name: this.name.trim(),
      phone: this.phone,
      verificationCode: this.verificationCode,
      password: this.password,
      role: 'default'
    };

    this.isLoading = true;
    AuthService.register(request).then((response: LoginResponse) => {
      this.isLoading = false;
      this.navigateAfterRegister(response);
    }).catch((err: Error) => {
      this.isLoading = false;
      this.showToast(err.message || this.t('registerFail'));
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
      this.RegisterContentColumn();
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
  RegisterContentColumn() {
    Column({ space: this.isWatchLayout ? 14 : 24 }) {
      Row() {
        NavBackButton()
        Blank()
      }
      .width('100%')
      .constraintSize({ maxWidth: 420 })

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

          Text(this.t('title'))
            .fontSize(this.isWatchLayout ? 26 : 28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111827')

          Text(this.t('subtitle'))
            .fontSize(this.isWatchLayout ? 13 : 18)
            .fontColor('#64748b')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)

        Scroll() {
          Column({ space: this.isWatchLayout ? 14 : 18 }) {
          Column({ space: 8 }) {
            Text(this.t('name'))
              .fontSize(14)
              .fontColor('#111827')
              .alignSelf(ItemAlign.Start)

            TextInput({ placeholder: this.t('namePlaceholder'), text: this.name })
              .height(this.isWatchLayout ? 42 : 52)
              .fontSize(this.largeFontEnabled ? 18 : 16)
              .maxLength(20)
              .onChange((value: string) => {
                this.name = value;
              })
              .borderRadius(12)
              .backgroundColor('#f8fafc')
              .fontColor('#111827')
              .border({ width: 1, color: '#d1d5db', radius: 12 })
              .padding({ left: 14, right: 14 })
          }

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
            Text(this.t('code'))
              .fontSize(14)
              .fontColor('#111827')
              .alignSelf(ItemAlign.Start)

            Row({ space: 10 }) {
              TextInput({ placeholder: this.t('codePlaceholder'), text: this.verificationCode })
                .layoutWeight(1)
                .height(this.isWatchLayout ? 42 : 52)
                .fontSize(this.largeFontEnabled ? 18 : 16)
                .type(InputType.Number)
                .maxLength(6)
                .onChange((value: string) => {
                  this.verificationCode = this.formatCodeInput(value);
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
          }

          Column({ space: 8 }) {
            Text(this.t('password'))
              .fontSize(14)
              .fontColor('#111827')
              .alignSelf(ItemAlign.Start)

            Row({ space: 8 }) {
              TextInput({ placeholder: this.t('passwordPlaceholder'), text: this.password })
                .layoutWeight(1)
                .height(this.isWatchLayout ? 42 : 52)
                .fontSize(this.largeFontEnabled ? 18 : 16)
                .type(this.showPassword ? InputType.Normal : InputType.Password)
                .maxLength(20)
                .onChange((value: string) => {
                  this.password = value;
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

          Text(this.t('guide'))
            .width('100%')
            .fontSize(12)
            .fontColor('#64748b')
            .textAlign(TextAlign.Start)

          Button(this.isLoading ? this.t('registering') : this.t('register'))
            .width('100%')
            .height(this.isWatchLayout ? 44 : 56)
            .fontSize(this.isWatchLayout ? 18 : 22)
            .fontWeight(FontWeight.Medium)
            .fontColor('#ffffff')
            .backgroundColor(this.name.trim().length > 0 && this.phone.length === 11 &&
              this.verificationCode.length > 0 && this.password.length >= 6 && !this.isLoading ? '#3b82f6' : '#a5b4c7')
            .borderRadius(14)
            .shadow({ radius: 14, color: '#3b82f640', offsetX: 0, offsetY: 6 })
            .enabled(this.name.trim().length > 0 && this.phone.length === 11 &&
              this.verificationCode.length > 0 && this.password.length >= 6 && !this.isLoading)
            .onClick(() => {
              this.handleRegister();
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

          Button(this.t('back'))
            .width('100%')
            .height(this.isWatchLayout ? 42 : 54)
            .fontSize(this.isWatchLayout ? 17 : 20)
            .fontColor('#2563eb')
            .backgroundColor('#ffffff')
            .borderRadius(14)
            .border({ width: 2, color: '#3b82f6', radius: 14 })
            .onClick(() => {
              router.back();
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
    }
    .width('100%')
    .padding({ top: this.isWatchLayout ? 0 : 16, bottom: this.isWatchLayout ? 12 : 24 })
  }
}
