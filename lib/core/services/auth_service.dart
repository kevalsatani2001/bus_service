import 'package:bus_service/core/models/auth_session.dart';
import 'package:bus_service/core/models/user_staff.dart';
import 'package:bus_service/core/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Handles phone + PIN login with pure Firebase Authentication.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  Future<AuthUserSession?> login({
    required String phone,
    required String pin,
    UserRole? expectedRole,
  }) async {
    final normalizedPhone = _normalizePhone(phone);
    if (normalizedPhone.isEmpty || pin.isEmpty) return null;

    AuthUserSession? session;
    final isTesting = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

    if (isTesting) {
      // 1. Try Firestore staff collection (offline fallback for unit tests)
      final fromDb = await FirestoreService.instance.authenticate(normalizedPhone, pin);
      if (fromDb != null) {
        if (expectedRole != null && fromDb.role != expectedRole) return null;
        session = fromDb;
      }
    } else {
      // 1. Try Firebase Auth sign in
      final email = '$normalizedPhone@mytravels.com';
      UserCredential? credential;
      try {
        credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: pin,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password' || e.code == 'user-disabled') {
          throw AuthException('મોબાઈલ નંબર અથવા પાસવર્ડ ખોટો છે (Incorrect phone or password)');
        } else {
          throw AuthException('લોગિન ભૂલ: ${e.message}');
        }
      } catch (e) {
        throw AuthException('લોગિન ભૂલ: ${e.toString()}');
      }

      if (credential != null && credential.user != null) {
        final uid = credential.user!.uid;
        final staff = await FirestoreService.instance.getStaffById(uid);
        if (staff != null) {
          if (expectedRole != null && staff.role != expectedRole) return null;
          session = AuthUserSession(
            uid: staff.uid,
            name: staff.name,
            phone: staff.phone,
            role: staff.role,
            tenantId: staff.tenantId,
          );
        } else {
          throw AuthException('સ્ટાફ એકાઉન્ટ માહિતી મળી નથી (Staff profile not found)');
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
