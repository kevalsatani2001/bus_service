import 'package:meta/meta.dart';
import 'utils.dart';

enum TripStatus {
  scheduled,
  live,
  completed;

  /// Parses a string into a [TripStatus], defaulting to [TripStatus.scheduled] if unmatched.
  static TripStatus fromString(String value) {
    return TripStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase().trim(),
      orElse: () => TripStatus.scheduled,
    );
  }

  /// Serializes the status to its string representation.
  String toJson() => name;
}

@immutable
class CurrentLocation {
  final double latitude;
  final double longitude;
  final DateTime lastUpdated;

  /// Getters for backward compatibility referencing latitude and longitude
  double get lat => latitude;
  double get lng => longitude;

  const CurrentLocation({
    required this.latitude,
    required this.longitude,
    required this.lastUpdated,
  });

  /// Returns a new [CurrentLocation] instance with optionally modified fields.
  CurrentLocation copyWith({
    double? latitude,
    double? longitude,
    DateTime? lastUpdated,
  }) {
    return CurrentLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Deserializes a [CurrentLocation] from a JSON map.
  factory CurrentLocation.fromJson(Map<String, dynamic> json) {
    return CurrentLocation(
      latitude: (json['latitude'] as num? ?? json['lat'] as num? ?? 0.0).toDouble(),
      longitude: (json['longitude'] as num? ?? json['lng'] as num? ?? 0.0).toDouble(),
      lastUpdated: parseDateTime(json['lastUpdated']) ?? DateTime.now(),
    );
  }

  /// Serializes a [CurrentLocation] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'lat': latitude, // backward compatibility
      'lng': longitude, // backward compatibility
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CurrentLocation &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.lastUpdated == lastUpdated;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude, lastUpdated);

  @override
  String toString() => 'CurrentLocation(latitude: $latitude, longitude: $longitude, lastUpdated: $lastUpdated)';
}

@immutable
class Trip {
  final String id;
  final String tenantId;
  final String busId;
  final String driverId;
  final String conductorId;
  final String routeId;
  final TripStatus status;
  final DateTime startDateTime;
  final CurrentLocation? currentLocation;

  const Trip({
    required this.id,
    required this.tenantId,
    required this.busId,
    required this.driverId,
    this.conductorId = '',
    required this.routeId,
    required this.status,
    required this.startDateTime,
    this.currentLocation,
  });

  /// Returns a new [Trip] instance with optionally modified fields.
  Trip copyWith({
    String? id,
    String? tenantId,
    String? busId,
    String? driverId,
    String? conductorId,
    String? routeId,
    TripStatus? status,
    DateTime? startDateTime,
    CurrentLocation? currentLocation,
  }) {
    return Trip(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      busId: busId ?? this.busId,
      driverId: driverId ?? this.driverId,
      conductorId: conductorId ?? this.conductorId,
      routeId: routeId ?? this.routeId,
      status: status ?? this.status,
      startDateTime: startDateTime ?? this.startDateTime,
      currentLocation: currentLocation ?? this.currentLocation,
    );
  }

  /// Deserializes a [Trip] from a JSON map.
  factory Trip.fromJson(Map<String, dynamic> json) {
    final locationMap = json['currentLocation'] as Map<String, dynamic>?;
    return Trip(
      id: json['id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      busId: json['busId'] as String? ?? '',
      driverId: json['driverId'] as String? ?? '',
      conductorId: json['conductorId'] as String? ?? '',
      routeId: json['routeId'] as String? ?? '',
      status: TripStatus.fromString(json['status'] as String? ?? ''),
      startDateTime: parseDateTime(json['startDateTime']) ?? DateTime.now(),
      currentLocation: locationMap != null ? CurrentLocation.fromJson(locationMap) : null,
    );
  }

  /// Serializes a [Trip] to a JSON map suitable for Firestore and Realtime Database.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenantId': tenantId,
      'busId': busId,
      'driverId': driverId,
      'conductorId': conductorId,
      'routeId': routeId,
      'status': status.toJson(),
      'startDateTime': startDateTime.toIso8601String(),
      if (currentLocation != null) 'currentLocation': currentLocation!.toJson(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Trip &&
        other.id == id &&
        other.tenantId == tenantId &&
        other.busId == busId &&
        other.driverId == driverId &&
        other.conductorId == conductorId &&
        other.routeId == routeId &&
        other.status == status &&
        other.startDateTime == startDateTime &&
        other.currentLocation == currentLocation;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      tenantId,
      busId,
      driverId,
      conductorId,
      routeId,
      status,
      startDateTime,
      currentLocation,
    );
  }

  @override
  String toString() {
    return 'Trip(id: $id, tenantId: $tenantId, busId: $busId, driverId: $driverId, conductorId: $conductorId, routeId: $routeId, status: $status, startDateTime: $startDateTime, currentLocation: $currentLocation)';
  }
}
