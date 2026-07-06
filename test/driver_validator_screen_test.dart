import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:bus_service/main.dart';
import 'package:bus_service/core/blocs/auth_bloc.dart';
import 'package:bus_service/core/navigation/app_router.dart';
import 'package:bus_service/core/models/auth_session.dart';
import 'package:bus_service/core/models/user_staff.dart';
import 'package:bus_service/features/ticket_verification/presentation/driver_validator_screen.dart';

void main() {
  setUp(() {
    AppRouter.authService.logout();
  });

  testWidgets('DriverHomeScreen Verify Boarding Passenger button navigates to scanner', (WidgetTester tester) async {
    final authBloc = AuthBloc();
    AppRouter.authService.bindBloc(authBloc);

    await tester.pumpWidget(MyApp(
      authBloc: authBloc,
    ));
    await tester.pump();

    authBloc.add(AuthLoginRequested(AuthUserSession(
      uid: 'D101',
      name: 'Rajesh Kumar',
      phone: '7777777777',
      role: UserRole.driver,
      tenantId: 'T1',
    )));
    await tester.pumpAndSettle();

    AppRouter.router.go('/driver/home');
    await tester.pumpAndSettle();

    expect(find.text('Verify Boarding (Ticket Scan)'), findsOneWidget);

    await tester.tap(find.text('Verify Boarding (Ticket Scan)'));
    await tester.pumpAndSettle();

    // Verify we navigated to DriverValidatorScreen
    expect(find.byType(DriverValidatorScreen), findsOneWidget);
    expect(find.text('Boarding Verification'), findsOneWidget);
    expect(find.text('Driver Validation Scanner (Test Mode)'), findsOneWidget);
  });

  testWidgets('DriverValidatorScreen verifies simulated boarding states', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: DriverValidatorScreen(tripId: 'TR001'),
      ),
    ));

    await tester.pump();

    // 1. Test Valid Check In scan simulation
    await tester.tap(find.text('Simulate Valid Scan'));
    // Yield to let the async microtasks run
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify success green overlay is displayed
    expect(find.text('Checked In!'), findsOneWidget);
    expect(find.text('Passenger: Jane Doe'), findsOneWidget);
    expect(find.text('Seat Number: 14A'), findsOneWidget);

    // Verify tally counter matches mock values (2 scanned / 5 total booked)
    expect(find.text('બોર્ડિંગ થયેલ પેસેન્જર: 2/5'), findsOneWidget);

    // Wait for the overlay banner to auto-dismiss (2.5 seconds)
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    // Verify overlay is gone and scanner is ready again
    expect(find.text('Checked In!'), findsNothing);
    expect(find.text('Ready to verify tickets'), findsOneWidget);

    // 2. Test Wrong Route/Trip scan simulation
    await tester.tap(find.text('Simulate Wrong Trip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify wrong trip error alert banner displays 'ખોટી ટિકિટ!'
    expect(find.text('ખોટી ટિકિટ!'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    // 3. Test Already Checked In scan simulation
    await tester.tap(find.text('Simulate Recheck'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify duplicate scanned error alert banner displays 'ટિકિટ ઓલરેડી વપરાયેલી છે!'
    expect(find.text('ટિકિટ ઓલરેડી વપરાયેલી છે!'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    // 4. Test Ticket Not Found scan simulation
    await tester.tap(find.text('Simulate Invalid'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify ticket database not found error banner displays 'ખોટી ટિકિટ!'
    expect(find.text('ખોટી ટિકિટ!'), findsOneWidget);
  });
}
