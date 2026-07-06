import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bus_service/features/live_tracking/presentation/passenger_map_screen.dart';
import 'package:bus_service/core/models/models.dart';

void main() {
  testWidgets('PassengerMapScreen layout rendering tests', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PassengerMapScreen(
          tripId: 'TR001',
          ticketHash: 'TICK-1042',
          ticket: Ticket(
            id: 'TICK-1042',
            tenantId: 'T1',
            tripId: 'TR001',
            passengerName: 'Test',
            passengerPhone: '9999999999',
            seatNumber: 'L4',
            boardingPoint: 'અડાજણ',
            dropPoint: 'બારડોલી',
            qrHash: 'TICK-1042',
            trackingUrl: 'https://mytravels.com/track/TICK-1042',
            isScanned: false,
            bookedAt: DateTime(2026, 7, 3),
          ),
        ),
      ),
    ));

    await tester.pumpAndSettle();

    expect(find.text('L4'), findsOneWidget);
    expect(find.text('SEAT'), findsOneWidget);
    expect(find.textContaining('ESTIMATED ARRIVAL'), findsOneWidget);
    expect(find.text('Live Tracking Active'), findsOneWidget);
    expect(find.text('Share Live Link'), findsOneWidget);
    expect(find.text('Bus Photos'), findsOneWidget);
    expect(find.text('Route Timeline (રૂટ)'), findsOneWidget);
  });
}
