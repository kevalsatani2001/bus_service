import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bus_service/features/live_tracking/bloc/tracking_bloc.dart';
import 'package:bus_service/features/live_tracking/presentation/driver_control_panel.dart';

void main() {
  testWidgets('DriverControlPanel renders wrapped contents and status buttons', (WidgetTester tester) async {
    final trackingBloc = TrackingBloc();

    await tester.pumpWidget(MaterialApp(
      home: BlocProvider<TrackingBloc>.value(
        value: trackingBloc,
        child: const DriverControlPanel(
          tripId: 'TR001',
          child: Center(
            child: Text('Underlying Driver Content'),
          ),
        ),
      ),
    ));

    await tester.pump();

    // Verify wrapped contents are rendered
    expect(find.text('Underlying Driver Content'), findsOneWidget);

    // Verify inactive tracking state labels
    expect(find.text('ટ્રેકિંગ બંધ છે'), findsOneWidget);
    expect(find.text('ટ્રિપ (Trip): TR001'), findsOneWidget);
    expect(find.text('ટ્રેકિંગ શરૂ કરો'), findsOneWidget);
  });
}
