import { BinaryMessenger, MethodCall, MethodCallHandler, MethodChannel, MethodResult, Log } from '@ohos/flutter_ohos';
import Geolocation from './GeoLocation';
import { UIAbility } from '@kit.AbilityKit';

const TAG = "MethodCallHandlerImpl";

export default class MethodCallHandlerImpl implements MethodCallHandler {
  private location: Geolocation | null = null;
  private channel: MethodChannel | null = null;
  private context: Context | null = null;
  private ability: UIAbility | null = null;

  setLocation(location: Geolocation | null) {
    Log.d(TAG, "set location");
    this.location = location;
  }

  setAbility(ability: UIAbility | null) {
    Log.d(TAG, "set ability");
    this.ability = this.ability;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    const method: string = call.method;
    Log.d(TAG, "method=" + method);
    switch (method) {
      case "checkPermission":
        this.onCheckPermission(result);
        break;
      case "isLocationServiceEnabled":
        this.onServiceEnabled(result);
        break;
      case "requestPermission":
        this.onRequestPermissions(result);
        break;
      case "getLastKnownPosition":
        this.onGetLastKnownPosition(result);
        break;
      case "getLocationAccuracy":
        result.notImplemented();
        break;
      case "getCurrentPosition":
        this.onGetCurrentPosition(result);
        break;
      case "cancelGetCurrentPosition":
        this.onCancelGetCurrentPosition();
        break;
      case "openAppSettings":
      case "openLocationSettings":
      default:
        result.notImplemented();
        break;
    }

  }

  startListening(context: Context,messenger: BinaryMessenger) {
    Log.d(TAG, "start listening");
    if(this.channel != null) {
      this.stopListening();
    }
    this.channel = new MethodChannel(messenger, "flutter.baseflow.com/geolocator_ohos");
    this.channel.setMethodCallHandler(this);
    this.context = context;
  }

  stopListening() {
    Log.d(TAG, "stop listening");
    if(this.channel == null) {
      return;
    }
    this.channel.setMethodCallHandler(null);
    this.channel = null;
  }

  private onCheckPermission(result: MethodResult) {
    Log.d(TAG, "check permission");
    if(this.location?.checkPermission()) {
      result.success(2);
    } else {
      result.success(0);
    }
  }

  private onRequestPermissions(result: MethodResult) {
    Log.d(TAG, "request permission");
    if(this.location) {
      this.location.result = result;
      this.location.requestPermissions();
    }
  }

  private onServiceEnabled(result: MethodResult) {
    Log.d(TAG, "on service enabled");
    if(this.location) {
      try{
        result.success(this.location.checkServiceEnabled() ? true : false);
      } catch (error) {
        result.error("SERVICE_STATUS_ERROR", "Location service status couldn't be determined", null);
      }
    }
  }

  private onGetLastKnownPosition(result: MethodResult) {
    Log.d(TAG, "on get last known position");
    if(this.location) {
      this.location.getLocationResult = result;
      if(!this.location.checkPermission()){
        this.location.requestPermissions();
      } else if(!this.location.checkAccuracyPermission()) {
        result.error("PERMISSION_DENIED", "Location permission denied", null);
        this.location.getLocationResult = null;
      } else {
        this.location.getLastKnownPosition();
      }
    }
  }

  private onGetCurrentPosition(result: MethodResult) {
    Log.d(TAG, "on get current position");
    if(this.location) {
      this.location.getLocationResult = result;
      if(!this.location.checkPermission()){
        this.location.requestPermissions();
      } else if(!this.location.checkAccuracyPermission()) {
        result.error("PERMISSION_DENIED", "Location permission denied", null);
        this.location.getLocationResult = null;
      } else {
        this.location.startRequestLocation();
      }
    }
  }

  private onCancelGetCurrentPosition() {
    Log.d(TAG, "on cancel get current position");
    if(this.location) {
      this.location.stopRequestLocation();
    }
  }

}