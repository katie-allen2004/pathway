import 'package:flutter/material.dart';
import 'package:pathway/core/theme/theme.dart';
import 'package:pathway/core/widgets/widgets.dart';

class AccessibilitySettingsPage extends StatefulWidget {
  const AccessibilitySettingsPage({super.key});

  @override
  State<AccessibilitySettingsPage> createState() => _AccessibilitySettingsPageState();
}

class _AccessibilitySettingsPageState extends State<AccessibilitySettingsPage> {
  // In real app: load/save these (Supabase, SharedPreferences, etc.)
  AppThemeMode themeMode = AppThemeMode.system;
  bool highContrast = false;
  bool dyslexiaFont = false;
  bool boldText = false;
  bool reduceMotion = false;
  bool largerTouchTargets = false;

  double textScale = 1.0; // 1.0 = default

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // A quick preview style (doesn't change whole app yet, just preview area)
    final previewTextTheme = theme.textTheme.apply(
      fontSizeFactor: textScale,
      fontFamily: dyslexiaFont ? 'OpenDyslexic' : null, // see note below
      bodyColor: highContrast ? Colors.black : null,
      displayColor: highContrast ? Colors.black : null,
    );

    return Scaffold(
      appBar: PathwayAppBar(
        height: 100,
        centertitle: false,
        title: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Text('Accessibility Settings', style: theme.appBarTheme.titleTextStyle),
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
                    ThemeModeSegmented(
                      value: themeMode,
                      onChanged: (v) => setState(() => themeMode = v),
                    ),

                    const Divider(height: 24),

                    SwitchInstance(
                      title: 'High contrast',
                      subtitle: 'Increases contrast for improved readability.',
                      value: highContrast,
                      onChanged: (v) => setState(() => highContrast = v),
                    ),

                    const Divider(height: 1),

                    SwitchInstance(
                      title: 'Bold text',
                      subtitle: 'Makes text heavier and easier to read.',
                      value: boldText,
                      onChanged: (v) => setState(() => boldText = v),
                    ),

                    const Divider(height: 1),

                    SwitchInstance(
                      title: 'Dyslexia-friendly font',
                      subtitle: 'Uses a font designed to improve readability.',
                      value: dyslexiaFont,
                      onChanged: (v) => setState(() => dyslexiaFont = v),
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
                      onChanged: (v) => setState(() => textScale = v),
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
                      value: reduceMotion,
                      onChanged: (v) => setState(() => reduceMotion = v),
                    ),

                    const Divider(height: 1),

                    SwitchInstance(
                      title: 'Larger touch targets',
                      subtitle: 'Adds extra spacing to make controls easier to tap.',
                      value: largerTouchTargets,
                      onChanged: (v) => setState(() => largerTouchTargets = v),
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
                      onPressed: () {
                        setState(() {
                          themeMode = AppThemeMode.system;
                          highContrast = false;
                          dyslexiaFont = false;
                          boldText = false;
                          reduceMotion = false;
                          largerTouchTargets = false;
                          textScale = 1.0;
                        });
                      },
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