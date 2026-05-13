import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { AuthService } from '../../services/AuthService';
import type { LoginResponse } from '../../models/Auth';
import {
  buildWatchPasswordLoginRequest,
  formatWatchPhoneInput,
  validateWatchPasswordLogin
} from './WatchLoginFormHelper';

@Entry
@Component
struct WatchLoginPage {
  @State phone: string = '';
  @State password: string = '';
  @State showPassword: boolean = false;
  @State isLoading: boolean = false;
  @State @Watch('onLoginSuccess') loginSuccessful: boolean = false;
  @State loginUserData: LoginResponse | null = null;

  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

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
    Column({ space: 4 }) {
      Text('手表端登录')
        .fontSize(this.largeFontEnabled ? 16 : 14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.highContrastEnabled ? '#000000' : '#1e293b')

      Text('请输入手机号和密码')
        .fontSize(this.largeFontEnabled ? 10 : 9)
        .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildPhoneField() {
    Column({ space: 4 }) {
      Text('手机号')
        .fontSize(this.largeFontEnabled ? 12 : 10)
        .fontColor(this.highContrastEnabled ? '#000000' : '#334155')
        .alignSelf(ItemAlign.Start)

      TextInput({ placeholder: '请输入 11 位手机号', text: this.phone })
        .height(30)
        .fontSize(this.largeFontEnabled ? 14 : 12)
        .type(InputType.PhoneNumber)
        .maxLength(11)
        .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
        .fontColor(this.highContrastEnabled ? '#000000' : '#0f172a')
        .borderRadius(6)
        .border({ width: 1.5, color: this.highContrastEnabled ? '#000000' : '#3b82f6' })
        .padding({ left: 10, right: 10 })
        .onChange((value: string) => {
          this.phone = formatWatchPhoneInput(value);
        })
    }
    .width('100%')
  }

  @Builder
  buildPasswordField() {
    Column({ space: 4 }) {
      Text('密码')
        .fontSize(this.largeFontEnabled ? 12 : 10)
        .fontColor(this.highContrastEnabled ? '#000000' : '#334155')
        .alignSelf(ItemAlign.Start)

      Row({ space: 4 }) {
        TextInput({ placeholder: '请输入密码', text: this.password })
          .layoutWeight(1)
          .height(30)
          .fontSize(this.largeFontEnabled ? 14 : 12)
          .type(this.showPassword ? InputType.Normal : InputType.Password)
          .maxLength(20)
          .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
          .fontColor(this.highContrastEnabled ? '#000000' : '#0f172a')
          .borderRadius(6)
          .border({ width: 1.5, color: this.highContrastEnabled ? '#000000' : '#3b82f6' })
          .padding({ left: 10, right: 10 })
          .onChange((value: string) => {
            this.password = value;
          })

        Button(this.showPassword ? '隐藏' : '显示')
          .width(40)
          .height(30)
          .fontSize(9)
          .padding(0)
          .backgroundColor(this.highContrastEnabled ? '#000000' : '#e2e8f0')
          .fontColor(this.highContrastEnabled ? '#ffff00' : '#334155')
          .borderRadius(6)
          .onClick(() => {
            this.showPassword = !this.showPassword;
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

      Scroll() {
        Column({ space: 10 }) {
          this.buildHeader()
          this.buildPhoneField()
          this.buildPasswordField()

          Text('未注册或忘记密码，请前往手机端完成操作')
            .fontSize(this.largeFontEnabled ? 10 : 8)
            .fontColor(this.highContrastEnabled ? '#000000' : '#64748b')
            .textAlign(TextAlign.Center)
            .width('100%')

          Button(this.isLoading ? '登录中...' : '登录')
            .width('100%')
            .height(32)
            .fontSize(this.largeFontEnabled ? 14 : 12)
            .fontWeight(FontWeight.Medium)
            .backgroundColor(this.phone.length === 11 && this.password.length >= 6 && !this.isLoading
              ? (this.highContrastEnabled ? '#000000' : '#3b82f6')
              : '#cbd5e1')
            .fontColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
            .borderRadius(6)
            .enabled(this.phone.length === 11 && this.password.length >= 6 && !this.isLoading)
            .onClick(() => {
              this.handleLogin();
            })
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 16, bottom: 16 })
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
