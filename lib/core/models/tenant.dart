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

  /// Getter for backward compatibility referencing the theme color hex.
  String get themeColor => themeColorHex;

  const Tenant({
    required this.id,
    required this.name,
    this.logoUrl,
    this.themeColorHex = '#2dd4bf',
    required this.isActive,
    required this.createdAt,
  });

  /// Returns a new [Tenant] instance with optionally modified fields.
  Tenant copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? themeColorHex,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Tenant(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      themeColorHex: themeColorHex ?? this.themeColorHex,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Deserializes a [Tenant] from a JSON map.
  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      logoUrl: json['logoUrl'] as String?,
      themeColorHex: json['themeColorHex'] as String? ?? json['themeColor'] as String? ?? '#2dd4bf',
      isActive: json['isActive'] as bool? ?? false,
      createdAt: parseDateTime(json['createdAt']) ?? DateTime.now(),
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
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, logoUrl, themeColorHex, isActive, createdAt);
  }

  @override
  String toString() {
    return 'Tenant(id: $id, name: $name, logoUrl: $logoUrl, themeColorHex: $themeColorHex, isActive: $isActive, createdAt: $createdAt)';
  }
}
