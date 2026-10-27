import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// APP TYPOGRAPHY UTILITIES
/// ─────────────────────────────────────────────────────────────────────────────
/// Centralized typography constants and utilities for consistent text styling 
/// throughout the Khairat app.
/// ═══════════════════════════════════════════════════════════════════════════════

/// ──────────────────────────────────────────────────────────────────────────────
/// AppTypography
/// ──────────────────────────────────────────────────────────────────────────────
/// Centralized typography styles for consistency across the app.
class AppTypography {
  AppTypography._();

  // ── FONT FAMILIES ────────────────────────────────────────────────────────────
  /// Use System default font (San Francisco on iOS, Roboto on Android)
  static const String defaultFontFamily = 'system';

  // ── DISPLAY STYLES (Hero content) ────────────────────────────────────────────
  /// Extra Large Display — Page titles, major headings (32px)
  static const TextStyle displayXL = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.5,
  );

  /// Large Display — Section titles (28px)
  static const TextStyle displayLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.2,
  );

  /// Medium Display — Subsection titles (24px)
  static const TextStyle displayMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0,
  );

  // ── HEADING STYLES (Cards, sections) ─────────────────────────────────────────
  /// Large Heading — Card titles, primary headings (22px)
  static const TextStyle headingLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0.1,
  );

  /// Medium Heading — Subheadings (18px)
  static const TextStyle headingMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.1,
  );

  /// Small Heading — Tertiary headings (16px)
  static const TextStyle headingSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.2,
  );

  // ── BODY STYLES (Regular content) ────────────────────────────────────────────
  /// Large Body — Primary body text (16px)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.2,
  );

  /// Medium Body — Secondary body text (14px)
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.2,
  );

  /// Small Body — Tertiary body text (12px)
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.3,
  );

  // ── LABEL STYLES (Buttons, badges) ──────────────────────────────────────────
  /// Large Label — Primary button text, badges (14px)
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: 0.5,
  );

  /// Medium Label — Secondary labels (13px)
  static const TextStyle labelMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.4,
  );

  /// Small Label — Small labels, captions (11px)
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.4,
  );

  // ── CAPTION STYLES (Hints, meta text) ────────────────────────────────────────
  /// Large Caption — Extended metadata (12px)
  static const TextStyle captionLarge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.2,
  );

  /// Medium Caption — Standard caption (11px)
  static const TextStyle captionMedium = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.2,
  );

  // ── SPECIALIZED STYLES ───────────────────────────────────────────────────────
  /// Stats Value — Large number display (36px, extra bold)
  static const TextStyle statValue = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -0.5,
  );

  /// Stats Label — Stat label text (14px, medium)
  static const TextStyle statLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.2,
  );

  /// Button Text — Standard button styling (16px, bold)
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.5,
  );

  /// Input Hint — Input field placeholder (14px)
  static const TextStyle inputHint = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.2,
  );
}

/// ──────────────────────────────────────────────────────────────────────────────
/// TextStyleExtensions
/// ──────────────────────────────────────────────────────────────────────────────
/// Helpful extensions for easy text styling modifications.
extension TextStyleExtensions on TextStyle {
  /// Apply a text color to this style
  TextStyle withColor(Color color) {
    return copyWith(color: color);
  }

  /// Apply font weight to this style
  TextStyle withWeight(FontWeight weight) {
    return copyWith(fontWeight: weight);
  }

  /// Apply font size to this style
  TextStyle withSize(double size) {
    return copyWith(fontSize: size);
  }

  /// Apply line height to this style
  TextStyle withHeight(double height) {
    return copyWith(height: height);
  }

  /// Apply letter spacing to this style
  TextStyle withSpacing(double spacing) {
    return copyWith(letterSpacing: spacing);
  }

  /// Make text bold
  TextStyle bold() {
    return copyWith(fontWeight: FontWeight.bold);
  }

  /// Make text semi-bold
  TextStyle semiBold() {
    return copyWith(fontWeight: FontWeight.w600);
  }

  /// Make text lighter
  TextStyle light() {
    return copyWith(fontWeight: FontWeight.w300);
  }
}
