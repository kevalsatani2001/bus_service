import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bus_service/main.dart';
import 'package:bus_service/core/blocs/auth_bloc.dart';
import 'package:bus_service/core/models/auth_session.dart';
import 'package:bus_service/core/navigation/app_router.dart';
import 'package:bus_service/core/models/user_staff.dart';

void main() {
  late AuthBloc authBloc;

  setUp(() {
    authBloc = AuthBloc();
    AppRouter.authService.bindBloc(authBloc);
    AppRouter.authService.logout();
  });

  void loginAs(UserRole role) {
    AppRouter.authService.login(role);
    authBloc.add(AuthLoginRequested(AuthUserSession(
      uid: 'test-${role.name}',
      name: 'Test User',
      phone: '9999999999',
      role: role,
      tenantId: role == UserRole.admin ? '' : 'T1',
    )));
  }

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(MyApp(authBloc: authBloc));
  }

  testWidgets('should load PassengerHomeScreen as initial route (/)', (WidgetTester tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle();

    expect(find.text('Bus SaaS Hub'), findsOneWidget);
    expect(find.text('Passenger Portal'), findsOneWidget);
    expect(find.text('Super Admin (App Owner)'), findsOneWidget);
  });

  testWidgets('should render TripDetailsScreen with extracted ticketHash parameter', (WidgetTester tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle();

    AppRouter.router.go('/passenger/trip-details/my-hash-123');
    await tester.pumpAndSettle();

    expect(find.text('Live Tracking Active'), findsOneWidget);
    expect(find.textContaining('TR001'), findsWidgets);
    expect(find.text('Rajesh Kumar'), findsOneWidget);
    expect(find.text('Share Live Link'), findsOneWidget);
  });

  testWidgets('should redirect unauthenticated admin access from /admin/dashboard to /admin/login', (WidgetTester tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle();

    AppRouter.router.go('/admin/dashboard');
    await tester.pumpAndSettle();

    expect(find.text('Super Admin Login'), findsOneWidget);
  });

  testWidgets('should allow admin access to /admin/dashboard if logged in as admin', (WidgetTester tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle();

    loginAs(UserRole.admin);
    await tester.pumpAndSettle();

    AppRouter.router.go('/admin/dashboard');
    await tester.pumpAndSettle();

    expect(find.text('Super Admin Panel'), findsOneWidget);
    expect(find.text('Platform Overview'), findsOneWidget);
  });

  testWidgets('should redirect driver role access to admin dashboard back to /admin/login', (WidgetTester tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle();

    loginAs(UserRole.driver);
    await tester.pumpAndSettle();

    AppRouter.router.go('/admin/dashboard');
    await tester.pumpAndSettle();

    expect(find.text('Super Admin Login'), findsOneWidget);
  });

  testWidgets('should redirect unauthenticated driver access from /driver/home to /driver/login', (WidgetTester tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle();

    AppRouter.router.go('/driver/home');
    await tester.pumpAndSettle();

    expect(find.text('Driver / Conductor Login'), findsOneWidget);
  });

  testWidgets('should allow driver access to /driver/home when logged in as driver', (WidgetTester tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle();

    loginAs(UserRole.driver);
    await tester.pumpAndSettle();

    AppRouter.router.go('/driver/home');
    await tester.pumpAndSettle();

    expect(find.text('Verify Boarding (Ticket Scan)'), findsOneWidget);
    expect(find.text('Digital Passenger Chart'), findsOneWidget);
  });

  testWidgets('should allow agency login and load dashboard portal', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;

    await pumpApp(tester);
    await tester.pumpAndSettle();

    loginAs(UserRole.agent);
    await tester.pumpAndSettle();

    AppRouter.router.go('/agency/dashboard');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Book Ticket / Generate QR').last);
    await tester.pumpAndSettle();

    expect(find.text('Generate Ticket / QR Code'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
  });
}
