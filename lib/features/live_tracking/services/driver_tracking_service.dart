import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:bus_service/firebase_options.dart';

/// A production-ready background location tracking service for the Driver's role.
///
/// Uses [flutter_background_service] for foreground execution on Android & tasks on iOS
/// and [geolocator] to fetch accurate GPS coordinates.
class DriverTrackingService {
  static const String notificationChannelId = 'driver_live_location_channel';
  static const int notificationId = 999;

  /// Configures and initializes the background service configuration.
  /// This should be called inside `main()` or during app boot lifecycle.
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'તમારી બસ ટ્રેક થઈ રહી છે',
        initialNotificationContent: 'ટ્રિપ શરૂ થવાની રાહ જોવાઈ રહી છે...',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  /// Starts location tracking in the foreground/background for the given [tripId].
  /// Validates and prompts for GPS location permissions and starts the service.
  static Future<bool> startTracking(String tripId, {BuildContext? context}) async {
    // 1. Check if location services are enabled on the device
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context != null && context.mounted) {
        _showAlert(
          context,
          'જીપીએસ બંધ છે (GPS Disabled)',
          'તમારી બસનું લાઇવ લોકેશન ટ્રેક કરવા માટે કૃપા કરીને તમારા મોબાઇલ પર જીપીએસ (લોકેશન સેટિંગ્સ) ચાલુ કરો.',
        );
      }
      return false;
    }

    // 2. Check and request location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context != null && context.mounted) {
          _showAlert(
            context,
            'પરમિશન નામંજૂર (Permission Denied)',
            'લાઇવ ટ્રેકિંગ માટે લોકેશન પરમિશન આપવી ફરજિયાત છે.',
          );
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context != null && context.mounted) {
        _showAlert(
          context,
          'પરમિશન બ્લોક છે (Permission Blocked)',
          'લોકેશન પરમિશન હંમેશા માટે બ્લોક કરેલ છે. કૃપા કરીને ફોન સેટિંગ્સમાં જઈ પરમિશન મેન્યુઅલી આપો.',
        );
      }
      return false;
    }

    // 3. Start the background service
    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
    }

    // 4. Wait for the service to be initialized, then send the start tracking event with tripId
    int retries = 0;
    while (!(await service.isRunning()) && retries < 15) {
      await Future.delayed(const Duration(milliseconds: 200));
      retries++;
    }

    service.invoke('startTracking', {'tripId': tripId});
    return true;
  }

  /// Stops tracking, removes the foreground notification, and stops the service.
  static Future<void> stopTracking() async {
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke('stopService');
    }
  }

  /// Returns true if background tracking is currently active.
  static Future<bool> isTrackingActive() async {
    try {
      return await FlutterBackgroundService().isRunning();
    } catch (_) {
      return false;
    }
  }

  /// Simple dialog pop-up helper to communicate permissions/hardware requirements to the Driver.
  static void _showAlert(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('સમજાઈ ગયું (OK)'),
          ),
        ],
      ),
    );
  }
}

/// The entrypoint function running inside the background isolate.
/// Avoid invoking visual layout commands directly inside this isolate context.
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase inside the background Dart isolate.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Already initialized or fails (e.g. running in testing mockup scenarios)
  }

  String? activeTripId;
  Timer? trackingTimer;

  // Listen for the start tracking event containing the trip ID
  service.on('startTracking').listen((event) {
    if (event == null) return;
    activeTripId = event['tripId'] as String?;

    if (activeTripId != null) {
      // Update Android foreground notification parameters
      if (service is AndroidServiceInstance) {
        service.setAsForegroundService();
        service.setForegroundNotificationInfo(
          title: 'તમારી બસ ટ્રેક થઈ રહી છે',
          content: 'ટ્રિપ $activeTripId નું લોકેશન ચાલુ છે.',
        );
      }

      // Configure location periodic updates (every 10 seconds)
      trackingTimer?.cancel();
      trackingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
        if (activeTripId == null) {
          timer.cancel();
          return;
        }

        try {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          );

          // Update Firebase Realtime Database
          final dbRef = FirebaseDatabase.instance
              .ref('trips/$activeTripId/currentLocation');

          await dbRef.set({
            'latitude': position.latitude,
            'longitude': position.longitude,
            'lat': position.latitude, // backward compatibility
            'lng': position.longitude, // backward compatibility
            'lastUpdated': DateTime.now().toIso8601String(),
          });
        } catch (_) {
          // Catch exceptions to ensure temporary connection drops or GPS timeouts
          // don't crash the background tracking loop.
        }
      });
    }
  });

  // Listen for the stop service command
  service.on('stopService').listen((event) {
    trackingTimer?.cancel();
    service.stopSelf();
  });
}

/// The iOS background service callback.
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}
