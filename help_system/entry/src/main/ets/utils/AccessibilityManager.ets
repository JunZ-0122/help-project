/**
 * 全局无障碍设置管理器
 * 负责管理应用的无障碍设置，包括大字体、高对比度和震动反馈
 * 使用 AppStorage 实现全局状态管理，使用 StorageUtil 实现持久化存储
 */

import { StorageUtil } from './StorageUtil';

/**
 * 无障碍设置接口
 */
export interface AccessibilitySettings {
  largeFontEnabled: boolean;      // 大字体模式
  highContrastEnabled: boolean;   // 高对比度模式
  vibrationEnabled: boolean;      // 震动反馈
}

/**
 * 默认无障碍设置
 */
export const DEFAULT_SETTINGS: AccessibilitySettings = {
  largeFontEnabled: false,
  highContrastEnabled: false,
  vibrationEnabled: true
};

/**
 * 存储键名接口
 */
export interface StorageKeysType {
  LARGE_FONT: string;
  HIGH_CONTRAST: string;
  VIBRATION: string;
  SETTINGS_JSON: string;
}

/**
 * AppStorage 和本地存储的键名常量
 */
export const STORAGE_KEYS: StorageKeysType = {
  LARGE_FONT: 'accessibility_large_font',
  HIGH_CONTRAST: 'accessibility_high_contrast',
  VIBRATION: 'accessibility_vibration',
  SETTINGS_JSON: 'accessibility_settings'  // 本地存储键名
};

/**
 * AccessibilityManager 单例类
 * 提供无障碍设置的加载、保存、更新和查询功能
 */
export class AccessibilityManager {
  private static instance: AccessibilityManager;
  private initDoneEmitted: boolean = false;
  private initDoneResolver!: () => void;
  /** 只执行一次实际初始化，避免 onCreate 与入口重复调用导致二次 sync 覆盖用户开关 */
  private initPromise: Promise<void> | null = null;
  /** 最近一次成功执行 updateHighContrast(true) 的时间；用于拦截 Toggle 在 ~60ms 内误发的 false */
  private highContrastOpenedAtMs: number = 0;
  private static readonly HC_IGNORE_FALSE_WITHIN_MS: number = 120;

  /**
   * 在 EntryAbility.init() 完成（含异步 loadSettings）后 resolve，供页面在读取 getSettings 前 await，避免未初始化状态。
   */
  public readonly initDone: Promise<void>;

  /**
   * 私有构造函数，确保单例模式
   */
  private constructor() {
    this.initDone = new Promise<void>((resolve: () => void) => {
      this.initDoneResolver = resolve;
    });
  }

  private markInitDone(): void {
    if (this.initDoneEmitted) {
      return;
    }
    this.initDoneEmitted = true;
    this.initDoneResolver();
  }

  /**
   * 获取 AccessibilityManager 单例实例
   */
  public static getInstance(): AccessibilityManager {
    if (!AccessibilityManager.instance) {
      AccessibilityManager.instance = new AccessibilityManager();
    }
    return AccessibilityManager.instance;
  }

  /**
   * 在异步 loadSettings 之前记录 AppStorage 快照，用于检测 init 完成前用户是否已切换开关。
   * 若晚到的 sync 直接覆盖，会出现「闪一下又关」的现象。
   */
  private captureSnapshot(): AccessibilitySettings {
    return {
      largeFontEnabled: AppStorage.get<boolean>(STORAGE_KEYS.LARGE_FONT) ?? DEFAULT_SETTINGS.largeFontEnabled,
      highContrastEnabled: AppStorage.get<boolean>(STORAGE_KEYS.HIGH_CONTRAST) ?? DEFAULT_SETTINGS.highContrastEnabled,
      vibrationEnabled: AppStorage.get<boolean>(STORAGE_KEYS.VIBRATION) ?? DEFAULT_SETTINGS.vibrationEnabled
    };
  }

  /**
   * 合并磁盘配置与 init 期间用户可能已修改的值：若某键相对快照已变化，保留当前 AppStorage（用户操作优先）。
   */
  private mergeWithUserChangesDuringInit(fileSettings: AccessibilitySettings, snap: AccessibilitySettings): AccessibilitySettings {
    const curLarge = AppStorage.get<boolean>(STORAGE_KEYS.LARGE_FONT);
    const curHigh = AppStorage.get<boolean>(STORAGE_KEYS.HIGH_CONTRAST);
    const curVib = AppStorage.get<boolean>(STORAGE_KEYS.VIBRATION);

    const large = (curLarge !== undefined && curLarge !== snap.largeFontEnabled)
      ? curLarge
      : fileSettings.largeFontEnabled;
    const high = (curHigh !== undefined && curHigh !== snap.highContrastEnabled)
      ? curHigh
      : fileSettings.highContrastEnabled;
    const vib = (curVib !== undefined && curVib !== snap.vibrationEnabled)
      ? curVib
      : fileSettings.vibrationEnabled;

    return {
      largeFontEnabled: large,
      highContrastEnabled: high,
      vibrationEnabled: vib
    };
  }

  /**
   * 初始化无障碍设置（幂等：多次调用共用一个 Promise）。
   * 必须在首帧 UI（loadContent）之前完成，否则晚到的 syncToAppStorage 会覆盖用户已切换的开关。
   */
  public init(): Promise<void> {
    if (this.initPromise !== null) {
      return this.initPromise;
    }
    this.initPromise = this.runInitOnce();
    return this.initPromise;
  }

  private async runInitOnce(): Promise<void> {
    try {
      // 先初始化 PersistentStorage 的键（确保持久化）
      this.initPersistentStorageKeys();

      const snap = this.captureSnapshot();
      const fileSettings = await this.loadSettings();
      const merged = this.mergeWithUserChangesDuringInit(fileSettings, snap);
      this.syncToAppStorage(merged);
      // 与 SETTINGS_JSON 对齐，避免仅内存与文件不一致
      await this.saveSettings(merged);
      console.info('无障碍设置初始化成功:', JSON.stringify(merged));
    } catch (err) {
      console.error('初始化无障碍设置失败:', err);
      // 使用默认设置
      this.syncToAppStorage(DEFAULT_SETTINGS);
    } finally {
      this.markInitDone();
    }
  }

  /**
   * 初始化 PersistentStorage 键
   * 确保无障碍设置可以持久化
   */
  private initPersistentStorageKeys(): void {
    try {
      // 为每个无障碍设置键初始化 PersistentStorage
      PersistentStorage.persistProp(STORAGE_KEYS.LARGE_FONT, DEFAULT_SETTINGS.largeFontEnabled);
      PersistentStorage.persistProp(STORAGE_KEYS.HIGH_CONTRAST, DEFAULT_SETTINGS.highContrastEnabled);
      PersistentStorage.persistProp(STORAGE_KEYS.VIBRATION, DEFAULT_SETTINGS.vibrationEnabled);
      console.info('PersistentStorage 键初始化成功');
    } catch (err) {
      console.warn('PersistentStorage 键初始化失败:', err);
    }
  }

  /**
   * 从本地存储加载设置
   * @returns 加载的设置或默认设置
   */
  private async loadSettings(): Promise<AccessibilitySettings> {
    try {
      const data = await StorageUtil.getString(STORAGE_KEYS.SETTINGS_JSON);
      if (data) {
        const settings = JSON.parse(data) as AccessibilitySettings;
        // 验证加载的设置格式是否正确
        if (this.isValidSettings(settings)) {
          return settings;
        }
      }
    } catch (err) {
      console.error('加载无障碍设置失败:', err);
    }
    return DEFAULT_SETTINGS;
  }

  /**
   * 验证设置对象是否有效
   */
  private isValidSettings(settings: Object): boolean {
    const s = settings as AccessibilitySettings;
    return settings !== null &&
      typeof settings === 'object' &&
      typeof s.largeFontEnabled === 'boolean' &&
      typeof s.highContrastEnabled === 'boolean' &&
      typeof s.vibrationEnabled === 'boolean';
  }

  /**
   * 保存设置到本地存储
   */
  private async saveSettings(settings: AccessibilitySettings): Promise<void> {
    try {
      await StorageUtil.saveString(STORAGE_KEYS.SETTINGS_JSON, JSON.stringify(settings));
      console.info('无障碍设置保存成功');
    } catch (err) {
      console.error('保存无障碍设置失败:', err);
    }
  }

  /**
   * 同步设置到 AppStorage
   * 使所有使用 @StorageLink 的组件能够访问这些设置
   */
  private syncToAppStorage(settings: AccessibilitySettings): void {
    // 使用 AppStorage.set 更新已存在的 PersistentStorage 键
    // 这样可以触发持久化保存
    AppStorage.set<boolean>(STORAGE_KEYS.LARGE_FONT, settings.largeFontEnabled);
    AppStorage.set<boolean>(STORAGE_KEYS.HIGH_CONTRAST, settings.highContrastEnabled);
    AppStorage.set<boolean>(STORAGE_KEYS.VIBRATION, settings.vibrationEnabled);
  }

  /**
   * 获取当前设置
   * @returns 当前的无障碍设置
   */
  public getSettings(): AccessibilitySettings {
    const largeFont = AppStorage.get<boolean>(STORAGE_KEYS.LARGE_FONT);
    const highContrast = AppStorage.get<boolean>(STORAGE_KEYS.HIGH_CONTRAST);
    const vibration = AppStorage.get<boolean>(STORAGE_KEYS.VIBRATION);
    
    return {
      largeFontEnabled: largeFont !== undefined ? largeFont : false,
      highContrastEnabled: highContrast !== undefined ? highContrast : false,
      vibrationEnabled: vibration !== undefined ? vibration : true
    };
  }

  /**
   * 更新大字体设置
   * @param enabled 是否启用大字体模式
   */
  public updateLargeFont(enabled: boolean): void {
    const prev = AppStorage.get<boolean>(STORAGE_KEYS.LARGE_FONT) ?? DEFAULT_SETTINGS.largeFontEnabled;
    if (enabled === prev) {
      return;
    }
    console.info('大字体设置更新请求:', enabled);
    AppStorage.set<boolean>(STORAGE_KEYS.LARGE_FONT, enabled);
    
    // 立即构建设置对象，不依赖getSettings()
    const settings: AccessibilitySettings = {
      largeFontEnabled: enabled,
      highContrastEnabled: AppStorage.get<boolean>(STORAGE_KEYS.HIGH_CONTRAST) ?? false,
      vibrationEnabled: AppStorage.get<boolean>(STORAGE_KEYS.VIBRATION) ?? true
    };
    
    void this.saveSettings(settings);
    console.info('大字体设置已更新:', enabled);
  }

  /**
   * 仅保存大字体设置到本地存储（不更新AppStorage，避免循环触发）
   * @param enabled 是否启用大字体模式
   */
  public saveLargeFontOnly(enabled: boolean): void {
    console.info('仅保存大字体设置:', enabled);
    
    // 构建设置对象
    const settings: AccessibilitySettings = {
      largeFontEnabled: enabled,
      highContrastEnabled: AppStorage.get<boolean>(STORAGE_KEYS.HIGH_CONTRAST) ?? false,
      vibrationEnabled: AppStorage.get<boolean>(STORAGE_KEYS.VIBRATION) ?? true
    };
    
    void this.saveSettings(settings);
    console.info('大字体设置保存完成:', enabled);
  }

  /**
   * 更新高对比度设置
   * @param enabled 是否启用高对比度模式
   * @param forceUserIntent 为 true 时跳过「短时间误关」防抖（用于非系统 Toggle 的明确点击，避免误拦用户快速关）
   * @returns 是否按本次请求写入了开关。若为防抖忽略误关的「关」，返回 false。
   */
  public updateHighContrast(enabled: boolean, forceUserIntent: boolean = false): boolean {
    const now = Date.now();
    if (!forceUserIntent &&
      !enabled &&
      this.highContrastOpenedAtMs > 0 &&
      (now - this.highContrastOpenedAtMs) < AccessibilityManager.HC_IGNORE_FALSE_WITHIN_MS) {
      console.info('高对比度: 忽略短时间内的误关（Toggle 重绘联动，距上次开 < ' +
        `${AccessibilityManager.HC_IGNORE_FALSE_WITHIN_MS}ms）`);
      AppStorage.set<boolean>(STORAGE_KEYS.HIGH_CONTRAST, true);
      return false;
    }

    const prevHigh = AppStorage.get<boolean>(STORAGE_KEYS.HIGH_CONTRAST) ?? DEFAULT_SETTINGS.highContrastEnabled;
    if (enabled === prevHigh) {
      return true;
    }

    console.info('高对比度设置更新请求:', enabled);
    AppStorage.set<boolean>(STORAGE_KEYS.HIGH_CONTRAST, enabled);

    if (enabled) {
      this.highContrastOpenedAtMs = now;
    } else {
      this.highContrastOpenedAtMs = 0;
    }

    // 立即构建设置对象，不依赖getSettings()
    const settings: AccessibilitySettings = {
      largeFontEnabled: AppStorage.get<boolean>(STORAGE_KEYS.LARGE_FONT) ?? false,
      highContrastEnabled: enabled,
      vibrationEnabled: AppStorage.get<boolean>(STORAGE_KEYS.VIBRATION) ?? true
    };

    void this.saveSettings(settings);
    console.info('高对比度设置已更新:', enabled);
    return true;
  }

  /**
   * 仅保存高对比度设置到本地存储（不更新AppStorage，避免循环触发）
   */
  public saveHighContrastOnly(enabled: boolean): void {
    console.info('仅保存高对比度设置:', enabled);
    const settings: AccessibilitySettings = {
      largeFontEnabled: AppStorage.get<boolean>(STORAGE_KEYS.LARGE_FONT) ?? false,
      highContrastEnabled: enabled,
      vibrationEnabled: AppStorage.get<boolean>(STORAGE_KEYS.VIBRATION) ?? true
    };
    void this.saveSettings(settings);
    console.info('高对比度设置保存完成:', enabled);
  }

  /**
   * 更新震动反馈设置
   * @param enabled 是否启用震动反馈
   */
  public updateVibration(enabled: boolean): void {
    const prev = AppStorage.get<boolean>(STORAGE_KEYS.VIBRATION) ?? DEFAULT_SETTINGS.vibrationEnabled;
    if (enabled === prev) {
      return;
    }
    console.info('震动反馈设置更新请求:', enabled);
    AppStorage.set<boolean>(STORAGE_KEYS.VIBRATION, enabled);
    
    // 立即构建设置对象，不依赖getSettings()
    const settings: AccessibilitySettings = {
      largeFontEnabled: AppStorage.get<boolean>(STORAGE_KEYS.LARGE_FONT) ?? false,
      highContrastEnabled: AppStorage.get<boolean>(STORAGE_KEYS.HIGH_CONTRAST) ?? false,
      vibrationEnabled: enabled
    };
    
    void this.saveSettings(settings);
    console.info('震动反馈设置已更新:', enabled);

    // 如果启用震动，触发一次震动反馈
    if (enabled) {
      this.triggerVibration();
    }
  }

  /**
   * 仅保存震动反馈设置到本地存储（不更新AppStorage，避免循环触发）
   */
  public saveVibrationOnly(enabled: boolean): void {
    console.info('仅保存震动反馈设置:', enabled);
    const settings: AccessibilitySettings = {
      largeFontEnabled: AppStorage.get<boolean>(STORAGE_KEYS.LARGE_FONT) ?? false,
      highContrastEnabled: AppStorage.get<boolean>(STORAGE_KEYS.HIGH_CONTRAST) ?? false,
      vibrationEnabled: enabled
    };
    void this.saveSettings(settings);
    console.info('震动反馈设置保存完成:', enabled);
    
    if (enabled) {
      this.triggerVibration();
    }
  }

  /**
   * 触发震动反馈
   * 仅在震动反馈设置启用时触发
   * 
   * 实现要求：
   * - 检查震动反馈设置是否启用（需求 3.3）
   * - 调用 HarmonyOS 震动 API 或使用占位符（需求 4.5.4）
   * - 处理震动 API 不可用的情况
   * 
   * 使用说明：
   * 在实际设备上使用时，需要：
   * 1. 导入 vibrator 模块：import vibrator from '@ohos.vibrator';
   * 2. 在 module.json5 中添加权限：
   *    "requestPermissions": [{ "name": "ohos.permission.VIBRATE" }]
   * 3. 取消注释下方的 vibrator API 调用代码
   */
  public triggerVibration(): void {
    // 检查震动反馈设置是否启用
    const vibrationEnabled = AppStorage.get<boolean>(STORAGE_KEYS.VIBRATION) || false;
    if (!vibrationEnabled) {
      return;
    }

    try {
      // 调用 HarmonyOS 震动 API（占位符实现）
      // 实际使用时取消注释以下代码：
      // vibrator.startVibration({
      //   type: 'time',
      //   duration: 50
      // }, {
      //   id: 0,
      //   usage: 'notification'
      // });
    } catch (err) {
      // 处理震动 API 不可用的情况
      console.warn('震动功能不可用:', err);
      // 静默失败，不影响其他功能
    }
  }

  /**
   * 重置为默认设置
   */
  public async reset(): Promise<void> {
    this.highContrastOpenedAtMs = 0;
    this.syncToAppStorage(DEFAULT_SETTINGS);
    await this.saveSettings(DEFAULT_SETTINGS);
    console.info('无障碍设置已重置为默认值');
  }
}
