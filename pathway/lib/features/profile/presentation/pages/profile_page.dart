import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pathway/core/theme/app_theme.dart';
import 'edit_profile_information_page.dart';
import 'package:pathway/core/routing/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});


  @override
  State<ProfilePage> createState() => _ProfilePageState();
}
class _ProfilePageState extends State<ProfilePage> {
  final supabase = Supabase.instance.client; // Access the Supabase client instance

  late Future<_ProfileHeaderData> _headerFuture; // Future for fetching profile header data (display name, email, avatar URL)

  // Method to fetch profile header data from Supabase
  @override
  void initState() {
    super.initState();
    _headerFuture = _fetchHeader();
  }

  Future<_ProfileHeaderData> _fetchHeader() async {
    // Get current authenticated user
    final authUser = supabase.auth.currentUser;
    if (authUser == null) throw Exception('Not signed in');
    
    // Query database for user's internal user_id using auth UUID
    /*final userRow = await supabase 
      .schema('pathway')
      .from('users')
      .select('user_id')
      .eq('external_id', authUser.id)
      .single();

    final int userId = (userRow['user_id'] as num).toInt();*/

    // Query database for user's profile information using internal user_id
    final profileRow = await supabase
      .schema('pathway')
      .from('profiles')
      .select('display_name, avatar_url')
      .eq('user_id', authUser.id)
      .maybeSingle();
      // Original: .eq('user_id', userId)

    if (profileRow == null) {
      return _ProfileHeaderData(
        displayName: 'User',
        email: authUser.email ?? '',
        avatarUrl: null,
      );
    }

    // Return profile header data, using defaults if display_name or avatar_url are not set
    return _ProfileHeaderData(
      displayName: (profileRow?['display_name'] as String?) ?? 'User',
      email: authUser.email ?? '',
      avatarUrl: profileRow['avatar_url'] as String?,
    );
  }

  // Method to refresh profile header data after editing profile information
  Future<void> _refresh() async {
    setState(() {
      _headerFuture = _fetchHeader();
    });
    await _headerFuture;
  }

@override
Widget build(BuildContext context) {
return Scaffold(
  appBar: PathwayAppBar(
    height: 220,
    automaticallyImplyLeading: false,
    centertitle: true,
    title: SafeArea(
      // Use FutureBuilder to display profile header data once it's fetched
      child: FutureBuilder<_ProfileHeaderData>(
        future: _headerFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final displayName = data?.displayName ?? 'Loading...'; // Show 'Loading...' until display name is fetched
          final email = data?.email ?? ''; // Email should be available immediately from auth user, but use empty string as fallback
          final avatarUrl = data?.avatarUrl; // Avatar URL may be null, handle this case in the UI

          // If avatarUrl is available, use it as the background image for the CircleAvatar. Otherwise, show a default icon.
          ImageProvider? avatarProvider;
          if (avatarUrl != null && avatarUrl.isNotEmpty) {
            avatarProvider = NetworkImage(avatarUrl);
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              // Display user's avatar if available, otherwise show default person icon
              CircleAvatar(
                radius: 50,
                backgroundImage: avatarProvider,
                child: avatarProvider == null
                    ? const Icon(Icons.person_rounded, size: 64, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 10),
              // Display user's display name and email, using default values if data is not yet available
              Text(
                displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 25,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                email,
                style: const TextStyle(
                  fontWeight: FontWeight.normal,
                  color: Color.fromARGB(255, 232, 227, 245),
                  fontSize: 20,
                ),
              ),
              // If there was an error fetching the profile data, display the error message below the email
              if (snapshot.hasError) ...[
                const SizedBox(height: 8),
                Text(
                  /*'Failed to load profile',*/
                  snapshot.error.toString(),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),

                ),
              ],
            ],
          );
        },
      ),
      ),
  ), 
    body: SafeArea(
      // Use RefreshIndicator to allow pull-to-refresh functionality for the profile page
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
            slivers: [
              // Profile information section with options to edit profile, manage notifications, and accessibility settings
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.person),
                          title: const Text('Edit profile information',
                              style: TextStyle(fontSize: 15)),
                          onTap: () async {
                            final changed = await Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const EditProfilePage()),
                            );
                            if (changed == true) _refresh();
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.notifications_rounded),
                          title: const Text('Notifications',
                              style: TextStyle(fontSize: 15)),
                          onTap: () {},
                        ),
                        const Divider(height: 1),
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.settings_accessibility_rounded),
                          title: const Text('Accessibility settings',
                              style: TextStyle(fontSize: 15)),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Security and account management section with options for security settings and managing blocked/muted accounts
              SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              dense: true,
                              leading: const Icon(Icons.security_rounded),
                              title: const Text('Security',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                )
                                              ),
                              onTap: () {
                                // Go to edit profile information page
                              },
                            ),
                            const Divider(height: 1),
                            ListTile(
                              dense: true,
                              leading: const Icon(Icons.notifications_off_rounded),
                              title: const Text('Blocked and muted accounts',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                )
                                              ),
                              onTap: () {
                                // Go to notification settings page
                              },
                            ),
                          ],
                        ),
                      )

                )
              ),
              // Help and support section with options for help center, contact us, and privacy policy
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              dense: true,
                              leading: const Icon(Icons.help_center_rounded),
                              title: const Text('Help',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                )
                                              ),
                              onTap: () {
                                // Sign out page
                              },
                            ),
                            const Divider(height: 1),
                            ListTile(
                              dense: true,
                              leading: const Icon(Icons.contact_page_rounded),
                              title: const Text('Contact us',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                )
                                              ),
                              onTap: () {
                                // Go to contact us page
                              },
                            ),
                            const Divider(height: 1),
                            ListTile(
                              dense: true,
                              leading: const Icon(Icons.lock_outline_rounded),
                              title: const Text('Privacy Policy',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                )
                                              ),
                              onTap: () {
                                // Go to privacy policy page
                              },
                            ),
                            const Divider(height: 1),   
                          ],
                        ),
                      )

                )
              ),
            // Sign out option at the bottom of the profile page, separated from other settings and options
            SliverToBoxAdapter(
              child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              dense: true,
                              leading: const Icon(
                                                Icons.logout_rounded,
                                                color: Colors.white),
                              title: const Text(
                                                'Sign out',
                                                style: TextStyle(
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 15,
                                                        color: Colors.white,
                                                      )
                                                ),
                              tileColor: Color.fromARGB(255, 76, 89, 185),
                              shape: RoundedRectangleBorder(borderRadius:BorderRadius.all(Radius.circular(10))),
                              onTap: () {
                                // Sign out page
                              },
                            ),
                          ]
                          )
                      )
                    ),
            ),
                      ],
                    ),
                  ),
                ),
              );
  }
}

// Private class to hold profile header data (display name, email, avatar URL) for use in the FutureBuilder
class _ProfileHeaderData {
  final String displayName;
  final String email;
  final String? avatarUrl;

  _ProfileHeaderData({
    required this.displayName,
    required this.email,
    required this.avatarUrl,
});
}