import 'dart:math';
import 'package:bus_service/core/models/models.dart';

/// Calculates live ETA from bus GPS to a destination stop.
class EtaService {
  EtaService._();

  static const double _avgSpeedKmh = 45.0;

  /// Haversine distance in kilometres between two coordinates.
  static double distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRad(double deg) => deg * pi / 180;

  /// Returns estimated minutes to reach destination from current bus position.
  static int estimateMinutes({
    required double busLat,
    required double busLng,
    required double destLat,
    required double destLng,
  }) {
    final km = distanceKm(busLat, busLng, destLat, destLng);
    if (km < 0.5) return 1;
    return max(1, (km / _avgSpeedKmh * 60).round());
  }

  /// Formats ETA for display.
  static String formatEta(int minutes) {
    if (minutes < 60) return '$minutes mins';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '$h hr $m mins' : '$h hr';
  }

  /// Determines stop status based on bus position along the route.
  static StopStatus stopStatus({
    required RouteStop stop,
    required double busLat,
    required double busLng,
    required List<RouteStop> allStops,
  }) {
    final busDistFromOrigin = _cumulativeDistance(busLat, busLng, allStops, stop.orderIndex);
    final stopDist = _distanceAlongRoute(allStops, stop.orderIndex);

    if ((busDistFromOrigin - stopDist).abs() < 1.0) {
      return StopStatus.current;
    }
    if (busDistFromOrigin > stopDist + 0.5) {
      return StopStatus.passed;
    }
    return StopStatus.upcoming;
  }

  static double _cumulativeDistance(
    double busLat,
    double busLng,
    List<RouteStop> stops,
    int upToIndex,
  ) {
    if (stops.isEmpty) return 0;
    var total = distanceKm(busLat, busLng, stops.first.latitude, stops.first.longitude);
    for (var i = 0; i < upToIndex && i < stops.length - 1; i++) {
      total += distanceKm(
        stops[i].latitude,
        stops[i].longitude,
        stops[i + 1].latitude,
        stops[i + 1].longitude,
      );
    }
    return total;
  }

  static double _distanceAlongRoute(List<RouteStop> stops, int index) {
    var total = 0.0;
    for (var i = 0; i < index && i < stops.length - 1; i++) {
      total += distanceKm(
        stops[i].latitude,
        stops[i].longitude,
        stops[i + 1].latitude,
        stops[i + 1].longitude,
      );
    }
    return total;
  }
}
