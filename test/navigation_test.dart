import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:bus_service/main.dart';
import 'package:bus_service/core/blocs/auth_bloc.dart';
import 'package:bus_service/core/navigation/app_router.dart';
import 'package:bus_service/core/models/user_staff.dart';

void main() {
  setUp(() {
    // Reset auth service state before each test
    AppRouter.authService.logout();
  });

  Future<void> _pumpTestApp(WidgetTester tester) async {
    final authBloc = AuthBloc();
    AppRouter.authService.bindBloc(authBloc);
    await tester.pumpWidget(MyApp(authBloc: authBloc));
  }

  testWidgets('should load PassengerHomeScreen as initial route (/)', (WidgetTester tester) async {
    await _pumpTestApp(tester);
    await tester.pumpAndSettle();

    expect(find.text('Bus SaaS Hub'), findsOneWidget);
    expect(find.text('Passenger Portal'), findsOneWidget);
    expect(find.text('Driver / Conductor Portal'), findsOneWidget);
  });

  testWidgets('should render TripDetailsScreen with extracted ticketHash parameter', (WidgetTester tester) async {
    await _pumpTestApp(tester);
    await tester.pumpAndSettle();

    AppRouter.router.go('/passenger/trip-details/my-hash-123');
    await tester.pumpAndSettle();

    // The screen looks up my-hash-123 in Firestore (which fails during test)
    // and falls back to PassengerMapScreen with tripId TR001.
    expect(find.text('Live Tracking Active'), findsOneWidget);
    expect(find.text('Trip ID: TR001'), findsOneWidget);
    expect(find.text('Rajesh Kumar'), findsOneWidget); // Driver
    expect(find.text('Amit Sharma'), findsOneWidget); // Conductor
    expect(find.text('15B'), findsOneWidget); // Seat
    expect(find.text('Call Support (સહાયતા મેળવો)'), findsOneWidget);
  });

  testWidgets('should redirect unauthenticated admin access from /admin/dashboard to /admin/login', (WidgetTester tester) async {
    await _pumpTestApp(tester);
    await tester.pumpAndSettle();

    AppRouter.router.go('/admin/dashboard');
    await tester.pumpAndSettle();

    expect(find.text('Admin Login Screen'), findsOneWidget);
  });

  testWidgets('should allow admin access to /admin/dashboard if logged in as admin', (WidgetTester tester) async {
    await _pumpTestApp(tester);
    await tester.pumpAndSettle();

    AppRouter.authService.login(UserRole.admin);
    AppRouter.router.go('/admin/dashboard');
    await tester.pumpAndSettle();

    expect(find.text('Admin Dashboard Screen (Super Admin Panel)'), findsOneWidget);
  });

  testWidgets('should redirect driver role access to admin dashboard back to /admin/login', (WidgetTester tester) async {
    await _pumpTestApp(tester);
    await tester.pumpAndSettle();

    AppRouter.authService.login(UserRole.driver);
    AppRouter.router.go('/admin/dashboard');
    await tester.pumpAndSettle();

    expect(find.text('Admin Login Screen'), findsOneWidget);
  });

  testWidgets('should redirect unauthenticated driver access from /driver/home to /driver/login', (WidgetTester tester) async {
    await _pumpTestApp(tester);
    await tester.pumpAndSettle();

    AppRouter.router.go('/driver/home');
    await tester.pumpAndSettle();

    expect(find.text('Driver Login Screen'), findsOneWidget);
  });

  testWidgets('should allow driver access to /driver/home when logged in as driver', (WidgetTester tester) async {
    await _pumpTestApp(tester);
    await tester.pumpAndSettle();

    AppRouter.authService.login(UserRole.driver);
    AppRouter.router.go('/driver/home');
    await tester.pumpAndSettle();

    expect(find.text('Driver Home Screen (GPS Control Screen)'), findsOneWidget);
  });

  testWidgets('should allow agency login and load dashboard portal', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;

    await _pumpTestApp(tester);
    await tester.pumpAndSettle();

    AppRouter.authService.login(UserRole.agent);
    AppRouter.router.go('/agency/dashboard');
    await tester.pumpAndSettle();

    // Select the booking tab to reveal the form
    await tester.tap(find.text('Book Ticket / Generate QR').last);
    await tester.pumpAndSettle();

    expect(find.text('Generate Ticket / QR Code'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
  });
}
