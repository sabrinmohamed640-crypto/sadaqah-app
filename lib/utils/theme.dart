import 'package:flutter/material.dart';

/// Khairat — Central Theme & Color System
/// ─────────────────────────────────────
/// Single source of truth for all colors and themes.
/// Import [AppColors] anywhere in the app for named color constants.
class AppTheme {
  AppTheme._();

  // ── Brand Palette ────────────────────────────────────────────────────────────
  /// Deep Charcoal — primary identity color; headers, navbars, dark surfaces.
  static const Color charcoal      = Color(0xFF1A202C);
  /// Muted Gold — accent / CTA; buttons, active indicators, highlights.
  static const Color gold          = Color(0xFFC5A059);
  /// Muted Gold dark variant — gradient end, pressed states.
  static const Color goldDark      = Color(0xFFA8863D);
  /// Off-White — light mode scaffold background.
  static const Color offWhite      = Color(0xFFF7FAFC);
  /// Soft Emerald — success states, donation receipts, positive indicators.
  static const Color emerald       = Color(0xFF38A169);
  /// Soft Emerald dark variant — deeper success shade.
  static const Color emeraldDark   = Color(0xFF276749);

  // ── Light Mode Surfaces ───────────────────────────────────────────────────────
  static const Color lightBackground   = Color(0xFFF7FAFC); // off-white
  static const Color lightSurface      = Color(0xFFFFFFFF); // pure white cards
  static const Color lightSurfaceAlt   = Color(0xFFEDF2F7); // subtle dividers/inputs

  // ── Dark Mode Surfaces ────────────────────────────────────────────────────────
  static const Color darkBackground    = Color(0xFF1A202C); // deep charcoal
  static const Color darkSurface       = Color(0xFF2D3748); // elevated card surface
  static const Color darkSurfaceAlt    = Color(0xFF4A5568); // input/border alt

  // ── Text ──────────────────────────────────────────────────────────────────────
  static const Color textPrimaryLight  = Color(0xFF1A202C); // charcoal on light
  static const Color textSecondaryLight= Color(0xFF4A5568);
  static const Color textMutedLight    = Color(0xFF718096);

  static const Color textPrimary       = Color(0xFFF7FAFC); // off-white on dark
  static const Color textSecondary     = Color(0xFFA0AEC0);
  static const Color textMuted         = Color(0xFF718096);

  // ── Legacy aliases (keep backward-compat with screens using AppTheme.xxx) ─────
  static const Color primaryColor      = gold;
  static const Color primaryDark       = goldDark;
  static const Color accentColor       = emerald;
  static const Color backgroundColor   = darkBackground;
  static const Color surfaceColor      = darkSurface;
  static const Color surfaceLightColor = darkSurfaceAlt;

  // ═══════════════════════════════════════════════════════════════════════════════
  //  LIGHT THEME
  // ═══════════════════════════════════════════════════════════════════════════════
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: gold,
      scaffoldBackgroundColor: lightBackground,

      colorScheme: const ColorScheme.light(
        primary: gold,
        primaryContainer: Color(0xFFF5E8C8),  // soft gold tint for containers
        secondary: emerald,
        secondaryContainer: Color(0xFFC6F6D5),
        surface: lightSurface,
        onPrimary: Color(0xFF1A202C),         // charcoal on gold — WCAG AA
        onSecondary: Colors.white,
        onSurface: textPrimaryLight,
        error: Color(0xFFE53E3E),
        onError: Colors.white,
        outline: Color(0xFFCBD5E0),
      ),

      // App Bar
      appBarTheme: const AppBarTheme(
        backgroundColor: charcoal,
        foregroundColor: offWhite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: offWhite,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
        iconTheme: IconThemeData(color: offWhite),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 1,
        shadowColor: Color(0x1A1A202C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),

      // Elevated Button → Muted Gold globally
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: charcoal,      // dark text on gold — high contrast
          disabledBackgroundColor: Color(0xFFD4B896),
          disabledForegroundColor: Color(0xFF7A6040),
          elevation: 2,
          shadowColor: Color(0x33C5A059),
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: charcoal,
          side: BorderSide(color: charcoal, width: 1.5),
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: gold,
          textStyle: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceAlt,
        hintStyle: TextStyle(color: textMutedLight),
        labelStyle: TextStyle(color: textSecondaryLight),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFCBD5E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFCBD5E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: gold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE53E3E)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE53E3E), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge:  TextStyle(color: textPrimaryLight, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: textPrimaryLight, fontSize: 28, fontWeight: FontWeight.bold),
        titleLarge:    TextStyle(color: textPrimaryLight, fontSize: 22, fontWeight: FontWeight.w700),
        titleMedium:   TextStyle(color: textPrimaryLight, fontSize: 18, fontWeight: FontWeight.w600),
        bodyLarge:     TextStyle(color: textPrimaryLight, fontSize: 16, height: 1.5),
        bodyMedium:    TextStyle(color: textSecondaryLight, fontSize: 14, height: 1.5),
        labelLarge:    TextStyle(color: textPrimaryLight, fontSize: 14, fontWeight: FontWeight.bold),
        bodySmall:     TextStyle(color: textMutedLight, fontSize: 12),
      ),

      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightSurface,
        indicatorColor: Color(0xFFF5E8C8),  // soft gold tint
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
                color: gold, fontWeight: FontWeight.bold, fontSize: 12);
          }
          return const TextStyle(color: textMutedLight, fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: gold);
          }
          return const IconThemeData(color: textMutedLight);
        }),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 1,
        space: 0,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: lightSurfaceAlt,
        labelStyle: const TextStyle(color: textPrimaryLight, fontSize: 13),
        side: const BorderSide(color: Color(0xFFCBD5E0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  //  DARK THEME
  // ═══════════════════════════════════════════════════════════════════════════════
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: gold,
      scaffoldBackgroundColor: darkBackground,

      colorScheme: const ColorScheme.dark(
        primary: gold,
        primaryContainer: Color(0xFF4A3820),  // dark gold container
        secondary: emerald,
        secondaryContainer: Color(0xFF1C4532),
        surface: darkSurface,
        onPrimary: Color(0xFF1A202C),         // charcoal on gold — WCAG AA
        onSecondary: Colors.white,
        onSurface: textPrimary,
        error: Color(0xFFFC8181),
        onError: charcoal,
        outline: Color(0xFF4A5568),
      ),

      // App Bar
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 2,
        shadowColor: Color(0x33000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Color(0xFF4A5568), width: 1),
        ),
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),

      // Elevated Button → Muted Gold globally
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: charcoal,      // dark text on gold — high contrast
          disabledBackgroundColor: Color(0xFF5C4A28),
          disabledForegroundColor: Color(0xFF9A7A45),
          elevation: 3,
          shadowColor: Color(0x55C5A059),
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: gold,
          side: BorderSide(color: gold, width: 1.5),
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: gold,
          textStyle: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        hintStyle: TextStyle(color: textMuted),
        labelStyle: TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF4A5568)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF4A5568)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: gold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFFC8181)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFFC8181), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge:  TextStyle(color: textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
        titleLarge:    TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.w700),
        titleMedium:   TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        bodyLarge:     TextStyle(color: textPrimary, fontSize: 16, height: 1.5),
        bodyMedium:    TextStyle(color: textSecondary, fontSize: 14, height: 1.5),
        labelLarge:    TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
        bodySmall:     TextStyle(color: textMuted, fontSize: 12),
      ),

      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: Color(0x33C5A059),   // translucent gold indicator
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
                color: gold, fontWeight: FontWeight.bold, fontSize: 12);
          }
          return const TextStyle(color: textSecondary, fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: gold);
          }
          return const IconThemeData(color: textSecondary);
        }),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: Color(0xFF4A5568),
        thickness: 1,
        space: 0,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: darkSurface,
        labelStyle: const TextStyle(color: textPrimary, fontSize: 13),
        side: const BorderSide(color: Color(0xFF4A5568)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  AppColors — Named shortcuts for use throughout the app
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Brand
  static const Color charcoal      = AppTheme.charcoal;
  static const Color gold          = AppTheme.gold;
  static const Color goldDark      = AppTheme.goldDark;
  static const Color offWhite      = AppTheme.offWhite;
  static const Color emerald       = AppTheme.emerald;
  static const Color emeraldDark   = AppTheme.emeraldDark;

  // Surfaces
  static const Color lightBackground  = AppTheme.lightBackground;
  static const Color lightSurface     = AppTheme.lightSurface;
  static const Color darkBackground   = AppTheme.darkBackground;
  static const Color darkSurface      = AppTheme.darkSurface;

  // Text
  static const Color textPrimary      = AppTheme.textPrimary;
  static const Color textSecondary    = AppTheme.textSecondary;
  static const Color textMuted        = AppTheme.textMuted;

  // Legacy aliases — preserve backward compat
  static const Color primary          = AppTheme.gold;
  static const Color primaryDark      = AppTheme.goldDark;
  static const Color accent           = AppTheme.emerald;
  static const Color background       = AppTheme.darkBackground;
  static const Color surface          = AppTheme.darkSurface;
  static const Color surfaceLight     = AppTheme.darkSurfaceAlt;
}
