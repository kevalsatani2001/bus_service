import 'package:meta/meta.dart';
import 'utils.dart';

@immutable
class Tenant {
  final String id;
  final String name;
  final String? logoUrl;
  final String themeColorHex; // Hex color representation (Default #2dd4bf)
  final bool isActive;
  final DateTime createdAt;

  // New fields for Agency Registration
  final String? ownerName;
  final String? email;
  final String? phone;
  final String? businessLicenseNo;
  final String status; // 'pending', 'approved', 'blocked'

  /// Getter for backward compatibility referencing the theme color hex.
  String get themeColor => themeColorHex;

  const Tenant({
    required this.id,
    required this.name,
    this.logoUrl,
    this.themeColorHex = '#2dd4bf',
    required this.isActive,
    required this.createdAt,
    this.ownerName,
    this.email,
    this.phone,
    this.businessLicenseNo,
    this.status = 'pending',
  });

  /// Returns a new [Tenant] instance with optionally modified fields.
  Tenant copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? themeColorHex,
    bool? isActive,
    DateTime? createdAt,
    String? ownerName,
    String? email,
    String? phone,
    String? businessLicenseNo,
    String? status,
  }) {
    return Tenant(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      themeColorHex: themeColorHex ?? this.themeColorHex,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      ownerName: ownerName ?? this.ownerName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      businessLicenseNo: businessLicenseNo ?? this.businessLicenseNo,
      status: status ?? this.status,
    );
  }

  /// Deserializes a [Tenant] from a JSON map.
  factory Tenant.fromJson(Map<String, dynamic> json) {
    final statusVal = json['status'] as String? ??
        ((json['isActive'] as bool? ?? false) ? 'approved' : 'pending');
    return Tenant(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      logoUrl: json['logoUrl'] as String?,
      themeColorHex: json['themeColorHex'] as String? ?? json['themeColor'] as String? ?? '#2dd4bf',
      isActive: json['isActive'] as bool? ?? (statusVal == 'approved'),
      createdAt: parseDateTime(json['createdAt']) ?? DateTime.now(),
      ownerName: json['ownerName'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      businessLicenseNo: json['businessLicenseNo'] as String?,
      status: statusVal,
    );
  }

  /// Serializes a [Tenant] to a JSON map suitable for Firestore and Realtime Database.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (logoUrl != null) 'logoUrl': logoUrl,
      'themeColorHex': themeColorHex,
      'themeColor': themeColorHex, // backward compatibility
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      if (ownerName != null) 'ownerName': ownerName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (businessLicenseNo != null) 'businessLicenseNo': businessLicenseNo,
      'status': status,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tenant &&
        other.id == id &&
        other.name == name &&
        other.logoUrl == logoUrl &&
        other.themeColorHex == themeColorHex &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.ownerName == ownerName &&
        other.email == email &&
        other.phone == phone &&
        other.businessLicenseNo == businessLicenseNo &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      logoUrl,
      themeColorHex,
      isActive,
      createdAt,
      ownerName,
      email,
      phone,
      businessLicenseNo,
      status,
    );
  }

  @override
  String toString() {
    return 'Tenant(id: $id, name: $name, logoUrl: $logoUrl, themeColorHex: $themeColorHex, isActive: $isActive, createdAt: $createdAt, ownerName: $ownerName, email: $email, phone: $phone, businessLicenseNo: $businessLicenseNo, status: $status)';
  }
}
