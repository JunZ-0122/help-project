import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../components/NavBackButton';
import { UserApi } from '../services/ApiService';
import { StorageUtil } from '../utils/StorageUtil';
import type { UserProfile } from '../models/User';

interface RoleInfo {
  id: string;
  title: string;
  description: string;
  path: string;
  color: string;
}

@Entry
@Component
struct RoleSelectPage {
  @State selectedRole: string = '';
  @State isUpdating: boolean = false;

  @StorageLink('accessibility_large_font') largeFontEnabled: boolean = false;
  @StorageLink('accessibility_high_contrast') highContrastEnabled: boolean = false;

  private roles: RoleInfo[] = [
    { id: 'help-seeker', title: '求助者', description: '我需要帮助', path: 'pages/help-seeker/HelpSeekerHomePage', color: '#2563eb' },
    { id: 'volunteer', title: '志愿者', description: '我想提供帮助', path: 'pages/volunteer/VolunteerHomePage', color: '#10b981' },
    { id: 'community', title: '社区管理', description: '管理和协调服务', path: 'pages/community/CommunityHomePage', color: '#8b5cf6' }
  ];

  private showToast(message: string): void {
    promptAction.showToast({
      message: message,
      duration: 1500
    });
  }

  handleRoleSelect(role: RoleInfo) {
    if (this.isUpdating) {
      return;
    }

    this.selectedRole = role.id;
    this.isUpdating = true;

    console.log('[RoleSelect] Starting role selection:', role.id);
    
    StorageUtil.get<UserProfile>('user').then((currentUser: UserProfile | null) => {
      console.log('[RoleSelect] Current user:', currentUser);
      
      const hasRole = !!(currentUser && currentUser.role && currentUser.role !== 'default');
      console.log('[RoleSelect] Has role:', hasRole);

      // 调用对应的 API
      if (hasRole) {
        console.log('[RoleSelect] Switching role to:', role.id);
        return UserApi.switchUserRole(role.id);
      } else {
        console.log('[RoleSelect] Setting initial role to:', role.id);
        return UserApi.updateUserRole(role.id);
      }
    }).then((updatedUser: UserProfile) => {
      console.log('[RoleSelect] API call successful, updated user:', updatedUser);
      console.log('[RoleSelect] 已选择角色:', role.title);

      // 直接跳转（不显示 Toast，避免 UI 上下文丢失）
      console.log('[RoleSelect] Navigating to:', role.path);
      router.replaceUrl({
        url: role.path
      }).then(() => {
        console.log('[RoleSelect] Navigation successful');
      }).catch((navErr: Error) => {
        console.error('[RoleSelect] Navigation error:', navErr);
      });

      // 保存更新后的用户信息（放到最后，预览器中不工作但真机需要）
      StorageUtil.set('user', updatedUser);
      console.log('[RoleSelect] User saved to storage');

    }).catch((err: Error) => {
      const error = err as Error;
      console.error('[RoleSelect] Error:', error);
      
      // 仅在真正的 API 错误时显示提示
      if (error.message && !error.message.includes('UI execution context')) {
        console.error('[RoleSelect] 角色更新失败:', error.message);
      }
      
      this.selectedRole = '';
    }).finally(() => {
      this.isUpdating = false;
    });
  }

  @Builder
  RoleCard(role: RoleInfo) {
    Button() {
      Column({ space: 10 }) {
        Text(role.title)
          .fontSize(this.largeFontEnabled ? 24 : 20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')

        Text(role.description)
          .fontSize(this.largeFontEnabled ? 17.5 : 14)
          .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')

        if (this.selectedRole === role.id) {
          Text('已选中')
            .fontSize(this.largeFontEnabled ? 15 : 12)
            .fontColor('#ffffff')
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .backgroundColor(this.highContrastEnabled ? '#000000' : role.color)
            .borderRadius(12)
        }
      }
      .width('100%')
      .padding(24)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#ffffff')
    .borderRadius(20)
    .border({
      width: this.selectedRole === role.id ? 3 : (this.highContrastEnabled ? 3 : 1),
      color: this.highContrastEnabled ? '#000000' : role.color
    })
    .onClick(() => {
      this.handleRoleSelect(role);
    })
  }

  build() {
    Column({ space: 24 }) {
      Row() {
        NavBackButton()
        Blank()
      }
      .width('100%')

      Column({ space: 12 }) {
        Text('选择您的身份')
          .fontSize(this.largeFontEnabled ? 36 : 30)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.highContrastEnabled ? '#000000' : '#1a1a1a')

        Text('请选择一个角色开始使用')
          .fontSize(this.largeFontEnabled ? 18 : 14)
          .fontColor(this.highContrastEnabled ? '#000000' : '#6b7280')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Column({ space: 16 }) {
        ForEach(this.roles, (role: RoleInfo) => {
          this.RoleCard(role)
        })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding(24)
    .backgroundColor(this.highContrastEnabled ? '#ffff00' : '#f9fafb')
  }
}
