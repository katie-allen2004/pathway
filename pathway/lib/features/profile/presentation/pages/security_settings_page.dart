import 'package:flutter/material.dart';
import 'package:pathway/core/theme/theme.dart';
import 'package:pathway/core/widgets/widgets.dart';
import 'package:provider/provider.dart';
import 'package:pathway/core/services/accessibility_controller.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // if you later wire actions

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

enum AutoLockOption { never, oneMin, fiveMin, fifteenMin }

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  // UI state (later: load/save)
  bool hideEmail = true;
  bool biometricLock = false;
  AutoLockOption autoLock = AutoLockOption.fiveMin;

  Future<void> _confirmAndDeleteAccount() async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.read<AccessibilityController>().settings;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: BorderSide(
            color: a11y.highContrast
                ? Colors.black
                : cs.outline.withValues(alpha: 0.2),
            width: a11y.highContrast ? 2 : 1,
          ),
        ),
        title: Text(
          'Delete account?',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This will permanently delete your account and data. This action cannot be undone.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: a11y.highContrast
                ? Colors.black
                : cs.onSurface.withValues(alpha: 0.82),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: a11y.highContrast ? Colors.black : cs.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Delete account: TODO')),
    );
  }

  Future<void> _signOutAllDevices() async {
    // TODO: wire up later (Supabase session revocation strategy)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign out everywhere: TODO')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.watch<AccessibilityController>().settings;

    final cardColor = a11y.highContrast ? Colors.white : cs.surface;
    final borderColor = a11y.highContrast
        ? Colors.black
        : cs.outline.withValues(alpha: 0.18);

    final mutedTextColor = a11y.highContrast
        ? Colors.black
        : cs.onSurface.withValues(alpha: 0.78);

    final dividerColor = a11y.highContrast
        ? Colors.black
        : cs.outline.withValues(alpha: 0.18);

    return Scaffold(
      appBar: PathwayAppBar(
        height: 100,
        centertitle: false,
        title: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            'Security settings', 
            style: theme.appBarTheme.titleTextStyle
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.page,
          children: [
            Text(
              'Control how your account is protected and what information is visible.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Account section
            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.card),
                side: BorderSide(
                  color: borderColor,
                  width: a11y.highContrast ? 2 : 1,
                ),
              ),
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account', 
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          ),
                      ),
                    const SizedBox(height: 8),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.lock_reset_rounded,
                        color: a11y.highContrast ? Colors.black : cs.primary,
                      ),
                      title: Text(
                        'Change password',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Update your password regularly.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: mutedTextColor,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: a11y.highContrast ? Colors.black : cs.onSurface,
                      ),
                      onTap: () {
                        // Route to EditProfilePage and scroll to password section
                        Navigator.of(context).pop(); // or route to your page
                      },
                    ),

                    Divider(color: dividerColor, height: 1),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.logout_rounded,
                        color: a11y.highContrast ? Colors.black : cs.primary,
                      ),
                      title: Text(
                        'Sign out on all devices',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Ends other active sessions.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: mutedTextColor,
                        ),
                      ),
                      onTap: _signOutAllDevices,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Privacy section
            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.card),
                side: BorderSide(
                  color: borderColor,
                  width: a11y.highContrast ? 2 : 1,
                ),
              ),
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy', 
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),

                    SettingsSwitchRow(
                      title: 'Hide my email',
                      subtitle: 'Keep your email private on your profile.',
                      value: hideEmail,
                      onChanged: (v) => setState(() => hideEmail = v),
                    ),

                    Divider(color: dividerColor, height: 1),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.block_rounded,
                        color: a11y.highContrast ? Colors.black : cs.primary,
                      ),
                      title: Text(
                        'Blocked & muted accounts',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: a11y.highContrast ? Colors.black : cs.onSurface,
                      ),
                      onTap: () {
                        // TODO: route to blocked/muted page (even placeholder)
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // App safety section
            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.card),
                side: BorderSide(
                  color: borderColor,
                  width: a11y.highContrast ? 2 : 1,
                ),
              ),
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App safety', 
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700
                      )
                    ),
                    const SizedBox(height: 8),

                    SettingsSwitchRow(
                      title: 'Require biometric unlock',
                      subtitle: 'Use Face ID / Touch ID when opening the app.',
                      value: biometricLock,
                      onChanged: (v) => setState(() => biometricLock = v),
                    ),

                    Divider(color: dividerColor, height: 1),

                    SettingsDropdownRow<AutoLockOption>(
                      title: 'Auto-lock',
                      subtitle: 'Lock the app after inactivity.',
                      value: autoLock,
                      items: const [
                        DropdownMenuItem(value: AutoLockOption.never, child: Text('Never')),
                        DropdownMenuItem(value: AutoLockOption.oneMin, child: Text('1 minute')),
                        DropdownMenuItem(value: AutoLockOption.fiveMin, child: Text('5 minutes')),
                        DropdownMenuItem(value: AutoLockOption.fifteenMin, child: Text('15 minutes')),
                      ],
                      onChanged: (v) => setState(() => autoLock = v ?? autoLock),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.card),
                side: BorderSide(
                  color: a11y.highContrast ? Colors.black : cs.error,
                  width: a11y.highContrast ? 2 : 1.2,
                ),
              ),
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Danger zone',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: a11y.highContrast ? Colors.black : cs.error,
                      ),
                    ),

                    const SizedBox(height: 8),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.delete_forever_rounded,
                        color: a11y.highContrast ? Colors.black : cs.error,
                      ),
                      title: Text(
                        'Delete account',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: a11y.highContrast ? Colors.black : cs.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        'Permanently delete your account.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: mutedTextColor,
                        ),
                      ),
                      onTap: _confirmAndDeleteAccount,
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