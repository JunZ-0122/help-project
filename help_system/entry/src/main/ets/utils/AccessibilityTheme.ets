export interface HighContrastRolePalette {
  avatarBg: string;
  avatarText: string;
  tagBg: string;
  tagText: string;
  statAccent: string;
  iconAccent: string;
}

/**
 * Elder-friendly high-contrast theme:
 * warm page background + white surfaces + strong typography + controlled borders.
 */
export class ElderHighContrastTheme {
  static readonly pageBg: string = '#f2ebe0';
  static readonly surface: string = '#ffffff';
  static readonly headerSurface: string = '#ffffff';
  static readonly inputSurface: string = '#fffdfa';
  static readonly disabledInputSurface: string = '#efe7da';
  static readonly textPrimary: string = '#1a1a1a';
  static readonly textSecondary: string = '#424242';
  static readonly textTertiary: string = '#616161';
  static readonly borderStrong: string = '#212121';
  static readonly borderWidth: number = 2;
  static readonly divider: string = '#757575';
  static readonly iconBoxBg: string = '#f7efe0';
  static readonly accentBlue: string = '#0d47a1';
  static readonly accentDanger: string = '#b71c1c';
  static readonly accentOn: string = '#2e7d32';
  static readonly tagBg: string = '#e3f2fd';
  static readonly tagText: string = '#0d47a1';
  static readonly avatarBg: string = '#0d47a1';
  static readonly avatarText: string = '#ffffff';

  private static readonly helpSeekerPalette: HighContrastRolePalette = {
    avatarBg: '#0d47a1',
    avatarText: '#ffffff',
    tagBg: '#e3f2fd',
    tagText: '#0d47a1',
    statAccent: '#1565c0',
    iconAccent: '#0d47a1'
  };

  private static readonly volunteerPalette: HighContrastRolePalette = {
    avatarBg: '#2e7d32',
    avatarText: '#ffffff',
    tagBg: '#e8f5e9',
    tagText: '#1b5e20',
    statAccent: '#2e7d32',
    iconAccent: '#2e7d32'
  };

  private static readonly communityPalette: HighContrastRolePalette = {
    avatarBg: '#ef6c00',
    avatarText: '#ffffff',
    tagBg: '#fff3e0',
    tagText: '#e65100',
    statAccent: '#ef6c00',
    iconAccent: '#ef6c00'
  };

  static cardBorder(): BorderOptions {
    return { width: ElderHighContrastTheme.borderWidth, color: ElderHighContrastTheme.borderStrong };
  }

  static subtleBorder(): BorderOptions {
    return { width: 1, color: ElderHighContrastTheme.divider };
  }

  static getRolePalette(role: string): HighContrastRolePalette {
    switch (role) {
      case 'volunteer':
        return ElderHighContrastTheme.volunteerPalette;
      case 'community':
        return ElderHighContrastTheme.communityPalette;
      case 'help-seeker':
      default:
        return ElderHighContrastTheme.helpSeekerPalette;
    }
  }
}
