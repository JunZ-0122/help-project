/**
 * 设置相关实体
 */

/**
 * 勿扰时段设置
 */
export interface DoNotDisturbSettings {
  enabled: boolean;
  startTime: string;
  endTime: string;
}

/**
 * 用户设置
 */
export interface UserSettings {
  userId: string;
  // 通知设置
  notifications: NotificationSettings;
  // 隐私设置
  privacy: PrivacySettings;
  // 无障碍设置
  accessibility: AccessibilitySettings;
  // 语言设置
  language: 'zh-CN' | 'en-US';
  // 主题设置
  theme: 'light' | 'dark' | 'auto';
}

/**
 * 通知设置
 */
export interface NotificationSettings {
  enabled: boolean;
  requestNotification: boolean;
  messageNotification: boolean;
  orderNotification: boolean;
  systemNotification: boolean;
  sound: boolean;
  vibration: boolean;
  doNotDisturb: DoNotDisturbSettings;
}

/**
 * 隐私设置
 */
export interface PrivacySettings {
  showPhone: boolean;
  showLocation: boolean;
  showOnlineStatus: boolean;
  allowStrangerMessage: boolean;
}

/**
 * 无障碍设置
 */
export interface AccessibilitySettings {
  largeFontEnabled: boolean;
  fontSize: 'small' | 'medium' | 'large' | 'extra-large';
  highContrastEnabled: boolean;
  voiceAssistEnabled: boolean;
  vibrationFeedback: boolean;
  screenReaderEnabled: boolean;
}

/**
 * 系统配置
 */
export interface SystemConfig {
  version: string;
  minVersion: string;
  updateUrl?: string;
  maintenanceMode: boolean;
  maintenanceMessage?: string;
  features: FeatureFlags;
}

/**
 * 功能开关
 */
export interface FeatureFlags {
  chat: boolean;
  emergency: boolean;
  community: boolean;
  review: boolean;
}
