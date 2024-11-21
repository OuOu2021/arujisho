import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  static const String _themeModeKey = 'themeMode';

  ThemeMode get themeMode => _themeMode;

  ThemeNotifier() {
    _init();
  }

  Future<void> _init() async {
    await _loadThemeMode();
    notifyListeners(); // Notify listeners after loading the theme mode
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _saveThemeMode();
    notifyListeners();
  }

  Future<void> _saveThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(_themeModeKey, _themeMode.name);
  }

  Future<void> _loadThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? themeModeName = prefs.getString(_themeModeKey);
    if (themeModeName != null) {
      switch (themeModeName) {
        case 'system':
          _themeMode = ThemeMode.system;
          break;
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
      }
    } else {
      _themeMode = ThemeMode.system;
    }
  }
}
