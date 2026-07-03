import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bus_service/core/models/user_staff.dart';
import 'package:bus_service/core/blocs/auth_bloc.dart';
import 'stub_screens.dart';
import 'package:bus_service/features/ticket_verification/presentation/passenger_scan_screen.dart';
import 'package:bus_service/features/ticket_verification/presentation/driver_validator_screen.dart';
import 'package:bus_service/web_panels/agency_dashboard/presentation/agency_dashboard_screen.dart';
import 'dart:async';

/// A Mock authentication service to manage user roles and authentication state.
/// Exposes login/logout capabilities and integrates with [GoRouter.refreshListenable]
/// to trigger route guard redirects.
class MockAuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  UserRole? _role;
  StreamSubscription? _subscription;

  bool get isAuthenticated => _isAuthenticated;
  UserRole? get role => _role;

  /// Binds this service listener to the AuthBloc state stream.
  void bindBloc(AuthBloc bloc) {
    _subscription?.cancel();
    _isAuthenticated = bloc.state.isAuthenticated;
    _role = bloc.state.role;
    
    _subscription = bloc.stream.listen((state) {
      _isAuthenticated = state.isAuthenticated;
      _role = state.role;
      notifyListeners();
    });
  }

  /// Authenticates the user with a specific [UserRole] role.
  void login(UserRole role) {
    _isAuthenticated = true;
    _role = role;
    notifyListeners();
  }

  /// Logs out the user.
  void logout() {
    _isAuthenticated = false;
    _role = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// The AppRouter class manages the go_router configuration, path definitions,
/// and role-based redirection guards for both mobile and web routes.
class AppRouter {
  /// The authentication service that provides state updates to the router.
  static final MockAuthService authService = MockAuthService();

  /// Router configurations and path matching.
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: authService,
    redirect: (context, state) => redirectGuard(context, state),
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Text('Error: Route ${state.uri} does not exist.', style: const TextStyle(fontSize: 16, color: Colors.red)),
      ),
    ),
    routes: [
      // 1. Mobile Home Menu Selector (initial route)
      GoRoute(
        path: '/',
        builder: (context, state) => const PassengerHomeScreen(),
      ),

      // 2. Mobile QR Scanner for passengers
      GoRoute(
        path: '/passenger/scan',
        builder: (context, state) => const PassengerScanScreen(),
      ),

      // 3. Mobile Public Trip Details Route (with error boundaries)
      GoRoute(
        path: '/passenger/trip-details',
        builder: (context, state) => const TripDetailsScreen(ticketHash: ''),
      ),
      GoRoute(
        path: '/passenger/trip-details/:ticketHash',
        pageBuilder: (context, state) {
          final ticketHash = state.pathParameters['ticketHash'] ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: TripDetailsScreen(ticketHash: ticketHash),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
                child: child,
              );
            },
          );
        },
      ),

      // 4. Super Admin Web Routes
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),

      // 5. Agency Portal Web Routes
      GoRoute(
        path: '/agency/login',
        builder: (context, state) => const AgencyLoginScreen(),
      ),
      GoRoute(
        path: '/agency/dashboard',
        builder: (context, state) => const AgencyDashboardScreen(),
      ),

      // 6. Driver Mobile Routes
      GoRoute(
        path: '/driver/login',
        builder: (context, state) => const DriverLoginScreen(),
      ),
      GoRoute(
        path: '/driver/home',
        builder: (context, state) => const DriverHomeScreen(),
      ),

      // 7. Driver verify boarding scanner (with error boundary)
      GoRoute(
        path: '/driver/verify',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Error: Missing Trip ID argument. Please access verification through the driver portal.',
                style: TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/driver/verify/:tripId',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId'] ?? '';
          return DriverValidatorScreen(tripId: tripId);
        },
      ),
    ],
  );

  /// Performs checks to guard routes and redirect to the correct screen.
  static String? redirectGuard(BuildContext context, GoRouterState state) {
    final path = state.uri.path;

    final isAdminPath = path.startsWith('/admin/dashboard');
    final isAgencyPath = path.startsWith('/agency/dashboard');
    final isDriverPath = path.startsWith('/driver/home') || path.startsWith('/driver/verify');

    // 1. Guard Super Admin Routes
    if (isAdminPath) {
      if (!authService.isAuthenticated || authService.role != UserRole.admin) {
        return '/admin/login';
      }
    }

    // 2. Guard Agency Portal Routes
    if (isAgencyPath) {
      // Agency dashboard is restricted to Agency staff (agent) or Admin.
      if (!authService.isAuthenticated ||
          (authService.role != UserRole.agent && authService.role != UserRole.admin)) {
        return '/agency/login';
      }
    }

    // 3. Guard Driver Routes
    if (isDriverPath) {
      if (!authService.isAuthenticated || authService.role != UserRole.driver) {
        return '/driver/login';
      }
    }

    // 4. Auto-redirect from login screen to dashboard if already authenticated with correct role
    if (path == '/admin/login' && authService.isAuthenticated && authService.role == UserRole.admin) {
      return '/admin/dashboard';
    }
    if (path == '/agency/login' && authService.isAuthenticated &&
        (authService.role == UserRole.agent || authService.role == UserRole.admin)) {
      return '/agency/dashboard';
    }
    if (path == '/driver/login' && authService.isAuthenticated && authService.role == UserRole.driver) {
      return '/driver/home';
    }

    return null; // Return null to proceed to the target route
  }
}
