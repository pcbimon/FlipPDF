// Simple Flutter widget test to verify the app can start up.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flippdf/main.dart';

void main() {
  testWidgets('App can start up', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify that the app loads successfully
    // This test passes if the app can render without throwing any exceptions
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();

    // Verify no exceptions were thrown during rendering
    expect(tester.takeException(), isNull);
  });

  testWidgets('App has a home widget', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();

    // Verify that there's a home screen or main content
    expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
  });

  testWidgets('App title is set correctly', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.title, isNotEmpty);
  });
}
