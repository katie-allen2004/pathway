import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'other_user_profile.dart';

class FollowListPage extends StatefulWidget {
  final String mode; // 'followers' or 'following'

  const FollowListPage({
    super.key,
    required this.mode,
  });

  @override
  State<FollowListPage> createState() => _FollowListPageState();
}

class _FollowListPageState extends State<FollowListPage> {
  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authUser = supabase.auth.currentUser;
      if (authUser == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // get the current logged in user's pathway user_id
      final meRow = await supabase
          .schema('pathway')
          .from('users')
          .select('user_id')
          .eq('external_id', authUser.id)
          .maybeSingle();

      if (meRow == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final myPathwayUserId = meRow['user_id'] as int;

      // pull rows from the subscriptions table depending on list
      final subscriptions = await supabase
          .schema('pathway')
          .from('user_subscriptions')
          .select(widget.mode == 'followers'
              ? 'subscriber_user_id'
              : 'target_user_id')
          .eq(
            widget.mode == 'followers'
                ? 'target_user_id'
                : 'subscriber_user_id',
            myPathwayUserId,
          );

      final rows = subscriptions as List;
      if (rows.isEmpty) {
        if (!mounted) return;
        setState(() {
          _users = [];
          _isLoading = false;
        });
        return;
      }

      final ids = rows
          .map<int>((row) => widget.mode == 'followers'
              ? row['subscriber_user_id'] as int
              : row['target_user_id'] as int)
          .toList();

      // get user + profile info for those ids
      final users = await supabase
          .schema('pathway')
          .from('users')
          .select('user_id, external_id, profiles(display_name, avatar_url)')
          .inFilter('user_id', ids);

      final userList = (users as List).map<Map<String, dynamic>>((row) {
        final profile = row['profiles'];
        return {
          'user_id': row['user_id'],
          'external_id': row['external_id'],
          'display_name': profile != null &&
                  profile['display_name'] != null &&
                  (profile['display_name'] as String).trim().isNotEmpty
              ? profile['display_name']
              : 'User',
          'avatar_url': profile?['avatar_url'],
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        _users = userList;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load follow list: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  String get _title {
    return widget.mode == 'followers' ? 'Followers' : 'Following';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(
                  child: Text('No $_title yet'),
                )
              : ListView.separated(
                  itemCount: _users.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final avatarUrl = user['avatar_url'] as String?;
                    final displayName = user['display_name'] as String;
                    final externalId = user['external_id'] as String;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            avatarUrl != null && avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                        child: (avatarUrl == null || avatarUrl.isEmpty)
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(displayName),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OtherUserProfilePage(
                              userId: externalId,
                              displayName: displayName,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}