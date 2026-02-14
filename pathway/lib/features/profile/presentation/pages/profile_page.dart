import 'package:flutter/material.dart';
import 'package:pathway/core/theme/app_theme.dart';
import 'edit_profile_information_page.dart';
import 'package:pathway/core/routing/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pathway/features/auth/presentation/login_screen.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: PathwayAppBar(
        height: 220,
        automaticallyImplyLeading: false,
        centertitle: true,
        title: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              const CircleAvatar(radius: 50, backgroundImage: NetworkImage('')),
              const SizedBox(height: 18),
              const Text(
                'User Name',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 25,
                ),
              ),
              const Text(
                'user-email@domain.com',
                style: TextStyle(color: Color.fromARGB(255, 232, 227, 245)),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
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
                        onTap: () =>
                            routePage(context, const EditProfilePage()),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.notifications_rounded),
                        title: const Text(
                          'Notifications',
                          style: TextStyle(fontSize: 15),
                        ),
                        onTap: () {
                          // Go to notification settings page
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.settings_accessibility_rounded,
                        ),
                        title: const Text(
                          'Accessibility settings',
                          style: TextStyle(fontSize: 15),
                        ),
                        onTap: () {
                          // Go to accessibility settings page
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
                        onTap: () {
                          // Go to edit profile information page
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.notifications_off_rounded),
                        title: const Text(
                          'Blocked and muted accounts',
                          style: TextStyle(fontSize: 15),
                        ),
                        onTap: () {
                          // Go to notification settings page
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
                        onTap: () {
                          // Sign out page
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.contact_page_rounded),
                        title: const Text(
                          'Contact us',
                          style: TextStyle(fontSize: 15),
                        ),
                        onTap: () {
                          // Go to contact us page
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.lock_outline_rounded),
                        title: const Text(
                          'Privacy Policy',
                          style: TextStyle(fontSize: 15),
                        ),
                        onTap: () {
                          // Go to privacy policy page
                        },
                      ),
                      const Divider(height: 1),
                    ],
                  ),
                ),
              ),
            ),
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
                          "Sign out",
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
                        onTap: () async {
                          try {
                            await Supabase.instance.client.auth.signOut();

                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Sign out failed: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
