# Role Profile Edit Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让求助者、志愿者、社区管理员三类角色统一采用“个人中心进入独立编辑页”的资料修改流程，并移除社区管理员个人中心中的内嵌表单。

**Architecture:** 先抽出一个只负责“基础资料表单初始化、校验、保存载荷构建”的轻量帮助模块，用单元测试锁定共享规则；然后在求助者和社区管理员侧分别接入独立编辑页，社区管理员页面同步移除内嵌表单并改成与志愿者一致的卡片跳转刷新链路。

**Tech Stack:** ArkTS、ArkUI、HarmonyOS Hypium、现有 `UserApi` / `StorageUtil` / `router`

---

## File Structure

- Create: `help_system/entry/src/main/ets/pages/profile/ProfileEditFormHelper.ets`
  - 统一封装基础资料表单的初始化、校验和更新请求体构建。
- Create: `help_system/entry/src/test/ProfileEditFormHelper.test.ets`
  - 先用测试锁定共享表单规则。
- Create: `help_system/entry/src/main/ets/pages/help-seeker/HelpSeekerProfileEditPage.ets`
  - 求助者独立编辑页。
- Create: `help_system/entry/src/main/ets/pages/community/CommunityProfileEditPage.ets`
  - 社区管理员独立编辑页。
- Modify: `help_system/entry/src/main/ets/pages/help-seeker/SeekerPersonalCenterPane.ets`
  - 让求助者个人资料头卡片进入编辑页。
- Modify: `help_system/entry/src/main/ets/pages/community/ProfilePage.ets`
  - 移除内嵌表单，改为点击资料卡进入编辑页，并补齐返回后的刷新逻辑。
- Modify: `help_system/entry/src/main/resources/base/profile/main_pages.json`
  - 注册新增编辑页。

### Task 1: 用测试锁定共享基础资料表单规则

**Files:**
- Create: `help_system/entry/src/test/ProfileEditFormHelper.test.ets`
- Test target: `help_system/entry/src/main/ets/pages/profile/ProfileEditFormHelper.ets`

- [ ] **Step 1: 写出失败的测试**

```ts
import { describe, it, expect } from '@ohos/hypium';
import type { UserProfile } from '../main/ets/models';
import {
  buildProfileUpdatePayload,
  createProfileFormState,
  validateProfileForm
} from '../main/ets/pages/profile/ProfileEditFormHelper';

export default function profileEditFormHelperTest() {
  describe('ProfileEditFormHelper', () => {
    const sourceProfile: UserProfile = {
      id: 'u-1',
      name: '  张三  ',
      phone: '13800138000',
      role: 'help-seeker',
      status: 'online',
      address: '  朝阳区  ',
      emergencyContact: '  李四  ',
      emergencyPhone: ' 13800138001 '
    };

    it('creates form state from profile with safe empty defaults', 0, () => {
      const form = createProfileFormState(sourceProfile);
      expect(form.name).assertEqual('  张三  ');
      expect(form.phone).assertEqual('13800138000');
      expect(form.address).assertEqual('  朝阳区  ');
      expect(form.emergencyContact).assertEqual('  李四  ');
      expect(form.emergencyPhone).assertEqual(' 13800138001 ');
    });

    it('rejects empty name after trimming', 0, () => {
      expect(validateProfileForm({
        name: '   ',
        phone: '13800138000',
        address: '',
        emergencyContact: '',
        emergencyPhone: ''
      })).assertEqual('请填写姓名');
    });

    it('rejects emergency phone shorter than 7 digits after trimming', 0, () => {
      expect(validateProfileForm({
        name: '张三',
        phone: '13800138000',
        address: '',
        emergencyContact: '',
        emergencyPhone: '123456'
      })).assertEqual('紧急联系电话格式不正确');
    });

    it('builds trimmed update payload for shared editable fields only', 0, () => {
      expect(JSON.stringify(buildProfileUpdatePayload(sourceProfile))).assertEqual(JSON.stringify({
        name: '张三',
        address: '朝阳区',
        emergencyContact: '李四',
        emergencyPhone: '13800138001'
      }));
    });
  });
}
```

- [ ] **Step 2: 运行测试并确认它失败**

Run:

```powershell
Set-Location C:\Users\22789\Desktop\endProject\help_system
.\hvigorw.cmd test --mode module -p module=entry
```

Expected: FAIL，因为 `ProfileEditFormHelper.ets` 还不存在，或者导出的函数缺失。

- [ ] **Step 3: 写最小实现让测试可通过**

```ts
import type { UserProfile } from '../../models';

export interface ProfileFormState {
  name: string;
  phone: string;
  address: string;
  emergencyContact: string;
  emergencyPhone: string;
}

export function createProfileFormState(profile: Partial<UserProfile>): ProfileFormState {
  return {
    name: profile.name ? profile.name : '',
    phone: profile.phone ? profile.phone : '',
    address: profile.address ? profile.address : '',
    emergencyContact: profile.emergencyContact ? profile.emergencyContact : '',
    emergencyPhone: profile.emergencyPhone ? profile.emergencyPhone : ''
  };
}

export function validateProfileForm(form: ProfileFormState): string {
  const trimmedName = form.name.trim();
  const trimmedEmergencyPhone = form.emergencyPhone.trim();
  if (!trimmedName) {
    return '请填写姓名';
  }
  if (trimmedEmergencyPhone && trimmedEmergencyPhone.length < 7) {
    return '紧急联系电话格式不正确';
  }
  return '';
}

export function buildProfileUpdatePayload(form: ProfileFormState): Partial<UserProfile> {
  return {
    name: form.name.trim(),
    address: form.address.trim(),
    emergencyContact: form.emergencyContact.trim(),
    emergencyPhone: form.emergencyPhone.trim()
  };
}
```

- [ ] **Step 4: 重新运行测试并确认转绿**

Run:

```powershell
Set-Location C:\Users\22789\Desktop\endProject\help_system
.\hvigorw.cmd test --mode module -p module=entry
```

Expected: `ProfileEditFormHelper.test.ets` PASS。

- [ ] **Step 5: 提交这一小步**

```powershell
Set-Location C:\Users\22789\Desktop\endProject
git add help_system/entry/src/main/ets/pages/profile/ProfileEditFormHelper.ets help_system/entry/src/test/ProfileEditFormHelper.test.ets
git commit -m "test: lock shared profile edit form rules"
```

### Task 2: 为求助者接入独立编辑页

**Files:**
- Create: `help_system/entry/src/main/ets/pages/help-seeker/HelpSeekerProfileEditPage.ets`
- Modify: `help_system/entry/src/main/ets/pages/help-seeker/SeekerPersonalCenterPane.ets`
- Modify: `help_system/entry/src/main/resources/base/profile/main_pages.json`
- Read: `help_system/entry/src/main/ets/pages/volunteer/VolunteerProfileEditPage.ets`

- [ ] **Step 1: 先写页面行为约束并确认当前实现不满足**

```text
约束：
1. 求助者个人资料头卡片点击后跳转到 pages/help-seeker/HelpSeekerProfileEditPage
2. 编辑页只展示 name / phone(禁用) / address / emergencyContact / emergencyPhone
3. 保存成功后 router.back()，返回个人中心后通过 refreshSig 重新拉取资料
```

Run:

```powershell
Select-String -Path "C:\Users\22789\Desktop\endProject\help_system\entry\src\main\ets\pages\help-seeker\SeekerPersonalCenterPane.ets" -Pattern "HelpSeekerProfileEditPage|openProfileEdit|onClick"
```

Expected: 看不到跳转到 `HelpSeekerProfileEditPage` 的实现。

- [ ] **Step 2: 新建求助者编辑页，复用共享帮助模块**

```ts
import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { NavBackButton } from '../../components/NavBackButton';
import { AuthService } from '../../services/AuthService';
import { UserApi } from '../../services/ApiService';
import { StorageUtil } from '../../utils/StorageUtil';
import {
  buildProfileUpdatePayload,
  createProfileFormState,
  validateProfileForm
} from '../profile/ProfileEditFormHelper';
import type { ProfileFormState } from '../profile/ProfileEditFormHelper';
import type { UserProfile } from '../../models';

@Entry
@Component
struct HelpSeekerProfileEditPage {
  @State form: ProfileFormState = createProfileFormState({});
  @State isLoading: boolean = false;
  @State isSaving: boolean = false;

  async aboutToAppear() {
    this.isLoading = true;
    try {
      const profile: UserProfile = await UserApi.getCurrentProfile();
      this.form = createProfileFormState(profile);
    } finally {
      this.isLoading = false;
    }
  }

  async saveProfile() {
    const error = validateProfileForm(this.form);
    if (error.length > 0) {
      promptAction.showToast({ message: error, duration: 1500 });
      return;
    }
    this.isSaving = true;
    try {
      const updatedProfile = await UserApi.updateUserProfile(buildProfileUpdatePayload(this.form));
      await StorageUtil.set('user', updatedProfile);
      promptAction.showToast({ message: '已保存', duration: 1500 });
      router.back();
    } finally {
      this.isSaving = false;
    }
  }
}
```

- [ ] **Step 3: 让求助者资料头卡片改为进入独立编辑页**

```ts
private openProfileEdit(): void {
  router.pushUrl({
    url: 'pages/help-seeker/HelpSeekerProfileEditPage'
  }).catch((err: Error) => {
    console.error('navigation failed:', err);
  });
}

// 在资料头卡片容器上增加：
.onClick(() => {
  this.openProfileEdit();
})
```

- [ ] **Step 4: 注册页面并做静态校验**

```json
"pages/help-seeker/HelpSeekerProfileEditPage",
```

Run:

```powershell
Select-String -Path "C:\Users\22789\Desktop\endProject\help_system\entry\src\main\resources\base\profile\main_pages.json" -Pattern "HelpSeekerProfileEditPage"
```

Expected: 能匹配到新增注册项。

- [ ] **Step 5: 提交这一小步**

```powershell
Set-Location C:\Users\22789\Desktop\endProject
git add help_system/entry/src/main/ets/pages/help-seeker/HelpSeekerProfileEditPage.ets help_system/entry/src/main/ets/pages/help-seeker/SeekerPersonalCenterPane.ets help_system/entry/src/main/resources/base/profile/main_pages.json
git commit -m "feat: add seeker profile edit page"
```

### Task 3: 移除社区管理员内嵌表单并改成独立编辑页

**Files:**
- Create: `help_system/entry/src/main/ets/pages/community/CommunityProfileEditPage.ets`
- Modify: `help_system/entry/src/main/ets/pages/community/ProfilePage.ets`
- Modify: `help_system/entry/src/main/resources/base/profile/main_pages.json`

- [ ] **Step 1: 先验证当前页面仍含内嵌表单逻辑**

Run:

```powershell
Select-String -Path "C:\Users\22789\Desktop\endProject\help_system\entry\src\main\ets\pages\community\ProfilePage.ets" -Pattern "showProfileForm|saveProfile|TextInput|基础资料"
```

Expected: 能匹配到内嵌编辑相关状态、方法和表单字段。

- [ ] **Step 2: 新建社区管理员编辑页，沿用共享基础资料逻辑**

```ts
@Entry
@Component
struct CommunityProfileEditPage {
  @State form: ProfileFormState = createProfileFormState({});
  @State isLoading: boolean = false;
  @State isSaving: boolean = false;

  async aboutToAppear() {
    this.isLoading = true;
    try {
      const profile = await UserApi.getCurrentProfile();
      this.form = createProfileFormState(profile);
    } finally {
      this.isLoading = false;
    }
  }

  async saveProfile() {
    const error = validateProfileForm(this.form);
    if (error.length > 0) {
      promptAction.showToast({ message: error, duration: 1500 });
      return;
    }
    this.isSaving = true;
    try {
      const updatedProfile = await UserApi.updateUserProfile(buildProfileUpdatePayload(this.form));
      await StorageUtil.set('user', updatedProfile);
      promptAction.showToast({ message: '已保存', duration: 1500 });
      router.back();
    } finally {
      this.isSaving = false;
    }
  }
}
```

- [ ] **Step 3: 从社区个人中心移除内嵌表单，改为资料卡跳转**

```ts
private skipNextPageShow: boolean = true;

onPageShow() {
  if (this.skipNextPageShow) {
    this.skipNextPageShow = false;
    return;
  }
  this.loadProfileData();
}

private openProfileEdit(): void {
  router.pushUrl({
    url: 'pages/community/CommunityProfileEditPage'
  }).catch((err: Error) => {
    console.error('navigation failed:', err);
  });
}

// 删除：
// - @State address / emergencyContact / emergencyPhone / isSaving / showProfileForm
// - menuItems 中的 edit 项
// - saveProfile()
// - build() 中的整块内嵌表单
//
// 在资料头卡片上增加：
.onClick(() => {
  this.openProfileEdit();
})
```

- [ ] **Step 4: 注册页面并确认旧内嵌表单标记已消失**

Run:

```powershell
Select-String -Path "C:\Users\22789\Desktop\endProject\help_system\entry\src\main\ets\pages\community\ProfilePage.ets" -Pattern "showProfileForm|saveProfile|基础资料"
Select-String -Path "C:\Users\22789\Desktop\endProject\help_system\entry\src\main\resources\base\profile\main_pages.json" -Pattern "CommunityProfileEditPage"
```

Expected:
- `ProfilePage.ets` 不再匹配旧内嵌表单标记
- `main_pages.json` 能匹配到 `CommunityProfileEditPage`

- [ ] **Step 5: 提交这一小步**

```powershell
Set-Location C:\Users\22789\Desktop\endProject
git add help_system/entry/src/main/ets/pages/community/CommunityProfileEditPage.ets help_system/entry/src/main/ets/pages/community/ProfilePage.ets help_system/entry/src/main/resources/base/profile/main_pages.json
git commit -m "feat: move community profile editing to standalone page"
```

### Task 4: 编译与回归验证

**Files:**
- Verify: `help_system/entry/src/main/ets/pages/help-seeker/HelpSeekerProfileEditPage.ets`
- Verify: `help_system/entry/src/main/ets/pages/community/CommunityProfileEditPage.ets`
- Verify: `help_system/entry/src/main/ets/pages/help-seeker/SeekerPersonalCenterPane.ets`
- Verify: `help_system/entry/src/main/ets/pages/community/ProfilePage.ets`
- Verify: `help_system/entry/src/main/resources/base/profile/main_pages.json`
- Verify: `help_system/entry/src/test/ProfileEditFormHelper.test.ets`

- [ ] **Step 1: 跑共享表单测试**

Run:

```powershell
Set-Location C:\Users\22789\Desktop\endProject\help_system
.\hvigorw.cmd test --mode module -p module=entry
```

Expected: `ProfileEditFormHelper.test.ets` 通过，且没有新增测试失败。

- [ ] **Step 2: 跑前端编译验证**

Run:

```powershell
Set-Location C:\Users\22789\Desktop\endProject\help_system
.\hvigorw.cmd assembleHap --mode module -p module=entry
```

Expected: `entry` 模块编译成功，新增页面和路由注册没有 ArkTS 错误。

- [ ] **Step 3: 做关键静态回归检查**

Run:

```powershell
Set-Location C:\Users\22789\Desktop\endProject
Select-String -Path ".\help_system\entry\src\main\ets\pages\community\ProfilePage.ets" -Pattern "showProfileForm|saveProfile|基础资料"
Select-String -Path ".\help_system\entry\src\main\ets\pages\help-seeker\SeekerPersonalCenterPane.ets" -Pattern "HelpSeekerProfileEditPage"
Select-String -Path ".\help_system\entry\src\main\ets\pages\community\ProfilePage.ets" -Pattern "CommunityProfileEditPage|openProfileEdit"
```

Expected:
- 社区管理员页面不再含内嵌表单关键字
- 求助者和社区管理员个人中心都已接入独立编辑页跳转

- [ ] **Step 4: 检查最终差异只覆盖本需求**

Run:

```powershell
Set-Location C:\Users\22789\Desktop\endProject
git diff -- help_system/entry/src/main/ets/pages/help-seeker help_system/entry/src/main/ets/pages/community help_system/entry/src/main/ets/pages/profile help_system/entry/src/main/resources/base/profile/main_pages.json help_system/entry/src/test/ProfileEditFormHelper.test.ets
```

Expected: 变更仅涉及新增编辑页、入口跳转、社区内嵌表单移除、共享帮助模块和相关测试。

- [ ] **Step 5: 提交最终实现**

```powershell
Set-Location C:\Users\22789\Desktop\endProject
git add help_system/entry/src/main/ets/pages/help-seeker help_system/entry/src/main/ets/pages/community help_system/entry/src/main/ets/pages/profile help_system/entry/src/main/resources/base/profile/main_pages.json help_system/entry/src/test/ProfileEditFormHelper.test.ets
git commit -m "feat: unify profile editing into standalone pages"
```

## Self-Review

- Spec coverage:
  - 求助者独立编辑页：Task 2
  - 社区管理员去内嵌表单并改独立编辑页：Task 3
  - 志愿者作为统一交互参考模型：Task 2 / Task 3 均以其为参考
  - 通用基础字段与手机号只读规则：Task 1
  - 保存后返回并刷新个人中心：Task 2 / Task 3
- Placeholder scan:
  - 没有 `TODO`、`TBD` 或“后续补充”式实现占位语句。
- Type consistency:
  - 共享表单结构统一为 `ProfileFormState`
  - 基础资料更新统一通过 `buildProfileUpdatePayload(...)`
  - 求助者与社区管理员都复用同一套校验与载荷构建规则
