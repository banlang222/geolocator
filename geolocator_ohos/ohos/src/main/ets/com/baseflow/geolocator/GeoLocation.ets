import { abilityAccessCtrl, bundleManager, Permissions, UIAbility } from '@kit.AbilityKit';
import { Log, MethodResult } from '@ohos/flutter_ohos';
import { geoLocationManager } from '@kit.LocationKit';
import { EventSink } from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';
import { BusinessError, emitter } from '@kit.BasicServicesKit';

const TAG = "Geolocation";

export default class Geolocation {
  ability: UIAbility | null = null;
  events: EventSink | null = null;
  result: MethodResult | null = null;
  getLocationResult: MethodResult | null = null;

  private tokenId: number | null = null;
  private atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
  private requestInfo: geoLocationManager.LocationRequest = {
    'priority': geoLocationManager.LocationRequestPriority.FIRST_FIX,
    'scenario': geoLocationManager.LocationRequestScenario.UNSET,
    'timeInterval': 0,
    'distanceInterval': 0,
    'maxAccuracy': 0
  };

  private locationCallback = (location: geoLocationManager.Location) => {
    let loc: Map<string, number> = new Map<string,number>();
    loc.set("latitude", location.latitude);
    loc.set("longitude", location.longitude);
    loc.set("altitude", location.altitude);
    loc.set("accuracy", location.accuracy);
    loc.set("speed", location.speed);
    loc.set("heading", location.direction);

    //单次定位数据返回后销毁通道
    if(this.getLocationResult != null) {
      this.getLocationResult.success(loc);
      this.getLocationResult = null;
    }
    //存在stream通道，持续发送位置； cancel后events=null，停止监听locationChange
    if(this.events != null) {
      this.events.success(loc);
    } else {
      geoLocationManager.off("locationChange", this.locationCallback);
    }
  }

  setAbility(ability: UIAbility | null) {
    this.ability = ability;
  }

  getTokenId(): void {
    if(!this.tokenId) {
      let bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      this.tokenId = bundleInfo.appInfo.accessTokenId;
    }
  }
  checkPermission() : boolean {
    this.getTokenId();
    let locationPermissionState = this.atManager?.verifyAccessTokenSync(this.tokenId, "ohos.permission.APPROXIMATELY_LOCATION");
    return locationPermissionState == abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
  }

  checkAccuracyPermission(): boolean {
    this.getTokenId();
    let locationPermissionState = this.atManager?.verifyAccessTokenSync(this.tokenId, "ohos.permission.LOCATION");
    return locationPermissionState == abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
  }

  requestPermissions() : void {
    if(!this.ability || !(this.result || this.getLocationResult || this.events != null)) {
      Log.d(TAG, "");
      return;
    }
    //有权限，无需继续请求
    if(this.checkPermission()) {
      this.result?.success(2);
      return;
    }
    let array: Array<Permissions> = [
      "ohos.permission.APPROXIMATELY_LOCATION",
      "ohos.permission.LOCATION"
    ];
    Log.d(TAG, "request permission from user");
    this.atManager?.requestPermissionsFromUser(this.ability.context, array).then((data)=>{
      if(data.authResults[0] == abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        Log.d(TAG, "result:PERMISSION_GRANTED");
        if(this.getLocationResult != null || this.events != null) {
          this.startRequestLocation();
        } else {
          this.result?.success(2);
          this.result = null;
        }
      } else if(data.authResults[0] == abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
        Log.d(TAG, "result:PERMISSION_DENIED_NEVER_ASK");
        this.sendError("PERMISSION_DENIED_NEVER_ASK", "Location permission denied forever, please open app settings", null);
        this.result?.success(1);
        this.result = null;
      } else {
        Log.d(TAG, "result:PERMISSION_DENIED");
        this.sendError("PERMISSION_DENIED", "Location permission denied", null);
        this.result?.success(0);
        this.result = null;
      }
    }).catch((err: BusinessError) => {
      Log.d(TAG, "error=" + JSON.stringify(err));
      this.sendError(String(err.code), err.name, err.message);
    })
  }

  checkServiceEnabled(): boolean {
    try{
      return geoLocationManager.isLocationEnabled();
    } catch (error) {
      Log.e(TAG, "isLocationEnabled err:" + JSON.stringify(error));
      return false;
    }
  }

  getLastKnownPosition() {
    this.locationCallback(geoLocationManager.getLastLocation());
  }
  startRequestLocation(): void {
    Log.d(TAG, "start request location");
    //单次数据返回
    geoLocationManager.getCurrentLocation(this.requestInfo).then((location)=>{
      this.locationCallback(location);
    }).catch((err: BusinessError)=>{
      Log.e(TAG, "GET_CURRENT_POSITION_ERROR:" + JSON.stringify(err));
    })
    if(!this.checkPermission()) {
      return;
    }
    //存在stream通道，监听位置变化
    if(this.events != null) {
      try{
        if(this.requestInfo.timeInterval == 0) {
          this.requestInfo.timeInterval = 1;
        }
        geoLocationManager.off("locationChange", this.locationCallback);
        geoLocationManager.on("locationChange", this.requestInfo, this.locationCallback);
      } catch (error) {
        Log.e(TAG, "LOCATION CHANGE ERROR:" + JSON.stringify(error), );
      }
    }
  }
  stopRequestLocation() {
    this.getLocationResult = null;
    geoLocationManager.off("locationChange", this.locationCallback);
  }

  private sendError(errorCode: string, errorMessage: string, errorDetails: ESObject) {
    if(this.getLocationResult != null) {
      this.getLocationResult.error(errorCode, errorMessage, errorDetails);
      this.getLocationResult = null;
    }
    if(this.events != null) {
      this.events.error(errorCode, errorMessage, errorDetails);
      this.events = null;
    }
  }
}