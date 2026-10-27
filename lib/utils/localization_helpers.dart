import 'package:flutter/material.dart';
import 'localization.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// ADVANCED LOCALIZATION UTILITIES
/// ─────────────────────────────────────────────────────────────────────────────
/// Enhanced localization with fallback support and missing key detection.
/// ═══════════════════════════════════════════════════════════════════════════════

/// ──────────────────────────────────────────────────────────────────────────────
/// LocalizationExtensions
/// ──────────────────────────────────────────────────────────────────────────────
/// Enhanced localization methods with fallback support.
extension LocalizationExtensions on AppLocalization {
  /// Translate a key with fallback to the key itself if not found.
  String translateSafe(String key, {String? fallback}) {
    final localizedValues = AppLocalization.localizedValues[language] ?? {};
    final result = localizedValues[key];
    return result ?? fallback ?? key;
  }

  /// Translate with default fallback for missing keys.
  String translateWithDefault(String key, String defaultValue) {
    return translateSafe(key, fallback: defaultValue);
  }

  /// Check if a localization key exists.
  bool hasKey(String key) {
    final localizedValues = AppLocalization.localizedValues[language] ?? {};
    return localizedValues.containsKey(key);
  }

  /// Get all missing keys (useful for debugging).
  List<String> getMissingKeys(List<String> keysToCheck) {
    return keysToCheck.where((key) => !hasKey(key)).toList();
  }
}

/// ──────────────────────────────────────────────────────────────────────────────
/// BuildContext Localization Extension
/// ──────────────────────────────────────────────────────────────────────────────
/// Convenient localization access via BuildContext.
extension BuildContextLocalization on BuildContext {
  /// Get the current AppLocalization instance.
  AppLocalization get localization {
    return AppLocalization(Localizations.localeOf(this).languageCode == 'ar'
        ? AppLanguage.ar
        : AppLanguage.en);
  }

  /// Translate with fallback support.
  String translateSafe(String key, {String? fallback}) {
    return localization.translateSafe(key, fallback: fallback);
  }

  /// Check if a key exists in localization.
  bool hasLocalizationKey(String key) {
    return localization.hasKey(key);
  }
}

/// ──────────────────────────────────────────────────────────────────────────────
/// DynamicLocalizationHelper
/// ──────────────────────────────────────────────────────────────────────────────
/// Helper for dynamic key generation with validation.
class DynamicLocalizationHelper {
  /// Generate and validate a dynamic localization key.
  static String generateKey(String prefix, String identifier, String suffix) {
    return '${prefix}_${identifier}_$suffix';
  }

  /// Safely translate a dynamically generated key with fallback.
  static String translateDynamic(
    AppLocalization loc,
    String prefix,
    String identifier,
    String suffix, {
    String? fallback,
  }) {
    final key = generateKey(prefix, identifier, suffix);
    return loc.translateSafe(key, fallback: fallback ?? identifier);
  }

  /// Example: For service localization
  /// translateDynamic(loc, 'service', 'zakat', 'title', fallback: 'Zakat')
  /// → Looks for 'service_zakat_title', falls back to 'Zakat'
}

/// ──────────────────────────────────────────────────────────────────────────────
/// Usage Examples:
/// ──────────────────────────────────────────────────────────────────────────────
///
/// // Basic safe translation
/// String title = loc.translateSafe('service_orphan_title', fallback: 'Orphan');
///
/// // In BuildContext
/// String greeting = context.translateSafe('greeting_morning', fallback: 'Good Morning');
///
/// // Dynamic keys
/// String serviceTitle = DynamicLocalizationHelper.translateDynamic(
///   loc, 'service', 'zakat', 'title', fallback: 'Zakat',
/// );
///
/// // Check if key exists
/// if (loc.hasKey('service_orphan_title')) {
///   // Use it
/// }
///
/// // Find missing keys (debugging)
/// final keysToCheck = ['service_zakat_title', 'unknown_key'];
/// final missing = loc.getMissingKeys(keysToCheck);
/// print('Missing keys: $missing');
