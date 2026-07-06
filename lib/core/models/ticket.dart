import 'package:meta/meta.dart';
import 'utils.dart';

@immutable
class Ticket {
  final String id;
  final String tenantId;
  final String tripId;
  final String passengerName;
  final String passengerPhone;
  final String seatNumber; // Alphanumeric support (e.g. "12A", "15")
  final String boardingPoint;
  final String dropPoint;
  final String qrHash;
  final String trackingUrl;
  final bool isScanned;
  final DateTime bookedAt;

  const Ticket({
    required this.id,
    required this.tenantId,
    required this.tripId,
    required this.passengerName,
    required this.passengerPhone,
    required this.seatNumber,
    this.boardingPoint = '',
    this.dropPoint = '',
    required this.qrHash,
    this.trackingUrl = '',
    required this.isScanned,
    required this.bookedAt,
  });

  /// Returns a new [Ticket] instance with optionally modified fields.
  Ticket copyWith({
    String? id,
    String? tenantId,
    String? tripId,
    String? passengerName,
    String? passengerPhone,
    String? seatNumber,
    String? boardingPoint,
    String? dropPoint,
    String? qrHash,
    String? trackingUrl,
    bool? isScanned,
    DateTime? bookedAt,
  }) {
    return Ticket(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      tripId: tripId ?? this.tripId,
      passengerName: passengerName ?? this.passengerName,
      passengerPhone: passengerPhone ?? this.passengerPhone,
      seatNumber: seatNumber ?? this.seatNumber,
      boardingPoint: boardingPoint ?? this.boardingPoint,
      dropPoint: dropPoint ?? this.dropPoint,
      qrHash: qrHash ?? this.qrHash,
      trackingUrl: trackingUrl ?? this.trackingUrl,
      isScanned: isScanned ?? this.isScanned,
      bookedAt: bookedAt ?? this.bookedAt,
    );
  }

  /// Deserializes a [Ticket] from a JSON map.
  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      tripId: json['tripId'] as String? ?? '',
      passengerName: json['passengerName'] as String? ?? '',
      passengerPhone: json['passengerPhone'] as String? ?? '',
      seatNumber: json['seatNumber'] as String? ?? '',
      boardingPoint: json['boardingPoint'] as String? ?? '',
      dropPoint: json['dropPoint'] as String? ?? '',
      qrHash: json['qrHash'] as String? ?? '',
      trackingUrl: json['trackingUrl'] as String? ?? '',
      isScanned: json['isScanned'] as bool? ?? false,
      bookedAt: parseDateTime(json['bookedAt']) ?? DateTime.now(),
    );
  }

  /// Serializes a [Ticket] to a JSON map suitable for Firestore and Realtime Database.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenantId': tenantId,
      'tripId': tripId,
      'passengerName': passengerName,
      'passengerPhone': passengerPhone,
      'seatNumber': seatNumber,
      'boardingPoint': boardingPoint,
      'dropPoint': dropPoint,
      'qrHash': qrHash,
      'trackingUrl': trackingUrl,
      'isScanned': isScanned,
      'bookedAt': bookedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Ticket &&
        other.id == id &&
        other.tenantId == tenantId &&
        other.tripId == tripId &&
        other.passengerName == passengerName &&
        other.passengerPhone == passengerPhone &&
        other.seatNumber == seatNumber &&
        other.qrHash == qrHash &&
        other.isScanned == isScanned &&
        other.bookedAt == bookedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      tenantId,
      tripId,
      passengerName,
      passengerPhone,
      seatNumber,
      qrHash,
      isScanned,
      bookedAt,
    );
  }

  @override
  String toString() {
    return 'Ticket(id: $id, tenantId: $tenantId, tripId: $tripId, passengerName: $passengerName, passengerPhone: $passengerPhone, seatNumber: $seatNumber, qrHash: $qrHash, isScanned: $isScanned, bookedAt: $bookedAt)';
  }
}
