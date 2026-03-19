import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  double textScale = 1.0; // 1.0 = default
  @override
  Widget build(BuildContext context) {
    final a11y = context.watch<AccessibilityController>();
    final s = a11y.settings;
    final theme = Theme.of(context);

    final darkDisabled = s.highContrast;
    final contrastDisabled = s.darkMode;

    // Preview style
    final previewTheme = _previewTextTheme(theme.textTheme, s);
    final previewWeight = s.boldText ? FontWeight.w700 : FontWeight.w400;

    return Scaffold(
      appBar: PathwayAppBar(
        height: 100,
        centertitle: false,
        title: Padding(
          padding: const EdgeInsets.only(top: 2.0, right: 12.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final baseStyle = theme.appBarTheme.titleTextStyle ?? const TextStyle();
              final useSmallerFont = s.dyslexiaFont;

              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Accessibility settings',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: baseStyle.copyWith(
                    fontSize: useSmallerFont
                        ? (baseStyle.fontSize ?? 25) - 4
                        : baseStyle.fontSize,
                  ),
                ),
              );
            },
          ),
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

                    const SizedBox(height: 8),
                    SwitchInstance(
                      title: 'Dark mode',
                      subtitle: darkDisabled
                          ? 'Disabled while High contrast is enabled.'
                          : 'Switch between light and dark appearance.',
                      value: s.darkMode,
                      enabled: !darkDisabled,
                      onChanged: (v) async {
                        // If enabling dark mode, turn off high contrast
                        final next = v
                            ? s.copyWith(darkMode: true, highContrast: false)
                            : s.copyWith(darkMode: false);
                        await a11y.update(next);
                      },
                    ),

                    const Divider(height: 24),

                    SwitchInstance(
                      title: 'High contrast',
                      subtitle: contrastDisabled
                          ? 'Disabled while Dark mode is enabled.'
                          : 'Increases contrast for improved readability.',
                      value: s.highContrast,
                      enabled: !contrastDisabled,
                      onChanged: (v) async {
                        // If enabling high contrast, turn off dark mode
                        final next = v
                            ? s.copyWith(highContrast: true, darkMode: false)
                            : s.copyWith(highContrast: false);
                        await a11y.update(next);
                      },
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
                      value: s.textScale,
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
                        color: s.highContrast
                          ? Colors.white
                          : theme.colorScheme.surface,
                        border: Border.all(
                          color: s.highContrast
                            ? Colors.black
                            : theme.colorScheme.outline.withValues(alpha: 0.25),
                          width: s.highContrast ? 2 : 1,
                        ),
                      ),
                      child: DefaultTextStyle.merge(
                        style: previewTheme.bodyMedium?.copyWith(
                          fontWeight: previewWeight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Preview',
                              style: previewTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: s.highContrast ? Colors.black : null,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'This is how text will look throughout the app.',
                              style: previewTheme.bodyMedium?.copyWith(
                                fontWeight: previewWeight,
                                color: s.highContrast ? Colors.black : null,
                              )),
                            SizedBox(height: 8),
                            Text(
                              'Buttons, labels, and body text should respond immediately.',
                              style: previewTheme.bodySmall?.copyWith(
                                fontWeight: previewWeight,
                                color: s.highContrast ? Colors.black : null,
                              ),
                            ),
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

                    const SizedBox(height: 6),
                    Text(
                      s.reduceMotion
                          ? 'Animations are minimized across the app.'
                          : 'Animations are enabled.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
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

    TextTheme _previewTextTheme(TextTheme base, AccessibilitySettings s) {
    // Use the SAME scaling behavior as the rest of the app (main.dart uses MediaQuery textScaler),
    // but for the preview we can apply a size factor so the box "shows" the scaling.
    final scaled = base.apply(fontSizeFactor: s.textScale);

    // Your global theme currently switches to AtkinsonHyperlegible when dyslexiaFont is on.
    // Keep the preview consistent with that.
    final family = s.dyslexiaFont ? 'OpenDyslexic' : null;

    if (!s.highContrast && family == null) return scaled;

    return scaled.apply(
      fontFamily: family,
      bodyColor: s.highContrast ? Colors.black : null,
      displayColor: s.highContrast ? Colors.black : null,
    );
  }
}

