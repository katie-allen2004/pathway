import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pathway/models/accessibility_settings.dart';

class AccessibilityController extends ChangeNotifier {
  AccessibilitySettings _settings = AccessibilitySettings.defaults();
  AccessibilitySettings get settings => _settings;

  static const _kDark = 'a11y_darkMode';
  static const _kContrast = 'a11y_highContrast';
  static const _kScale = 'a11y_textScale';
  static const _kDyslexia = 'a11y_dyslexiaFont';
  static const _kBold = 'a11y_boldText';
  static const _kReduceMotion = 'a11y_reduceMotion';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _settings = AccessibilitySettings(
      darkMode: prefs.getBool(_kDark) ?? false,
      highContrast: prefs.getBool(_kContrast) ?? false,
      textScale: prefs.getDouble(_kScale) ?? 1.0,
      dyslexiaFont: prefs.getBool(_kDyslexia) ?? false,
      boldText: prefs.getBool(_kBold) ?? false,
      reduceMotion: prefs.getBool(_kReduceMotion) ?? false,
    );
    notifyListeners();
  }

  Future<void> update(AccessibilitySettings next) async {
    _settings = next;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDark, next.darkMode);
    await prefs.setBool(_kContrast, next.highContrast);
    await prefs.setDouble(_kScale, next.textScale);
    await prefs.setBool(_kDyslexia, next.dyslexiaFont);
    await prefs.setBool(_kBold, next.boldText);
    await prefs.setBool(_kReduceMotion, next.reduceMotion);
  }
}