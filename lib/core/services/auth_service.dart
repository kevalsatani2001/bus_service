import 'package:bus_service/core/models/auth_session.dart';
import 'package:bus_service/core/models/user_staff.dart';
import 'package:bus_service/core/services/firestore_service.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Handles phone + PIN login with Firestore lookup and built-in demo accounts.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  /// Demo accounts shown on login screens (works without Firebase too).
  static const demoAccounts = <Map<String, String>>[
    {'role': 'admin', 'phone': '9999999999', 'pin': '1234', 'name': 'App Owner (Super Admin)', 'tenantId': ''},
    {'role': 'agent', 'phone': '8888888888', 'pin': '1234', 'name': 'Agency Booking Office', 'tenantId': 'T1'},
    {'role': 'driver', 'phone': '7777777777', 'pin': '1234', 'name': 'Rajesh Kumar (Driver)', 'tenantId': 'T1'},
    {'role': 'conductor', 'phone': '6666666666', 'pin': '1234', 'name': 'Amit Sharma (Conductor)', 'tenantId': 'T1'},
  ];

  Future<AuthUserSession?> login({
    required String phone,
    required String pin,
    UserRole? expectedRole,
  }) async {
    final normalizedPhone = _normalizePhone(phone);
    if (normalizedPhone.isEmpty || pin.isEmpty) return null;

    AuthUserSession? session;

    // 1. Try Firestore staff collection
    final fromDb = await FirestoreService.instance.authenticate(normalizedPhone, pin);
    if (fromDb != null) {
      if (expectedRole != null && fromDb.role != expectedRole) return null;
      session = fromDb;
    } else {
      // 2. Fallback demo accounts (dev / offline mode)
      for (final demo in demoAccounts) {
        if (_normalizePhone(demo['phone']!) == normalizedPhone && demo['pin'] == pin) {
          final role = UserRole.fromString(demo['role']!);
          if (expectedRole != null && role != expectedRole) return null;
          session = AuthUserSession(
            uid: 'demo-${demo['role']}',
            name: demo['name']!,
            phone: normalizedPhone,
            role: role,
            tenantId: demo['tenantId'] ?? '',
          );
          break;
        }
      }
    }

    if (session == null) return null;

    // Check Tenant activation status
    if (session.role != UserRole.admin && session.tenantId.isNotEmpty) {
      final tenant = await FirestoreService.instance.getTenant(session.tenantId);
      if (tenant != null) {
        if (tenant.status == 'pending' || !tenant.isActive) {
          throw AuthException('તમારી એજન્સી મંજૂરી માટે બાકી છે (Agency pending approval)');
        }
        if (tenant.status == 'blocked') {
          throw AuthException('તમારી એજન્સી બ્લોક કરેલી છે (Agency is blocked)');
        }
      }
    }

    return session;
  }

  String _normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 10) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }
}
