export class DateUtil {
  static format(date: Date | number | string, format: string = 'YYYY-MM-DD HH:mm:ss'): string {
    const d: Date = typeof date === 'string'
      ? new Date(date)
      : (typeof date === 'number' ? new Date(date) : date);

    const year: string = d.getFullYear().toString();
    const month: string = (d.getMonth() + 1).toString().padStart(2, '0');
    const day: string = d.getDate().toString().padStart(2, '0');
    const hours: string = d.getHours().toString().padStart(2, '0');
    const minutes: string = d.getMinutes().toString().padStart(2, '0');
    const seconds: string = d.getSeconds().toString().padStart(2, '0');

    return format
      .replace('YYYY', year)
      .replace('MM', month)
      .replace('DD', day)
      .replace('HH', hours)
      .replace('mm', minutes)
      .replace('ss', seconds);
  }

  static getRelativeTime(date: Date | number | string): string {
    const d: Date = typeof date === 'string'
      ? new Date(date)
      : (typeof date === 'number' ? new Date(date) : date);
    const now: Date = new Date();
    const diff: number = now.getTime() - d.getTime();

    const seconds: number = Math.floor(diff / 1000);
    const minutes: number = Math.floor(seconds / 60);
    const hours: number = Math.floor(minutes / 60);
    const days: number = Math.floor(hours / 24);

    if (seconds < 60) {
      return '刚刚';
    }
    if (minutes < 60) {
      return minutes.toString() + '分钟前';
    }
    if (hours < 24) {
      return hours.toString() + '小时前';
    }
    if (days === 1) {
      return '昨天';
    }
    if (days < 7) {
      return days.toString() + '天前';
    }
    return DateUtil.format(d, 'MM-DD');
  }

  static getToday(): string {
    return DateUtil.format(new Date(), 'YYYY-MM-DD');
  }

  static getNow(): string {
    return DateUtil.format(new Date(), 'HH:mm');
  }

  /** 中文展示：2月11日 10:30 */
  static formatCnMonthDayTime(date: Date | number | string): string {
    const d: Date = typeof date === 'string'
      ? new Date(date)
      : (typeof date === 'number' ? new Date(date) : date);
    const m = d.getMonth() + 1;
    const day = d.getDate();
    const hours = d.getHours().toString().padStart(2, '0');
    const minutes = d.getMinutes().toString().padStart(2, '0');
    return `${m}\u6708${day}\u65e5 ${hours}:${minutes}`;
  }

  static isToday(date: Date | number | string): boolean {
    const d: Date = typeof date === 'string'
      ? new Date(date)
      : (typeof date === 'number' ? new Date(date) : date);
    const today: Date = new Date();
    return d.getFullYear() === today.getFullYear() &&
      d.getMonth() === today.getMonth() &&
      d.getDate() === today.getDate();
  }

  static isYesterday(date: Date | number | string): boolean {
    const d: Date = typeof date === 'string'
      ? new Date(date)
      : (typeof date === 'number' ? new Date(date) : date);
    const yesterday: Date = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    return d.getFullYear() === yesterday.getFullYear() &&
      d.getMonth() === yesterday.getMonth() &&
      d.getDate() === yesterday.getDate();
  }

  static getDaysDiff(date1: Date | number | string, date2: Date | number | string): number {
    const d1: Date = typeof date1 === 'string'
      ? new Date(date1)
      : (typeof date1 === 'number' ? new Date(date1) : date1);
    const d2: Date = typeof date2 === 'string'
      ? new Date(date2)
      : (typeof date2 === 'number' ? new Date(date2) : date2);
    const diff: number = Math.abs(d1.getTime() - d2.getTime());
    return Math.floor(diff / (1000 * 60 * 60 * 24));
  }
}
