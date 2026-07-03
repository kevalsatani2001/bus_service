import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bus_service/firebase_options.dart';
import 'package:bus_service/core/navigation/app_router.dart';
import 'package:bus_service/core/blocs/auth_bloc.dart';
import 'package:bus_service/core/blocs/theme_bloc.dart';
import 'package:bus_service/features/live_tracking/bloc/tracking_bloc.dart';
import 'package:bus_service/core/theme/tenant_theme_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Cloud Firestore & Realtime Database connection settings
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Suppress errors during tests or hot-reloads
  }

  final authBloc = AuthBloc();
  
  // Link GoRouter redirects to AuthBloc transitions
  AppRouter.authService.bindBloc(authBloc);

  runApp(MyApp(authBloc: authBloc));
}

class MyApp extends StatelessWidget {
  final AuthBloc authBloc;

  const MyApp({super.key, required this.authBloc});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
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
