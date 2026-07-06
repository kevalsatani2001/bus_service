import 'package:bus_service/core/models/user_staff.dart';

/// Logged-in user session passed through AuthBloc and route guards.
class AuthUserSession {
  final String uid;
  final String name;
  final String phone;
  final UserRole role;
  final String tenantId;

  const AuthUserSession({
    required this.uid,
    required this.name,
    required this.phone,
    required this.role,
    required this.tenantId,
  });
}
