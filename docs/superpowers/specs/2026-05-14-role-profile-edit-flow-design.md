# 角色个人资料编辑流程设计说明

**日期：** 2026-05-14

**范围**
- 统一三类角色个人中心的资料编辑交互方式。
- 将“个人中心内嵌编辑”改为“进入独立编辑页”。
- 覆盖以下页面：
  - `help-seeker/ProfilePage.ets` + `SeekerPersonalCenterPane.ets`
  - `volunteer/ProfilePage.ets` + `VolunteerProfileEditPage.ets`
  - `community/ProfilePage.ets`
- 复用现有的用户资料更新接口和志愿者技能接口。

**问题背景**
- 志愿者目前已经采用独立编辑页，形成了清晰的“查看个人中心 -> 进入编辑页 -> 保存 -> 返回”的流程。
- 社区管理员当前是在个人中心页面内直接展开表单编辑，导致同一页面同时承担展示、跳转、设置和表单编辑职责。
- 求助者当前没有与志愿者一致的独立编辑页体验。
- 因此，同一个“修改个人资料”能力在三个角色上的产品表现不一致。

**目标**
- 让三个角色都采用一致的资料编辑入口和跳转方式。
- 让个人中心页面专注于展示与导航，不再承担内嵌表单编辑。
- 尽量复用现有后端更新能力，减少额外改动范围。
- 把本次修改控制在可稳定落地的规模内，不引入不必要的表结构扩展。

**非目标**
- 不重做与本需求无关的个人中心视觉设计。
- 不修改账号手机号的变更规则。
- 本轮不新增后端数据库字段。
- 本轮不把三个角色的编辑页强行合并成一个通用页面。

**最终方案**
- 统一采用志愿者当前的交互模型：从个人中心进入独立编辑页，保存后返回上一页。
- 保留按角色拆分的编辑页，但统一它们的页面结构、表单校验和保存流程。
- 明确收敛范围：本轮不给求助者增加新的专属后端字段，求助者仅编辑通用基础资料。

**用户体验设计**
- 志愿者：
  - 保持现有从个人中心进入独立编辑页的方式。
  - 保留志愿者专属的技能编辑能力。
- 社区管理员：
  - 移除个人中心中的内嵌编辑表单。
  - 在个人中心中增加跳转入口，进入新的社区管理员独立编辑页。
- 求助者：
  - 在个人中心中增加“编辑资料”入口。
  - 点击后进入新的求助者独立编辑页。

**字段规则**
- 三个角色共用的可编辑字段：
  - `name`
  - `address`
  - `emergencyContact`
  - `emergencyPhone`
- 三个角色共用的只读字段：
  - `phone`
- 志愿者专属可编辑字段：
  - `skills`
- 本轮不纳入编辑范围的字段：
  - `disabilities`
  - `certifications`
  - `age`
  - `gender`
  - `avatar`
  - `role`

**表单校验规则**
- `name` 为必填项。
- `emergencyPhone` 为选填项，但如果填写，沿用当前已有页面中的基础长度校验规则。
- `phone` 仅展示，不允许在本页编辑。
- 保存请求进行中时，保存按钮需要置灰禁用，避免重复提交。

**页面跳转与数据流**
- 进入编辑页时，统一通过 `UserApi.getCurrentProfile()` 拉取最新资料，不直接依赖首页缓存。
- 保存基础资料时，统一调用 `UserApi.updateUserProfile(...)`。
- 志愿者如果修改了技能，则在基础资料保存成功后，再调用 `UserApi.updateMyVolunteerSkills(...)` 保存技能。
- 保存成功后统一执行：
  - 将最新资料写回 `StorageUtil`
  - 调用 `router.back()` 返回上一页
  - 在个人中心重新显示时触发资料刷新
- 如果接口返回登录失效，则统一走现有的“登出并跳转登录页”流程。

**页面职责划分**
- 个人中心页面只负责：
  - 资料摘要展示
  - 菜单与跳转入口
  - 无障碍设置开关
  - 退出登录
- 独立编辑页负责：
  - 表单状态管理
  - 字段校验
  - 保存请求
  - 加载与保存反馈

**实现方式**
- 以 `pages/volunteer/VolunteerProfileEditPage.ets` 作为参考实现。
- 新增页面：
  - `pages/help-seeker/HelpSeekerProfileEditPage.ets`
  - `pages/community/CommunityProfileEditPage.ets`
- 修改三个角色个人中心的入口逻辑，使其都跳转到各自的独立编辑页。
- 从 `pages/community/ProfilePage.ets` 中移除原有内嵌编辑表单及相关状态。
- 在 `resources/base/profile/main_pages.json` 中注册新增页面。

**涉及文件**
- `C:\Users\22789\Desktop\endProject\help_system\entry\src\main\ets\pages\help-seeker\SeekerPersonalCenterPane.ets`
- `C:\Users\22789\Desktop\endProject\help_system\entry\src\main\ets\pages\help-seeker\ProfilePage.ets`
- `C:\Users\22789\Desktop\endProject\help_system\entry\src\main\ets\pages\help-seeker\HelpSeekerProfileEditPage.ets`
- `C:\Users\22789\Desktop\endProject\help_system\entry\src\main\ets\pages\volunteer\ProfilePage.ets`
- `C:\Users\22789\Desktop\endProject\help_system\entry\src\main\ets\pages\volunteer\VolunteerProfileEditPage.ets`
- `C:\Users\22789\Desktop\endProject\help_system\entry\src\main\ets\pages\community\ProfilePage.ets`
- `C:\Users\22789\Desktop\endProject\help_system\entry\src\main\ets\pages\community\CommunityProfileEditPage.ets`
- `C:\Users\22789\Desktop\endProject\help_system\entry\src\main\resources\base\profile\main_pages.json`
- 相关测试文件：`C:\Users\22789\Desktop\endProject\help_system\entry\src\test\`

**验证方案**
- 验证三个角色都可以从个人中心进入各自的编辑页。
- 验证共享字段能正确加载当前最新资料。
- 验证保存成功后，返回个人中心时展示内容能及时刷新。
- 额外验证志愿者技能的读取、切换和保存逻辑没有被破坏。
- 验证社区管理员个人中心不再出现内嵌编辑表单。
- 最后执行一次前端编译或构建验证，确保新增页面注册和类型引用正常。

**风险**
- 社区管理员个人中心当前职责较多，去掉内嵌表单时需要小心清理残留状态和无用代码。
- 如果 `main_pages.json` 忘记注册新页面，会在运行时导致跳转失败。
- 如果现有测试用例依赖社区管理员的旧内嵌编辑行为，需要同步调整断言。

**后续可选优化**
- 如果后续产品希望求助者编辑“特殊需求说明”或更细的身体情况字段，应单独立项，并明确后端字段、存储方式和展示规则。
- 如果本次完成后发现三个编辑页结构高度相似，可以在下一轮抽取共用表单组件或公共构建方法。

**自检结论**
- 文档中没有保留占位项。
- 范围已经明确限制在“统一编辑交互”和“基础资料编辑”。
- 求助者字段范围已明确：本轮不新增后端字段。
- 设计方案与用户要求一致，统一采用独立编辑页，不再使用个人中心内嵌表单。
