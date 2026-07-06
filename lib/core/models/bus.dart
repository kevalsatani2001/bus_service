import 'package:meta/meta.dart';

enum BusLayoutType {
  sleeper,
  seater;

  /// Parses a string into a [BusLayoutType], defaulting to [BusLayoutType.seater] if unmatched.
  static BusLayoutType fromString(String value) {
    return BusLayoutType.values.firstWhere(
      (e) => e.name == value.toLowerCase().trim(),
      orElse: () => BusLayoutType.seater,
    );
  }

  /// Serializes the layout type to its string representation.
  String toJson() => name;
}

@immutable
class Bus {
  final String id;
  final String busNumber;
  final String tenantId;
  final int totalSeats;
  final BusLayoutType layoutType;
  final String exteriorPhotoUrl;
  final String interiorPhotoUrl;
  final List<String> berthPhotoUrls;

  const Bus({
    required this.id,
    required this.busNumber,
    required this.tenantId,
    required this.totalSeats,
    required this.layoutType,
    this.exteriorPhotoUrl = '',
    this.interiorPhotoUrl = '',
    this.berthPhotoUrls = const [],
  });

  /// Returns a new [Bus] instance with optionally modified fields.
  Bus copyWith({
    String? id,
    String? busNumber,
    String? tenantId,
    int? totalSeats,
    BusLayoutType? layoutType,
    String? exteriorPhotoUrl,
    String? interiorPhotoUrl,
    List<String>? berthPhotoUrls,
  }) {
    return Bus(
      id: id ?? this.id,
      busNumber: busNumber ?? this.busNumber,
      tenantId: tenantId ?? this.tenantId,
      totalSeats: totalSeats ?? this.totalSeats,
      layoutType: layoutType ?? this.layoutType,
      exteriorPhotoUrl: exteriorPhotoUrl ?? this.exteriorPhotoUrl,
      interiorPhotoUrl: interiorPhotoUrl ?? this.interiorPhotoUrl,
      berthPhotoUrls: berthPhotoUrls ?? this.berthPhotoUrls,
    );
  }

  /// Deserializes a [Bus] from a JSON map.
  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['id'] as String? ?? '',
      busNumber: json['busNumber'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      totalSeats: json['totalSeats'] as int? ?? 0,
      layoutType: BusLayoutType.fromString(json['layoutType'] as String? ?? ''),
      exteriorPhotoUrl: json['exteriorPhotoUrl'] as String? ?? '',
      interiorPhotoUrl: json['interiorPhotoUrl'] as String? ?? '',
      berthPhotoUrls: (json['berthPhotoUrls'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  /// Serializes a [Bus] to a JSON map suitable for Firestore and Realtime Database.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'busNumber': busNumber,
      'tenantId': tenantId,
      'totalSeats': totalSeats,
      'layoutType': layoutType.toJson(),
      'exteriorPhotoUrl': exteriorPhotoUrl,
      'interiorPhotoUrl': interiorPhotoUrl,
      'berthPhotoUrls': berthPhotoUrls,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Bus &&
        other.id == id &&
        other.busNumber == busNumber &&
        other.tenantId == tenantId &&
        other.totalSeats == totalSeats &&
        other.layoutType == layoutType;
  }

  @override
  int get hashCode {
    return Object.hash(id, busNumber, tenantId, totalSeats, layoutType);
  }

  @override
  String toString() {
    return 'Bus(id: $id, busNumber: $busNumber, tenantId: $tenantId, totalSeats: $totalSeats, layoutType: $layoutType)';
  }
}
