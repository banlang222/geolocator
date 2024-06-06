import { BinaryMessenger, Log } from '@ohos/flutter_ohos';
import EventChannel, { EventSink, StreamHandler } from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';
import Geolocation from './GeoLocation';

const TAG = "StreamHandlerImpl";

export default class StreamHandlerImpl implements StreamHandler {
  private location: Geolocation | null = null;
  private channel: EventChannel | null = null;

  setLocation(location: Geolocation | null): void {
    Log.d(TAG, "set location");
    this.location = location;
  }

  startListening(messenger: BinaryMessenger) {
    Log.d(TAG, "start listening");
    if(this.channel != null) {
      this.stopListening();
    }
    this.channel = new EventChannel(messenger, "flutter.baseflow.com/geolocator_updates_ohos");
    this.channel.setStreamHandler(this);
  }

  stopListening() {
    Log.d(TAG, "stop listening");
    if(this.channel == null) {
      return;
    }
    this.channel.setStreamHandler(null);
    this.channel = null;
  }

  //flutter端开始监听时会触发
  onListen(arg: ESObject, events: EventSink): void {
    Log.d(TAG, "on listen")
    if(this.location == null || this.location.ability == null) {
      Log.d(TAG, "location==null ?" + String(this.location == null) + ", ability==null ?" + String(this.location?.ability == null));
      return;
    }
    this.location.events = events;
    if(!this.location.checkPermission()) {
      Log.d(TAG, "no permission, so, request");
      this.location.requestPermissions();
    } else if(!this.location.checkAccuracyPermission()) {
      Log.d(TAG, "user denied permission");
      events.error("PEMISSION_DENIED", "Location permission denied", null);
      this.location.events = null;
    } else {
      Log.d(TAG, "start request location")
      this.location.startRequestLocation();
    }

  }

  //flutter端取消监听时会触发
  onCancel(args: ESObject): void {
    Log.d(TAG, "cancel listening");
    if(this.location) {
      // 会在下次定位数据回报时自动停止位置监听，见GeoLocation.locationCallback
      this.location.events = null;
    }
  }
}