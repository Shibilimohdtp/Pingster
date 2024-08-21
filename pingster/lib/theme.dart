import 'package:flutter/material.dart';

class PingsterTheme {
  static const Color primary100 = Color(0xFF4DB6AC);
  static const Color primary200 = Color(0xFF009688);
  static const Color secondary100 = Color(0xFF80CBC4);
  static const Color secondary200 = Color(0xFF4DB6AC);
  static const Color accent100 = Color(0xFFFF7043);
  static const Color accent200 = Color(0xFFFF5722);
  static const Color text100 = Color(0xFF424242);
  static const Color text200 = Color(0xFF212121);
  static const Color background100 = Color(0xFFE0F2F1);
  static const Color background200 = Color(0xFFB2DFDB);
  static const Color error100 = Color(0xFFEF5350);
  static const Color error200 = Color(0xFFF44336);
  static const Color success100 = Color(0xFF66BB6A);
  static const Color success200 = Color(0xFF4CAF50);
  static const Color appBar100 = Color(0xFF26A69A);
  static const Color appBar200 = Color(0xFF00796B);

  static final ThemeData lightTheme = ThemeData(
    primaryColor: primary200,
    scaffoldBackgroundColor: background100,
    appBarTheme: const AppBarTheme(
      backgroundColor: appBar100,
      foregroundColor: Colors.white,
    ),
    colorScheme: ColorScheme.light(
      primary: primary200,
      secondary: secondary200,
      background: background100,
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
    colorScheme: ColorScheme.dark(
      primary: primary100,
      secondary: secondary100,
      background: text200,
      error: error100,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: background100),
      bodyMedium: TextStyle(color: background200),
    ),
  );
}
