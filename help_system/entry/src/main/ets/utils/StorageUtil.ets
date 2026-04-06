/**
 * 本地存储工具类
 * 使用 HarmonyOS Preferences API 实现持久化存储
 * 支持三种存储模式：
 * 1. Preferences API（生产环境，真实持久化）
 * 2. PersistentStorage（预览模式，持久化到应用数据）
 * 3. Memory Storage（降级方案，仅内存）
 */

import preferences from '@ohos.data.preferences';
import { common } from '@kit.AbilityKit';

// 存储模式枚举
enum StorageMode {
  PREFERENCES = 'PREFERENCES',      // Preferences API
  PERSISTENT = 'PERSISTENT',        // PersistentStorage
  MEMORY = 'MEMORY'                 // Memory Storage
}

export class StorageUtil {
  private static readonly STORE_NAME = 'help_system_store';
  private static dataPreferences: preferences.Preferences | null = null;
  private static currentMode: StorageMode = StorageMode.MEMORY;
  
  // 存储键名常量
  static readonly KEY_TOKEN = 'user_token';
  static readonly KEY_REFRESH_TOKEN = 'refresh_token';
  static readonly KEY_USER_INFO = 'user_info';
  static readonly KEY_SETTINGS = 'user_settings';

  /**
   * 初始化 Preferences
   * 注意：需要在组件中调用 initContext 传入 context
   */
  private static context: common.UIAbilityContext | null = null;
  private static isInitialized: boolean = false;

  /**
   * 初始化 Context（在应用启动时调用）
   */
  static initContext(ctx: common.UIAbilityContext): void {
    StorageUtil.context = ctx;
    StorageUtil.isInitialized = true;
    console.info('[StorageUtil] Context 初始化成功');
    
    // 尝试初始化 Preferences
    StorageUtil.initPreferences();
  }

  /**
   * 获取已保存的 Context（供定位等需要申请权限的工具使用）
   */
  static getContext(): common.UIAbilityContext | null {
    return StorageUtil.context;
  }

  /**
   * 初始化 Preferences（异步）
   */
  private static async initPreferences(): Promise<void> {
    if (!StorageUtil.context) {
      console.warn('[StorageUtil] Context 未设置，无法初始化 Preferences');
      return;
    }

    try {
      StorageUtil.dataPreferences = await preferences.getPreferences(StorageUtil.context, StorageUtil.STORE_NAME);
      StorageUtil.currentMode = StorageMode.PREFERENCES;
      console.info('[StorageUtil] Preferences API 初始化成功 - 使用真实持久化存储');
    } catch (err) {
      console.error('[StorageUtil] Preferences 初始化失败:', err);
      console.info('[StorageUtil] 降级到 PersistentStorage 模式');
      StorageUtil.currentMode = StorageMode.PERSISTENT;
      StorageUtil.initPersistentStorage();
    }
  }

  /**
   * 初始化 PersistentStorage（预览模式降级方案）
   */
  private static initPersistentStorage(): void {
    try {
      // 初始化 PersistentStorage 的键
      PersistentStorage.persistProp('token', '');
      PersistentStorage.persistProp('refreshToken', '');
      PersistentStorage.persistProp('user', '');
      console.info('[StorageUtil] PersistentStorage 初始化成功 - 数据会持久化到应用存储');
    } catch (err) {
      console.error('[StorageUtil] PersistentStorage 初始化失败:', err);
      console.warn('[StorageUtil] 降级到 Memory 模式 - 数据不会持久化');
      StorageUtil.currentMode = StorageMode.MEMORY;
    }
  }

  private static async getPreferences(): Promise<preferences.Preferences> {
    // 如果已经初始化了 Preferences，直接返回
    if (StorageUtil.dataPreferences !== null) {
      return StorageUtil.dataPreferences;
    }

    // 如果 context 未初始化，尝试从全局获取
    if (StorageUtil.context === null) {
      try {
        const ctx: common.UIAbilityContext | null = null;
        if (ctx) {
          StorageUtil.context = ctx;
          console.info('[StorageUtil] 从 globalThis 获取 Context 成功');
        }
      } catch (err) {
        console.warn('[StorageUtil] 无法从 globalThis 获取 Context');
      }
    }

    // 尝试初始化 Preferences
    if (StorageUtil.context !== null) {
      try {
        StorageUtil.dataPreferences = await preferences.getPreferences(StorageUtil.context, StorageUtil.STORE_NAME);
        StorageUtil.currentMode = StorageMode.PREFERENCES;
        console.info('[StorageUtil] Preferences API 初始化成功');
        return StorageUtil.dataPreferences;
      } catch (err) {
        console.error('[StorageUtil] Preferences 初始化失败:', err);
      }
    }

    // 降级到 PersistentStorage
    if (StorageUtil.currentMode !== StorageMode.PERSISTENT) {
      console.info('[StorageUtil] 降级到 PersistentStorage 模式');
      StorageUtil.currentMode = StorageMode.PERSISTENT;
      StorageUtil.initPersistentStorage();
    }

    // 返回一个模拟的 Preferences 对象
    return StorageUtil.createMemoryPreferences();
  }

  /**
   * 创建内存存储降级方案
   */
  private static memoryStorage: Map<string, preferences.ValueType> = new Map();

  private static createMemoryPreferences(): preferences.Preferences {
    console.warn('[StorageUtil] 使用 Memory 模式（数据不会持久化）');
    
    // 创建一个模拟的 Preferences 对象
    const mockPreferences = {
      put: async (key: string, value: preferences.ValueType): Promise<void> => {
        StorageUtil.memoryStorage.set(key, value);
        console.info(`[StorageUtil-Memory] 保存: ${key}`);
      },
      get: async (key: string, defValue: preferences.ValueType): Promise<preferences.ValueType> => {
        const value = StorageUtil.memoryStorage.get(key);
        console.info(`[StorageUtil-Memory] 读取: ${key} = ${value !== undefined ? '有值' : '无值'}`);
        return value !== undefined ? value : defValue;
      },
      delete: async (key: string): Promise<void> => {
        StorageUtil.memoryStorage.delete(key);
        console.info(`[StorageUtil-Memory] 删除: ${key}`);
      },
      clear: async (): Promise<void> => {
        StorageUtil.memoryStorage.clear();
        console.info('[StorageUtil-Memory] 清空所有数据');
      },
      flush: async (): Promise<void> => {
        // 内存存储不需要 flush
      },
      has: async (key: string): Promise<boolean> => {
        return StorageUtil.memoryStorage.has(key);
      },
      getAll: async (): Promise<Object> => {
        const result: Record<string, preferences.ValueType> = {};
        StorageUtil.memoryStorage.forEach((value, key) => {
          result[key] = value;
        });
        return result;
      },
      on: (): void => {
        // 内存存储不支持监听
      },
      off: (): void => {
        // 内存存储不支持监听
      },
      // 同步方法（新版本 API 要求）
      getSync: (key: string, defValue: preferences.ValueType): preferences.ValueType => {
        const value = StorageUtil.memoryStorage.get(key);
        return value !== undefined ? value : defValue;
      },
      getAllSync: (): Object => {
        const result: Record<string, preferences.ValueType> = {};
        StorageUtil.memoryStorage.forEach((value, key) => {
          result[key] = value;
        });
        return result;
      },
      hasSync: (key: string): boolean => {
        return StorageUtil.memoryStorage.has(key);
      },
      putSync: (key: string, value: preferences.ValueType): void => {
        StorageUtil.memoryStorage.set(key, value);
      },
      deleteSync: (key: string): void => {
        StorageUtil.memoryStorage.delete(key);
      },
      clearSync: (): void => {
        StorageUtil.memoryStorage.clear();
      },
      flushSync: (): void => {
        // 内存存储不需要 flush
      }
    } as preferences.Preferences;

    return mockPreferences;
  }

  /**
   * 获取当前存储模式
   */
  static getStorageMode(): string {
    return StorageUtil.currentMode;
  }

  /**
   * 保存字符串
   */
  static async saveString(key: string, value: string): Promise<boolean> {
    try {
      console.info(`[StorageUtil-${StorageUtil.currentMode}] 开始保存: ${key}`);
      
      // 如果使用 PersistentStorage 模式
      if (StorageUtil.currentMode === StorageMode.PERSISTENT) {
        try {
          AppStorage.setOrCreate(key, value);
          console.info(`[StorageUtil-PERSISTENT] 保存成功: ${key}`);
          return true;
        } catch (err) {
          console.error('[StorageUtil-PERSISTENT] 保存失败:', err);
          return false;
        }
      }
      
      // 使用 Preferences 或 Memory 模式
      const prefs = await StorageUtil.getPreferences();
      await prefs.put(key, value);
      await prefs.flush();
      console.info(`[StorageUtil-${StorageUtil.currentMode}] 保存成功: ${key}`);
      return true;
    } catch (err) {
      console.error(`[StorageUtil-${StorageUtil.currentMode}] 保存数据失败:`, err);
      return false;
    }
  }

  /**
   * 获取字符串
   */
  static async getString(key: string, defaultValue: string = ''): Promise<string> {
    try {
      console.info(`[StorageUtil-${StorageUtil.currentMode}] 开始读取: ${key}`);
      
      // 如果使用 PersistentStorage 模式
      if (StorageUtil.currentMode === StorageMode.PERSISTENT) {
        try {
          const value = AppStorage.get<string>(key);
          const result = value !== undefined ? value : defaultValue;
          console.info(`[StorageUtil-PERSISTENT] 读取结果: ${key} = ${result ? '有值' : '无值'}`);
          return result;
        } catch (err) {
          console.error('[StorageUtil-PERSISTENT] 读取失败:', err);
          return defaultValue;
        }
      }
      
      // 使用 Preferences 或 Memory 模式
      const prefs = await StorageUtil.getPreferences();
      const value = await prefs.get(key, defaultValue);
      const result = value as string;
      console.info(`[StorageUtil-${StorageUtil.currentMode}] 读取结果: ${key} = ${result ? '有值' : '无值'}`);
      return result;
    } catch (err) {
      console.error(`[StorageUtil-${StorageUtil.currentMode}] 获取数据失败:`, err);
      return defaultValue;
    }
  }

  /**
   * 保存对象（JSON）
   */
  static async saveObject(key: string, value: Object): Promise<boolean> {
    try {
      const jsonString = JSON.stringify(value);
      return await StorageUtil.saveString(key, jsonString);
    } catch (err) {
      console.error('保存对象失败:', err);
      return false;
    }
  }

  /**
   * 获取对象（JSON）
   */
  static async getObject<T>(key: string, defaultValue: T | null = null): Promise<T | null> {
    try {
      const jsonString = await StorageUtil.getString(key);
      if (jsonString) {
        return JSON.parse(jsonString) as T;
      }
      return defaultValue;
    } catch (err) {
      console.error('获取对象失败:', err);
      return defaultValue;
    }
  }

  /**
   * 删除数据
   */
  static async remove(key: string): Promise<boolean> {
    try {
      console.info(`[StorageUtil-${StorageUtil.currentMode}] 开始删除: ${key}`);
      
      // 如果使用 PersistentStorage 模式
      if (StorageUtil.currentMode === StorageMode.PERSISTENT) {
        try {
          AppStorage.delete(key);
          console.info(`[StorageUtil-PERSISTENT] 删除成功: ${key}`);
          return true;
        } catch (err) {
          console.error('[StorageUtil-PERSISTENT] 删除失败:', err);
          return false;
        }
      }
      
      // 使用 Preferences 或 Memory 模式
      const prefs = await StorageUtil.getPreferences();
      await prefs.delete(key);
      await prefs.flush();
      console.info(`[StorageUtil-${StorageUtil.currentMode}] 删除成功: ${key}`);
      return true;
    } catch (err) {
      console.error(`[StorageUtil-${StorageUtil.currentMode}] 删除数据失败:`, err);
      return false;
    }
  }

  /**
   * 清空所有数据
   */
  static async clear(): Promise<boolean> {
    try {
      console.info(`[StorageUtil-${StorageUtil.currentMode}] 开始清空所有数据`);
      
      // 如果使用 PersistentStorage 模式
      if (StorageUtil.currentMode === StorageMode.PERSISTENT) {
        try {
          AppStorage.clear();
          console.info('[StorageUtil-PERSISTENT] 清空所有数据成功');
          return true;
        } catch (err) {
          console.error('[StorageUtil-PERSISTENT] 清空数据失败:', err);
          return false;
        }
      }
      
      // 使用 Preferences 或 Memory 模式
      const prefs = await StorageUtil.getPreferences();
      await prefs.clear();
      await prefs.flush();
      console.info(`[StorageUtil-${StorageUtil.currentMode}] 清空所有数据成功`);
      return true;
    } catch (err) {
      console.error(`[StorageUtil-${StorageUtil.currentMode}] 清空数据失败:`, err);
      return false;
    }
  }

  /**
   * 保存 Token
   */
  static async saveToken(token: string, refreshToken: string): Promise<boolean> {
    const result1 = await StorageUtil.saveString(StorageUtil.KEY_TOKEN, token);
    const result2 = await StorageUtil.saveString(StorageUtil.KEY_REFRESH_TOKEN, refreshToken);
    return result1 && result2;
  }

  /**
   * 获取 Token
   */
  static async getToken(): Promise<string> {
    return await StorageUtil.getString(StorageUtil.KEY_TOKEN);
  }

  /**
   * 清除 Token
   */
  static async clearToken(): Promise<boolean> {
    const result1 = await StorageUtil.remove(StorageUtil.KEY_TOKEN);
    const result2 = await StorageUtil.remove(StorageUtil.KEY_REFRESH_TOKEN);
    return result1 && result2;
  }

  /**
   * 通用 set 方法（兼容旧代码）
   */
  static async set<T>(key: string, value: T): Promise<void> {
    if (typeof value === 'string') {
      await StorageUtil.saveString(key, value as string);
    } else {
      await StorageUtil.saveObject(key, value as Object);
    }
  }

  /**
   * 通用 get 方法（兼容旧代码）
   */
  static async get<T>(key: string, defaultValue?: T): Promise<T | null> {
    if (typeof defaultValue === 'string') {
      return await StorageUtil.getString(key, defaultValue as string) as T;
    } else {
      return await StorageUtil.getObject<T>(key, defaultValue || null);
    }
  }
}
