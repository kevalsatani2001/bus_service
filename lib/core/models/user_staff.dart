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

  // New fields for Driver Registration
  final String? email;
  final String? licenseNumber;
  final String? vehicleDetails;
  final String? status; // 'pending', 'approved'

  const UserStaff({
    required this.uid,
    required this.name,
    required this.phone,
    required this.role,
    required this.tenantId,
    this.email,
    this.licenseNumber,
    this.vehicleDetails,
    this.status = 'approved',
  });

  /// Returns a new [UserStaff] instance with optionally modified fields.
  UserStaff copyWith({
    String? uid,
    String? name,
    String? phone,
    UserRole? role,
    String? tenantId,
    String? email,
    String? licenseNumber,
    String? vehicleDetails,
    String? status,
  }) {
    return UserStaff(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      tenantId: tenantId ?? this.tenantId,
      email: email ?? this.email,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      vehicleDetails: vehicleDetails ?? this.vehicleDetails,
      status: status ?? this.status,
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
      email: json['email'] as String?,
      licenseNumber: json['licenseNumber'] as String?,
      vehicleDetails: json['vehicleDetails'] as String?,
      status: json['status'] as String? ?? 'approved',
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
      if (email != null) 'email': email,
      if (licenseNumber != null) 'licenseNumber': licenseNumber,
      if (vehicleDetails != null) 'vehicleDetails': vehicleDetails,
      if (status != null) 'status': status,
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
        other.tenantId == tenantId &&
        other.email == email &&
        other.licenseNumber == licenseNumber &&
        other.vehicleDetails == vehicleDetails &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(
      uid,
      name,
      phone,
      role,
      tenantId,
      email,
      licenseNumber,
      vehicleDetails,
      status,
    );
  }

  @override
  String toString() {
    return 'UserStaff(uid: $uid, name: $name, phone: $phone, role: $role, tenantId: $tenantId, email: $email, licenseNumber: $licenseNumber, vehicleDetails: $vehicleDetails, status: $status)';
  }
}
