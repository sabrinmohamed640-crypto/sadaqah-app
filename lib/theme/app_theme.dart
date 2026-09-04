import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryEmerald = Color(0xFF0F766E);
  static const Color primaryEmeraldLight = Color(0xFF14B8A6);
  static const Color accentGold = Color(0xFFD97706);
  static const Color bgDark = Color(0xFF090D16);
  static const Color cardDark = Color(0xFF131A29);
  static const Color borderDark = Color(0xFF1E293B);
  static const Color textLight = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: primaryEmerald,
      cardColor: cardDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryEmeraldLight,
        secondary: accentGold,
        surface: cardDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textLight,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.02,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryEmerald,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
