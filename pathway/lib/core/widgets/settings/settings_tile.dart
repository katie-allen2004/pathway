import 'package:flutter/material.dart';

class TileSection extends StatelessWidget {
  final List<Widget> tiles;
  final EdgeInsets padding;

  const TileSection({
    super.key, 
    required this.tiles,
    this.padding = const EdgeInsets.all(16),
    });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: padding,
        child: Card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _withDividers(tiles),
          ),
        ),
      ),
    );
  }

  List<Widget> _withDividers(List<Widget> children) {
    final out = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      out.add(children[i]);
      if (i < children.length - 1) {
        out.add(const Divider(height: 1));
      }
    }
    return out;
  }
}

class TileInstance extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const TileInstance({
    super.key, 
    required this.icon, 
    required this.title, 
    this.onTap,
    });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon),
      title: Text(
        title, 
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15),
      ),
      onTap: onTap,
    );
  }
}

class SwitchInstance extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  const SwitchInstance({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: Theme.of(context).textTheme.bodyMedium),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65)),
            ),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}

class SettingsSliderTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double v)? labelBuilder;
  final ValueChanged<double> onChanged;

  const SettingsSliderTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.min = 0.8,
    this.max = 1.4,
    this.divisions = 6,
    this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final label = labelBuilder?.call(value) ?? '${(value * 100).round()}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodyMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65)),
          ),
        ],
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: label,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

enum AppThemeMode { system, light, dark }

class ThemeModeSegmented extends StatelessWidget {
  final AppThemeMode value;
  final ValueChanged<AppThemeMode> onChanged;

  const ThemeModeSegmented({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AppThemeMode>(
      segments: const [
        ButtonSegment(value: AppThemeMode.system, label: Text('System')),
        ButtonSegment(value: AppThemeMode.light, label: Text('Light')),
        ButtonSegment(value: AppThemeMode.dark, label: Text('Dark')),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}