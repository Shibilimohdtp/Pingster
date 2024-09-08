import 'package:flutter/material.dart';

class PingsterTheme {
  static const Color primary100 = Color(0xFFA0522D); // Sienna
  static const Color primary200 = Color(0xFF8B4513); // Saddle Brown
  static const Color secondary100 = Color(0xFFD2B48C); // Tan
  static const Color secondary200 = Color(0xFFCD853F); // Peru
  static const Color accent100 = Color(0xFFFFD700); // Gold
  static const Color accent200 = Color(0xFFDAA520); // Goldenrod
  static const Color text100 = Color(0xFF333333); // Dark Gray
  static const Color text200 = Color(0xFF1A1A1A); // Very Dark Gray
  static const Color background100 = Color(0xFFF5F5DC); // Beige
  static const Color background200 = Color(0xFFD2B48C); // Tan
  static const Color error100 = Color(0xFFB22222); // Firebrick
  static const Color error200 = Color(0xFF8B0000); // Dark Red
  static const Color success100 = Color(0xFF32CD32); // Lime Green
  static const Color success200 = Color(0xFF228B22); // Forest Green
  static const Color appBar100 = Color(0xFF8B4513); // Saddle Brown
  static const Color appBar200 = Color(0xFF5F4C34); // Dark Brown

  static final ThemeData lightTheme = ThemeData(
    primaryColor: primary200,
    scaffoldBackgroundColor: background100,
    appBarTheme: const AppBarTheme(
      backgroundColor: appBar100,
      foregroundColor: Colors.white,
    ),
    colorScheme: const ColorScheme.light(
      primary: primary200,
      secondary: secondary200,
      surface: background100,
      error: error200,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: text200),
      bodyMedium: TextStyle(color: text100),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    primaryColor: primary100,
    scaffoldBackgroundColor: text200,
    appBarTheme: const AppBarTheme(
      backgroundColor: appBar200,
      foregroundColor: Colors.white,
    ),
    colorScheme: const ColorScheme.dark(
      primary: primary100,
      secondary: secondary100,
      surface: text200,
      error: error100,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: background100),
      bodyMedium: TextStyle(color: background200),
    ),
  );

  static ThemeData getThemeData(String theme) {
    switch (theme) {
      case 'light':
        return lightTheme;
      case 'dark':
        return darkTheme;
      default:
        return lightTheme;
    }
  }
}
