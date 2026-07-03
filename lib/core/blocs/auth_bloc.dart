import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bus_service/core/models/user_staff.dart';

// Events
abstract class AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final UserRole role;
  AuthLoginRequested(this.role);
}

class AuthLogoutRequested extends AuthEvent {}

// State
class AuthState {
  final bool isAuthenticated;
  final UserRole? role;

  AuthState({required this.isAuthenticated, this.role});

  factory AuthState.initial() => AuthState(isAuthenticated: false, role: null);
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthState.initial()) {
    on<AuthLoginRequested>((event, emit) {
      emit(AuthState(isAuthenticated: true, role: event.role));
    });

    on<AuthLogoutRequested>((event, emit) {
      emit(AuthState(isAuthenticated: false, role: null));
    });
  }
}
