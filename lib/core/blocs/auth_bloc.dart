import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bus_service/core/models/auth_session.dart';
import 'package:bus_service/core/models/user_staff.dart';
import 'package:bus_service/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

abstract class AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final AuthUserSession session;
  AuthLoginRequested(this.session);
}

class AuthLogoutRequested extends AuthEvent {}

class AuthState {
  final bool isAuthenticated;
  final AuthUserSession? session;

  const AuthState({required this.isAuthenticated, this.session});

  UserRole? get role => session?.role;
  String? get tenantId => session?.tenantId;
  String? get userId => session?.uid;
  String? get userName => session?.name;

  factory AuthState.initial() => const AuthState(isAuthenticated: false, session: null);
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthState.initial()) {
    on<AuthLoginRequested>((event, emit) {
      emit(AuthState(isAuthenticated: true, session: event.session));
    });

    on<AuthLogoutRequested>((event, emit) async {
      final isTesting = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
      if (!isTesting) {
        try {
          await FirebaseAuth.instance.signOut();
        } catch (_) {}
      }
      emit(AuthState.initial());
    });
  }

  /// Convenience for login screens.
  Future<String?> loginWithCredentials({
    required String phone,
    required String pin,
    UserRole? expectedRole,
  }) async {
    try {
      final session = await AuthService.instance.login(
        phone: phone,
        pin: pin,
        expectedRole: expectedRole,
      );
      if (session == null) return 'ખોટો મોબાઇલ નંબર અથવા PIN';
      if (expectedRole != null && session.role != expectedRole) {
        return 'આ લોગિન ${_roleLabel(expectedRole)} માટે નથી';
      }
      add(AuthLoginRequested(session));
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'લોગિન નિષ્ફળ ગયું: ${e.toString()}';
    }
  }

  String _roleLabel(UserRole role) => switch (role) {
        UserRole.admin => 'Admin',
        UserRole.agent => 'Agency',
        UserRole.driver => 'Driver',
        UserRole.conductor => 'Conductor',
      };
}
