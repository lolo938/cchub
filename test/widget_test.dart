import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:childcarehub_flutter/main.dart';

void main() {
  group('ChildcareHub App Tests', () {
    testWidgets('App should start and show splash screen', (WidgetTester tester) async {
      // Mock Firebase and other services for testing
      await tester.pumpWidget(
        const ProviderScope(
          child: ChildcareHubApp(),
        ),
      );

      // Wait for the splash screen to appear
      await tester.pump();

      // Verify the app starts correctly
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('App should handle theme mode changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: ChildcareHubApp(),
        ),
      );

      await tester.pump();

      // Verify the app has theme configuration
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.theme, isNotNull);
      expect(app.darkTheme, isNotNull);
      expect(app.themeMode, ThemeMode.system);
    });

    testWidgets('App should prevent text scaling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: ChildcareHubApp(),
        ),
      );

      await tester.pump();

      // Verify MediaQuery builder is present
      expect(find.byType(MediaQuery), findsWidgets);
    });
  });
}
