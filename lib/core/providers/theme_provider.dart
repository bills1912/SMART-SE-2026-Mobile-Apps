import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../services/storage_service.dart';

enum ThemeModeType { light, dark, system }

class ThemeProvider extends ChangeNotifier {
  ThemeModeType _themeModeType = ThemeModeType.system;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider() {
    _loadThemeFromStorage();
  }

  ThemeModeType get themeModeType => _themeModeType;
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode {
    if (_themeModeType == ThemeModeType.system) {
      final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeModeType == ThemeModeType.dark;
  }

  void _loadThemeFromStorage() {
    final savedMode = StorageService.getString('theme_mode');
    if (savedMode != null) {
      switch (savedMode) {
        case 'light':
          _themeModeType = ThemeModeType.light;
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeModeType = ThemeModeType.dark;
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeModeType = ThemeModeType.system;
          _themeMode = ThemeMode.system;
      }
    }
  }

  void setThemeMode(ThemeModeType mode) {
    _themeModeType = mode;
    switch (mode) {
      case ThemeModeType.light:
        _themeMode = ThemeMode.light;
        StorageService.setString('theme_mode', 'light');
        break;
      case ThemeModeType.dark:
        _themeMode = ThemeMode.dark;
        StorageService.setString('theme_mode', 'dark');
        break;
      case ThemeModeType.system:
        _themeMode = ThemeMode.system;
        StorageService.setString('theme_mode', 'system');
        break;
    }
    notifyListeners();
  }

  void toggleTheme() {
    switch (_themeModeType) {
      case ThemeModeType.light:
        setThemeMode(ThemeModeType.dark);
        break;
      case ThemeModeType.dark:
        setThemeMode(ThemeModeType.system);
        break;
      case ThemeModeType.system:
        setThemeMode(ThemeModeType.light);
        break;
    }
  }
}
