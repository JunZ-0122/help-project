/**
 * 老年人友好 · 高对比度配色（暖色浅底 + 深字 + 粗描边）
 * 避免纯黑底/大面积刺黄，减轻眩光与视疲劳；对比度满足日常阅读需求。
 */
export class ElderHighContrastTheme {
  /** 整页背景：暖米白，比纯白柔和 */
  static readonly pageBg: string = '#f2ebe0';
  /** 卡片/内容区：纯白，与背景区分 */
  static readonly surface: string = '#ffffff';
  /** 主标题、正文 */
  static readonly textPrimary: string = '#1a1a1a';
  /** 次要说明（仍保持足够对比） */
  static readonly textSecondary: string = '#424242';
  /** 辅助/占位 */
  static readonly textTertiary: string = '#616161';
  /** 卡片/模块外描边（清晰分区，便于老年人辨认区域） */
  static readonly borderStrong: string = '#212121';
  static readonly borderWidth: number = 2;
  /** 分割线 */
  static readonly divider: string = '#757575';
  /** 图标浅底块 */
  static readonly iconBoxBg: string = '#f7efe0';
  /** 主操作、链接色（深蓝，在白底上对比清晰） */
  static readonly accentBlue: string = '#0d47a1';
  /** 危险/退出 */
  static readonly accentDanger: string = '#b71c1c';
  /** 开关开启、成功态 */
  static readonly accentOn: string = '#2e7d32';
  /** 标签/弱强调底（浅蓝灰） */
  static readonly tagBg: string = '#e3f2fd';
  static readonly tagText: string = '#0d47a1';
  /** 头像渐变高对比时改为实色 */
  static readonly avatarBg: string = '#0d47a1';
  static readonly avatarText: string = '#ffffff';

  static cardBorder(): BorderOptions {
    return { width: ElderHighContrastTheme.borderWidth, color: ElderHighContrastTheme.borderStrong };
  }

  static subtleBorder(): BorderOptions {
    return { width: 1, color: ElderHighContrastTheme.divider };
  }
}
