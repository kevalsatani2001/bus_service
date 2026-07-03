import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bus_service/web_panels/agency_dashboard/widgets/ticket_booking_form.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  testWidgets('TicketBookingForm fields rendering and seat selection toggle tests', (WidgetTester tester) async {
    // Set view size to desktop format to ensure visibility of all fields
    tester.view.physicalSize = const Size(1024, 1200);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TicketBookingForm(tenantId: 'T1'),
        ),
      ),
    ));

    await tester.pump();

    // Verify name and phone input text fields render
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Passenger Name'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);

    // Verify trip route selector dropdown is visible
    expect(find.text('Select Scheduled Trip Route'), findsOneWidget);

    // Verify Sleeper layout is NOT visible initially (trip is not selected)
    expect(find.text('Select Seat from Layout Berth'), findsNothing);

    // Tap on Dropdown and select a trip
    await tester.tap(find.text('Select Scheduled Trip Route'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delhi - Jaipur (Live)').last);
    await tester.pumpAndSettle();

    // Now seat selection area must be visible
    expect(find.text('Select Seat from Layout Berth'), findsOneWidget);
    expect(find.text('Selected Seat No:'), findsOneWidget);
    expect(find.text('None Selected'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
  });

  testWidgets('TicketBookingForm validates inputs and displays success QR code modal', (WidgetTester tester) async {
    // Set view size to desktop format to ensure visibility of submit button
    tester.view.physicalSize = const Size(1024, 1200);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TicketBookingForm(tenantId: 'T1'),
        ),
      ),
    ));

    await tester.pump();

    // Tap submit button without inputting anything
    await tester.tap(find.text('Confirm Seat & Book Ticket'));
    await tester.pumpAndSettle();

    // Name and phone number fields should show validation errors
    expect(find.text('Please enter passenger name'), findsOneWidget);
    expect(find.text('Please enter phone number'), findsOneWidget);

    // Fill in Name and Phone
    await tester.enterText(find.widgetWithText(TextFormField, 'Passenger Name'), 'Bob Tester');
    await tester.enterText(find.widgetWithText(TextFormField, 'Phone Number'), '9988776655');
    await tester.pumpAndSettle();

    // Select trip
    await tester.tap(find.text('Select Scheduled Trip Route'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delhi - Jaipur (Live)').last);
    await tester.pumpAndSettle();

    // Verify validation errors disappear on next submit attempt
    await tester.tap(find.text('Confirm Seat & Book Ticket'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter passenger name'), findsNothing);
    expect(find.text('Please enter phone number'), findsNothing);

    // Tap on an available seat (e.g. L4, since L1 and L3 are booked)
    await tester.tap(find.text('L4'));
    await tester.pumpAndSettle();

    // Selected Seat No text should change from 'None Selected' to 'L4'
    expect(find.text('L4'), findsAtLeastNWidgets(1));

    // Tap confirm seat & book ticket button
    await tester.tap(find.text('Confirm Seat & Book Ticket'));
    await tester.pumpAndSettle();

    // Dialog Modal should open showing Ticket Booked Successfully
    expect(find.text('Ticket Booked Successfully!'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget); // QrImageView is present

    // Verify Action buttons and Dismiss button
    expect(find.text('Print Ticket'), findsOneWidget);
    expect(find.text('Share to WA'), findsOneWidget);
    expect(find.text('Dismiss'), findsOneWidget);

    // Tap Print Ticket placeholder
    await tester.tap(find.text('Print Ticket'));
    await tester.pump();

    // Tap Dismiss to close modal
    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();

    expect(find.text('Ticket Booked Successfully!'), findsNothing);

    addTearDown(tester.view.resetPhysicalSize);
  });
}
