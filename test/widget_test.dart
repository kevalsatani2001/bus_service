import 'package:flutter_test/flutter_test.dart';
import 'package:bus_service/main.dart';
import 'package:bus_service/core/blocs/auth_bloc.dart';
import 'package:bus_service/core/navigation/stub_screens.dart';

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    final authBloc = AuthBloc();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(authBloc: authBloc));
    await tester.pumpAndSettle();

    // Verify that the initial screen is the PassengerHomeScreen (the selector menu)
    expect(find.byType(PassengerHomeScreen), findsOneWidget);
    expect(find.text('Bus SaaS Hub'), findsOneWidget);
  });
}
