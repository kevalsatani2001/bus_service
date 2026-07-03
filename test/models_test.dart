import 'package:flutter_test/flutter_test.dart';
import 'package:bus_service/core/models/models.dart';

// A mock class to simulate Firestore's Timestamp class in test environment.
class MockFirestoreTimestamp {
  final DateTime _dateTime;
  MockFirestoreTimestamp(this._dateTime);
  DateTime toDate() => _dateTime;
}

void main() {
  group('Date Parsing Utility Tests', () {
    test('should parse DateTime directly', () {
      final now = DateTime.now();
      expect(parseDateTime(now), equals(now));
    });

    test('should parse ISO 8601 String', () {
      final isoStr = '2026-07-03T12:00:00.000Z';
      final parsed = parseDateTime(isoStr);
      expect(parsed, isNotNull);
      expect(parsed!.isUtc, isTrue);
      expect(parsed.year, equals(2026));
      expect(parsed.month, equals(7));
      expect(parsed.day, equals(3));
    });

    test('should parse milliseconds since epoch', () {
      final epochMs = 1783080000000; // a time in 2026
      final parsed = parseDateTime(epochMs);
      expect(parsed, isNotNull);
      expect(parsed!.millisecondsSinceEpoch, equals(epochMs));
    });

    test('should parse duck-typed Firestore Timestamp object with toDate() method', () {
      final now = DateTime.now();
      final mockTimestamp = MockFirestoreTimestamp(now);
      final parsed = parseDateTime(mockTimestamp);
      expect(parsed, equals(now));
    });

    test('should return null for invalid types or null input', () {
      expect(parseDateTime(null), isNull);
      expect(parseDateTime('not-a-date'), isNull);
      expect(parseDateTime([]), isNull);
    });
  });

  group('Tenant Model Tests', () {
    final now = DateTime.now();
    final tenantJson = {
      'id': 'tenant-123',
      'name': 'Red Line Express',
      'logoUrl': 'https://example.com/logo.png',
      'themeColorHex': '#FF0000',
      'isActive': true,
      'createdAt': now.toIso8601String(),
    };

    test('fromJson & toJson serialization consistency', () {
      final tenant = Tenant.fromJson(tenantJson);
      expect(tenant.id, equals('tenant-123'));
      expect(tenant.name, equals('Red Line Express'));
      expect(tenant.logoUrl, equals('https://example.com/logo.png'));
      expect(tenant.themeColorHex, equals('#FF0000'));
      expect(tenant.themeColor, equals('#FF0000'));
      expect(tenant.isActive, isTrue);
      // Strip millisecond differences that could happen during string conversion
      expect(tenant.createdAt.toIso8601String(), equals(now.toIso8601String()));

      final serialized = tenant.toJson();
      expect(serialized['id'], equals('tenant-123'));
      expect(serialized['name'], equals('Red Line Express'));
      expect(serialized['logoUrl'], equals('https://example.com/logo.png'));
      expect(serialized['themeColorHex'], equals('#FF0000'));
      expect(serialized['themeColor'], equals('#FF0000'));
      expect(serialized['isActive'], isTrue);
      expect(serialized['createdAt'], equals(now.toIso8601String()));
    });

    test('fromJson handles missing logoUrl', () {
      final jsonCopy = Map<String, dynamic>.from(tenantJson)..remove('logoUrl');
      final tenant = Tenant.fromJson(jsonCopy);
      expect(tenant.logoUrl, isNull);
      expect(tenant.toJson().containsKey('logoUrl'), isFalse);
    });

    test('copyWith creates new instances with updated values', () {
      final tenant = Tenant.fromJson(tenantJson);
      final updated = tenant.copyWith(name: 'Blue Line Express', isActive: false);

      expect(updated.id, equals(tenant.id));
      expect(updated.name, equals('Blue Line Express'));
      expect(updated.isActive, isFalse);
      expect(updated.logoUrl, equals(tenant.logoUrl));
    });

    test('equality and hashCode check', () {
      final tenant1 = Tenant.fromJson(tenantJson);
      final tenant2 = Tenant.fromJson(tenantJson);
      expect(tenant1, equals(tenant2));
      expect(tenant1.hashCode, equals(tenant2.hashCode));

      final different = tenant1.copyWith(id: 'tenant-456');
      expect(tenant1, isNot(equals(different)));
    });
  });

  group('UserStaff Model Tests', () {
    final userJson = {
      'uid': 'user-999',
      'name': 'John Driver',
      'phone': '+15550199',
      'role': 'driver',
      'tenantId': 'tenant-123',
    };

    test('fromJson & toJson serialization consistency', () {
      final user = UserStaff.fromJson(userJson);
      expect(user.uid, equals('user-999'));
      expect(user.name, equals('John Driver'));
      expect(user.phone, equals('+15550199'));
      expect(user.role, equals(UserRole.driver));
      expect(user.tenantId, equals('tenant-123'));

      final serialized = user.toJson();
      expect(serialized['role'], equals('driver'));
    });

    test('UserRole parsing handles whitespace, case variations, and fallback defaults', () {
      expect(UserRole.fromString(' DRIVER '), equals(UserRole.driver));
      expect(UserRole.fromString('Conductor'), equals(UserRole.conductor));
      expect(UserRole.fromString('agent'), equals(UserRole.agent));
      expect(UserRole.fromString('admin'), equals(UserRole.admin));
      expect(UserRole.fromString('unknown_role'), equals(UserRole.agent)); // Fallback default
    });

    test('copyWith & equality checks', () {
      final user1 = UserStaff.fromJson(userJson);
      final user2 = user1.copyWith(name: 'John Changed');
      expect(user1, isNot(equals(user2)));
      expect(user2.name, equals('John Changed'));
      expect(user2.role, equals(UserRole.driver));
    });
  });

  group('Bus Model Tests', () {
    final busJson = {
      'id': 'bus-1',
      'busNumber': 'NY-1234-BUS',
      'tenantId': 'tenant-123',
      'totalSeats': 40,
      'layoutType': 'sleeper',
    };

    test('fromJson & toJson serialization consistency', () {
      final bus = Bus.fromJson(busJson);
      expect(bus.id, equals('bus-1'));
      expect(bus.busNumber, equals('NY-1234-BUS'));
      expect(bus.tenantId, equals('tenant-123'));
      expect(bus.totalSeats, equals(40));
      expect(bus.layoutType, equals(BusLayoutType.sleeper));

      final serialized = bus.toJson();
      expect(serialized['layoutType'], equals('sleeper'));
    });

    test('BusLayoutType parsing fallback', () {
      expect(BusLayoutType.fromString('Seater'), equals(BusLayoutType.seater));
      expect(BusLayoutType.fromString('invalid_layout'), equals(BusLayoutType.seater));
    });
  });

  group('Trip Model Tests', () {
    final startDateTime = DateTime.now();
    final lastUpdated = startDateTime.add(Duration(minutes: 30));

    final tripJson = {
      'id': 'trip-500',
      'tenantId': 'tenant-123',
      'busId': 'bus-1',
      'driverId': 'user-999',
      'routeId': 'route-888',
      'status': 'live',
      'startDateTime': startDateTime.toIso8601String(),
      'currentLocation': {
        'latitude': 40.7128,
        'longitude': -74.0060,
        'lastUpdated': lastUpdated.toIso8601String(),
      }
    };

    test('fromJson & toJson serialization consistency with live location', () {
      final trip = Trip.fromJson(tripJson);
      expect(trip.id, equals('trip-500'));
      expect(trip.tenantId, equals('tenant-123'));
      expect(trip.busId, equals('bus-1'));
      expect(trip.driverId, equals('user-999'));
      expect(trip.routeId, equals('route-888'));
      expect(trip.status, equals(TripStatus.live));
      expect(trip.startDateTime.toIso8601String(), equals(startDateTime.toIso8601String()));
      
      expect(trip.currentLocation, isNotNull);
      expect(trip.currentLocation!.latitude, equals(40.7128));
      expect(trip.currentLocation!.longitude, equals(-74.0060));
      expect(trip.currentLocation!.lat, equals(40.7128));
      expect(trip.currentLocation!.lng, equals(-74.0060));
      expect(trip.currentLocation!.lastUpdated.toIso8601String(), equals(lastUpdated.toIso8601String()));

      final serialized = trip.toJson();
      expect(serialized['status'], equals('live'));
      expect(serialized['currentLocation']['latitude'], equals(40.7128));
      expect(serialized['currentLocation']['longitude'], equals(-74.0060));
      expect(serialized['currentLocation']['lat'], equals(40.7128));
      expect(serialized['currentLocation']['lng'], equals(-74.0060));
    });

    test('Trip handles null currentLocation during scheduled status', () {
      final jsonCopy = Map<String, dynamic>.from(tripJson)..remove('currentLocation');
      final trip = Trip.fromJson(jsonCopy);
      expect(trip.currentLocation, isNull);
      expect(trip.toJson().containsKey('currentLocation'), isFalse);
    });

    test('TripStatus parsing fallback', () {
      expect(TripStatus.fromString('Completed'), equals(TripStatus.completed));
      expect(TripStatus.fromString('unknown_status'), equals(TripStatus.scheduled));
    });
  });

  group('Ticket Model Tests', () {
    final bookedAtTime = DateTime.now();
    final ticketJson = {
      'id': 'ticket-001',
      'tenantId': 'tenant-123',
      'tripId': 'trip-500',
      'passengerName': 'Alice Smith',
      'passengerPhone': '+15550234',
      'seatNumber': '12A',
      'qrHash': 'abc123hashxyz',
      'isScanned': false,
      'bookedAt': bookedAtTime.toIso8601String(),
    };

    test('fromJson & toJson serialization consistency', () {
      final ticket = Ticket.fromJson(ticketJson);
      expect(ticket.id, equals('ticket-001'));
      expect(ticket.tenantId, equals('tenant-123'));
      expect(ticket.tripId, equals('trip-500'));
      expect(ticket.passengerName, equals('Alice Smith'));
      expect(ticket.passengerPhone, equals('+15550234'));
      expect(ticket.seatNumber, equals('12A'));
      expect(ticket.qrHash, equals('abc123hashxyz'));
      expect(ticket.isScanned, isFalse);
      expect(ticket.bookedAt.toIso8601String(), equals(bookedAtTime.toIso8601String()));

      final serialized = ticket.toJson();
      expect(serialized['isScanned'], isFalse);
      expect(serialized['seatNumber'], equals('12A'));
      expect(serialized['bookedAt'], equals(bookedAtTime.toIso8601String()));
    });
  });
}
