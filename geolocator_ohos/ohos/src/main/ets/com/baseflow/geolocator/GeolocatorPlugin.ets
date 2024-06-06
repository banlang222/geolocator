import { AbilityAware, AbilityPluginBinding, FlutterPlugin, Log, MethodResult } from "@ohos/flutter_ohos";
import { FlutterPluginBinding } from "@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin";
import Geolocation from './GeoLocation';
import MethodCallHandlerImpl from "./MethodCallHandlerImpl";
import StreamHandlerImpl from "./StreamHandlerImpl";

const TAG = "Geolocator";

export default class GeolocatorPlugin implements FlutterPlugin, AbilityAware  {
  private methodCallHandler: MethodCallHandlerImpl | null = null;
  private streamHandler: StreamHandlerImpl | null = null;
  private abilityBinding: AbilityPluginBinding | null = null;
  private location: Geolocation | null = null;


  getUniqueClassName(): string {
    return TAG;
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    Log.d(TAG, "geolocator attached to engine");
    this.methodCallHandler = new MethodCallHandlerImpl();
    this.methodCallHandler.startListening(binding.getApplicationContext(), binding.getBinaryMessenger());
    this.streamHandler = new StreamHandlerImpl();
    this.streamHandler.startListening(binding.getBinaryMessenger());
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    Log.d(TAG, "geolocator detached from engine");
    if(this.methodCallHandler != null) {
      this.methodCallHandler?.stopListening();
      this.methodCallHandler = null;
    }
    if(this.streamHandler != null) {
      this.streamHandler?.stopListening();
      this.streamHandler = null;
    }
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    Log.d(TAG, "geolocator attached to ability");
    this.abilityBinding = binding;
    this.location = new Geolocation();
    this.location.setAbility(this.abilityBinding.getAbility());
    this.methodCallHandler?.setLocation(this.location);
    this.streamHandler?.setLocation(this.location);
  }

  onDetachedFromAbility(): void {
    Log.d(TAG, "geolocator detached from ability");
    this.streamHandler?.stopListening();
    this.streamHandler?.setLocation(null);
    this.methodCallHandler?.setLocation(null);
    this.methodCallHandler?.setAbility(null);
  }

}