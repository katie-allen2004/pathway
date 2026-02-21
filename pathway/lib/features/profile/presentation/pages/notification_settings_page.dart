import 'package:flutter/material.dart';
import 'package:pathway/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

    return Scaffold(
      appBar: PathwayAppBar(
        height: 100,
        centertitle: false,
        title: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Text(
            'Notification Settings',
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
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: SwitchInstance(
                            title: 'Allow notifications',
                            value: allowNotifications,
                            onChanged: _toggleMaster,
                          ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
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
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),

                      /// Dependent switches
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: SwitchInstance(
                                title: 'Friends',
                                value: friends,
                                enabled: allowNotifications,
                                onChanged: (v) => setState(() => friends = v),
                              ),
                              
                      ),

                      const Divider(),

                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: SwitchInstance(
                                title: 'Subscribed users',
                                value: subscribedUsers,
                                enabled: allowNotifications,
                                onChanged: (v) => setState(() => subscribedUsers = v),
                              ),
                      ),

                      const Divider(),

                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: SwitchInstance(
                                  title: 'Favorited venues',
                                  value: favoritedVenues,
                                  enabled: allowNotifications,
                                  onChanged: (v) => setState(() => favoritedVenues = v),
                                ),
                      ),

                      const Divider(),

                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: SwitchInstance(
                                  title: 'Messages',
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
