import 'package:flutter/material.dart';

class AppTheme {
  static const _lightBackground = Color(0xFFFFFFFF);
  static const _lightText = Color(0xFF000000);
  static const _lightSecondary = Color(0xFF666666);
  static const _lightDivider = Color(0xFFE0E0E0);

  static const _darkBackground = Color(0xFF000000);
  static const _darkText = Color(0xFFFFFFFF);
  static const _darkSecondary = Color(0xFF999999);
  static const _darkDivider = Color(0xFF333333);

  static ThemeData light() => _buildTheme(
        brightness: Brightness.light,
        background: _lightBackground,
        textColor: _lightText,
        secondary: _lightSecondary,
        divider: _lightDivider,
      );

  static ThemeData dark() => _buildTheme(
        brightness: Brightness.dark,
        background: _darkBackground,
        textColor: _darkText,
        secondary: _darkSecondary,
        divider: _darkDivider,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color textColor,
    required Color secondary,
    required Color divider,
  }) {
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: textColor,
        onPrimary: background,
        secondary: secondary,
        onSecondary: background,
        error: textColor,
        onError: background,
        surface: background,
        onSurface: textColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 0.5,
        space: 0,
      ),
      iconTheme: IconThemeData(color: textColor),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: textColor,
        foregroundColor: background,
        elevation: 0,
        shape: const CircleBorder(),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 32,
          fontWeight: FontWeight.w400,
          color: textColor,
          height: 1.3,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 28,
          fontWeight: FontWeight.w400,
          color: textColor,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textColor,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textColor,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textColor,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w300,
          color: secondary,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor,
          letterSpacing: 1.2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: textColor),
        ),
        hintStyle: TextStyle(color: secondary, fontSize: 16),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: background,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
      cardTheme: CardThemeData(
        color: background,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),
      ),
    );
  }
}
