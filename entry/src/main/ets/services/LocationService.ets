import {
  abilityAccessCtrl,
  common
} from '@kit.AbilityKit';
import { geoLocationManager } from '@kit.LocationKit';

export interface LocationData {
  latitude: number;
  longitude: number;
}

/**
 * 鸿蒙定位服务。
 */
export class LocationService {

  async getCurrentLocation(
    context: common.UIAbilityContext
  ): Promise<LocationData> {
    const atManager =
      abilityAccessCtrl.createAtManager();

    const permissionResult =
      await atManager.requestPermissionsFromUser(
        context,
        [
          'ohos.permission.LOCATION',
          'ohos.permission.APPROXIMATELY_LOCATION'
        ]
      );

    let permissionGranted: boolean = false;

    for (
      let i = 0;
      i < permissionResult.authResults.length;
      i++
    ) {
      if (permissionResult.authResults[i] === 0) {
        permissionGranted = true;
        break;
      }
    }

    if (!permissionGranted) {
      throw new Error(
        '定位权限未授权，请在系统设置中允许定位权限'
      );
    }

    if (!geoLocationManager.isLocationEnabled()) {
      throw new Error(
        '系统定位服务未开启，请开启定位功能'
      );
    }

    const locationRequest:
      geoLocationManager.CurrentLocationRequest = {
      priority:
        geoLocationManager.LocationRequestPriority.FIRST_FIX,
      scenario:
        geoLocationManager.LocationRequestScenario.UNSET,
      maxAccuracy: 100
    };

    const location =
      await geoLocationManager.getCurrentLocation(
        locationRequest
      );

    if (!location) {
      throw new Error(
        '未获取到有效位置信息'
      );
    }

    return {
      latitude: location.latitude,
      longitude: location.longitude
    };
  }
}
