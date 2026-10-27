// This is a basic Flutter widget test for Khairat.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zakat_sadaqah_app/main.dart';
import 'package:zakat_sadaqah_app/utils/localization.dart';

/// Sets a standard 390×844 logical-pixel viewport (iPhone 14 equivalent).
void _setStandardViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// Sets a large viewport to prevent layout overflow in complex screens.
void _setLargeViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  testWidgets('Dashboard renders successfully', (WidgetTester tester) async {
    _setStandardViewport(tester);

    await tester.pumpWidget(const LocalizationManager(
      initialLanguage: AppLanguage.en,
      child: ZakatSadaqahApp(),
    ));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Verify app name is rendered in the AppBar
    expect(find.text('Khairat'), findsOneWidget);

    // Verify overview card sections are rendered
    expect(find.text('Your Contribution Overview'), findsOneWidget);
    expect(find.text('Zakat Paid'), findsOneWidget);
    expect(find.text('Sadaqah Paid'), findsOneWidget);

    // Verify quick actions are rendered
    expect(find.text('Calculate Zakat'), findsOneWidget);
    expect(find.text('Quick Pay'), findsOneWidget);
  });

  testWidgets('Bottom navigation transitions correctly to Services Screen', (WidgetTester tester) async {
    _setStandardViewport(tester);

    await tester.pumpWidget(const LocalizationManager(
      initialLanguage: AppLanguage.en,
      child: ZakatSadaqahApp(),
    ));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Find and tap the "Services" tab
    final servicesTab = find.text('Services');
    expect(servicesTab, findsOneWidget);
    await tester.tap(servicesTab);
    await tester.pumpAndSettle();

    // Verify that the Services screen has loaded with header and grid
    expect(find.text('Services Portal'), findsOneWidget);
    expect(find.text('Zakat'), findsOneWidget);
    expect(find.text('Periodic Donation'), findsOneWidget);
    expect(find.text('Charity Gift'), findsOneWidget);
    expect(find.text('Campaigns'), findsOneWidget);

    // Search bar check
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('Services screen search filters cards correctly', (WidgetTester tester) async {
    _setStandardViewport(tester);

    await tester.pumpWidget(const LocalizationManager(
      initialLanguage: AppLanguage.en,
      child: ZakatSadaqahApp(),
    ));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Navigate to Services Screen
    await tester.tap(find.text('Services'));
    await tester.pumpAndSettle();

    // All services are visible initially
    expect(find.text('Zakat'), findsOneWidget);
    expect(find.text('Periodic Donation'), findsOneWidget);

    // Type a search query to filter results
    await tester.enterText(find.byType(TextField), 'zakat');
    await tester.pumpAndSettle();

    // Only Zakat card should remain visible
    expect(find.text('Zakat'), findsOneWidget);
    // Periodic Donation should be filtered out
    expect(find.text('Periodic Donation'), findsNothing);

    // Clear the search field to restore all cards
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();

    // All services visible again
    expect(find.text('Zakat'), findsOneWidget);
    expect(find.text('Periodic Donation'), findsOneWidget);
  });

  testWidgets('Language toggle changes app state to Arabic', (WidgetTester tester) async {
    // Use a large viewport so the More tab and its content are fully visible
    _setLargeViewport(tester);

    // Start with English
    await tester.pumpWidget(const LocalizationManager(
      initialLanguage: AppLanguage.en,
      child: ZakatSadaqahApp(),
    ));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Navigate to More Screen
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    // Verify More screen is in English
    expect(find.text('Change Language'), findsOneWidget);
    expect(find.text('English / العربية'), findsOneWidget);

    // Tap to toggle language
    await tester.tap(find.text('Change Language'));
    await tester.pumpAndSettle();

    // Verify the LocalizationManagerState has switched to Arabic
    final locManager = tester.state<LocalizationManagerState>(
      find.byType(LocalizationManager),
    );
    expect(locManager.language, equals(AppLanguage.ar));
    expect(locManager.localization.translate('app_name'), equals('خيرات'));
    expect(locManager.textDirection, equals(TextDirection.rtl));
  });
}
