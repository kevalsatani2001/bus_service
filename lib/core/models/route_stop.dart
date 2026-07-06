import 'package:meta/meta.dart';

enum StopStatus { upcoming, passed, current }

@immutable
class RouteStop {
  final String id;
  final String name;
  final String nameGuj;
  final double latitude;
  final double longitude;
  final int orderIndex;
  final bool isBoardingPoint;
  final bool isDropPoint;

  const RouteStop({
    required this.id,
    required this.name,
    required this.nameGuj,
    required this.latitude,
    required this.longitude,
    required this.orderIndex,
    this.isBoardingPoint = false,
    this.isDropPoint = false,
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    return RouteStop(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameGuj: json['nameGuj'] as String? ?? '',
      latitude: (json['latitude'] as num? ?? 0).toDouble(),
      longitude: (json['longitude'] as num? ?? 0).toDouble(),
      orderIndex: json['orderIndex'] as int? ?? 0,
      isBoardingPoint: json['isBoardingPoint'] as bool? ?? false,
      isDropPoint: json['isDropPoint'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nameGuj': nameGuj,
        'latitude': latitude,
        'longitude': longitude,
        'orderIndex': orderIndex,
        'isBoardingPoint': isBoardingPoint,
        'isDropPoint': isDropPoint,
      };
}

@immutable
class BusRoute {
  final String id;
  final String tenantId;
  final String name;
  final String origin;
  final String destination;
  final List<RouteStop> stops;

  const BusRoute({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.origin,
    required this.destination,
    required this.stops,
  });

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    final stopsList = (json['stops'] as List<dynamic>? ?? [])
        .map((s) => RouteStop.fromJson(Map<String, dynamic>.from(s as Map)))
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return BusRoute(
      id: json['id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      origin: json['origin'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      stops: stopsList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenantId': tenantId,
        'name': name,
        'origin': origin,
        'destination': destination,
        'stops': stops.map((s) => s.toJson()).toList(),
      };

  List<String> get boardingPoints =>
      stops.where((s) => s.isBoardingPoint).map((s) => s.nameGuj).toList();

  List<String> get dropPoints =>
      stops.where((s) => s.isDropPoint).map((s) => s.nameGuj).toList();

  RouteStop? stopByName(String name) {
    try {
      return stops.firstWhere(
        (s) => s.nameGuj == name || s.name == name,
      );
    } catch (_) {
      return null;
    }
  }
}
