import 'package:flutter/material.dart';
import 'package:pathway/core/theme/theme.dart';
import 'package:pathway/core/widgets/widgets.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pathway/core/services/accessibility_controller.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends State<NotificationSettingsPage> {
  bool allowNotifications = true;

  bool friends = true;
  bool subscribedUsers = true;
  bool favoritedVenues = true;
  bool messages = true;

  void _toggleMaster(bool value) {
    setState(() {
      allowNotifications = value;

      if (!value) {
        friends = false;
        subscribedUsers = false;
        favoritedVenues = false;
        messages = false;
      }
    });
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
        : cs.onSurface.withValues(alpha: 0.72);

    final dividerColor = a11y.highContrast
        ? Colors.black
        : cs.outline.withValues(alpha: 0.18);

    return Scaffold(
      appBar: PathwayAppBar(
        height: 100,
        centertitle: false,
        title: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Text(
            'Notification settings',
            style: theme.appBarTheme.titleTextStyle,
          ),
        ),
      ),
      body: SafeArea(
          child: Padding(
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Main switch
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
                  child: SwitchInstance(
                            title: 'Allow notifications',
                            subtitle: 'Turn all app notifications on or off.',
                            value: allowNotifications,
                            onChanged: _toggleMaster,
                          ),
                ),
              ),
              const SizedBox(height: 16),
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
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          'Receive notifications from:',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: mutedTextColor,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      const SizedBox(height: 8),
                      /// Dependent switches
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: SwitchInstance(
                                title: 'Friends',
                                subtitle: 'Updates and activity from your friends.',
                                value: friends,
                                enabled: allowNotifications,
                                onChanged: (v) => setState(() => friends = v),
                              ),
                              
                      ),

                      Divider(color: dividerColor),

                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: SwitchInstance(
                                title: 'Subscribed users',
                                subtitle: 'Activity from users you follow.',
                                value: subscribedUsers,
                                enabled: allowNotifications,
                                onChanged: (v) => setState(() => subscribedUsers = v),
                              ),
                      ),

                      Divider(color: dividerColor),

                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: SwitchInstance(
                                  title: 'Favorited venues',
                                  subtitle: 'Changes and updates for venues you saved.',
                                  value: favoritedVenues,
                                  enabled: allowNotifications,
                                  onChanged: (v) => setState(() => favoritedVenues = v),
                                ),
                      ),

                      Divider(color: dividerColor),

                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: SwitchInstance(
                                  title: 'Messages',
                                  subtitle: 'Direct messages and conversation activity.',
                                  value: messages,
                                  enabled: allowNotifications,
                                  onChanged: (v) => setState(() => messages = v),
                                ),
                      )
                    ]
                  )
                )
              )
            ],
        )
      )
    ),
   );
  }
}
