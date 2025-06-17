// Simple Flutter widget test to verify the app can start up.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pdf_flipbook/main.dart';

void main() {
  testWidgets('App can start up', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app loads successfully
    // This test passes if the app can render without throwing any exceptions
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
