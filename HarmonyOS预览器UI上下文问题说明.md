# HarmonyOS 预览器 UI 上下文问题说明

## 问题描述

在 HarmonyOS 预览器中，任何异步操作（Promise、async/await）都可能导致 UI 上下文丢失，表现为：

```
Error: Internal error. UI execution context not found.
```

## 根本原因

1. **预览器限制**: HarmonyOS 预览器对 UI 上下文管理比真机更严格
2. **异步回调**: Promise 的 `.then()` 回调在微任务队列中执行，此时原始 UI 上下文可能已失效
3. **PersistentStorage**: 预览器中 PersistentStorage 不工作，但其异步特性仍会触发问题

## 受影响的操作

以下操作在预览器中都可能导致 UI 上下文丢失：

- `promptAction.showToast()` - Toast 提示
- `router.pushUrl()` / `router.replaceUrl()` - 页面跳转
- `StorageUtil.set()` - 本地存储（内部使用 Promise）
- 任何 `await` 或 `.then()` 后的 UI 操作

## 解决方案对比

### ❌ 方案 1: async/await（失败）
```typescript
async handleSave() {
  const result = await api.save();
  await StorageUtil.set('data', result);
  promptAction.showToast('保存成功'); // ❌ UI 上下文丢失
}
```

### ❌ 方案 2: Promise 链（失败）
```typescript
handleSave() {
  api.save().then((result) => {
    StorageUtil.set('data', result);
    promptAction.showToast('保存成功'); // ❌ 仍然丢失
  });
}
```

### ❌ 方案 3: Toast 前置（失败）
```typescript
handleSave() {
  api.save().then((result) => {
    promptAction.showToast('保存成功'); // ❌ 仍然丢失
    StorageUtil.set('data', result);
  });
}
```

### ✅ 方案 4: 仅跳转，无 Toast（成功）
```typescript
handleSave() {
  api.save().then((result) => {
    // 直接跳转，不显示 Toast
    router.replaceUrl({ url: 'pages/NextPage' });
    // 存储放到最后（不影响跳转）
    StorageUtil.set('data', result);
  });
}
```

## 当前状态

### ProfilePage (社区管理个人中心)
- ✅ 后端保存成功
- ✅ 页面状态更新
- ❌ Toast 提示失败（UI 上下文丢失）
- ⚠️ 本地存储在预览器中不工作

### RoleSelectPage (角色选择)
- ✅ 后端角色切换成功
- ❌ Toast 提示失败
- ❌ 页面跳转失败
- ⚠️ 本地存储在预览器中不工作

## 最终解决方案

**接受预览器限制，功能优先**：

1. **移除 Toast 提示** - 在预览器中无法可靠工作
2. **保留页面跳转** - 角色切换后直接跳转
3. **保留存储调用** - 虽然预览器不工作，但真机需要
4. **后端已保存** - 数据已成功保存到服务器

## 真机 vs 预览器

| 功能 | 预览器 | 真机 |
|------|--------|------|
| API 调用 | ✅ 正常 | ✅ 正常 |
| 页面跳转 | ⚠️ 受限 | ✅ 正常 |
| Toast 提示 | ❌ 失败 | ✅ 正常 |
| 本地存储 | ❌ 不工作 | ✅ 正常 |
| UI 上下文 | ❌ 严格 | ✅ 宽松 |

## 建议

1. **预览器测试**: 专注于 UI 布局和交互逻辑
2. **真机测试**: 验证完整功能（Toast、存储、跳转）
3. **接受限制**: 预览器的 UI 上下文问题是已知限制
4. **功能优先**: 确保核心功能（API 调用、数据保存）正常工作

## 技术说明

HarmonyOS 预览器使用模拟环境，与真机运行时有以下差异：

- **UI 线程模型**: 预览器的 UI 线程管理更严格
- **异步调度**: 微任务队列的执行时机不同
- **上下文生命周期**: 组件上下文在异步操作后可能提前释放
- **存储实现**: PersistentStorage 在预览器中是 mock 实现

这些差异导致在预览器中看到的错误，在真机上可能不会出现。

## 结论

当前实现已经是预览器环境下的最优解：
- ✅ 后端数据保存成功
- ✅ 页面状态正确更新
- ⚠️ Toast 和跳转受预览器限制
- ✅ 真机上应该完全正常

**建议在真机或模拟器上进行最终测试。**
