import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { AuthService } from '../../services/AuthService';
import type { LoginResponse } from '../../models/Auth';
import {
  appendWatchPhoneDigit,
  appendWatchPasswordDigit,
  buildWatchFieldPreview,
  buildWatchPasswordLoginRequest,
  buildWatchPasswordPreview,
  deleteWatchLoginCharacter,
  validateWatchPasswordLogin
} from './WatchLoginFormHelper';

type WatchLoginField = 'phone' | 'password';

@Entry
@Component
struct WatchLoginPage {
  @State phone: string = '';
  @State password: string = '';
  @State showPassword: boolean = false;
  @State activeField: WatchLoginField = 'phone';
  @State pressedKey: string = '';
  @State isLoading: boolean = false;
  @State @Watch('onLoginSuccess') loginSuccessful: boolean = false;
  @State loginUserData: LoginResponse | null = null;
  private pressedKeyTimer: number = -1;

  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  aboutToDisappear(): void {
    if (this.pressedKeyTimer !== -1) {
      clearTimeout(this.pressedKeyTimer);
      this.pressedKeyTimer = -1;
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

  private handleKeypadDigit(digit: string): void {
    if (this.activeField === 'phone') {
      const nextPhone: string = appendWatchPhoneDigit(this.phone, digit);
      if (nextPhone !== this.phone) {
        this.phone = nextPhone;
        if (nextPhone.length === 11 && this.password.length === 0) {
          this.activeField = 'password';
        }
      }
      return;
    }

    this.password = appendWatchPasswordDigit(this.password, digit);
  }

  private handleKeypadDelete(): void {
    if (this.activeField === 'phone') {
      this.phone = deleteWatchLoginCharacter(this.phone);
      return;
    }

    this.password = deleteWatchLoginCharacter(this.password);
  }

  private clearActiveField(): void {
    if (this.activeField === 'phone') {
      this.phone = '';
      return;
    }

    this.password = '';
  }

  private showKeyPressFeedback(key: string): void {
    this.pressedKey = key;
    if (this.pressedKeyTimer !== -1) {
      clearTimeout(this.pressedKeyTimer);
    }
    this.pressedKeyTimer = setTimeout(() => {
      this.pressedKey = '';
      this.pressedKeyTimer = -1;
    }, 120);
  }

  private loginButtonEnabled(): boolean {
    return this.phone.length === 11 && this.password.length >= 6 && !this.isLoading;
  }

  private handleLogin(): void {
    const error: string = validateWatchPasswordLogin(this.phone, this.password);
    if (error.length > 0) {
      promptAction.showToast({ message: error, duration: 2000 });
      return;
    }

    this.isLoading = true;
    AuthService.login(buildWatchPasswordLoginRequest(this.phone, this.password)).then((res: LoginResponse) => {
      this.isLoading = false;
      this.loginUserData = res;
      this.loginSuccessful = true;
    }).catch((e: Error) => {
      this.isLoading = false;
      promptAction.showToast({ message: e.message || '登录失败', duration: 2000 });
    });
  }

  @Builder
  buildHeader() {
    Column({ space: 1 }) {
      Text('手表端登录')
        .fontSize(this.largeFontEnabled ? 14 : 12)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.highContrastEnabled ? '#000000' : '#1e293b')

      Text('同屏输入')
        .fontSize(this.largeFontEnabled ? 8 : 7)
        .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildPhoneField() {
    Column({ space: 2 }) {
      Text('手机号')
        .fontSize(this.largeFontEnabled ? 9 : 8)
        .fontColor(this.highContrastEnabled ? '#000000' : '#334155')
        .width('100%')

      Row() {
        Text(buildWatchFieldPreview(this.phone, '请输入手机号', this.activeField === 'phone'))
          .fontSize(this.largeFontEnabled ? 11 : 10)
          .fontColor(this.phone.length > 0 || this.activeField === 'phone'
            ? (this.highContrastEnabled ? '#000000' : '#0f172a')
            : '#94a3b8')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
        .width('100%')
        .height(22)
        .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
        .borderRadius(6)
        .border({
          width: this.activeField === 'phone' ? 2 : 1,
          color: this.highContrastEnabled ? '#000000' : (this.activeField === 'phone' ? '#2563eb' : '#cbd5e1')
        })
        .padding({ left: 8, right: 8 })
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.activeField = 'phone';
        })
    }
    .width('84%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  buildPasswordField() {
    Column({ space: 2 }) {
      Text('密码')
        .fontSize(this.largeFontEnabled ? 9 : 8)
        .fontColor(this.highContrastEnabled ? '#000000' : '#334155')
        .width('100%')

      Row({ space: 3 }) {
        Row() {
          Text(buildWatchPasswordPreview(this.password, this.showPassword, this.activeField === 'password'))
            .fontSize(this.largeFontEnabled ? 11 : 10)
            .fontColor(this.password.length > 0 || this.activeField === 'password'
              ? (this.highContrastEnabled ? '#000000' : '#0f172a')
              : '#94a3b8')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }
          .layoutWeight(1)
          .height(22)
          .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
          .borderRadius(6)
          .border({
            width: this.activeField === 'password' ? 2 : 1,
            color: this.highContrastEnabled ? '#000000' : (this.activeField === 'password' ? '#2563eb' : '#cbd5e1')
          })
          .padding({ left: 8, right: 8 })
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.activeField = 'password';
          })

        Button(this.showPassword ? '隐' : '显')
          .width(24)
          .height(22)
          .fontSize(9)
          .padding(0)
          .backgroundColor(this.highContrastEnabled ? '#000000' : '#e2e8f0')
          .fontColor(this.highContrastEnabled ? '#ffff00' : '#334155')
          .borderRadius(6)
          .onClick(() => {
            this.showPassword = !this.showPassword;
            this.activeField = 'password';
          })
      }
      .width('100%')
    }
    .width('84%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  buildKeypad() {
    Column({ space: 2 }) {
      ForEach(['1,2,3', '4,5,6', '7,8,9'], (row: string) => {
        Row({ space: 3 }) {
          ForEach(row.split(','), (digit: string) => {
            Button(digit)
              .layoutWeight(1)
              .height(20)
              .fontSize(10)
              .fontWeight(FontWeight.Medium)
              .backgroundColor(this.pressedKey === digit
                ? (this.highContrastEnabled ? '#000000' : '#2563eb')
                : (this.highContrastEnabled ? '#000000' : '#ffffff'))
              .fontColor(this.pressedKey === digit
                ? '#ffffff'
                : (this.highContrastEnabled ? '#ffff00' : '#1e293b'))
              .borderRadius(6)
              .border({ width: 1, color: '#cbd5e1' })
              .scale(this.pressedKey === digit ? { x: 0.96, y: 0.96 } : { x: 1, y: 1 })
              .enabled(!this.isLoading)
              .onClick(() => {
                this.showKeyPressFeedback(digit);
                this.handleKeypadDigit(digit);
              })
          })
        }
      })

      Row({ space: 3 }) {
        Button('清空')
          .layoutWeight(1)
          .height(20)
          .fontSize(9)
          .backgroundColor(this.pressedKey === 'clear'
            ? (this.highContrastEnabled ? '#000000' : '#2563eb')
            : (this.highContrastEnabled ? '#000000' : '#f1f5f9'))
          .fontColor(this.pressedKey === 'clear'
            ? '#ffffff'
            : (this.highContrastEnabled ? '#ffff00' : '#475569'))
          .borderRadius(6)
          .scale(this.pressedKey === 'clear' ? { x: 0.96, y: 0.96 } : { x: 1, y: 1 })
          .enabled(!this.isLoading)
          .onClick(() => {
            this.showKeyPressFeedback('clear');
            this.clearActiveField();
          })

        Button('0')
          .layoutWeight(1)
          .height(20)
          .fontSize(10)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(this.pressedKey === '0'
            ? (this.highContrastEnabled ? '#000000' : '#2563eb')
            : (this.highContrastEnabled ? '#000000' : '#ffffff'))
          .fontColor(this.pressedKey === '0'
            ? '#ffffff'
            : (this.highContrastEnabled ? '#ffff00' : '#1e293b'))
          .borderRadius(6)
          .border({ width: 1, color: '#cbd5e1' })
          .scale(this.pressedKey === '0' ? { x: 0.96, y: 0.96 } : { x: 1, y: 1 })
          .enabled(!this.isLoading)
          .onClick(() => {
            this.showKeyPressFeedback('0');
            this.handleKeypadDigit('0');
          })

        Button('删除')
          .layoutWeight(1)
          .height(20)
          .fontSize(9)
          .backgroundColor(this.pressedKey === 'delete'
            ? (this.highContrastEnabled ? '#000000' : '#2563eb')
            : (this.highContrastEnabled ? '#000000' : '#f1f5f9'))
          .fontColor(this.pressedKey === 'delete'
            ? '#ffffff'
            : (this.highContrastEnabled ? '#ffff00' : '#475569'))
          .borderRadius(6)
          .scale(this.pressedKey === 'delete' ? { x: 0.96, y: 0.96 } : { x: 1, y: 1 })
          .enabled(!this.isLoading)
          .onClick(() => {
            this.showKeyPressFeedback('delete');
            this.handleKeypadDelete();
          })
      }
      .width('100%')
    }
    .width('100%')
  }

  build() {
    Stack() {
      Circle()
        .width('100%')
        .height('100%')
        .fill(this.highContrastEnabled ? '#ffff00' : '#ffffff')

      Column({ space: 4 }) {
        this.buildHeader()
        this.buildPhoneField()
        this.buildPasswordField()
        this.buildKeypad()

        Button(this.isLoading ? '登录中...' : '登录')
          .width('100%')
          .height(24)
          .fontSize(this.largeFontEnabled ? 12 : 11)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(this.loginButtonEnabled()
            ? (this.highContrastEnabled ? '#000000' : '#3b82f6')
            : '#cbd5e1')
          .fontColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
          .borderRadius(6)
          .enabled(this.loginButtonEnabled())
          .onClick(() => {
            this.handleLogin();
          })
      }
      .width('100%')
      .height('100%')
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#f0f4ff')
  }
}
