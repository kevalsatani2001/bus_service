import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bus_service/features/seat_layout/widgets/sleeper_layout.dart';

void main() {
  testWidgets('SleeperLayout renders Lower Berth by default and switches to Upper Berth', (WidgetTester tester) async {
    String selectedSeat = '';

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SleeperLayout(
          bookedSeats: const ['L3', 'U12'],
          onSeatSelected: (seat) {
            selectedSeat = seat;
          },
        ),
      ),
    ));

    await tester.pumpAndSettle();

    // Verify Tab labels are displayed
    expect(find.text('Lower Berth (નીચલો માળ)'), findsOneWidget);
    expect(find.text('Upper Berth (ઉપલો માળ)'), findsOneWidget);

    // Verify lower berth seat L1 is visible, but U1 from upper berth is not yet
    expect(find.text('L1'), findsOneWidget);
    expect(find.text('U1'), findsNothing);

    // Tap on Upper Berth Tab
    await tester.tap(find.text('Upper Berth (ઉપલો માળ)'));
    await tester.pumpAndSettle();

    // Verify upper berth seats are now visible, lower are hidden
    expect(find.text('U1'), findsOneWidget);
    expect(find.text('L1'), findsNothing);
  });

  testWidgets('SleeperLayout triggers callback on tapping available seat', (WidgetTester tester) async {
    String selectedSeat = '';

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SleeperLayout(
          bookedSeats: const ['L3'],
          onSeatSelected: (seat) {
            selectedSeat = seat;
          },
        ),
      ),
    ));

    await tester.pumpAndSettle();

    // Tap on available seat L1
    await tester.tap(find.text('L1'));
    await tester.pumpAndSettle();

    expect(selectedSeat, equals('L1'));
  });

  testWidgets('SleeperLayout does not trigger callback on booked seat tap', (WidgetTester tester) async {
    String selectedSeat = '';

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SleeperLayout(
          bookedSeats: const ['L1'], // L1 is booked
          onSeatSelected: (seat) {
            selectedSeat = seat;
          },
        ),
      ),
    ));

    await tester.pumpAndSettle();

    // Tap on booked seat L1
    await tester.tap(find.text('L1'));
    await tester.pumpAndSettle();

    // Callback should not be triggered, selectedSeat remains empty
    expect(selectedSeat, isEmpty);
  });
}
