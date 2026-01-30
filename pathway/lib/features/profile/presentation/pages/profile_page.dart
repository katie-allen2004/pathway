import 'package:flutter/material.dart';
import 'package:pathway/core/theme/app_theme.dart';

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
          const CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(''),
          ),
          const SizedBox(height: 18),
          const Text('User Name', 
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 25,
                    ),
                  ),
          const Text(
            'user-email@domain.com',
            style: TextStyle(
              color: Color.fromARGB(255, 232, 227, 245),
            )
          )
        ],
        )
      ,)

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
                              leading: const Icon(Icons.person),
                              title: const Text('Edit profile information'),
                              onTap: () {
                                // Go to edit profile information page
                              },
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.notifications_rounded),
                              title: const Text('Notifications'),
                              onTap: () {
                                // Go to notification settings page
                              },
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.settings_accessibility_rounded),
                              title: const Text('Accessibility settings'),
                              onTap: () {
                                // Go to accessibility settings page
                              },
                            ),
                          ],
                        ),
                      )

                )
              ),
              SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.security_rounded),
                              title: const Text('Security'),
                              onTap: () {
                                // Go to edit profile information page
                              },
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.notifications_off_rounded),
                              title: const Text('Blocked and muted accounts'),
                              onTap: () {
                                // Go to notification settings page
                              },
                            ),
                          ],
                        ),
                      )

                )
              ),
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.help_center_rounded),
                              title: const Text('Help'),
                              onTap: () {
                                // Sign out page
                              },
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.contact_page_rounded),
                              title: const Text('Contact us'),
                              onTap: () {
                                // Go to contact us page
                              },
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.lock_outline_rounded),
                              title: const Text('Privacy Policy'),
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
            SliverToBoxAdapter(
              child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(
                                                Icons.logout_rounded,
                                                color: Colors.white),
                              title: const Text(
                                                'Sign Out',
                                                style: TextStyle(
                                                        fontWeight: FontWeight.w700,
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
              )
            ]
          )
    )
          );
  }
}