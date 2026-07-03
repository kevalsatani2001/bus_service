import 'package:meta/meta.dart';

enum UserRole {
  driver,
  conductor,
  agent,
  admin;

  /// Parses a string into a [UserRole], defaulting to [UserRole.agent] if unmatched.
  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value.toLowerCase().trim(),
      orElse: () => UserRole.agent,
    );
  }

  /// Serializes the role to its string representation.
  String toJson() => name;
}

@immutable
class UserStaff {
  final String uid;
  final String name;
  final String phone;
  final UserRole role;
  final String tenantId;

  const UserStaff({
    required this.uid,
    required this.name,
    required this.phone,
    required this.role,
    required this.tenantId,
  });

  /// Returns a new [UserStaff] instance with optionally modified fields.
  UserStaff copyWith({
    String? uid,
    String? name,
    String? phone,
    UserRole? role,
    String? tenantId,
  }) {
    return UserStaff(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      tenantId: tenantId ?? this.tenantId,
    );
  }

  /// Deserializes a [UserStaff] from a JSON map.
  factory UserStaff.fromJson(Map<String, dynamic> json) {
    return UserStaff(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String? ?? ''),
      tenantId: json['tenantId'] as String? ?? '',
    );
  }

  /// Serializes a [UserStaff] to a JSON map suitable for Firestore and Realtime Database.
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'role': role.toJson(),
      'tenantId': tenantId,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserStaff &&
        other.uid == uid &&
        other.name == name &&
        other.phone == phone &&
        other.role == role &&
        other.tenantId == tenantId;
  }

  @override
  int get hashCode {
    return Object.hash(uid, name, phone, role, tenantId);
  }

  @override
  String toString() {
    return 'UserStaff(uid: $uid, name: $name, phone: $phone, role: $role, tenantId: $tenantId)';
  }
}
