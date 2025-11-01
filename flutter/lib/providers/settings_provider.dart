import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  late SharedPreferences _prefs;
  bool _darkMode = false;
  String _language = 'en';  // en, hi, mr
  bool _notificationsEnabled = true;

  // Getters
  bool get darkMode => _darkMode;
  String get language => _language;
  bool get notificationsEnabled => _notificationsEnabled;

  Locale get currentLocale {
    switch (_language) {
      case 'hi':
        return const Locale('hi');
      case 'mr':
        return const Locale('mr');
      default:
        return const Locale('en');
    }
  }

  // Initialize
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _darkMode = _prefs.getBool('darkMode') ?? false;
    _language = _prefs.getString('language') ?? 'en';
    _notificationsEnabled = _prefs.getBool('notificationsEnabled') ?? true;
    notifyListeners();
  }

  // Toggle Dark Mode
  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    await _prefs.setBool('darkMode', value);
    notifyListeners();
  }

  // Set Language
  Future<void> setLanguage(String lang) async {
    if (['en', 'hi', 'mr'].contains(lang)) {
      _language = lang;
      await _prefs.setString('language', lang);
      notifyListeners();
    }
  }

  // Toggle Notifications
  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _prefs.setBool('notificationsEnabled', value);
    notifyListeners();
  }
}
