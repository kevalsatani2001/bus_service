/// Global app configuration constants.
class AppConfig {
  AppConfig._();

  /// Base URL for passenger tracking links embedded in QR codes.
  static const String trackingBaseUrl = 'https://building-guard-app.web.app/track';

  /// Builds a public tracking URL for the given ticket ID.
  static String trackingUrl(String ticketId) =>
      '$trackingBaseUrl/$ticketId';

  /// Extracts ticket ID from a tracking URL or returns null.
  static String? ticketIdFromUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.contains('/track/')) {
      return trimmed.split('/track/').last.split('?').first.split('#').first;
    }
    if (trimmed.contains('/passenger/trip-details/')) {
      return trimmed.split('/passenger/trip-details/').last.split('?').first;
    }
    return null;
  }
}
