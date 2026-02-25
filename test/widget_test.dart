// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:netcalc_app/main.dart';

void main() {
  testWidgets('Renders the home page and main widgets', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    
    // Pump a second frame to allow the FutureBuilder to complete.
    await tester.pump();

    // Verify that the main widgets are rendered.
    expect(find.text('Total Savings'), findsOneWidget);
    expect(find.text('Recent History'), findsOneWidget);
    expect(find.text('Add to Balance'), findsOneWidget);
  });
}
