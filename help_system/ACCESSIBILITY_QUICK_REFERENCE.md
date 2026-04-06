# 无障碍设置快速参考卡

## 🎯 测试目标
验证 23 个页面的无障碍设置功能（大字体、高对比度、页面切换一致性）

---

## 📍 设置位置
**个人中心** → **无障碍设置** → 三个开关：
- 🔤 大字体模式
- 🎨 高对比度模式  
- 📳 震动反馈提示

---

## ✅ 预期效果

### 大字体模式
- 文字增大 **25%**
- 布局自适应，无溢出

### 高对比度模式
- 背景：**黄色** (#ffff00)
- 文字：**黑色** (#000000)
- 边框：**3px 黑色**
- 字体：**加粗**

---

## 📋 23 个页面清单

### 求助者 (6)
- [ ] HelpSeekerHomePage
- [ ] EmergencyRequestPage
- [ ] RequestTypePage
- [ ] MyRequestsPage
- [ ] RequestDetailPage
- [ ] ProfilePage

### 志愿者 (8)
- [ ] VolunteerHomePage
- [ ] RequestDetailPage
- [ ] MyOrdersPage
- [ ] OrderDetailPage
- [ ] ProgressPage
- [ ] ChatPage
- [ ] ReviewPage
- [ ] ProfilePage

### 社区管理 (5)
- [ ] CommunityHomePage
- [ ] AssignPage
- [ ] ManagePage
- [ ] RequestDetailPage
- [ ] StatisticsPage

### 公共页面 (3)
- [ ] LoginPage
- [ ] RoleSelectPage
- [ ] SplashPage

### 其他 (1)
- [ ] ErrorPage

---

## 🔍 每个页面验证 3 项

1. ✅ **大字体模式**: 文字增大 25%，布局正常
2. ✅ **高对比度模式**: 黑黄配色，3px 边框，字体加粗
3. ✅ **页面切换**: 设置保持一致

---

## 🚀 快速测试流程

### 步骤 1：启用设置
1. 启动应用并登录
2. 进入个人中心
3. 点击"无障碍设置"
4. 启用"大字体模式"和"高对比度模式"

### 步骤 2：验证页面
1. 导航到目标页面
2. 检查大字体效果
3. 检查高对比度效果
4. 截图记录

### 步骤 3：验证一致性
1. 在多个页面间切换
2. 确认设置始终生效
3. 返回个人中心，确认开关状态

### 步骤 4：验证持久化
1. 关闭应用
2. 重新启动
3. 确认设置恢复

---

## ⚠️ 常见问题

| 问题 | 可能原因 | 解决方法 |
|------|---------|---------|
| 设置不生效 | 页面未添加 @StorageLink | 检查代码实现 |
| 页面切换后失效 | 新页面未适配 | 检查新页面代码 |
| 重启后丢失 | 持久化失败 | 检查 EntryAbility 初始化 |
| 布局错乱 | 容器固定高度 | 调整布局代码 |

---

## 📊 测试记录

### 简化记录表

| # | 页面 | 大字体 | 高对比度 | 切换 | 问题 |
|---|------|--------|---------|------|------|
| 1 | HelpSeekerHomePage | ⬜ | ⬜ | ⬜ | |
| 2 | EmergencyRequestPage | ⬜ | ⬜ | ⬜ | |
| 3 | RequestTypePage | ⬜ | ⬜ | ⬜ | |
| ... | | | | | |

**符号说明**: ✅ 通过 | ❌ 失败 | ⬜ 未测试

---

## 🎯 完成标准

- [ ] 所有 23 个页面已测试
- [ ] 大字体模式全部生效
- [ ] 高对比度模式全部生效
- [ ] 页面切换设置一致
- [ ] 应用重启设置保持
- [ ] 无严重布局问题

---

## 📞 需要帮助？

查看详细文档：
- `ACCESSIBILITY_VERIFICATION_CHECKLIST.md` - 完整验证清单
- `ACCESSIBILITY_MANUAL_TESTING_GUIDE.md` - 详细测试指南
- `.kiro/specs/accessibility-global-state/requirements.md` - 需求文档

---

## ⏱️ 预估时间

- **快速验证**: 5 分钟（5 个核心页面）
- **标准验证**: 30 分钟（所有页面基础测试）
- **完整验证**: 1 小时（包含边界测试和报告）

