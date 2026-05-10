import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { StorageUtil } from './StorageUtil';

/**
 * 定位工具：获取当前经纬度（需在 module.json5 中声明定位权限，并在运行时授权）
 */
export interface LocationPoint {
  latitude: number;
  longitude: number;
}

type LocationProvider = () => Promise<LocationPoint | null>;
type DelayProvider = (delayMs: number) => Promise<void>;
let lastLocationFailureReason: string = '';

/** 定位权限（与 module.json5 中声明一致，Permissions 为类型故用字符串断言） */
const LOCATION_PERMISSIONS: Permissions[] = [
  'ohos.permission.APPROXIMATELY_LOCATION' as Permissions,
  'ohos.permission.LOCATION' as Permissions
];

/** 权限请求结果（与 AbilityKit 返回结构一致） */
interface PermissionRequestResultLike {
  authResults: number[];
}

/**
 * 申请定位权限（在获取位置前调用，会弹出系统授权框）
 * @returns 是否已授权（用户同意或此前已同意）
 */
export async function requestLocationPermission(): Promise<boolean> {
  const ctx: common.UIAbilityContext | null = StorageUtil.getContext();
  if (!ctx) {
    lastLocationFailureReason = 'no context';
    console.warn('LocationUtil: no context, cannot request permission');
    return false;
  }
  try {
    const atManager = abilityAccessCtrl.createAtManager();
    const result: PermissionRequestResultLike =
      await atManager.requestPermissionsFromUser(ctx, LOCATION_PERMISSIONS) as PermissionRequestResultLike;
    if (result.authResults && result.authResults.length > 0) {
      const granted = result.authResults.every((code: number) => code === 0);
      lastLocationFailureReason = granted ? '' : 'permission denied';
      return granted;
    }
  } catch (err) {
    const businessError = err as BusinessErrorLike;
    lastLocationFailureReason = `permission error code=${businessError.code}`;
    console.warn('LocationUtil requestLocationPermission failed:', JSON.stringify(err));
  }
  return false;
}

/** 定位请求参数（与 geoLocationManager SingleLocationRequest 兼容，便于真机与模拟器 GPS 模拟） */
export interface LocationRequestOptions {
  locatingTimeoutMs: number;
  /** 定位优先级，可选：优先速度时模拟器 GPS 模拟更易返回 */
  locatingPriority?: number;
}

/** 定位结果（经纬度） */
export interface LocationResultLike {
  latitude?: number;
  longitude?: number;
}

interface SingleLocatingPriorityMap {
  PRIORITY_ACCURACY: number;
  PRIORITY_LOCATING_SPEED: number;
}

// Current HarmonyOS SingleLocationRequest priority values from SDK typings.
export const SINGLE_LOCATING_PRIORITY_ACCURACY: number = 0x501;
export const SINGLE_LOCATING_PRIORITY_SPEED: number = 0x502;

export function createSingleLocationRequest(
  locatingPriority: number = SINGLE_LOCATING_PRIORITY_SPEED
): LocationRequestOptions {
  return {
    locatingTimeoutMs: 15000,
    locatingPriority: locatingPriority
  };
}

/**
 * 获取当前设备位置。若未授权或定位失败返回 null。
 * 真机：使用 GPS/网络定位；DevEco 模拟器：需先在“GPS模拟”中设置经纬度，此处会读取模拟器注入的位置。
 */
export async function getCurrentPosition(): Promise<LocationPoint | null> {
  try {
    const geo = await getGeoLocationManager();
    if (!geo || typeof geo.getCurrentLocation !== 'function') {
      lastLocationFailureReason = 'LocationKit unavailable';
      return null;
    }
    const runtimePriority = geo.LocatingPriority?.PRIORITY_LOCATING_SPEED;
    const request = createSingleLocationRequest(
      typeof runtimePriority === 'number' ? runtimePriority : SINGLE_LOCATING_PRIORITY_SPEED
    );
    const location: LocationResultLike | undefined = await geo.getCurrentLocation(request);
    if (location && typeof location.latitude === 'number' && typeof location.longitude === 'number') {
      lastLocationFailureReason = '';
      const point: LocationPoint = { latitude: location.latitude, longitude: location.longitude };
      return point;
    }
    lastLocationFailureReason = 'no coordinates returned';
  } catch (err) {
    const businessError = err as BusinessErrorLike;
    lastLocationFailureReason = `code=${businessError.code}, message=${businessError.message}`;
    console.warn(`LocationUtil getCurrentPosition failed: code=${businessError.code}, message=${businessError.message}`);
    const geo = await getGeoLocationManager();
    if (geo && typeof geo.getLastLocation === 'function') {
      try {
        const lastLocation = geo.getLastLocation();
        if (lastLocation &&
          typeof lastLocation.latitude === 'number' &&
          typeof lastLocation.longitude === 'number') {
          lastLocationFailureReason = '';
          return {
            latitude: lastLocation.latitude,
            longitude: lastLocation.longitude
          };
        }
      } catch (lastErr) {
        const lastBusinessError = lastErr as BusinessErrorLike;
        lastLocationFailureReason = `lastLocation code=${lastBusinessError.code}, message=${lastBusinessError.message}`;
        console.warn(`LocationUtil getLastLocation failed: code=${lastBusinessError.code}, message=${lastBusinessError.message}`);
      }
    }
  }
  return null;
}

async function getGeoLocationManager(): Promise<LocationKitGeoManager | undefined> {
  const locationModule = await import('@ohos.geoLocationManager');
  const moduleWithDefault = locationModule as GeoLocationModuleLike;
  return moduleWithDefault.default;
}

export function getLastLocationFailureReason(): string {
  return lastLocationFailureReason;
}

async function waitForRetry(delayMs: number): Promise<void> {
  await new Promise<void>((resolve) => {
    setTimeout(() => {
      resolve();
    }, delayMs);
  });
}

export async function retryGetCurrentPosition(
  provider: LocationProvider = getCurrentPosition,
  maxAttempts: number = 3,
  delayProvider: DelayProvider = waitForRetry,
  delayMs: number = 700
): Promise<LocationPoint | null> {
  const attempts = maxAttempts > 0 ? maxAttempts : 1;
  for (let attempt = 0; attempt < attempts; attempt++) {
    const position = await provider();
    if (position) {
      return position;
    }
    if (attempt < attempts - 1) {
      await delayProvider(delayMs);
    }
  }
  return null;
}

/** LocationKit geoLocationManager 形状（仅用于类型） */
interface LocationKitGeoManager {
  LocatingPriority?: SingleLocatingPriorityMap;
  getCurrentLocation(req: LocationRequestOptions): Promise<LocationResultLike>;
  getLastLocation?(): LocationResultLike;
}

interface BusinessErrorLike {
  code?: number;
  message?: string;
}

interface GeoLocationModuleLike {
  default?: LocationKitGeoManager;
}
