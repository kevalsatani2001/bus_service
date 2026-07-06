import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bus_service/core/models/auth_session.dart';
import 'package:bus_service/core/models/models.dart';
import 'package:bus_service/core/services/seed_data_service.dart';

/// Central Firestore data access with seed-data fallback.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  FirebaseFirestore? get _db {
    if (_isTesting) return null;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  bool get _isTesting => !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  // Local persistence cache
  static List<Tenant> _localTenants = [];
  static List<UserStaff> _localStaff = [];
  static Map<String, String> _localPins = {};
  static List<Bus> _localBuses = [];
  static List<Trip> _localTrips = [];
  static List<Ticket> _localTickets = [];
  static bool _localDbInitialized = false;

  Future<void> _ensureLocalDbInitialized() async {
    if (_localDbInitialized) return;

    if (_isTesting) {
      _localTenants = [
        Tenant(
          id: SeedDataService.defaultTenantId,
          name: 'Demo Travel Agency (Surat)',
          themeColorHex: '#3F51B5',
          isActive: true,
          createdAt: DateTime.now(),
          status: 'approved',
        ),
      ];
      _localStaff = List.from(SeedDataService.defaultStaff);
      _localPins = {
        'D101': '1234',
        'C201': '1234',
        'D102': '1234',
        'C202': '1234',
      };
      _localBuses = List.from(SeedDataService.defaultBuses);
      _localTrips = List.from(SeedDataService.defaultTrips);
      _localTickets = [];
      _localDbInitialized = true;
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load Tenants
      final tenantsJson = prefs.getString('local_tenants');
      if (tenantsJson != null) {
        final List<dynamic> list = jsonDecode(tenantsJson);
        _localTenants = list.map((item) => Tenant.fromJson(item)).toList();
      } else {
        _localTenants = [
          Tenant(
            id: SeedDataService.defaultTenantId,
            name: 'Demo Travel Agency (Surat)',
            themeColorHex: '#3F51B5',
            isActive: true,
            createdAt: DateTime.now(),
            status: 'approved',
          ),
        ];
      }

      // Load Staff
      final staffJson = prefs.getString('local_staff');
      if (staffJson != null) {
        final List<dynamic> list = jsonDecode(staffJson);
        _localStaff = list.map((item) => UserStaff.fromJson(item)).toList();
      } else {
        _localStaff = List.from(SeedDataService.defaultStaff);
      }

      // Load Pins
      final pinsJson = prefs.getString('local_pins');
      if (pinsJson != null) {
        final Map<String, dynamic> map = jsonDecode(pinsJson);
        _localPins = map.map((k, v) => MapEntry(k, v as String));
      } else {
        _localPins = {
          'D101': '1234',
          'C201': '1234',
          'D102': '1234',
          'C202': '1234',
        };
      }

      // Load Buses
      final busesJson = prefs.getString('local_buses');
      if (busesJson != null) {
        final List<dynamic> list = jsonDecode(busesJson);
        _localBuses = list.map((item) => Bus.fromJson(item)).toList();
      } else {
        _localBuses = List.from(SeedDataService.defaultBuses);
      }

      // Load Trips
      final tripsJson = prefs.getString('local_trips');
      if (tripsJson != null) {
        final List<dynamic> list = jsonDecode(tripsJson);
        _localTrips = list.map((item) => Trip.fromJson(item)).toList();
      } else {
        _localTrips = List.from(SeedDataService.defaultTrips);
      }

      // Load Tickets
      final ticketsJson = prefs.getString('local_tickets');
      if (ticketsJson != null) {
        final List<dynamic> list = jsonDecode(ticketsJson);
        _localTickets = list.map((item) => Ticket.fromJson(item)).toList();
      } else {
        _localTickets = [];
      }

      _localDbInitialized = true;
    } catch (_) {
      if (_localTenants.isEmpty) {
        _localTenants = [
          Tenant(
            id: SeedDataService.defaultTenantId,
            name: 'Demo Travel Agency (Surat)',
            themeColorHex: '#3F51B5',
            isActive: true,
            createdAt: DateTime.now(),
            status: 'approved',
          ),
        ];
      }
      if (_localStaff.isEmpty) {
        _localStaff = List.from(SeedDataService.defaultStaff);
      }
      if (_localPins.isEmpty) {
        _localPins = {
          'D101': '1234',
          'C201': '1234',
          'D102': '1234',
          'C202': '1234',
        };
      }
      if (_localBuses.isEmpty) {
        _localBuses = List.from(SeedDataService.defaultBuses);
      }
      if (_localTrips.isEmpty) {
        _localTrips = List.from(SeedDataService.defaultTrips);
      }
      _localDbInitialized = true;
    }
  }

  Future<void> _saveLocalTenants() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_tenants', jsonEncode(_localTenants.map((t) => t.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> _saveLocalStaff() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_staff', jsonEncode(_localStaff.map((s) => s.toJson()).toList()));
      await prefs.setString('local_pins', jsonEncode(_localPins));
    } catch (_) {}
  }

  Future<void> _saveLocalBuses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_buses', jsonEncode(_localBuses.map((b) => b.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> _saveLocalTrips() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_trips', jsonEncode(_localTrips.map((t) => t.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> _saveLocalTickets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_tickets', jsonEncode(_localTickets.map((t) => t.toJson()).toList()));
    } catch (_) {}
  }

  Future<List<Bus>> getBuses(String tenantId) async {
    await _ensureLocalDbInitialized();
    final db = _db;
    if (db != null) {
      try {
        final snap = await db.collection('buses').where('tenantId', isEqualTo: tenantId).get();
        final list = snap.docs.map((d) => Bus.fromJson({...d.data(), 'id': d.id})).toList();
        if (list.isNotEmpty) {
          _localBuses.removeWhere((b) => b.tenantId == tenantId);
          _localBuses.addAll(list);
          await _saveLocalBuses();
          return list;
        }
      } catch (_) {}
    }
    return _localBuses.where((b) => b.tenantId == tenantId).toList();
  }

  Future<void> addBus(Bus bus) async {
    await _ensureLocalDbInitialized();
    _localBuses.removeWhere((b) => b.id == bus.id);
    _localBuses.add(bus);
    await _saveLocalBuses();
    final db = _db;
    if (db != null) {
      try {
        await db.collection('buses').doc(bus.id).set(bus.toJson());
      } catch (_) {}
    }
  }

  Future<List<UserStaff>> getStaff(String tenantId) async {
    await _ensureLocalDbInitialized();
    final db = _db;
    if (db != null) {
      try {
        final snap = await db.collection('staff').where('tenantId', isEqualTo: tenantId).get();
        final list = snap.docs.map((d) => UserStaff.fromJson({...d.data(), 'uid': d.id})).toList();
        if (list.isNotEmpty) {
          _localStaff.removeWhere((s) => s.tenantId == tenantId);
          _localStaff.addAll(list);
          await _saveLocalStaff();
          return list;
        }
      } catch (_) {}
    }
    return _localStaff.where((s) => s.tenantId == tenantId).toList();
  }

  Future<UserStaff?> getStaffById(String uid) async {
    await _ensureLocalDbInitialized();
    final db = _db;
    if (db != null) {
      try {
        final doc = await db.collection('staff').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          final staff = UserStaff.fromJson({...doc.data()!, 'uid': doc.id});
          _localStaff.removeWhere((s) => s.uid == uid);
          _localStaff.add(staff);
          await _saveLocalStaff();
          return staff;
        }
      } catch (_) {}
    }
    return _localStaff.where((s) => s.uid == uid).firstOrNull;
  }

  Future<BusRoute?> getRoute(String routeId) async {
    final db = _db;
    if (db != null) {
      try {
        final doc = await db.collection('routes').doc(routeId).get();
        if (doc.exists && doc.data() != null) {
          return BusRoute.fromJson({...doc.data()!, 'id': doc.id});
        }
      } catch (_) {}
    }
    if (routeId == 'RT001') return SeedDataService.suratBardoliRoute;
    return SeedDataService.suratRirampurRoute;
  }

  Future<List<Trip>> getTrips(String tenantId) async {
    await _ensureLocalDbInitialized();
    final db = _db;
    if (db != null) {
      try {
        final snap = await db.collection('trips').where('tenantId', isEqualTo: tenantId).get();
        final list = snap.docs.map((d) => Trip.fromJson({...d.data(), 'id': d.id})).toList();
        if (list.isNotEmpty) {
          _localTrips.removeWhere((t) => t.tenantId == tenantId);
          _localTrips.addAll(list);
          await _saveLocalTrips();
          return list;
        }
      } catch (_) {}
    }
    return _localTrips.where((t) => t.tenantId == tenantId).toList();
  }

  Future<Trip?> getTrip(String tripId) async {
    await _ensureLocalDbInitialized();
    final db = _db;
    if (db != null) {
      try {
        final doc = await db.collection('trips').doc(tripId).get();
        if (doc.exists && doc.data() != null) {
          final trip = Trip.fromJson({...doc.data()!, 'id': doc.id});
          _localTrips.removeWhere((t) => t.id == tripId);
          _localTrips.add(trip);
          await _saveLocalTrips();
          return trip;
        }
      } catch (_) {}
    }
    return _localTrips.where((t) => t.id == tripId).firstOrNull;
  }

  Future<void> addTrip(Trip trip) async {
    await _ensureLocalDbInitialized();
    _localTrips.removeWhere((t) => t.id == trip.id);
    _localTrips.add(trip);
    await _saveLocalTrips();
    final db = _db;
    if (db != null) {
      try {
        await db.collection('trips').doc(trip.id).set(trip.toJson());
      } catch (_) {}
    }
  }

  Future<void> saveTicket(Ticket ticket) async {
    await _ensureLocalDbInitialized();
    _localTickets.removeWhere((t) => t.id == ticket.id);
    _localTickets.add(ticket);
    await _saveLocalTickets();
    final db = _db;
    if (db != null) {
      try {
        await db.collection('tickets').doc(ticket.id).set(ticket.toJson());
      } catch (_) {}
    }
  }

  Future<Ticket?> getTicket(String ticketId) async {
    await _ensureLocalDbInitialized();
    final db = _db;
    if (db != null) {
      try {
        final doc = await db.collection('tickets').doc(ticketId).get();
        if (doc.exists && doc.data() != null) {
          final ticket = Ticket.fromJson({...doc.data()!, 'id': doc.id});
          _localTickets.removeWhere((t) => t.id == ticketId);
          _localTickets.add(ticket);
          await _saveLocalTickets();
          return ticket;
        }
      } catch (_) {}
    }
    return _localTickets.where((t) => t.id == ticketId).firstOrNull;
  }

  Future<List<String>> getBookedSeats(String tripId) async {
    await _ensureLocalDbInitialized();
    final db = _db;
    if (db != null) {
      try {
        final snap = await db.collection('tickets').where('tripId', isEqualTo: tripId).get();
        return snap.docs
            .map((d) => d.data()['seatNumber'] as String? ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      } catch (_) {}
    }
    return _localTickets
        .where((t) => t.tripId == tripId)
        .map((t) => t.seatNumber)
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Stream<List<Ticket>> watchTripTickets(String tripId) {
    final db = _db;
    if (db != null) {
      try {
        return db
            .collection('tickets')
            .where('tripId', isEqualTo: tripId)
            .snapshots()
            .map((snap) => snap.docs.map((d) => Ticket.fromJson({...d.data(), 'id': d.id})).toList());
      } catch (_) {}
    }
    return Stream.value(_localTickets.where((t) => t.tripId == tripId).toList());
  }

  Future<String> generateTicketId() async {
    final db = _db;
    if (db != null) {
      try {
        final counterRef = db.collection('counters').doc('tickets');
        return await db.runTransaction<String>((tx) async {
          final snap = await tx.get(counterRef);
          final current = (snap.data()?['last'] as int?) ?? 1041;
          final next = current + 1;
          tx.set(counterRef, {'last': next}, SetOptions(merge: true));
          return 'TICK-$next';
        });
      } catch (_) {}
    }
    return 'TICK-${DateTime.now().millisecondsSinceEpoch % 100000}';
  }

  // ── Tenants / Agencies ─────────────────────────────────────────────

  Future<List<Tenant>> getTenants() async {
    await _ensureLocalDbInitialized();
    final db = _db;
    if (db != null) {
      try {
        final snap = await db.collection('agencies').get();
        final list = snap.docs.map((d) => Tenant.fromJson({...d.data(), 'id': d.id})).toList();
        if (list.isNotEmpty) {
          _localTenants = list;
          await _saveLocalTenants();
          return list;
        }
      } catch (_) {}
    }
    return _localTenants;
  }

  Future<Tenant?> getTenant(String id) async {
    await _ensureLocalDbInitialized();
    final db = _db;
    if (db != null) {
      try {
        final doc = await db.collection('agencies').doc(id).get();
        if (doc.exists && doc.data() != null) {
          final tenant = Tenant.fromJson({...doc.data()!, 'id': doc.id});
          _localTenants.removeWhere((t) => t.id == id);
          _localTenants.add(tenant);
          await _saveLocalTenants();
          return tenant;
        }
      } catch (_) {}
    }
    return _localTenants.where((t) => t.id == id).firstOrNull;
  }

  Future<void> saveTenant(Tenant tenant) async {
    await _ensureLocalDbInitialized();
    Tenant normalizedTenant = tenant;
    if (tenant.phone != null) {
      final digits = tenant.phone!.replaceAll(RegExp(r'[^0-9]'), '');
      final normalizedPhone = digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
      normalizedTenant = tenant.copyWith(phone: normalizedPhone);
    }
    _localTenants.removeWhere((t) => t.id == normalizedTenant.id);
    _localTenants.add(normalizedTenant);
    await _saveLocalTenants();
    final db = _db;
    if (db != null) {
      try {
        await db.collection('agencies').doc(normalizedTenant.id).set(normalizedTenant.toJson());
      } catch (e) {
        print("FIRESTORE ERROR in saveTenant: $e");
      }
    }
  }

  Future<void> deleteTenant(String tenantId) async {
    await _ensureLocalDbInitialized();
    _localTenants.removeWhere((t) => t.id == tenantId);
    // Also delete agency staff
    _localStaff.removeWhere((s) => s.tenantId == tenantId);
    await _saveLocalTenants();
    await _saveLocalStaff();
    final db = _db;
    if (db != null) {
      try {
        await db.collection('agencies').doc(tenantId).delete();
        final staffSnap = await db.collection('staff').where('tenantId', isEqualTo: tenantId).get();
        for (final doc in staffSnap.docs) {
          await doc.reference.delete();
        }
      } catch (_) {}
    }
  }

  Future<void> updateTenantStatus(String tenantId, String status) async {
    await _ensureLocalDbInitialized();
    final idx = _localTenants.indexWhere((t) => t.id == tenantId);
    if (idx != -1) {
      final updated = _localTenants[idx].copyWith(status: status, isActive: status == 'approved');
      _localTenants[idx] = updated;
      await _saveLocalTenants();
    }
    final db = _db;
    if (db != null) {
      try {
        await db.collection('agencies').doc(tenantId).update({
          'status': status,
          'isActive': status == 'approved',
        });
      } catch (_) {}
    }
  }

  Future<List<UserStaff>> getAllStaff() async {
    await _ensureLocalDbInitialized();
    final db = _db;
    if (db != null) {
      try {
        final snap = await db.collection('staff').get();
        final list = snap.docs.map((d) => UserStaff.fromJson({...d.data(), 'uid': d.id})).toList();
        if (list.isNotEmpty) {
          _localStaff = list;
          await _saveLocalStaff();
          return list;
        }
      } catch (_) {}
    }
    return _localStaff;
  }

  Future<void> saveStaffWithPin(UserStaff staff, String pin) async {
    await _ensureLocalDbInitialized();
    final digits = staff.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final normalizedPhone = digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
    final normalizedStaff = staff.copyWith(phone: normalizedPhone);

    _localStaff.removeWhere((s) => s.uid == normalizedStaff.uid);
    _localStaff.add(normalizedStaff);
    _localPins[normalizedStaff.uid] = pin;
    await _saveLocalStaff();
    final db = _db;
    if (db != null) {
      try {
        await db.collection('staff').doc(normalizedStaff.uid).set({
          ...normalizedStaff.toJson(),
          'pin': pin,
        });
      } catch (e) {
        print("FIRESTORE ERROR in saveStaffWithPin: $e");
      }
    }
  }

  Future<void> deleteStaff(String uid) async {
    await _ensureLocalDbInitialized();
    _localStaff.removeWhere((s) => s.uid == uid);
    _localPins.remove(uid);
    await _saveLocalStaff();
    final db = _db;
    if (db != null) {
      try {
        await db.collection('staff').doc(uid).delete();
      } catch (_) {}
    }
  }

  Future<AuthUserSession?> authenticate(String phone, String pin) async {
    await _ensureLocalDbInitialized();
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final lookupPhone = digits.length >= 10 ? digits.substring(digits.length - 10) : digits;

    final db = _db;
    if (db != null) {
      try {
        final snap = await db
            .collection('staff')
            .where('phone', isEqualTo: lookupPhone)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          final doc = snap.docs.first;
          final data = doc.data();
          if ((data['pin'] as String? ?? '') == pin) {
            final staff = UserStaff.fromJson({...data, 'uid': doc.id});
            return AuthUserSession(
              uid: staff.uid,
              name: staff.name,
              phone: staff.phone,
              role: staff.role,
              tenantId: staff.tenantId,
            );
          }
        }
      } catch (_) {}
    }

    // Fallback local auth
    for (final staff in _localStaff) {
      final staffDigits = staff.phone.replaceAll(RegExp(r'[^0-9]'), '');
      final staffPhoneNormalized = staffDigits.length >= 10 ? staffDigits.substring(staffDigits.length - 10) : staffDigits;
      if (staffPhoneNormalized == lookupPhone) {
        final localPin = _localPins[staff.uid];
        if (localPin == pin) {
          return AuthUserSession(
            uid: staff.uid,
            name: staff.name,
            phone: staff.phone,
            role: staff.role,
            tenantId: staff.tenantId,
          );
        }
      }
    }
    return null;
  }

  Future<List<Ticket>> getAllTickets() async {
    await _ensureLocalDbInitialized();
    final db = _db;
    if (db != null) {
      try {
        final snap = await db.collection('tickets').get();
        final list = snap.docs.map((d) => Ticket.fromJson({...d.data(), 'id': d.id})).toList();
        if (list.isNotEmpty) {
          _localTickets = list;
          await _saveLocalTickets();
          return list;
        }
      } catch (_) {}
    }
    return _localTickets;
  }
}

/// Offline GPS coordinate queue — saves locally when network drops, syncs on reconnect.
class OfflineLocationQueue {
  OfflineLocationQueue._();
  static final OfflineLocationQueue instance = OfflineLocationQueue._();

  static const _prefsKey = 'offline_location_queue';

  Future<void> enqueue({
    required String tripId,
    required double lat,
    required double lng,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_prefsKey) ?? [];
      existing.add(jsonEncode({
        'tripId': tripId,
        'lat': lat,
        'lng': lng,
        'timestamp': DateTime.now().toIso8601String(),
      }));
      await prefs.setStringList(_prefsKey, existing);
    } catch (_) {}
  }

  Future<void> syncPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getStringList(_prefsKey) ?? [];
      if (pending.isEmpty) return;

      final remaining = <String>[];
      for (final entry in pending) {
        try {
          final data = jsonDecode(entry) as Map<String, dynamic>;
          final tripId = data['tripId'] as String;
          await FirebaseDatabase.instance.ref('trips/$tripId/currentLocation').set({
            'latitude': data['lat'],
            'longitude': data['lng'],
            'lat': data['lat'],
            'lng': data['lng'],
            'lastUpdated': data['timestamp'],
          });
        } catch (_) {
          remaining.add(entry);
        }
      }
      await prefs.setStringList(_prefsKey, remaining);
    } catch (_) {}
  }

  Future<int> pendingCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_prefsKey) ?? []).length;
    } catch (_) {
      return 0;
    }
  }
}
