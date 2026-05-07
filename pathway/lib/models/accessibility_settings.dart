// AccessibilitySettings class: Sets a model for accessibility settings

class AccessibilitySettings {
  final bool darkMode;
  final bool highContrast;
  final double textScale;
  final bool dyslexiaFont;
  final bool boldText;
  final bool reduceMotion;

  const AccessibilitySettings({
    required this.darkMode,
    required this.highContrast,
    required this.textScale,
    required this.dyslexiaFont,
    required this.boldText,
    required this.reduceMotion,
  });

  factory AccessibilitySettings.defaults() => const AccessibilitySettings(
        darkMode: false,
        highContrast: false,
        textScale: 1.0,
        dyslexiaFont: false,
        boldText: false,
        reduceMotion: false,
      );

  AccessibilitySettings copyWith({
    bool? darkMode,
    bool? highContrast,
    double? textScale,
    bool? dyslexiaFont,
    bool? boldText,
    bool? reduceMotion,
  }) {
    return AccessibilitySettings(
      darkMode: darkMode ?? this.darkMode,
      highContrast: highContrast ?? this.highContrast,
      textScale: textScale ?? this.textScale,
      dyslexiaFont: dyslexiaFont ?? this.dyslexiaFont,
      boldText: boldText ?? this.boldText,
      reduceMotion: reduceMotion ?? this.reduceMotion,
    );
  }
}