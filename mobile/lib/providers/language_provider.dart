import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  static const String _languageKey = 'selected_language';
  // Locale _currentLocale = const Locale('fr');
  Locale _currentLocale = const Locale('pt');
  Locale get currentLocale => _currentLocale;

  String get currentLanguageCode => _currentLocale.languageCode;

  String get currentLanguageName {
    switch (_currentLocale.languageCode) {
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      case 'pt':
        return 'Português';
      default:
        return 'Português';
    }
  }

  List<Map<String, dynamic>> get supportedLanguages => [
        {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
        {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
        {'code': 'pt', 'name': 'Português', 'flag': '🇵🇹'},
      ];

  Future<void> initializeLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_languageKey);

    if (savedLanguage != null) {
      _currentLocale = Locale(savedLanguage);
      notifyListeners();
    } else {
      _currentLocale = const Locale('pt');
      await prefs.setString(_languageKey, 'pt');
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    if (languageCode != _currentLocale.languageCode) {
      _currentLocale = Locale(languageCode);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);

      notifyListeners();
    }
  }
}
