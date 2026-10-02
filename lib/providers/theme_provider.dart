import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  /// Restores the theme the user picked last time; follows the device
  /// setting until they pick one.
  ThemeProvider(this._prefs) : _themeMode = _read(_prefs);

  static const _key = 'theme_mode';

  final SharedPreferences _prefs;
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  static ThemeMode _read(SharedPreferences prefs) {
    final saved = prefs.getString(_key);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == saved,
      orElse: () => ThemeMode.system,
    );
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    _prefs.setString(_key, mode.name);
  }

  /// Switches to the opposite of the brightness currently on screen.
  void toggleTheme(Brightness current) {
    setThemeMode(current == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
  }
}
