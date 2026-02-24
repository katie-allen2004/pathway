import 'package:flutter/material.dart';
import 'package:pathway/core/theme/theme.dart';
import 'package:pathway/core/widgets/widgets.dart';
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This will permanently delete your account and data. This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
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

    return Scaffold(
      appBar: PathwayAppBar(
        height: 100,
        centertitle: false,
        title: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text('Security', style: theme.appBarTheme.titleTextStyle),
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
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Account', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.lock_reset_rounded),
                      title: const Text('Change password'),
                      subtitle: Text(
                        'Update your password regularly.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        // Route to EditProfilePage and scroll to password section
                        Navigator.of(context).pop(); // or route to your page
                      },
                    ),

                    const Divider(height: 1),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.logout_rounded),
                      title: const Text('Sign out on all devices'),
                      subtitle: Text(
                        'Ends other active sessions.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.65),
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
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Privacy', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),

                    SettingsSwitchRow(
                      title: 'Hide my email',
                      subtitle: 'Keep your email private on your profile.',
                      value: hideEmail,
                      onChanged: (v) => setState(() => hideEmail = v),
                    ),

                    const Divider(height: 1),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.block_rounded),
                      title: const Text('Blocked & muted accounts'),
                      trailing: const Icon(Icons.chevron_right_rounded),
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
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('App safety', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),

                    SettingsSwitchRow(
                      title: 'Require biometric unlock',
                      subtitle: 'Use Face ID / Touch ID when opening the app.',
                      value: biometricLock,
                      onChanged: (v) => setState(() => biometricLock = v),
                    ),

                    const Divider(height: 1),

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

            // Danger zone
            Card(
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Danger zone', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.delete_forever_rounded, color: cs.error),
                      title: Text('Delete account', style: TextStyle(color: cs.error, fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        'Permanently delete your account.',
                        style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: .65)),
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