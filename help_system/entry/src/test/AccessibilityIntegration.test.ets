import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { AccessibilityManager, DEFAULT_SETTINGS, STORAGE_KEYS, AccessibilitySettings } from '../main/ets/utils/AccessibilityManager';
import { StorageUtil } from '../main/ets/utils/StorageUtil';

/**
 * 无障碍功能集成测试
 * 
 * 测试完整的用户流程和多个设置的交互
 */
export default function accessibilityIntegrationTest() {
  describe('Accessibility Integration Tests', () => {
    let manager: AccessibilityManager;

    beforeEach(async () => {
      manager = AccessibilityManager.getInstance();
      // 确保每个测试开始时都是干净的状态
      await StorageUtil.remove(STORAGE_KEYS.SETTINGS_JSON);
      await manager.reset();
    });

    afterEach(async () => {
      // 清理测试数据
      await StorageUtil.remove(STORAGE_KEYS.SETTINGS_JSON);
      await manager.reset();
    });

    describe('Complete User Flow: Settings → Navigation → Restart', () => {
      it('should persist settings through complete user flow', 0, async () => {
        // 步骤 1: 用户在个人中心设置无障碍选项
        await manager.updateLargeFont(true);
        await manager.updateHighContrast(true);
        await manager.updateVibration(false);
        
        // 验证设置已应用到 AppStorage（模拟 UI 立即更新）
        let largeFontEnabled = AppStorage.get<boolean>(STORAGE_KEYS.LARGE_FONT);
        let highContrastEnabled = AppStorage.get<boolean>(STORAGE_KEYS.HIGH_CONTRAST);
        let vibrationEnabled = AppStorage.get<boolean>(STORAGE_KEYS.VIBRATION);
        
        expect(largeFontEnabled).assertEqual(true);
        expect(highContrastEnabled).assertEqual(true);
        expect(vibrationEnabled).assertEqual(false);
        
        // 步骤 2: 用户导航到其他页面（模拟页面切换）
        // 在真实场景中，新页面会通过 @StorageLink 读取 AppStorage
        // 这里我们模拟多次页面导航
        for (let i = 0; i < 5; i++) {
          // 模拟新页面读取设置
          const settings = manager.getSettings();
          expect(settings.largeFontEnabled).assertEqual(true);
          expect(settings.highContrastEnabled).assertEqual(true);
          expect(settings.vibrationEnabled).assertEqual(false);
        }
        
        // 验证 AppStorage 中的值在导航过程中保持不变
        largeFontEnabled = AppStorage.get<boolean>(STORAGE_KEYS.LARGE_FONT);
        highContrastEnabled = AppStorage.get<boolean>(STORAGE_KEYS.HIGH_CONTRAST);
        vibrationEnabled = AppStorage.get<boolean>(STORAGE_KEYS.VIBRATION);
        
        expect(largeFontEnabled).assertEqual(true);
        expect(highContrastEnabled).assertEqual(true);
        expect(vibrationEnabled).assertEqual(false);
        
        // 步骤 3: 验证设置已保存到本地存储
        const savedData = await StorageUtil.getString(STORAGE_KEYS.SETTINGS_JSON);
        expect(savedData).assertNotNull();
        
        const savedSettings = JSON.parse(savedData) as AccessibilitySettings;
        expect(savedSettings.largeFontEnabled).assertEqual(true);
        expect(savedSettings.highContrastEnabled).assertEqual(true);
        expect(savedSettings.vibrationEnabled).assertEqual(false);
        
        // 步骤 4: 模拟应用重启（重新初始化 AccessibilityManager）
        await manager.init();
        
        // 步骤 5: 验证设置在重启后恢复
        const restoredSettings = manager.getSettings();
        expect(restoredSettings.largeFontEnabled).assertEqual(true);
        expect(restoredSettings.highContrastEnabled).assertEqual(true);
        expect(restoredSettings.vibrationEnabled).assertEqual(false);
        
        // 验证 AppStorage 也已恢复
        largeFontEnabled = AppStorage.get<boolean>(STORAGE_KEYS.LARGE_FONT);
        highContrastEnabled = AppStorage.get<boolean>(STORAGE_KEYS.HIGH_CONTRAST);
        vibrationEnabled = AppStorage.get<boolean>(STORAGE_KEYS.VIBRATION);
        
        expect(largeFontEnabled).assertEqual(true);
        expect(highContrastEnabled).assertEqual(true);
        expect(vibrationEnabled).assertEqual(false);
      });

      it('should handle settings changes during navigation', 0, async () => {
        // 初始设置
        await manager.updateLargeFont(true);
        
        // 模拟用户在页面 A
        let settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(true);
        
        // 用户导航到页面 B 并修改设置
        await manager.updateHighContrast(true);
        
        // 验证两个设置都生效
        settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(true);
        expect(settings.highContrastEnabled).assertEqual(true);
        
        // 用户导航到页面 C
        settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(true);
        expect(settings.highContrastEnabled).assertEqual(true);
        
        // 用户在页面 C 修改设置
        await manager.updateLargeFont(false);
        
        // 验证最新设置生效
        settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(false);
        expect(settings.highContrastEnabled).assertEqual(true);
      });

      it('should maintain settings consistency across app lifecycle', 0, async () => {
        // 第一次使用：设置无障碍选项
        await manager.updateLargeFont(true);
        await manager.updateVibration(false);
        
        // 模拟应用关闭和重启
        await manager.init();
        
        // 验证设置恢复
        let settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(true);
        expect(settings.vibrationEnabled).assertEqual(false);
        
        // 用户修改设置
        await manager.updateHighContrast(true);
        
        // 再次模拟应用关闭和重启
        await manager.init();
        
        // 验证所有设置都恢复
        settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(true);
        expect(settings.highContrastEnabled).assertEqual(true);
        expect(settings.vibrationEnabled).assertEqual(false);
      });
    });

    describe('Multiple Settings Enabled Simultaneously', () => {
      it('should handle all three settings enabled at once', 0, async () => {
        // 启用所有无障碍设置
        await manager.updateLargeFont(true);
        await manager.updateHighContrast(true);
        await manager.updateVibration(true);
        
        // 验证所有设置都已启用
        const settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(true);
        expect(settings.highContrastEnabled).assertEqual(true);
        expect(settings.vibrationEnabled).assertEqual(true);
        
        // 验证 AppStorage 中的值
        const largeFontEnabled = AppStorage.get<boolean>(STORAGE_KEYS.LARGE_FONT);
        const highContrastEnabled = AppStorage.get<boolean>(STORAGE_KEYS.HIGH_CONTRAST);
        const vibrationEnabled = AppStorage.get<boolean>(STORAGE_KEYS.VIBRATION);
        
        expect(largeFontEnabled).assertEqual(true);
        expect(highContrastEnabled).assertEqual(true);
        expect(vibrationEnabled).assertEqual(true);
        
        // 验证设置已保存
        const savedData = await StorageUtil.getString(STORAGE_KEYS.SETTINGS_JSON);
        const savedSettings = JSON.parse(savedData) as AccessibilitySettings;
        
        expect(savedSettings.largeFontEnabled).assertEqual(true);
        expect(savedSettings.highContrastEnabled).assertEqual(true);
        expect(savedSettings.vibrationEnabled).assertEqual(true);
      });

      it('should handle two settings enabled (large font + high contrast)', 0, async () => {
        // 启用大字体和高对比度
        await manager.updateLargeFont(true);
        await manager.updateHighContrast(true);
        
        // 验证设置
        const settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(true);
        expect(settings.highContrastEnabled).assertEqual(true);
        expect(settings.vibrationEnabled).assertEqual(DEFAULT_SETTINGS.vibrationEnabled);
        
        // 模拟应用重启
        await manager.init();
        
        // 验证设置恢复
        const restoredSettings = manager.getSettings();
        expect(restoredSettings.largeFontEnabled).assertEqual(true);
        expect(restoredSettings.highContrastEnabled).assertEqual(true);
      });

      it('should handle two settings enabled (large font + vibration)', 0, async () => {
        // 启用大字体和震动反馈
        await manager.updateLargeFont(true);
        await manager.updateVibration(true);
        
        // 验证设置
        const settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(true);
        expect(settings.highContrastEnabled).assertEqual(DEFAULT_SETTINGS.highContrastEnabled);
        expect(settings.vibrationEnabled).assertEqual(true);
        
        // 模拟应用重启
        await manager.init();
        
        // 验证设置恢复
        const restoredSettings = manager.getSettings();
        expect(restoredSettings.largeFontEnabled).assertEqual(true);
        expect(restoredSettings.vibrationEnabled).assertEqual(true);
      });

      it('should handle two settings enabled (high contrast + vibration)', 0, async () => {
        // 启用高对比度和震动反馈
        await manager.updateHighContrast(true);
        await manager.updateVibration(true);
        
        // 验证设置
        const settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(DEFAULT_SETTINGS.largeFontEnabled);
        expect(settings.highContrastEnabled).assertEqual(true);
        expect(settings.vibrationEnabled).assertEqual(true);
        
        // 模拟应用重启
        await manager.init();
        
        // 验证设置恢复
        const restoredSettings = manager.getSettings();
        expect(restoredSettings.highContrastEnabled).assertEqual(true);
        expect(restoredSettings.vibrationEnabled).assertEqual(true);
      });

      it('should handle sequential enabling of all settings', 0, async () => {
        // 逐个启用设置
        await manager.updateLargeFont(true);
        
        let settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(true);
        expect(settings.highContrastEnabled).assertEqual(false);
        expect(settings.vibrationEnabled).assertEqual(DEFAULT_SETTINGS.vibrationEnabled);
        
        await manager.updateHighContrast(true);
        
        settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(true);
        expect(settings.highContrastEnabled).assertEqual(true);
        expect(settings.vibrationEnabled).assertEqual(DEFAULT_SETTINGS.vibrationEnabled);
        
        await manager.updateVibration(false);
        
        settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(true);
        expect(settings.highContrastEnabled).assertEqual(true);
        expect(settings.vibrationEnabled).assertEqual(false);
      });

      it('should handle disabling settings one by one', 0, async () => {
        // 先启用所有设置
        await manager.updateLargeFont(true);
        await manager.updateHighContrast(true);
        await manager.updateVibration(true);
        
        // 逐个禁用设置
        await manager.updateLargeFont(false);
        
        let settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(false);
        expect(settings.highContrastEnabled).assertEqual(true);
        expect(settings.vibrationEnabled).assertEqual(true);
        
        await manager.updateHighContrast(false);
        
        settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(false);
        expect(settings.highContrastEnabled).assertEqual(false);
        expect(settings.vibrationEnabled).assertEqual(true);
        
        await manager.updateVibration(false);
        
        settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(false);
        expect(settings.highContrastEnabled).assertEqual(false);
        expect(settings.vibrationEnabled).assertEqual(false);
      });

      it('should persist multiple settings through restart', 0, async () => {
        // 启用多个设置
        await manager.updateLargeFont(true);
        await manager.updateHighContrast(true);
        
        // 模拟应用重启
        await manager.init();
        
        // 验证设置恢复
        let settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(true);
        expect(settings.highContrastEnabled).assertEqual(true);
        
        // 修改一个设置
        await manager.updateVibration(false);
        
        // 再次模拟应用重启
        await manager.init();
        
        // 验证所有设置都恢复
        settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(true);
        expect(settings.highContrastEnabled).assertEqual(true);
        expect(settings.vibrationEnabled).assertEqual(false);
      });
    });

    describe('Settings Reset Functionality', () => {
      it('should reset all settings to default values', 0, async () => {
        // 设置一些非默认值
        await manager.updateLargeFont(true);
        await manager.updateHighContrast(true);
        await manager.updateVibration(false);
        
        // 验证设置已更新
        let settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(true);
        expect(settings.highContrastEnabled).assertEqual(true);
        expect(settings.vibrationEnabled).assertEqual(false);
        
        // 重置设置
        await manager.reset();
        
        // 验证设置已重置为默认值
        settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(DEFAULT_SETTINGS.largeFontEnabled);
        expect(settings.highContrastEnabled).assertEqual(DEFAULT_SETTINGS.highContrastEnabled);
        expect(settings.vibrationEnabled).assertEqual(DEFAULT_SETTINGS.vibrationEnabled);
      });

      it('should persist reset settings to storage', 0, async () => {
        // 设置一些非默认值
        await manager.updateLargeFont(true);
        await manager.updateHighContrast(true);
        
        // 重置设置
        await manager.reset();
        
        // 验证本地存储中的值已重置
        const savedData = await StorageUtil.getString(STORAGE_KEYS.SETTINGS_JSON);
        const savedSettings = JSON.parse(savedData) as AccessibilitySettings;
        
        expect(savedSettings.largeFontEnabled).assertEqual(DEFAULT_SETTINGS.largeFontEnabled);
        expect(savedSettings.highContrastEnabled).assertEqual(DEFAULT_SETTINGS.highContrastEnabled);
        expect(savedSettings.vibrationEnabled).assertEqual(DEFAULT_SETTINGS.vibrationEnabled);
      });

      it('should sync reset settings to AppStorage', 0, async () => {
        // 设置一些非默认值
        await manager.updateLargeFont(true);
        await manager.updateHighContrast(true);
        
        // 重置设置
        await manager.reset();
        
        // 验证 AppStorage 中的值已重置
        const largeFontEnabled = AppStorage.get<boolean>(STORAGE_KEYS.LARGE_FONT);
        const highContrastEnabled = AppStorage.get<boolean>(STORAGE_KEYS.HIGH_CONTRAST);
        const vibrationEnabled = AppStorage.get<boolean>(STORAGE_KEYS.VIBRATION);
        
        expect(largeFontEnabled).assertEqual(DEFAULT_SETTINGS.largeFontEnabled);
        expect(highContrastEnabled).assertEqual(DEFAULT_SETTINGS.highContrastEnabled);
        expect(vibrationEnabled).assertEqual(DEFAULT_SETTINGS.vibrationEnabled);
      });

      it('should maintain reset settings after app restart', 0, async () => {
        // 设置一些非默认值
        await manager.updateLargeFont(true);
        await manager.updateVibration(false);
        
        // 重置设置
        await manager.reset();
        
        // 模拟应用重启
        await manager.init();
        
        // 验证设置仍然是默认值
        const settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(DEFAULT_SETTINGS.largeFontEnabled);
        expect(settings.highContrastEnabled).assertEqual(DEFAULT_SETTINGS.highContrastEnabled);
        expect(settings.vibrationEnabled).assertEqual(DEFAULT_SETTINGS.vibrationEnabled);
      });

      it('should handle reset when already at default values', 0, async () => {
        // 确保设置已经是默认值
        await manager.reset();
        
        let settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(DEFAULT_SETTINGS.largeFontEnabled);
        expect(settings.highContrastEnabled).assertEqual(DEFAULT_SETTINGS.highContrastEnabled);
        expect(settings.vibrationEnabled).assertEqual(DEFAULT_SETTINGS.vibrationEnabled);
        
        // 再次重置
        await manager.reset();
        
        // 验证设置仍然是默认值
        settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(DEFAULT_SETTINGS.largeFontEnabled);
        expect(settings.highContrastEnabled).assertEqual(DEFAULT_SETTINGS.highContrastEnabled);
        expect(settings.vibrationEnabled).assertEqual(DEFAULT_SETTINGS.vibrationEnabled);
      });

      it('should allow setting new values after reset', 0, async () => {
        // 设置一些值
        await manager.updateLargeFont(true);
        await manager.updateHighContrast(true);
        
        // 重置
        await manager.reset();
        
        // 验证重置成功
        let settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(DEFAULT_SETTINGS.largeFontEnabled);
        expect(settings.highContrastEnabled).assertEqual(DEFAULT_SETTINGS.highContrastEnabled);
        
        // 设置新值
        await manager.updateLargeFont(true);
        await manager.updateVibration(false);
        
        // 验证新值生效
        settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(true);
        expect(settings.vibrationEnabled).assertEqual(false);
      });

      it('should handle multiple reset operations', 0, async () => {
        // 第一次：设置 -> 重置
        await manager.updateLargeFont(true);
        await manager.reset();
        
        let settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(DEFAULT_SETTINGS.largeFontEnabled);
        
        // 第二次：设置 -> 重置
        await manager.updateHighContrast(true);
        await manager.reset();
        
        settings = manager.getSettings();
        expect(settings.highContrastEnabled).assertEqual(DEFAULT_SETTINGS.highContrastEnabled);
        
        // 第三次：设置 -> 重置
        await manager.updateVibration(false);
        await manager.reset();
        
        settings = manager.getSettings();
        expect(settings.vibrationEnabled).assertEqual(DEFAULT_SETTINGS.vibrationEnabled);
      });
    });

    describe('Complex Integration Scenarios', () => {
      it('should handle rapid setting changes with navigation', 0, async () => {
        // 快速修改设置并导航
        await manager.updateLargeFont(true);
        let settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(true);
        
        await manager.updateHighContrast(true);
        settings = manager.getSettings();
        expect(settings.highContrastEnabled).assertEqual(true);
        
        await manager.updateLargeFont(false);
        settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(false);
        
        await manager.updateVibration(false);
        settings = manager.getSettings();
        expect(settings.vibrationEnabled).assertEqual(false);
        
        // 验证最终状态
        expect(settings.largeFontEnabled).assertEqual(false);
        expect(settings.highContrastEnabled).assertEqual(true);
        expect(settings.vibrationEnabled).assertEqual(false);
      });

      it('should handle settings changes, reset, and restart cycle', 0, async () => {
        // 设置 -> 重置 -> 重启 -> 设置 -> 重启
        await manager.updateLargeFont(true);
        await manager.updateHighContrast(true);
        
        await manager.reset();
        
        await manager.init();
        let settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(DEFAULT_SETTINGS.largeFontEnabled);
        expect(settings.highContrastEnabled).assertEqual(DEFAULT_SETTINGS.highContrastEnabled);
        
        await manager.updateVibration(false);
        
        await manager.init();
        settings = manager.getSettings();
        expect(settings.vibrationEnabled).assertEqual(false);
      });

      it('should maintain data integrity across multiple operations', 0, async () => {
        // 复杂的操作序列
        await manager.updateLargeFont(true);
        await manager.updateHighContrast(true);
        await manager.updateVibration(false);
        
        // 验证状态
        let settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(true);
        expect(settings.highContrastEnabled).assertEqual(true);
        expect(settings.vibrationEnabled).assertEqual(false);
        
        // 模拟重启
        await manager.init();
        
        // 修改一个设置
        await manager.updateLargeFont(false);
        
        // 验证其他设置不受影响
        settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(false);
        expect(settings.highContrastEnabled).assertEqual(true);
        expect(settings.vibrationEnabled).assertEqual(false);
        
        // 重置
        await manager.reset();
        
        // 验证所有设置都重置
        settings = manager.getSettings();
        expect(settings.largeFontEnabled).assertEqual(DEFAULT_SETTINGS.largeFontEnabled);
        expect(settings.highContrastEnabled).assertEqual(DEFAULT_SETTINGS.highContrastEnabled);
        expect(settings.vibrationEnabled).assertEqual(DEFAULT_SETTINGS.vibrationEnabled);
      });
    });
  });
}
