import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bus_service/web_panels/agency_dashboard/widgets/ticket_booking_form.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  testWidgets('TicketBookingForm fields rendering and seat selection toggle tests', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 1400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TicketBookingForm(tenantId: 'T1'),
        ),
      ),
    ));

    await tester.pumpAndSettle();

    expect(find.text('Passenger Name (પેસેન્જર નામ)'), findsOneWidget);
    expect(find.text('Boarding Point (બેસવાનું)'), findsOneWidget);
    expect(find.text('Drop Point (ઉતરવાનું ગામ)'), findsOneWidget);
    expect(find.text('Select Scheduled Trip Route'), findsOneWidget);
    expect(find.text('Select Seat from Layout Berth (2x1 Sleeper)'), findsNothing);

    await tester.tap(find.text('Select Scheduled Trip Route'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Live').last);
    await tester.pumpAndSettle();

    expect(find.text('Select Seat from Layout Berth (2x1 Sleeper)'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
  });

  testWidgets('TicketBookingForm validates inputs and displays success QR code modal', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 1400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TicketBookingForm(tenantId: 'T1'),
        ),
      ),
    ));

    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm Seat & Book Ticket'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter passenger name'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Passenger Name (પેસેન્જર નામ)'), 'Bob Tester');
    await tester.enterText(find.widgetWithText(TextFormField, 'Phone Number (મોબાઇલ)'), '9988776655');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Boarding Point (બેસવાનું)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('અડાજણ').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Drop Point (ઉતરવાનું ગામ)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('બારડોલી').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Select Scheduled Trip Route'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Live').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('L4'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm Seat & Book Ticket'));
    await tester.pumpAndSettle();

    expect(find.text('Ticket Booked Successfully!'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Print Ticket'), findsOneWidget);
    expect(find.text('Share to WA'), findsOneWidget);

    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();

    addTearDown(tester.view.resetPhysicalSize);
  });
}
