import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bus_service/firebase_options.dart';
import 'package:bus_service/core/navigation/app_router.dart';
import 'package:bus_service/core/blocs/auth_bloc.dart';
import 'package:bus_service/core/blocs/theme_bloc.dart';
import 'package:bus_service/features/live_tracking/bloc/tracking_bloc.dart';
import 'package:bus_service/core/theme/tenant_theme_loader.dart';
import 'package:bus_service/features/live_tracking/services/driver_tracking_service.dart';
import 'package:bus_service/core/services/firestore_service.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Cloud Firestore & Realtime Database connection settings
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await DriverTrackingService.initializeService();
    await OfflineLocationQueue.instance.syncPending();
  } catch (_) {
    // Suppress errors during tests or hot-reloads
  }

  final authBloc = AuthBloc();
  
  // Link GoRouter redirects to AuthBloc transitions
  AppRouter.authService.bindBloc(authBloc);

  runApp(MyApp(authBloc: authBloc));
}

class MyApp extends StatefulWidget {
  final AuthBloc authBloc;

  const MyApp({super.key, required this.authBloc});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();
    
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (_) {}

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => _handleDeepLink(uri),
      onError: (err) => debugPrint("Deep link stream error: $err"),
    );
  }

  void _handleDeepLink(Uri uri) {
    if (uri.path.startsWith('/track/')) {
      final ticketHash = uri.pathSegments.last;
      if (ticketHash.isNotEmpty) {
        AppRouter.router.go('/track/$ticketHash');
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: widget.authBloc),
        BlocProvider<ThemeBloc>(create: (context) => ThemeBloc()),
        BlocProvider<TrackingBloc>(create: (context) => TrackingBloc()..add(TrackingCheckStatusRequested())),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp.router(
            title: 'Multi-Tenant Bus SaaS Platform',
            debugShowCheckedModeBanner: false,
            theme: TenantThemeLoader.generateThemeFromColor(themeState.themeColor),
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
