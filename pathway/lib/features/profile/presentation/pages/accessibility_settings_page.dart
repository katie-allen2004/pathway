import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pathway/core/theme/theme.dart';
import 'package:pathway/core/widgets/widgets.dart';
import 'package:pathway/core/utils/accessibility_controller.dart';
import 'package:pathway/models/accessibility_settings.dart';

class AccessibilitySettingsPage extends StatefulWidget {
  const AccessibilitySettingsPage({super.key});

  @override
  State<AccessibilitySettingsPage> createState() => _AccessibilitySettingsPageState();
}

class _AccessibilitySettingsPageState extends State<AccessibilitySettingsPage> {
  // TODO: Load/save these settings from Supabase

  AppThemeMode themeMode = AppThemeMode.system;
  bool highContrast = false;
  bool dyslexiaFont = false;
  bool boldText = false;
  bool reduceMotion = false;
  bool largerTouchTargets = false;

  double textScale = 1.0; // 1.0 = default
  @override
  Widget build(BuildContext context) {
    final a11y = context.watch<AccessibilityController>();
    final s = a11y.settings;
    final theme = Theme.of(context);

    // Preview style
    final previewTextTheme = theme.textTheme.apply(
      fontSizeFactor: textScale,
      fontFamily: dyslexiaFont ? 'OpenDyslexic' : null,
      bodyColor: highContrast ? Colors.black : null,
      displayColor: highContrast ? Colors.black : null,
    );

    return Scaffold(
      appBar: PathwayAppBar(
        height: 100,
        centertitle: false,
        title: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Text('Accessibility settings', style: theme.appBarTheme.titleTextStyle),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.page,
          children: [
            Text(
              'Adjust display and interaction settings to fit your needs.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Display section
            Card(
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Display', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),

                    Text('Theme', style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    SwitchInstance(
                      title: 'Dark mode',
                      subtitle: 'Switch between light and dark appearance.',
                      value: s.darkMode,
                      onChanged: (v) => a11y.update(s.copyWith(darkMode: v)),
                    ),

                    const Divider(height: 24),

                    SwitchInstance(
                      title: 'High contrast',
                      subtitle: 'Increases contrast for improved readability.',
                      value: s.highContrast,
                      onChanged: (v) => a11y.update(s.copyWith(highContrast: v)),
                    ),

                    const Divider(height: 1),

                    SwitchInstance(
                      title: 'Bold text',
                      subtitle: 'Makes text heavier and easier to read.',
                      value: s.boldText,
                      onChanged: (v) => a11y.update(s.copyWith(boldText: v)),
                    ),

                    const Divider(height: 1),

                    SwitchInstance(
                      title: 'Dyslexia-friendly font',
                      subtitle: 'Uses a font designed to improve readability.',
                      value: s.dyslexiaFont,
                      onChanged: (v) => a11y.update(s.copyWith(dyslexiaFont: v)),
                    ),

                    const Divider(height: 24),

                    SettingsSliderTile(
                      title: 'Text size',
                      subtitle: 'Adjust text scaling across the app.',
                      value: textScale,
                      min: 0.85,
                      max: 1.5,
                      divisions: 13,
                      labelBuilder: (v) => '${(v * 100).round()}%',
                      onChanged: (v) => a11y.update(s.copyWith(textScale: v)),
                    ),

                    const SizedBox(height: 12),

                    // Preview box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadii.input),
                        color: theme.colorScheme.surface,
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.25),
                        ),
                      ),
                      child: DefaultTextStyle.merge(
                        style: previewTextTheme.bodyMedium?.copyWith(
                          fontWeight: boldText ? FontWeight.w700 : FontWeight.w400,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Preview'),
                            SizedBox(height: 6),
                            Text('This is how text will look throughout the app.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Interaction section
            Card(
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Interaction', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),

                    SwitchInstance(
                      title: 'Reduce motion',
                      subtitle: 'Minimizes animations and motion effects.',
                      value: s.reduceMotion,
                      onChanged: (v) => a11y.update(s.copyWith(reduceMotion: v)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Quick reset
            Card(
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Reset to defaults',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(
                      onPressed: () => a11y.update(AccessibilitySettings.defaults()),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}