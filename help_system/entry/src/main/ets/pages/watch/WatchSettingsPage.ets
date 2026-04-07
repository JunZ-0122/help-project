import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { WatchButton } from '../../components/WatchButton';
import { WatchCircularLayout } from '../../components/WatchCircularLayout';
import { UserApi } from '../../services/ApiService';
import { StorageUtil } from '../../utils/StorageUtil';
import type { UserProfile } from '../../models/User';

@Entry
@Component
struct WatchSettingsPage {
  @State currentRole: string = '';
  @State isSwitching: boolean = false;

  aboutToAppear(): void {
    this.loadRole();
  }

  private async loadRole(): Promise<void> {
    try {
      const user: UserProfile | null = await StorageUtil.get<UserProfile>('user');
      if (user && user.role) {
        this.currentRole = user.role as string;
      }
    } catch (_) {
      // ignore
    }
  }

  private roleLabel(role: string): string {
    switch (role) {
      case 'help-seeker':
        return '求助者';
      case 'volunteer':
        return '志愿者';
      default:
        return role;
    }
  }

  private targetRole(): string {
    return this.currentRole === 'help-seeker' ? 'volunteer' : 'help-seeker';
  }

  private async switchRole(): Promise<void> {
    if (this.isSwitching) {
      return;
    }
    this.isSwitching = true;

    const target = this.targetRole();

    try {
      const updated = await UserApi.switchUserRole(target);
      await StorageUtil.set('user', updated);

      promptAction.showToast({
        message: `已切换为${this.roleLabel(target)}`,
        duration: 1500
      });

      if (target === 'help-seeker') {
        router.replaceUrl({ url: 'pages/watch/WatchSeekerHomePage' }).catch((err: Error) => {
          console.error('nav failed:', err);
        });
      } else {
        router.replaceUrl({ url: 'pages/watch/WatchVolunteerHomePage' }).catch((err: Error) => {
          console.error('nav failed:', err);
        });
      }
    } catch (e) {
      const err = e as Error;
      promptAction.showToast({
        message: err.message || '切换失败',
        duration: 2000
      });
    } finally {
      this.isSwitching = false;
    }
  }

  build() {
    Column() {
      WatchCircularLayout({
        centerRadius: 120,
        edgePadding: 16,
        content: () => {
          this.pageContent();
        }
      });
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  pageContent() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        NavBackButton();

        Text('设置')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1);
      }
      .width('100%');

      Text(`当前身份：${this.roleLabel(this.currentRole)}`)
        .fontSize(11)
        .fontColor('#64748b')
        .width('100%')
        .textAlign(TextAlign.Center);

      // ✅ 按钮1（修复）
      WatchButton({
        text: this.isSwitching ? '切换中...' : `切换为${this.roleLabel(this.targetRole())}`,
        buttonType: 'primary',
        buttonSize: 'medium',
        buttonWidth: '100%',
        buttonEnabled: !this.isSwitching
      })
        .onClick(() => {
          this.switchRole();
        });

      // ✅ 按钮2（修复）
      WatchButton({
        text: '无障碍设置',
        buttonType: 'secondary',
        buttonSize: 'medium',
        buttonWidth: '100%'
      })
        .onClick(() => {
          router.pushUrl({ url: 'pages/watch/WatchAccessibilityPage' }).catch((err: Error) => {
            console.error('nav accessibility failed:', err);
          });
        });
    }
    .width('100%');
  }
}