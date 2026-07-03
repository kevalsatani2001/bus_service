import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bus_service/main.dart';
import 'package:bus_service/features/ticket_verification/presentation/passenger_scan_screen.dart';
import 'package:bus_service/core/blocs/auth_bloc.dart';
import 'package:bus_service/core/blocs/theme_bloc.dart';

import 'package:bus_service/core/navigation/app_router.dart';

void main() {
  setUp(() {
    AppRouter.router.go('/passenger/scan');
  });

  testWidgets('PassengerScanScreen camera rendering and simulated scan updates theme', (WidgetTester tester) async {
    final authBloc = AuthBloc();

    // Pump the root MyApp to ensure the theme bloc and router are fully registered
    await tester.pumpWidget(MyApp(authBloc: authBloc));
    AppRouter.router.go('/passenger/scan');
    await tester.pumpAndSettle();

    // Verify PassengerScanScreen and elements are rendered
    expect(find.byType(PassengerScanScreen), findsOneWidget);
    expect(find.text('Scan QR Ticket'), findsOneWidget);
    expect(find.text('Align ticket QR inside bounds'), findsOneWidget);
    expect(find.text('Simulate Scan Ticket'), findsOneWidget);

    final BuildContext elementContext = tester.element(find.byType(PassengerScanScreen));
    final themeBloc = elementContext.read<ThemeBloc>();
    
    // Verify default initial theme color
    expect(themeBloc.state.themeColor, Colors.indigo);

    // Tap the simulation button to scan a mock QR code with tenant custom color (#E91E63)
    await tester.tap(find.text('Simulate Scan Ticket'));
    await tester.pumpAndSettle();

    // Verify theme color has updated dynamically via ThemeBloc
    expect(themeBloc.state.themeColor, const Color(0xffe91e63));
    expect(themeBloc.state.tenantName, 'Custom Test Agency');
  });

  testWidgets('PassengerScanScreen supports manual ticket ID entry search', (WidgetTester tester) async {
    final authBloc = AuthBloc();

    await tester.pumpWidget(MyApp(authBloc: authBloc));
    AppRouter.router.go('/passenger/scan');
    await tester.pumpAndSettle();

    final BuildContext elementContext = tester.element(find.byType(PassengerScanScreen));
    final themeBloc = elementContext.read<ThemeBloc>();

    // Reset/Verify initial theme color
    themeBloc.add(ThemeReset());
    await tester.pumpAndSettle();
    expect(themeBloc.state.themeColor, Colors.indigo);

    // Enter a ticket ID manually
    await tester.enterText(find.byType(TextField), 'TCK-MOCK-999');
    await tester.pump();

    // Tap submit arrow button
    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pumpAndSettle();

    // Verify theme color updates to pink and user transitions
    expect(themeBloc.state.themeColor, const Color(0xffe91e63));
    expect(themeBloc.state.tenantName, 'Custom Test Agency');
  });
}
