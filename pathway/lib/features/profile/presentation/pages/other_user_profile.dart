import 'package:flutter/material.dart';
import 'package:pathway/core/widgets/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/features/auth/data/report_user.dart';

class OtherUserProfilePage extends StatefulWidget {
  final String userId;
  final String displayName;
  final VoidCallback? onMessage;

  const OtherUserProfilePage({
    super.key,
    required this.userId,
    required this.displayName,
    this.onMessage,
  });

  @override
  State<OtherUserProfilePage> createState() => _OtherUserProfilePageState();
}

class _OtherUserProfilePageState extends State<OtherUserProfilePage> {
  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  bool _isFollowLoading = false;
  bool _isFollowing = false;

  int _followerCount = 0;
  int _followingCount = 0;

  int? _currentPathwayUserId;
  int? _viewedPathwayUserId;

  @override
  void initState() {
    super.initState();
    _loadFollowData();
  }

  Future<void> _loadFollowData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentAuthUserId = supabase.auth.currentUser?.id;

      if (currentAuthUserId == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final currentPathwayRow = await supabase
          .schema('pathway')
          .from('users')
          .select('user_id')
          .eq('external_id', currentAuthUserId)
          .maybeSingle();

      final viewedPathwayRow = await supabase
          .schema('pathway')
          .from('users')
          .select('user_id')
          .eq('external_id', widget.userId)
          .maybeSingle();

      final currentPathwayUserId = currentPathwayRow?['user_id'] as int?;
      final viewedPathwayUserId = viewedPathwayRow?['user_id'] as int?;

      bool isFollowing = false;
      int followerCount = 0;
      int followingCount = 0;

      if (viewedPathwayUserId != null) {
        final followers = await supabase
            .schema('pathway')
            .from('user_subscriptions')
            .select('subscriber_user_id')
            .eq('target_user_id', viewedPathwayUserId);

        followerCount = (followers as List).length;

        final following = await supabase
            .schema('pathway')
            .from('user_subscriptions')
            .select('target_user_id')
            .eq('subscriber_user_id', viewedPathwayUserId);

        followingCount = (following as List).length;
      }

      if (currentPathwayUserId != null && viewedPathwayUserId != null) {
        final followRow = await supabase
            .schema('pathway')
            .from('user_subscriptions')
            .select('subscriber_user_id')
            .eq('subscriber_user_id', currentPathwayUserId)
            .eq('target_user_id', viewedPathwayUserId)
            .maybeSingle();

        isFollowing = followRow != null;
      }

      if (!mounted) return;
      setState(() {
        _currentPathwayUserId = currentPathwayUserId;
        _viewedPathwayUserId = viewedPathwayUserId;
        _isFollowing = isFollowing;
        _followerCount = followerCount;
        _followingCount = followingCount;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load follow data: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_currentPathwayUserId == null || _viewedPathwayUserId == null) return;

    setState(() {
      _isFollowLoading = true;
    });

    try {
      if (_isFollowing) {
        await supabase
            .schema('pathway')
            .from('user_subscriptions')
            .delete()
            .eq('subscriber_user_id', _currentPathwayUserId!)
            .eq('target_user_id', _viewedPathwayUserId!);

        if (!mounted) return;
        setState(() {
          _isFollowing = false;
          if (_followerCount > 0) {
            _followerCount -= 1;
          }
        });
      } else {
        await supabase
            .schema('pathway')
            .from('user_subscriptions')
            .insert({
          'subscriber_user_id': _currentPathwayUserId,
          'target_user_id': _viewedPathwayUserId,
        });

        if (!mounted) return;
        setState(() {
          _isFollowing = true;
          _followerCount += 1;
        });
      }
    } catch (e) {
      debugPrint('Failed to toggle follow: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update follow status: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isFollowLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final bool isViewingOwnProfile = widget.userId == currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: PathwayAppBar(
        height: 80,
        title: const Text("User Profile"),
        centertitle: true,
        automaticallyImplyLeading: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _ProfileHeader(displayName: widget.displayName),
            const SizedBox(height: 30),

            _IdentitySection(displayName: widget.displayName, followerCount: _followerCount, followingCount: _followingCount, isLoading: _isLoading),
            const SizedBox(height: 24),

            if (!isViewingOwnProfile) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading || _isFollowLoading ? null : _toggleFollow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFollowing ? Colors.grey.shade300 : null,
                            foregroundColor: _isFollowing ? Colors.black87 : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isFollowLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(_isFollowing ? 'Following' : 'Follow'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: widget.onMessage,
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                          label: const Text("Message"),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            _buildInfoCard(
              icon: Icons.info_outline,
              title: "About",
              content: "This is a verified Pathway student profile. Reach out to start a conversation about accessible venues!",
            ),
            const SizedBox(height: 12),

            _buildInfoCard(
              icon: Icons.history,
              title: "Activity",
              content: "No recent reviews or posts to display at this time.",
            ),
            const SizedBox(height: 12),

            if (!isViewingOwnProfile)
              _ModerationTools(userId: widget.userId, displayName: widget.displayName),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16), 
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.deepPurple, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String displayName;
  const _ProfileHeader({required this.displayName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF0F2F5), 
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: CircleAvatar(
          radius: 50,
          backgroundColor: Colors.white,
          child: CircleAvatar(
            radius: 46,
            backgroundColor: Colors.grey.shade200,
            child: const Icon(Icons.person, size: 50, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

class _IdentitySection extends StatelessWidget {
  final String displayName;
  final int followerCount;
  final int followingCount;
  final bool isLoading;

  const _IdentitySection({
    required this.displayName,
    required this.followerCount,
    required this.followingCount,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          displayName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const Text(
          "Pathway Verified User",
          style: TextStyle(color: Colors.grey, letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatChip(
              label: 'Followers',
              value: isLoading ? '...' : followerCount.toString(),
            ),
            const SizedBox(width: 12),
            _StatChip(
              label: 'Following',
              value: isLoading ? '...' : followingCount.toString(),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ModerationTools extends StatelessWidget {
  final String userId;
  final String displayName;
  const _ModerationTools({required this.userId, required this.displayName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 5, 
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.gpp_maybe_outlined, color: Colors.redAccent, size: 28),
            const SizedBox(height: 12),
            const Text(
              "Community Safety", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              "Is this user violating community standards? Let us know to keep the community safe.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _triggerReportFlow(context),
                icon: const Icon(Icons.flag_outlined, size: 20),
                label: Text("Report $displayName"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerReportFlow(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ReportUserDialog(reportedUserId: userId),
    );
  }
}