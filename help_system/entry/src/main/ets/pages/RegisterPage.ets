import router from '@ohos.router';
import pasteboard from '@ohos.pasteboard';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../components/NavBackButton';
import { AuthService } from '../services/AuthService';
import { extractVerificationCode, shouldShowMockMessage } from '../utils';
import { isWearableDevice } from '../utils/DeviceFormUtil';
import type { LoginResponse, RegisterRequest, SendVerificationCodeResponse } from '../models/Auth';

@Entry
@Component
struct RegisterPage {
  @State name: string = '';
  @State phone: string = '';
  @State verificationCode: string = '';
  @State password: string = '123456';
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
      case 'title':
        return '创建您的账号';
      case 'subtitle':
        return '先完成注册，再选择您的身份';
      case 'name':
        return '姓名';
      case 'namePlaceholder':
        return '请输入您的姓名';
      case 'phone':
        return '手机号';
      case 'phonePlaceholder':
        return '请输入手机号';
      case 'code':
        return '验证码';
      case 'codePlaceholder':
        return '请输入 6 位验证码';
      case 'password':
        return '初始密码';
      case 'passwordGuide':
        return '验证码注册后，默认密码固定为 123456';
      case 'registering':
        return '注册中...';
      case 'register':
        return '注册';
      case 'or':
        return '或';
      case 'back':
        return '返回登录';
      case 'guide':
        return '注册后将先进入身份选择页面';
      case 'codeSent':
        return '验证码已发送';
      case 'sendCodeFail':
        return '验证码发送失败，请重试';
      case 'badPhone':
        return '请输入正确的手机号';
      case 'missing':
        return '请填写完整信息';
      case 'badCode':
        return '请输入6位验证码';
      case 'registerSuccess':
        return '注册成功';
      case 'registerAndChooseRole':
        return '注册成功，请先选择身份';
      case 'openRoleSelectFail':
        return '无法打开角色选择页';
      case 'openHomeFail':
        return '无法打开首页';
      case 'registerFail':
        return '注册失败，请重试';
      case 'resend':
        return '重新发送';
      case 'getCode':
        return '获取验证码';
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

  private navigateAfterRegister(response: LoginResponse): void {
    const role = response.user.role;
    if (!role || role === 'default') {
      this.showToast(this.t('registerAndChooseRole'));
      router.replaceUrl({
        url: 'pages/RoleSelectPage',
        params: { user: response.user }
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
      params: { user: response.user }
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
    }).then((response: SendVerificationCodeResponse) => {
      this.codeSent = true;
      this.countdown = response.cooldownSeconds > 0 ? response.cooldownSeconds : 60;
      this.showMockSms(response.mockMessage, response.debugCode);
      this.showToast(this.t('codeSent'));

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

  handleRegister() {
    if (!this.name.trim() || !this.phone || !this.verificationCode) {
      this.showToast(this.t('missing'));
      return;
    }

    if (this.phone.length !== 11) {
      this.showToast(this.t('badPhone'));
      return;
    }

    if (this.verificationCode.length !== 6) {
      this.showToast(this.t('badCode'));
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
    Stack() {
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

              Text(this.t('passwordGuide'))
                .width('100%')
                .fontSize(13)
                .fontColor('#64748b')
                .textAlign(TextAlign.Start)
                .padding({ left: 2, right: 2, top: 4, bottom: 4 })
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
                this.verificationCode.length === 6 && !this.isLoading ? '#3b82f6' : '#a5b4c7')
              .borderRadius(14)
              .shadow({ radius: 14, color: '#3b82f640', offsetX: 0, offsetY: 6 })
              .enabled(this.name.trim().length > 0 && this.phone.length === 11 &&
                this.verificationCode.length === 6 && !this.isLoading)
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
