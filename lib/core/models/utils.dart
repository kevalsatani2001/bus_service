/// Helper method to parse [DateTime] from various types.
/// Supports [DateTime], [String] (ISO 8601), [int] (milliseconds since epoch),
/// and dynamic objects that expose a `toDate()` method (such as Firestore's Timestamp).
DateTime? parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  
  // Try dynamic toDate() invocation to support Firestore's native Timestamp
  // without creating a hard compile-time dependency on the firestore package.
  try {
    return (value as dynamic).toDate() as DateTime;
  } catch (_) {
    // Return null if parsing fails
  }
  return null;
}
