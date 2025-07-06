// Simple Flutter widget test to verify the app can start up with localization.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flippdf/main.dart';
import 'package:flippdf/language_provider.dart';
import 'package:flippdf/localizations.dart';

void main() {
  testWidgets('App can start up with localization', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => LanguageProvider(),
        child: const MyApp(),
      ),
    );

    // Verify that the app loads successfully
    // This test passes if the app can render without throwing any exceptions
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App renders without errors with localization', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => LanguageProvider(),
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify no exceptions were thrown during rendering
    expect(tester.takeException(), isNull);
  });

  testWidgets('App has correct default language (English)', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => LanguageProvider(),
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify that English text is displayed by default
    expect(find.text('Select PDF File'), findsOneWidget);
    expect(find.text('Select a PDF file to view as a Flipbook'), findsOneWidget);
  });

  testWidgets('Language switcher is present', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => LanguageProvider(),
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify that language switcher icon is present
    expect(find.byIcon(Icons.language), findsOneWidget);
  });

  testWidgets('App supports localization', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => LanguageProvider(),
        child: const MyApp(),
      ),
    );

    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.supportedLocales, contains(const Locale('en')));
    expect(app.supportedLocales, contains(const Locale('th')));
  });

  testWidgets('App has correct title', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => LanguageProvider(),
        child: const MyApp(),
      ),
    );

    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.title, equals('PDF Flipbook'));
  });
}
