// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:crud_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Setup an in-memory sqflite implementation for widget tests.
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('App renders with no records', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(firebaseConfigured: false));
    await tester.pumpAndSettle(); // Wait for async operations to complete

    expect(find.text('Students'), findsOneWidget);
    expect(find.text('No records found.'), findsOneWidget);
  });
}
