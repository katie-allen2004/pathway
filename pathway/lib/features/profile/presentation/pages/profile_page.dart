import 'package:flutter/material.dart';
import 'package:pathway/core/theme/theme.dart';
import 'package:pathway/core/widgets/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pathway/core/routing/app_router.dart';
import 'edit_profile_information_page.dart';
import 'notification_settings_page.dart';
import 'accessibility_settings_page.dart';
import 'package:pathway/features/auth/presentation/login_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final supabase = Supabase.instance.client;

  late Future<_ProfileHeaderData> _headerFuture;

  @override
  void initState() {
    super.initState();
    _headerFuture = _fetchHeader();
  }

  Future<_ProfileHeaderData> _fetchHeader() async {
    final authUser = supabase.auth.currentUser;
    if (authUser == null) throw Exception('Not signed in');

    final profileRow = await supabase
        .schema('pathway')
        .from('profiles')
        .select('display_name, avatar_url')
        .eq('user_id', authUser.id) // profiles.user_id is uuid
        .maybeSingle();

    if (profileRow == null) {
      return _ProfileHeaderData(
        displayName: 'User',
        email: authUser.email ?? '',
        avatarUrl: null,
      );
    }

    return _ProfileHeaderData(
      displayName: (profileRow['display_name'] as String?) ?? 'User',
      email: authUser.email ?? '',
      avatarUrl: profileRow['avatar_url'] as String?,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _headerFuture = _fetchHeader();
    });
    await _headerFuture;
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign out failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PathwayAppBar(
        height: 220,
        automaticallyImplyLeading: false,
        centertitle: true,
        title: SafeArea(
          child: FutureBuilder<_ProfileHeaderData>(
            future: _headerFuture,
            builder: (context, snapshot) {
              final data = snapshot.data;
              final displayName = data?.displayName ?? 'Loading...';
              final email = data?.email ?? '';
              final avatarUrl = data?.avatarUrl;

              ImageProvider? avatarProvider;
              if (avatarUrl != null && avatarUrl.isNotEmpty) {
                avatarProvider = NetworkImage(avatarUrl);
              }

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: avatarProvider,
                    child: avatarProvider == null
                        ? const Icon(
                            Icons.person_rounded,
                            size: 64,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(height: 10),
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
                  if (snapshot.hasError) ...[
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            slivers: [
              // Profile section
              TileSection(
                tiles: [
                  TileInstance(icon: Icons.person, title: 'Edit profile information', onTap: () async {
                            final changed = await routePage(context, const EditProfilePage());
                            if (changed == true) _refresh();
                          },
                    ),
                  TileInstance(icon: Icons.notifications_rounded, title: 'Notifications', onTap: () async {
                            final changed = await routePage(context, const NotificationSettingsPage());
                            if (changed == true) _refresh();
                          },
                    ),
                  TileInstance(icon: Icons.settings_accessibility_rounded, title: 'Accessibility settings', onTap: () async {
                            final changes = await routePage(context, const AccessibilitySettingsPage());
                            if (changes == true) _refresh();
                  }),
                ]
              ),

              // Security section
              TileSection(
                tiles: [
                  TileInstance(icon: Icons.security_rounded, title: 'Security settings', onTap: () {
                    // TODO: Implement security settings page
                  }),
                  TileInstance(icon: Icons.notifications_off_rounded, title: 'Blocked and muted accounts', onTap: () {
                    // TODO: Implement blocked/muted accounts page
                  }),
                ]
              ),

              // Help section
              TileSection(
                tiles: [
                  TileInstance(icon: Icons.help_center_rounded, title: 'Help', onTap: () {
                    // TODO: Implement help page
                  }),
                  TileInstance(icon: Icons.contact_page_rounded, title: 'Contact us', onTap: () {
                    // TODO: Implement contact us page
                  }),
                  TileInstance(icon: Icons.lock_outline_rounded, title: 'Privacy Policy', onTap: () {
                    // TODO: Implement privacy policy page
                  }),
                ]
              ),
              // Sign out section
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
                            color: Colors.white,
                          ),
                          title: const Text(
                            'Sign out',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          tileColor: AppColors.primary,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          onTap: _signOut,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
