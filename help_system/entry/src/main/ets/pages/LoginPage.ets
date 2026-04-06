import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { AuthService } from '../services/AuthService';
import { StorageUtil } from '../utils/StorageUtil';
import { isWearableDevice } from '../utils/DeviceFormUtil';
import type { LoginRequest, LoginResponse } from '../models/Auth';

@Entry
@Component
struct LoginPage {
  @State phone: string = '';
  @State code: string = '';
  @State codeSent: boolean = false;
  @State countdown: number = 0;
  @State isLoading: boolean = false;
  @State formOpacity: number = 0;
  @State logoScale: number = 0.8;
  /** 手表圆屏高度小，需滚动 + 紧凑布局，否则只能看到标题看不到表单 */
  @State isWatchLayout: boolean = false;
  @State @Watch('onLoginSuccess') loginSuccessful: boolean = false;
  @State loginUserData: LoginResponse | null = null;
  private countdownTimer: number = -1;

  // 无障碍设置
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

  // 监听登录成功状态变化，执行路由跳转
  onLoginSuccess() {
    if (this.loginSuccessful && this.loginUserData) {
      const user = this.loginUserData.user;
      const role: string | undefined = user.role as string | undefined;
      
      // 根据用户角色决定跳转页面
      let targetUrl = '';
      let message = '';
      
      if (!role) {
        // 新用户，没有角色 -> 跳转到角色选择页
        targetUrl = 'pages/RoleSelectPage';
        message = '欢迎！请选择您的身份';
        console.info('新用户登录，跳转到角色选择页');
      } else {
        // 已有角色的用户 -> 直接跳转到对应主页
        switch (role) {
          case 'help-seeker':
            targetUrl = 'pages/help-seeker/HelpSeekerHomePage';
            message = '欢迎回来，求助者';
            break;
          case 'volunteer':
            targetUrl = 'pages/volunteer/VolunteerHomePage';
            message = '欢迎回来，志愿者';
            break;
          case 'community':
            targetUrl = 'pages/community/CommunityHomePage';
            message = '欢迎回来，管理员';
            break;
          default:
            // 未知角色，跳转到角色选择页
            targetUrl = 'pages/RoleSelectPage';
            message = '请选择您的身份';
            break;
        }
        console.info(`已有角色用户登录: ${role}，跳转到对应主页`);
      }
      
      // 显示成功提示
      promptAction.showToast({
        message: message,
        duration: 2000
      });
      
      // 执行路由跳转
      router.pushUrl({
        url: targetUrl,
        params: {
          user: user
        }
      }).then(() => {
        console.info(`页面跳转成功: ${targetUrl}`);
      }).catch((err: Error) => {
        console.error('导航失败:', err);
        promptAction.showToast({
          message: '页面跳转失败: ' + err.message,
          duration: 2000
        });
      });
    }
  }

  handleSendCode() {
    if (this.phone.length !== 11) {
      promptAction.showToast({
        message: '请输入正确的手机号',
        duration: 2000
      });
      return;
    }

    // 调用发送验证码 API
    AuthService.sendVerificationCode({
      phone: this.phone,
      type: 'login'
    }).then((success: boolean) => {
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
            this.countdown = 0;
          }
        }, 1000);
      } else {
        promptAction.showToast({
          message: '发送验证码失败，请重试',
          duration: 2000
        });
      }
    }).catch((err: Error) => {
      console.error('发送验证码失败:', err);
      promptAction.showToast({
        message: err.message || '发送验证码失败，请重试',
        duration: 2000
      });
    });
  }

  handleLogin() {
    console.info('开始登录流程');
    
    if (!this.phone || !this.code) {
      promptAction.showToast({
        message: '请填写完整信息',
        duration: 2000
      });
      return;
    }

    if (this.phone.length !== 11) {
      promptAction.showToast({
        message: '请输入正确的手机号',
        duration: 2000
      });
      return;
    }

    if (this.code.length < 4) {
      promptAction.showToast({
        message: '请输入正确的验证码',
        duration: 2000
      });
      return;
    }

    console.info('验证通过，开始调用登录 API');
    this.isLoading = true;

    // 调用登录 API
    const loginRequest: LoginRequest = {
      phone: this.phone,
      password: this.code, // 使用验证码作为密码（临时方案）
      loginType: 'sms'
    };
    
    AuthService.login(loginRequest).then(async (response: LoginResponse) => {
      console.info('登录成功:', JSON.stringify(response));
      console.info(`[LoginPage] 当前存储模式: ${StorageUtil.getStorageMode()}`);
      
      // 验证 Token 是否保存成功（使用 getString 而不是 get）
      const savedToken: string = await StorageUtil.getString('token');
      console.info('[LoginPage] Token 保存验证:', savedToken ? '成功' : '失败');
      console.info('[LoginPage] Token 值:', savedToken);
      
      // 再次读取确认
      const verifyToken: string = await StorageUtil.getString('token');
      console.info('[LoginPage] Token 二次验证:', verifyToken ? '成功' : '失败');
      console.info('[LoginPage] Token 二次读取值:', verifyToken);
      
      this.isLoading = false;
      
      // 保存登录数据并触发状态变化
      this.loginUserData = response;
      this.loginSuccessful = true; // 这会触发 @Watch 回调
      
      console.info('登录流程完成，等待状态监听器触发跳转');
    }).catch((err: Error) => {
      console.error('登录失败:', err);
      this.isLoading = false;
      console.error('登录失败，错误信息:', err.message);
      
      promptAction.showToast({
        message: err.message || '登录失败，请重试',
        duration: 2000
      });
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
      if (this.isWatchLayout) {
        Scroll() {
          this.LoginContentColumn();
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.TopStart)
      } else {
        this.LoginContentColumn();
      }
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
    Column({ space: this.isWatchLayout ? 14 : 40 }) {
        // Logo & 标题 with animation
        Column({ space: this.isWatchLayout ? 8 : 20 }) {
          Row() {
            Image($r('app.media.startIcon'))
              .width(this.isWatchLayout ? 40 : 72)
              .height(this.isWatchLayout ? 40 : 72)
              .borderRadius(this.isWatchLayout ? 10 : 18)
          }
          .width(this.isWatchLayout ? 52 : 88)
          .height(this.isWatchLayout ? 52 : 88)
          .linearGradient({
            angle: 135,
            colors: [[0x3b82f6, 0.0], [0x6366f1, 1.0]]
          })
          .borderRadius(this.isWatchLayout ? 14 : 22)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .shadow(this.isWatchLayout ? undefined : {
            radius: 20,
            color: '#3b82f650',
            offsetX: 0,
            offsetY: 8
          })
          .scale({ x: this.logoScale, y: this.logoScale })

          Column({ space: 8 }) {
            Text('欢迎使用互助帮扶')
              .fontSize(this.isWatchLayout
                ? (this.largeFontEnabled ? 18 : 15)
                : (this.largeFontEnabled ? 32.5 : 26))
              .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Bold)
              .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
              .letterSpacing(1)
            
            Text('让爱心触手可及')
              .fontSize(this.isWatchLayout
                ? (this.largeFontEnabled ? 18 : 15)
                : (this.largeFontEnabled ? 18.75 : 15))
              .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
              .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
          }
        }
        .alignItems(HorizontalAlign.Center)

        // 登录表单 with animation
        Column({ space: this.isWatchLayout ? 12 : 24 }) {
          // 手机号输入
          Column({ space: this.isWatchLayout ? 6 : 10 }) {
            Text('手机号')
              .fontSize(this.largeFontEnabled ? 17.5 : 14)
              .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)
              .fontColor(this.highContrastEnabled ? '#000000' : '#374151')
              .alignSelf(ItemAlign.Start)

            TextInput({ placeholder: '请输入手机号' })
              .height(this.isWatchLayout
                ? (this.largeFontEnabled ? 44 : 40)
                : (this.largeFontEnabled ? 70 : 56))
              .fontSize(this.largeFontEnabled ? 22.5 : 18)
              .textAlign(TextAlign.Center)
              .letterSpacing(2)
              .maxLength(11)
              .type(InputType.PhoneNumber)
              .onChange((value: string) => {
                this.phone = this.formatPhoneInput(value);
              })
              .borderRadius(14)
              .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
              .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
              .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
              .border({
                width: this.highContrastEnabled ? 3 : 2,
                color: this.highContrastEnabled ? '#000000' : (this.phone.length > 0 ? '#3b82f6' : '#e5e7eb'),
                radius: 14
              })
              .animation({
                duration: 300,
                curve: Curve.EaseInOut
              })
          }

          // 验证码输入
          Column({ space: this.isWatchLayout ? 6 : 10 }) {
            Text('验证码')
              .fontSize(this.largeFontEnabled ? 17.5 : 14)
              .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)
              .fontColor(this.highContrastEnabled ? '#000000' : '#374151')
              .alignSelf(ItemAlign.Start)

            Row({ space: 12 }) {
              TextInput({ placeholder: '请输入验证码' })
                .height(this.isWatchLayout
                  ? (this.largeFontEnabled ? 44 : 40)
                  : (this.largeFontEnabled ? 70 : 56))
                .fontSize(this.largeFontEnabled ? 22.5 : 18)
                .textAlign(TextAlign.Center)
                .letterSpacing(4)
                .maxLength(6)
                .type(InputType.Number)
                .onChange((value: string) => {
                  this.code = this.formatCodeInput(value);
                })
                .borderRadius(14)
                .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
                .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')
                .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
                .border({
                  width: this.highContrastEnabled ? 3 : 2,
                  color: this.highContrastEnabled ? '#000000' : (this.code.length > 0 ? '#3b82f6' : '#e5e7eb'),
                  radius: 14
                })
                .layoutWeight(1)
                .animation({
                  duration: 300,
                  curve: Curve.EaseInOut
                })

              Button(this.countdown > 0 ? `${this.countdown}秒` : this.codeSent ? '重新发送' : '获取验证码')
                .height(this.isWatchLayout
                  ? (this.largeFontEnabled ? 44 : 40)
                  : (this.largeFontEnabled ? 70 : 56))
                .fontSize(this.largeFontEnabled ? 17.5 : 14)
                .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)
                .backgroundColor(this.highContrastEnabled ? '#ffff00' : (this.phone.length === 11 && this.countdown === 0 ? '#f3f4f6' : '#e5e7eb'))
                .fontColor(this.highContrastEnabled ? '#000000' : (this.phone.length === 11 && this.countdown === 0 ? '#374151' : '#9ca3af'))
                .borderRadius(14)
                .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
                .enabled(this.phone.length === 11 && this.countdown === 0)
                .onClick(() => {
                  this.handleSendCode();
                })
            }
          }

          // 登录按钮
          Button(this.isLoading ? '登录中...' : '登录 / 注册')
            .width('100%')
            .height(this.isWatchLayout
              ? (this.largeFontEnabled ? 46 : 42)
              : (this.largeFontEnabled ? 70 : 56))
            .fontSize(this.isWatchLayout
              ? (this.largeFontEnabled ? 18 : 16)
              : (this.largeFontEnabled ? 22.5 : 18))
            .fontWeight(FontWeight.Bold)
            .fontColor(this.highContrastEnabled ? '#000000' : '#ffffff')
            .linearGradient(this.highContrastEnabled ? undefined : {
              angle: 90,
              colors: this.phone.length === 11 && this.code.length > 0 && !this.isLoading
                ? [[0x3b82f6, 0.0], [0x6366f1, 1.0]]
                : [[0xe5e7eb, 0.0], [0xe5e7eb, 1.0]]
            })
            .backgroundColor(this.highContrastEnabled ? '#ffff00' : undefined)
            .borderRadius(14)
            .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
            .shadow(this.highContrastEnabled ? undefined : {
              radius: this.phone.length === 11 && this.code.length > 0 && !this.isLoading ? 16 : 0,
              color: '#3b82f640',
              offsetX: 0,
              offsetY: 8
            })
            .enabled(this.phone.length === 11 && this.code.length > 0 && !this.isLoading)
            .onClick(() => {
              this.handleLogin();
            })
            .animation({
              duration: 300,
              curve: Curve.EaseInOut
            })

          // 帮助文本
          Column({ space: 6 }) {
            Text('首次登录将自动创建账号')
              .fontSize(this.largeFontEnabled ? 16.25 : 13)
              .fontColor(this.highContrastEnabled ? '#000000' : '#9ca3af')
              .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Normal)
              .textAlign(TextAlign.Center)

            Text('无需复杂注册流程')
              .fontSize(this.largeFontEnabled ? 16.25 : 13)
              .fontColor(this.highContrastEnabled ? '#000000' : '#3b82f6')
              .textAlign(TextAlign.Center)
              .fontWeight(this.highContrastEnabled ? FontWeight.Bold : FontWeight.Medium)
          }
          .width('100%')
          .margin({ top: 12 })
        }
        .width('100%')
        .padding(this.isWatchLayout ? 10 : 32)
        .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
        .borderRadius(this.isWatchLayout ? 14 : 20)
        .border(this.highContrastEnabled ? { width: 3, color: '#000000' } : undefined)
        .shadow(this.highContrastEnabled ? undefined : {
          radius: 32,
          color: '#0f000018',
          offsetX: 0,
          offsetY: 12
        })
        .opacity(this.formOpacity)
    }
    .width('100%')
    .constraintSize({ maxWidth: 420 })
  }
}