import 'package:flutter/material.dart';
import 'package:pathway/core/widgets/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:pathway/features/auth/presentation/login_screen.dart';
import 'package:pathway/core/services/accessibility_controller.dart';
import 'package:provider/provider.dart';
import 'package:pathway/models/accessibility_settings.dart';
import 'package:pathway/features/venues/data/venue_model.dart'; 
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.read<AccessibilityController>().settings;
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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: a11y.highContrast
                    ? Colors.black
                    : cs.onSurface.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "My Submissions",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
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
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        "No submissions yet.",
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: controller,
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final venue = VenueModel.fromJson(items[i]);
                      return ListTile(
                        leading: _buildStatusIcon(venue.status, highContrast: a11y.highContrast),
                        title: Text(venue.name),
                        subtitle: Text(
                          "Status: ${venue.status}",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: a11y.highContrast
                                ? Colors.black
                                : cs.onSurface.withValues(alpha: 0.75),
                          ),
                        ),
                        trailing: Icon(
                          Icons.info_outline,
                          size: 20,
                          color: a11y.highContrast ? Colors.black : cs.onSurface,
                        ),
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
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  final a11y = context.read<AccessibilityController>().settings;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        venue.name,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //const BadgesSection(),
          //status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
            color: a11y.highContrast
                ? Colors.white
                : (venue.status == 'rejected'
                    ? Colors.red
                    : (venue.status == 'approved' ? Colors.green : Colors.orange))
                    .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "Status: ${venue.status.toUpperCase()}", 
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: a11y.highContrast
                    ? Colors.black
                    : venue.status == 'rejected'
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
                color: a11y.highContrast ? Colors.white : cs.surfaceContainerHighest,
                border: Border.all(
                  color: a11y.highContrast
                      ? Colors.black
                      : cs.outline.withValues(alpha: 0.25),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                venue.modNotes ?? "No specific notes provided.", 
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: a11y.highContrast ? Colors.black : cs.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "To resubmit, please create a new application for this venue from the map screen with the requested updates.",
              style: theme.textTheme.bodySmall?.copyWith(
                color: a11y.highContrast
                  ? Colors.black
                  : cs.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ] else if (venue.status == 'pending') ...[
            Text(
              "Our team is currently reviewing your submission. It will appear on the map once approved.",
              style: theme.textTheme.bodySmall?.copyWith(
                color: a11y.highContrast
                    ? Colors.black
                    : cs.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ] else ...[
            Text(
              "Your venue is live! Thank you for helping the community improve accessibility.",
              style: theme.textTheme.bodySmall?.copyWith(
                color: a11y.highContrast
                    ? Colors.black
                    : cs.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: Text(
            "Close",
            style: theme.textTheme.labelLarge?.copyWith(
              color: a11y.highContrast ? Colors.black : cs.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

// list icons
Widget _buildStatusIcon(String status, {bool highContrast = false}) {
  switch (status) {
    case 'approved': return Icon(Icons.check_circle, color: (highContrast ? Colors.black : Colors.green));
    case 'rejected': return Icon(Icons.cancel, color: (highContrast ? Colors.black : Colors.red));
    default: return Icon(Icons.pending, color:  (highContrast ? Colors.black : Colors.orange));
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
    if (authUser == null) {
      debugPrint('No auth user found');
      return;
    }

    debugPrint('AUTH USER ID: ${authUser.id}');
    debugPrint('AUTH EMAIL: ${authUser.email}');

    try {
      final userRow = await supabase
          .schema('pathway')
          .from('users')
          .select('user_id, external_id')
          .eq('external_id', authUser.id)
          .maybeSingle();

      debugPrint('PATHWAY USER ROW: $userRow');

      if (userRow == null) {
        debugPrint('No matching pathway.users row found for this auth user');
        return;
      }

      final pathwayUserId = userRow['user_id'] as int;
      debugPrint('PATHWAY USER ID: $pathwayUserId');

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

      debugPrint('FOLLOWERS RAW: $followers');
      debugPrint('FOLLOWING RAW: $following');

      if (!mounted) return;
      setState(() {
        _followerCount = (followers as List).length;
        _followingCount = (following as List).length;
      });

      debugPrint('COUNTS SET: followers=$_followerCount following=$_followingCount');
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
      final theme = Theme.of(context);
      final cs = theme.colorScheme;
      final a11y = context.watch<AccessibilityController>().settings;
    return Scaffold(
      appBar: PathwayAppBar(
        height: 250,
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
                    backgroundColor: a11y.highContrast
                        ? Colors.black
                        : Colors.white.withValues(alpha: 0.14),
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
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.appBarTheme.titleTextStyle?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 25,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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
                      final changed = await context.push('/profile/edit');
                      if (changed == true) _refresh();
                    },
                  ),
                  TileInstance(
                    icon: Icons.notifications_rounded,
                    title: 'Notification settings',
                    onTap: () async {
                      final changed = await context.push('/profile/notification');
                      if (changed == true) _refresh();
                    },
                  ),
                  TileInstance(
                    icon: Icons.settings_accessibility_rounded,
                    title: 'Accessibility settings',
                    onTap: () async {
                      final changes = await context.push('/profile/accessibility');
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
                      final changed = await context.push('/profile/favorites');
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
                      final changes = await context.push('/profile/security');
                      if (changes == true) _refresh();
                    },
                  ),
                  TileInstance(
                    icon: Icons.notifications_off_rounded,
                    title: 'Blocked and muted users',
                    onTap: () async {
                      final changed = await context.push('/profile/blocked-muted');
                      if (changed == true) _refresh();
                    },
                  ),
                  // updated for admin view 
                  if (_isAdmin) 
                    TileInstance(
                      icon: Icons.admin_panel_settings_rounded,
                      title: 'Moderator Dashboard',
                      onTap: () => context.push('/profile/moderator'),
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
                      final changed = await context.push('/profile/help');
                      if (changed == true) _refresh();
                    },
                  ),
                  TileInstance(
                    icon: Icons.contact_page_rounded,
                    title: 'Contact us',
                    onTap: () async {
                      final changed = await context.push('/profile/contact-us');
                      if (changed == true) _refresh();
                    },
                  ),
                  TileInstance(
                    icon: Icons.lock_outline_rounded,
                    title: 'Privacy Policy',
                    onTap: () async {
                      final changed = await context.push('/profile/privacy-policy');
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
                          leading: Icon(
                            Icons.logout_rounded,
                            color: a11y.highContrast ? Colors.white : cs.onPrimary,
                          ),
                          title: Text(
                            'Sign out',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: a11y.highContrast ? Colors.white : cs.onPrimary,
                            ),
                          ),
                          tileColor: a11y.highContrast ? Colors.black : cs.primary,
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
    final theme = Theme.of(context);
    final a11y = context.watch<AccessibilityController>().settings;

    final borderColor = a11y.highContrast
      ? Colors.white
      : Colors.white.withValues(alpha: 0.45);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: a11y.highContrast 
              ? Colors.black.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count.toString(),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
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