import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { StorageUtil } from './StorageUtil';

/**
 * 定位工具：获取当前经纬度（需在 module.json5 中声明定位权限，运行时授权）
 */
export interface LocationPoint {
  latitude: number;
  longitude: number;
}

/** 定位权限（与 module.json5 中声明一致，Permissions 为类型故用字符串再断言） */
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
    console.warn('LocationUtil: no context, cannot request permission');
    return false;
  }
  try {
    const atManager = abilityAccessCtrl.createAtManager();
    const result: PermissionRequestResultLike =
      await atManager.requestPermissionsFromUser(ctx, LOCATION_PERMISSIONS) as PermissionRequestResultLike;
    if (result.authResults && result.authResults.length > 0) {
      const granted = result.authResults.every((code: number) => code === 0);
      return granted;
    }
  } catch (err) {
    console.warn('LocationUtil requestLocationPermission failed:', JSON.stringify(err));
  }
  return false;
}

/** 定位请求参数（与 @kit.LocationKit SingleLocationRequest 兼容，便于真机与模拟器 GPS 模拟） */
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

/** 定位优先级枚举值（与 LocationKit 一致，便于模拟器 GPS 模拟快速返回） */
interface LocatingPriorityMap {
  PRIORITY_ACCURACY: number;
  PRIORITY_FAST_FIRST: number;
  PRIORITY_LOW_POWER: number;
}

const LocatingPriority: LocatingPriorityMap = {
  PRIORITY_ACCURACY: 0x201,
  PRIORITY_FAST_FIRST: 0x200,
  PRIORITY_LOW_POWER: 0x202
};

/**
 * 获取当前设备位置。若未授权或定位失败返回 null。
 * 真机：使用 GPS/网络定位；DevEco 模拟器：需先在「GPS模拟」中设置经纬度，此处会读取模拟器注入的位置。
 */
export async function getCurrentPosition(): Promise<LocationPoint | null> {
  try {
    const locationKit = await import('@kit.LocationKit');
    const kit = locationKit as LocationKitModule;
    const geo = kit.geoLocationManager;
    if (!geo || typeof geo.getCurrentLocation !== 'function') {
      return null;
    }
    const request: LocationRequestOptions = {
      locatingTimeoutMs: 15000,
      locatingPriority: LocatingPriority.PRIORITY_FAST_FIRST
    };
    const location: LocationResultLike | undefined = await geo.getCurrentLocation(request);
    if (location && typeof location.latitude === 'number' && typeof location.longitude === 'number') {
      const point: LocationPoint = { latitude: location.latitude, longitude: location.longitude };
      return point;
    }
  } catch (err) {
    console.warn('LocationUtil getCurrentPosition failed:', JSON.stringify(err));
  }
  return null;
}

/** LocationKit geoLocationManager 形状（仅用于类型） */
interface LocationKitGeoManager {
  getCurrentLocation(req: LocationRequestOptions): Promise<LocationResultLike>;
}

/** @kit.LocationKit 动态 import 结果（仅取所需属性） */
interface LocationKitModule {
  geoLocationManager?: LocationKitGeoManager;
}
