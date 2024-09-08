import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _themeData = PingsterTheme.lightTheme;
  final String key = "theme";

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  ThemeData get themeData => _themeData;

  bool get isDarkMode => _themeData == PingsterTheme.darkTheme;

  Future<void> _loadThemeFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isDark = prefs.getBool(key) ?? false;
    _themeData = isDark ? PingsterTheme.darkTheme : PingsterTheme.lightTheme;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_themeData == PingsterTheme.lightTheme) {
      _themeData = PingsterTheme.darkTheme;
      await prefs.setBool(key, true);
    } else {
      _themeData = PingsterTheme.lightTheme;
      await prefs.setBool(key, false);
    }
    notifyListeners();
  }
}