import 'package:flutter/material.dart';
import 'package:pathway/core/theme/theme.dart';
import 'package:pathway/core/widgets/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pathway/core/routing/app_router.dart';
// import admin view
import 'package:pathway/features/admin/presentation/mod_dashboard.dart'; 
import 'edit_profile_information_page.dart';
import 'notification_settings_page.dart';
import 'accessibility_settings_page.dart';
import 'security_settings_page.dart';
import 'blocked_muted_users_page.dart';
import 'contact_us_page.dart';
import 'help_page.dart';
import 'privacy_policy_page.dart';
import 'package:pathway/features/auth/presentation/login_screen.dart';
import 'favorites_page.dart';
import 'package:pathway/core/services/accessibility_controller.dart';
import 'package:provider/provider.dart';
import 'package:pathway/models/accessibility_settings.dart';
import 'package:pathway/features/venues/data/venue_model.dart'; 
import '../widgets/badges_section.dart';
import 'follow_list_page.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final supabase = Supabase.instance.client;

  late Future<_ProfileHeaderData> _headerFuture;
  
  // admin status
  bool _isAdmin = false; 

  // follow counts
  int _followerCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _headerFuture = _fetchHeader();
    // admin check 
    _checkAdminStatus(); 
    _loadFollowCounts();
  }

  void _showSubmissionsBottomSheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent, 
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("My Submissions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: supabase
                    .schema('pathway')
                    .from('venues')
                    .stream(primaryKey: ['venue_id'])
                    .eq('created_by_user_id', supabase.auth.currentUser?.id ?? ''),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final items = snapshot.data!;
                  if (items.isEmpty) return const Center(child: Text("No submissions yet."));

                  return ListView.builder(
                    controller: controller,
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final venue = VenueModel.fromJson(items[i]);
                      return ListTile(
                        leading: _buildStatusIcon(venue.status),
                        title: Text(venue.name),
                        subtitle: Text("Status: ${venue.status}"),
                        trailing: const Icon(Icons.info_outline, size: 20),
                        onTap: () {
                          _showFeedbackDetail(venue);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// read only
void _showFeedbackDetail(VenueModel venue) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        venue.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BadgesSection(),
          //status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (venue.status == 'rejected' 
                      ? Colors.red 
                      : (venue.status == 'approved' ? Colors.green : Colors.orange))
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "Status: ${venue.status.toUpperCase()}", 
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: venue.status == 'rejected' 
                    ? Colors.red 
                    : (venue.status == 'approved' ? Colors.green : Colors.orange),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // logic based text 
          if (venue.status == 'rejected') ...[
            const Text(
              "Moderator Feedback:", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                venue.modNotes ?? "No specific notes provided.", 
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "To resubmit, please create a new application for this venue from the map screen with the requested updates.",
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ] else if (venue.status == 'pending') ...[
            const Text(
              "Our team is currently reviewing your submission. It will appear on the map once approved.",
              style: TextStyle(color: Colors.black54),
            ),
          ] else ...[
            const Text(
              "Your venue is live! Thank you for helping the community improve accessibility.",
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text("Close", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

// list icons
Widget _buildStatusIcon(String status) {
  switch (status) {
    case 'approved': return const Icon(Icons.check_circle, color: Colors.green);
    case 'rejected': return const Icon(Icons.cancel, color: Colors.red);
    default: return const Icon(Icons.pending, color: Colors.orange);
  }
}

  // updated for admin view 
  void _checkAdminStatus() {
    final user = supabase.auth.currentUser;
    setState(() {
      _isAdmin = user?.userMetadata?['role'] == 'admin' || 
                 user?.email == 'admin@pathway.com'; 
    });
  }

  Future<void> _loadFollowCounts() async {
    final authUser = supabase.auth.currentUser;
    if (authUser == null) return;

    try {
      final userRow = await supabase
          .schema('pathway')
          .from('users')
          .select('user_id')
          .eq('external_id', authUser.id)
          .maybeSingle();

      if (userRow == null) return;

      final pathwayUserId = userRow['user_id'] as int;

      final followers = await supabase
          .schema('pathway')
          .from('user_subscriptions')
          .select('subscriber_user_id')
          .eq('target_user_id', pathwayUserId);

      final following = await supabase
          .schema('pathway')
          .from('user_subscriptions')
          .select('target_user_id')
          .eq('subscriber_user_id', pathwayUserId);

      if (!mounted) return;
      setState(() {
        _followerCount = (followers as List).length;
        _followingCount = (following as List).length;
      });
    } catch (e) {
      debugPrint('Failed to load follow counts: $e');
    }
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

    final rawDisplayName = profileRow['display_name'] as String?;

    return _ProfileHeaderData(
      displayName: (rawDisplayName != null && rawDisplayName.trim().isNotEmpty)
          ? rawDisplayName
          : 'User',
      email: authUser.email ?? '',
      avatarUrl: profileRow['avatar_url'] as String?,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _headerFuture = _fetchHeader();
      // admin status
      _checkAdminStatus(); 
    });
    _loadFollowCounts();
    await _headerFuture;
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
      final a11y = Provider.of<AccessibilityController>(context, listen: false);
      await a11y.update(AccessibilitySettings.defaults());

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
        automaticallyImplyLeading: true, 
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
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _FollowCountButton(
                        label: 'Followers',
                        count: _followerCount,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FollowListPage(mode: 'followers'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _FollowCountButton(
                        label: 'Following',
                        count: _followingCount,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FollowListPage(mode: 'following'),
                            ),
                          );
                        },
                      ),
                    ],
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
              // profile
              TileSection(
                tiles: [
                  TileInstance(
                    icon: Icons.person,
                    title: 'Edit profile information',
                    onTap: () async {
                      final changed = await routePage(
                        context,
                        const EditProfilePage(),
                      );
                      if (changed == true) _refresh();
                    },
                  ),
                  TileInstance(
                    icon: Icons.notifications_rounded,
                    title: 'Notification settings',
                    onTap: () async {
                      final changed = await routePage(
                        context,
                        const NotificationSettingsPage(),
                      );
                      if (changed == true) _refresh();
                    },
                  ),
                  TileInstance(
                    icon: Icons.settings_accessibility_rounded,
                    title: 'Accessibility settings',
                    onTap: () async {
                      final changes = await routePage(
                        context,
                        const AccessibilitySettingsPage(),
                      );
                      if (changes == true) _refresh();
                    },
                  ),
                ],
              ),
              TileSection(
                tiles: [
                  TileInstance(
                    icon: Icons.favorite,
                    title: 'Favorites',
                    onTap: () async {
                      final changed = await routePage(
                        context,
                        const FavoritesPage(),
                      );
                      if (changed == true) _refresh();
                    },
                  ),
                ],
              ),
              TileSection(
                tiles: [
                  TileInstance(
                    icon: Icons.map_rounded,
                    title: 'My Venue Submissions',
                    onTap: () {
                      _showSubmissionsBottomSheet();
                    },
                  ),
                ],
              ),
              // security
              TileSection(
                tiles: [
                  TileInstance(
                    icon: Icons.security_rounded,
                    title: 'Security settings',
                    onTap: () async {
                      final changes = await routePage(
                        context,
                        const SecuritySettingsPage(),
                      );
                      if (changes == true) _refresh();
                    },
                  ),
                  TileInstance(
                    icon: Icons.notifications_off_rounded,
                    title: 'Blocked and muted users',
                    onTap: () async {
                      final changed = await routePage(
                        context,
                        const BlockedMutedPage(),
                      );
                      if (changed == true) _refresh();
                    },
                  ),
                  // updated for admin view 
                  if (_isAdmin) 
                    TileInstance(
                      icon: Icons.admin_panel_settings_rounded,
                      title: 'Moderator Dashboard',
                      onTap: () => routePage(context, const ModeratorDashboard()),
                    ),
                ],
              ),

              // this the help section
              TileSection(
                tiles: [
                  TileInstance(
                    icon: Icons.help_center_rounded,
                    title: 'Help',
                    onTap: () async {
                      final changed = await routePage(
                        context,
                        const HelpPage(),
                      );
                      if (changed == true) _refresh();
                    },
                  ),
                  TileInstance(
                    icon: Icons.contact_page_rounded,
                    title: 'Contact us',
                    onTap: () async {
                      final changed = await routePage(
                        context,
                        const ContactUsPage(),
                      );
                      if (changed == true) _refresh();
                    },
                  ),
                  TileInstance(
                    icon: Icons.lock_outline_rounded,
                    title: 'Privacy Policy',
                    onTap: () async {
                      final changed = await routePage(
                        context,
                        const PrivacyPolicyPage(),
                      );
                      if (changed == true) _refresh();
                    },
                  ),
                ],
              ),
              // sign out
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

class _FollowCountButton extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback onTap;

  const _FollowCountButton({
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
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