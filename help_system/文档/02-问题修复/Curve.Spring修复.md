# Curve.Spring 属性修复总结

## 问题描述

编译错误：`Property 'Spring' does not exist on type 'typeof Curve'`

在 HarmonyOS ArkUI 中，`Curve.Spring` 属性不存在，需要使用其他支持的曲线类型。

## 错误位置

1. **SplashPage.ets** - 第 18 行
   - Logo 入场动画使用了 `Curve.Spring`

2. **RoleSelectPage.ets** - 第 180 行
   - 角色卡片缩放动画使用了 `Curve.Spring`

## 修复方案

将 `Curve.Spring` 替换为 `Curve.EaseInOut`，这是 HarmonyOS 支持的标准缓动曲线。

### 修复前
```typescript
animateTo({
  duration: 800,
  curve: Curve.Spring,  // ❌ 不支持
  onFinish: () => { ... }
}, () => { ... });
```

### 修复后
```typescript
animateTo({
  duration: 800,
  curve: Curve.EaseInOut,  // ✅ 支持
  onFinish: () => { ... }
}, () => { ... });
```

## HarmonyOS 支持的 Curve 类型

- `Curve.Linear` - 线性
- `Curve.Ease` - 默认缓动
- `Curve.EaseIn` - 加速
- `Curve.EaseOut` - 减速
- `Curve.EaseInOut` - 先加速后减速
- `Curve.FastOutSlowIn` - 快出慢进
- `Curve.LinearOutSlowIn` - 线性出慢进
- `Curve.FastOutLinearIn` - 快出线性进
- `Curve.ExtremeDeceleration` - 极度减速
- `Curve.Sharp` - 锐利
- `Curve.Rhythm` - 节奏
- `Curve.Smooth` - 平滑
- `Curve.Friction` - 摩擦

## 修复文件列表

1. ✅ `help_system/entry/src/main/ets/pages/SplashPage.ets`
   - 第 18 行：`Curve.Spring` → `Curve.EaseInOut`

2. ✅ `help_system/entry/src/main/ets/pages/RoleSelectPage.ets`
   - 第 180 行：`Curve.Spring` → `Curve.EaseInOut`

## 验证结果

- [x] 编译通过
- [x] 动画效果正常
- [x] 无运行时错误

## 总结

这是项目中最后一个编译错误。修复后，所有页面都能正常编译和运行。`Curve.EaseInOut` 提供了平滑的动画效果，适合用于入场动画和交互反馈。

---

**修复日期**: 2026-02-26  
**修复状态**: ✅ 完成
