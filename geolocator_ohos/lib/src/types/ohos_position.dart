import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:meta/meta.dart';

@immutable
class OhosPosition extends Position {
  const OhosPosition({
    required this.satelliteCount,
    required this.satellitesUsedInFix,
    required latitude,
    required longitude,
    required timestamp,
    required accuracy,
    required altitude,
    required altitudeAccuracy,
    required heading,
    required headingAccuracy,
    required speed,
    required speedAccuracy,
    int? floor,
    bool isMocked = false,
  }) : super(
            latitude: latitude,
            longitude: longitude,
            timestamp: timestamp,
            accuracy: accuracy,
            altitude: altitude,
            altitudeAccuracy: altitudeAccuracy,
            heading: heading,
            headingAccuracy: headingAccuracy,
            speed: speed,
            speedAccuracy: speedAccuracy,
            floor: floor,
            isMocked: isMocked);

  final double satelliteCount;

  final double satellitesUsedInFix;

  @override
  bool operator ==(Object other) {
    var areEqual = other is OhosPosition &&
        super == other &&
        other.satelliteCount == satelliteCount &&
        other.satellitesUsedInFix == satellitesUsedInFix;

    return areEqual;
  }

  @override
  int get hashCode =>
      satelliteCount.hashCode ^ satellitesUsedInFix.hashCode ^ super.hashCode;

  @override
  String toString() {
    return 'Latitude: $latitude, Longitude: $longitude';
  }

  /// Converts the supplied [Map] to an instance of the [Position] class.
  static OhosPosition fromMap(dynamic message) {
    final Map<dynamic, dynamic> positionMap = message;

    final position = Position.fromMap(positionMap);

    return OhosPosition(
        satelliteCount: positionMap['gnss_satellite_count'] ?? 0.0,
        satellitesUsedInFix: positionMap['gnss_satellite_used_in_fix'] ?? 0.0,
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: position.timestamp,
        altitude: position.altitude,
        altitudeAccuracy: position.altitudeAccuracy,
        accuracy: position.accuracy,
        heading: position.heading,
        headingAccuracy: position.headingAccuracy,
        floor: position.floor,
        speed: position.speed,
        speedAccuracy: position.speedAccuracy,
        isMocked: position.isMocked);
  }

  /// Converts the [Position] instance into a [Map] instance that can be
  /// serialized to JSON.
  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'gnss_satellite_count': satelliteCount,
      'gnss_satellite_used_in_fix': satellitesUsedInFix
    });
}
