import deviceInfo from '@ohos.deviceInfo';
import display from '@ohos.display';

/**
 * 判断是否为可穿戴（手表）设备。
 * 说明：部分模拟器/系统上 deviceType 不是字符串 wearable，而是数字枚举，
 * 因此增加数字与屏幕尺寸兜底，避免误判为手机而走 SplashPage。
 */
export function isWearableDevice(): boolean {
  try {
    const t = deviceInfo.deviceType;
    if (typeof t === 'string') {
      return t.toLowerCase() === 'wearable';
    }
    if (typeof t === 'number') {
      // 不同 API 版本枚举值可能不同，常见手表为 5/6
      if (t === 5 || t === 6) {
        return true;
      }
    }
  } catch (_e) {
    // ignore
  }

  try {
    const d = display.getDefaultDisplaySync();
    const w = d.width;
    const h = d.height;
    const minE = Math.min(w, h);
    const maxE = Math.max(w, h);
    // 圆形表盘常见约 390~480；手机竖屏宽可小但高远大于宽
    if (minE > 0 && maxE > 0 && minE <= 520 && maxE <= 520) {
      return true;
    }
  } catch (_e) {
    // ignore
  }

  return false;
}

export function isPhoneDevice(): boolean {
  return !isWearableDevice();
}
