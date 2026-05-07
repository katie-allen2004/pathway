import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pathway/models/accessibility_settings.dart';

class AccessibilityController extends ChangeNotifier {
  AccessibilitySettings _settings = AccessibilitySettings.defaults();
  AccessibilitySettings get settings => _settings;

  // Set controller settings 
  static const _kDark = 'a11y_darkMode';
  static const _kContrast = 'a11y_highContrast';
  static const _kScale = 'a11y_textScale';
  static const _kDyslexia = 'a11y_dyslexiaFont';
  static const _kBold = 'a11y_boldText';
  static const _kReduceMotion = 'a11y_reduceMotion';

  Future<void> load() async {
    // Load local accessibility settings (settings set during session)
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

  Future<void> loadFromDatabase() async {
    // Load accessibility settings set by user and stored in db
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final row = await Supabase.instance.client
      .schema('pathway')
      .from('user_accessibility_settings')
      .select()
      .eq('user_id', user.id)
      .maybeSingle();

    // If no settings are set, attempt to save current settings
    if (row == null) {
      await saveToDatabase();
      return;
    }
    
    // Set AccessibilitySettings based on data pulled from db
    _settings = AccessibilitySettings(
      darkMode: row['dark_mode'] ?? false,
      highContrast: row['high_contrast'] ?? false,
      textScale: (row['text_scale'] ?? 1.0).toDouble(),
      dyslexiaFont: row['dyslexia_font'] ?? false,
      boldText: row['bold_text'] ?? false,
      reduceMotion: row['reduce_motion'] ?? false,
    );

    notifyListeners();

    // Set SharedPreferences (local settings) with those from the db
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDark, _settings.darkMode);
    await prefs.setBool(_kContrast, _settings.highContrast);
    await prefs.setDouble(_kScale, _settings.textScale);
    await prefs.setBool(_kDyslexia, _settings.dyslexiaFont);
    await prefs.setBool(_kBold, _settings.boldText);
    await prefs.setBool(_kReduceMotion, _settings.reduceMotion);
    }

  Future<void> saveToDatabase() async {
    // Attempt to save AccessibilitySettings to db
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await Supabase.instance.client
        .schema('pathway')
        .from('user_accessibility_settings')
        .upsert({
          'user_id': user.id,
          'dark_mode': _settings.darkMode,
          'high_contrast': _settings.highContrast,
          'text_scale': _settings.textScale,
          'dyslexia_font': _settings.dyslexiaFont,
          'bold_text': _settings.boldText,
          'reduce_motion': _settings.reduceMotion,
          'updated_at': DateTime.now().toIso8601String(),
        });
  }

  Future<void> update(AccessibilitySettings next) async {
    // Update _settings (db instance) to next instance of AccessibilitySettings
    _settings = next;
    notifyListeners();

    // Update local instance of AccessibilitySettings to next instance 
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDark, next.darkMode);
    await prefs.setBool(_kContrast, next.highContrast);
    await prefs.setDouble(_kScale, next.textScale);
    await prefs.setBool(_kDyslexia, next.dyslexiaFont);
    await prefs.setBool(_kBold, next.boldText);
    await prefs.setBool(_kReduceMotion, next.reduceMotion);

    try {
      // Attempt to save new settings to db
      await saveToDatabase();
    } catch(e) {
      debugPrint('Failed to save accessibility settings to DB: $e');
    }
  }

  // Translate user's AccessibilitySettings to JSON
  Map<String, dynamic> toJson(String userId) {
    return {
      'user_id': userId,
      'dark_mode': _settings.darkMode,
      'high_contrast': _settings.textScale,
      'dyslexia_font': _settings.dyslexiaFont,
      'bold_text': _settings.boldText,
      'reduce_motion': _settings.reduceMotion,
    };
  }

  // Return AccessibilitySettings from a given row
  AccessibilitySettings fromRow(Map<String, dynamic> row) {
    return AccessibilitySettings(
      darkMode: row['dark_mode'] ?? false,
      highContrast: row['high_contrast'] ?? false,
      textScale: (row['text_scale'] ?? 1.0).toDouble(),
      dyslexiaFont: row['dyslexia_dont'] ?? false,
      boldText: row['bold_text'] ?? false,
      reduceMotion: row['reduce_motion'] ?? false,
    );
  }
}