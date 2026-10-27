import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  // App Names
  static const String appName = 'Khairat';
  static const String appSubtitle = 'Modern Islamic Financial Services';

  // Standard Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // App Padding
  static const EdgeInsets screenPadding = EdgeInsets.all(spacingMd);
  static const EdgeInsets cardPadding = EdgeInsets.all(spacingMd);

  // Zakat Rules Constants (Sample reference values)
  static const double zakatRate = 0.025; // 2.5%
  static const double goldNisabGrams = 85.0; // Nisab threshold in grams of gold
  static const double silverNisabGrams = 595.0; // Nisab threshold in grams of silver
  /// Default gold price per gram (USD) for nisab — user can override in calculator.
  static const double defaultGoldPricePerGram = 75.0;

  // Shared Preferences or Storage Keys (for future use)
  static const String keyUserToken = 'user_token';
  static const String keyThemeMode = 'theme_mode';
  static const String keyUserRole = 'user_role'; // Muzakki or Mustahik

  static double parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }
}
