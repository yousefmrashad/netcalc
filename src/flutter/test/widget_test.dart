import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:netcalc_app/main.dart';

void main() {
  testWidgets('Renders the home page and main widgets', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    
    // Pump frames to allow the Future and SharedPreferences initialization to complete.
    await tester.pumpAndSettle();

    // Verify that the main widgets are rendered.
    expect(find.text('Total Savings'), findsOneWidget);
    expect(find.text('Recent History'), findsOneWidget);
    expect(find.text('Add to Balance'), findsOneWidget);
  });
}
