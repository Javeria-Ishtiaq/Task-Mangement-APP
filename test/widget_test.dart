// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskmangementapp/main.dart';

void main() {
  testWidgets('Task Manager basic UI renders and can add a task',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());

    // Wait for splash to finish (user extended to 15s)
    await tester.pump(const Duration(seconds: 16));
    await tester.pumpAndSettle();

    // Initially shows empty state text
    expect(find.text('No tasks yet'), findsOneWidget);

    // Tap prominent FAB
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Enter a task title and confirm
    await tester.enterText(find.byType(TextField), 'Buy milk');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    // New task appears
    expect(find.text('Buy milk'), findsOneWidget);

    // Toggle complete
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
  });
}
