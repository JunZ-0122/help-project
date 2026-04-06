import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AccessibilityManager } from '../utils/AccessibilityManager';
import { StorageUtil } from '../utils/StorageUtil';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 初始化 StorageUtil（必须在最开始）
    StorageUtil.initContext(this.context);
    hilog.info(DOMAIN, 'testTag', 'StorageUtil initialized');

    // 无障碍 init 延后到 onWindowStageCreate 中、loadContent 之前完成，避免晚到的 sync 覆盖用户已切换的开关

    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    const loadMainAndConfigureBar = (): void => {
      windowStage.loadContent('pages/Index', (err) => {
        if (err.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
          return;
        }
        hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');

        // 配置状态栏显示
        windowStage.getMainWindow().then((windowClass) => {
          windowClass.setWindowSystemBarEnable(['status']).then(() => {
            hilog.info(DOMAIN, 'testTag', 'Succeeded in enabling status bar.');

            const systemBarProperties: window.SystemBarProperties = {
              statusBarColor: '#ffffff',
              statusBarContentColor: '#000000',
              isStatusBarLightIcon: false
            };

            windowClass.setWindowSystemBarProperties(systemBarProperties).then(() => {
              hilog.info(DOMAIN, 'testTag', 'Succeeded in setting system bar properties.');
            }).catch((e: Error) => {
              hilog.error(DOMAIN, 'testTag', 'Failed to set system bar properties. Cause: %{public}s', JSON.stringify(e));
            });
          }).catch((e: Error) => {
            hilog.error(DOMAIN, 'testTag', 'Failed to enable status bar. Cause: %{public}s', JSON.stringify(e));
          });
        }).catch((e: Error) => {
          hilog.error(DOMAIN, 'testTag', 'Failed to get main window. Cause: %{public}s', JSON.stringify(e));
        });
      });
    };

    AccessibilityManager.getInstance().init()
      .then(() => {
        hilog.info(DOMAIN, 'testTag', 'AccessibilityManager initialized before loadContent');
        loadMainAndConfigureBar();
      })
      .catch((err: Error) => {
        hilog.error(DOMAIN, 'testTag', 'Failed to initialize AccessibilityManager. Cause: %{public}s', JSON.stringify(err));
        loadMainAndConfigureBar();
      });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}