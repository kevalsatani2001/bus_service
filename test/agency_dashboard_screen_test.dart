import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bus_service/web_panels/agency_dashboard/presentation/agency_dashboard_screen.dart';

void main() {
  testWidgets('AgencyDashboardScreen renders sidebar on desktop screen width', (WidgetTester tester) async {
    // Set screen size to desktop width (e.g. 1024x768)
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const MaterialApp(
      home: AgencyDashboardScreen(),
    ));

    await tester.pumpAndSettle();

    // Verify desktop layout sidebar items are present
    expect(find.text('Overview/Stats'), findsAtLeastNWidgets(1));
    expect(find.text('Buses'), findsAtLeastNWidgets(1));
    expect(find.text('Trips'), findsAtLeastNWidgets(1));
    expect(find.text('Book Ticket / Generate QR'), findsAtLeastNWidgets(1));
    expect(find.text('Active Fleet'), findsOneWidget); // KPI Card

    // Sidebar collapse trigger should be visible
    expect(find.text('Collapse Sidebar'), findsOneWidget);

    // Reset physical size
    addTearDown(tester.view.resetPhysicalSize);
  });

  testWidgets('AgencyDashboardScreen renders drawer icon on mobile screen width', (WidgetTester tester) async {
    // Set screen size to mobile width (e.g. 400x800)
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const MaterialApp(
      home: AgencyDashboardScreen(),
    ));

    await tester.pumpAndSettle();

    // In mobile view, the desktop sidebar should be hidden
    expect(find.text('Collapse Sidebar'), findsNothing);

    // Verify Hamburger drawer icon exists (scaffold appBar icon button)
    expect(find.byType(IconButton), findsAtLeastNWidgets(1));

    // Reset physical size
    addTearDown(tester.view.resetPhysicalSize);
  });

  testWidgets('AgencyDashboardScreen switches tabs on user click', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const MaterialApp(
      home: AgencyDashboardScreen(),
    ));

    await tester.pumpAndSettle();

    // Initial state: Overview tab active
    expect(find.text('Weekly Booking Revenue'), findsOneWidget);
    expect(find.text('Bus Fleet Management'), findsNothing);

    // Click on "Buses" tab
    await tester.tap(find.text('Buses'));
    await tester.pumpAndSettle();

    // Buses view should now render
    expect(find.text('Bus Fleet Management'), findsOneWidget);
    expect(find.text('Weekly Booking Revenue'), findsNothing);

    // Click on "Book Ticket / Generate QR" tab
    await tester.tap(find.text('Book Ticket / Generate QR'));
    await tester.pumpAndSettle();

    // Booking view should now render
    expect(find.text('Generate Ticket / QR Code'), findsOneWidget);
    expect(find.text('Passenger Name (પેસેન્જર નામ)'), findsOneWidget);

    // Reset physical size
    addTearDown(tester.view.resetPhysicalSize);
  });
}
