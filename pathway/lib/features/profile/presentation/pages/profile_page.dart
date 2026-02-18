import 'package:flutter/material.dart';
import 'package:pathway/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'edit_profile_information_page.dart';
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
                          title: const Text(
                            'Edit profile information',
                            style: TextStyle(fontSize: 15),
                          ),
                          onTap: () async {
                            final changed = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const EditProfilePage(),
                              ),
                            );
                            if (changed == true) _refresh();
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.notifications_rounded),
                          title: const Text(
                            'Notifications',
                            style: TextStyle(fontSize: 15),
                          ),
                          onTap: () {},
                        ),
                        const Divider(height: 1),
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.settings_accessibility_rounded),
                          title: const Text(
                            'Accessibility settings',
                            style: TextStyle(fontSize: 15),
                          ),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Security section
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
                          title: const Text(
                            'Security',
                            style: TextStyle(fontSize: 15),
                          ),
                          onTap: () {},
                        ),
                        const Divider(height: 1),
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.notifications_off_rounded),
                          title: const Text(
                            'Blocked and muted accounts',
                            style: TextStyle(fontSize: 15),
                          ),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Help section
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
                          title: const Text(
                            'Help',
                            style: TextStyle(fontSize: 15),
                          ),
                          onTap: () {},
                        ),
                        const Divider(height: 1),
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.contact_page_rounded),
                          title: const Text(
                            'Contact us',
                            style: TextStyle(fontSize: 15),
                          ),
                          onTap: () {},
                        ),
                        const Divider(height: 1),
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.lock_outline_rounded),
                          title: const Text(
                            'Privacy Policy',
                            style: TextStyle(fontSize: 15),
                          ),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
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
                          tileColor: const Color.fromARGB(255, 76, 89, 185),
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
