import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bus_service/features/live_tracking/presentation/passenger_map_screen.dart';

void main() {
  testWidgets('PassengerMapScreen layout rendering tests', (WidgetTester tester) async {
    // Pump the tracking map screen into the tester widget tree.
    // The screen connects to Firebase Realtime Database.
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: PassengerMapScreen(
          tripId: 'trip-789',
          ticketHash: 'ticket-hash-xyz',
        ),
      ),
    ));

    // Wait for the UI frames to finish drawing
    await tester.pump();

    // Verify static bottom panel details are displayed
    expect(find.text('Rajesh Kumar'), findsOneWidget); // Driver
    expect(find.text('Amit Sharma'), findsOneWidget); // Conductor
    expect(find.text('15B'), findsOneWidget); // Seat
    expect(find.text('YOUR SEAT'), findsOneWidget);
    expect(find.text('ESTIMATED ARRIVAL'), findsOneWidget);

    // Verify Live Tracking indicator is active
    expect(find.text('Live Tracking Active'), findsOneWidget);
    expect(find.text('Trip ID: trip-789'), findsOneWidget);
  });
}
