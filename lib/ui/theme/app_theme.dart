import 'package:flutter/material.dart';

class AppTheme {
  static const _primaryColor = Color(0xFF1DB954); // Tidal-ish accent
  static const _surfaceColor = Color(0xFF121212);
  static const _cardColor = Color(0xFF1E1E1E);
  static const _hoverColor = Color(0xFF2A2A2A);

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: _primaryColor,
        secondary: _primaryColor,
        surface: _surfaceColor,
        onSurface: Colors.white,
        onPrimary: Colors.black,
      ),
      scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      cardColor: _cardColor,
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          color: Colors.white70,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: Colors.white54,
        ),
        bodySmall: TextStyle(
          fontSize: 11,
          color: Colors.white38,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white70, size: 22),
      dividerColor: Colors.white10,
      hoverColor: _hoverColor,
      splashColor: Colors.white10,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: const TextStyle(color: Colors.white38),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white24),
        radius: const Radius.circular(4),
        thickness: WidgetStateProperty.all(6),
      ),
    );
  }
}
