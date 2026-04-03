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

  bool _looksLikeUuid(String value) {
  final uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  return uuidRegex.hasMatch(value);
}
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];

  List<Map<String, dynamic>> _filteredUsers = [];
  final TextEditingController _searchController = TextEditingController();

  // who i currently follow
  Set<String> _followedExternalIds = {};

  // my pathway bigint id
  int? _myPathwayUserId;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterUsers(String query) {
    final trimmed = query.trim().toLowerCase();

    if (trimmed.isEmpty) {
      setState(() {
        _filteredUsers = List<Map<String, dynamic>>.from(_users);
      });
      return;
    }

    setState(() {
      _filteredUsers = _users.where((user) {
        final displayName = (user['display_name'] as String).toLowerCase();
        return displayName.contains(trimmed);
      }).toList();
    });
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

      // get all the people i follow so button states are correct
      final myFollowingRows = await supabase
          .schema('pathway')
          .from('user_subscriptions')
          .select('target_user_id')
          .eq('subscriber_user_id', myPathwayUserId);

      // pull rows from the subscriptions table depending on list
      final subscriptions = await supabase
          .schema('pathway')
          .from('user_subscriptions')
          .select(
            widget.mode == 'followers'
                ? 'subscriber_user_id'
                : 'target_user_id',
          )
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
          _myPathwayUserId = myPathwayUserId;
          _users = [];
          _filteredUsers = [];
          _followedExternalIds = {};
          _isLoading = false;
        });
        return;
      }

      final ids = rows
          .map<int>(
            (row) =>
                widget.mode == 'followers'
                    ? row['subscriber_user_id'] as int
                    : row['target_user_id'] as int,
          )
          .toList();

      // get user rows
      final users = await supabase
          .schema('pathway')
          .from('users')
          .select('user_id, external_id, email')
          .inFilter('user_id', ids);

      final followedPathwayIds =
          (myFollowingRows as List)
              .map<int>((row) => row['target_user_id'] as int)
              .toSet();

      final followedUsers =
          (users as List)
              .where((row) => followedPathwayIds.contains(row['user_id'] as int))
              .map<String>((row) => row['external_id'] as String)
              .toSet();

      final externalIds =
          (users as List)
              .map<String>((row) => row['external_id'] as String)
              .toList();

      final profileIds = externalIds.where(_looksLikeUuid).toList();

      final profiles = profileIds.isEmpty
          ? <dynamic>[]
          : await supabase
              .schema('pathway')
              .from('profiles')
              .select('user_id, display_name, avatar_url')
              .inFilter('user_id', profileIds);

      final profileMap = <String, Map<String, dynamic>>{};
      for (final row in (profiles as List)) {
        profileMap[row['user_id'] as String] = row as Map<String, dynamic>;
      }

      final userList =
          (users as List).map<Map<String, dynamic>>((row) {
            final userId = row['user_id'] as int;
            final externalId = row['external_id'] as String;
            final email = row['email'] as String?;
            final profile = profileMap[externalId];

            final rawDisplayName = profile?['display_name'] as String?;
            final fallbackName =
                (email != null && email.contains('@'))
                    ? email.split('@').first
                    : 'User';

            final displayName =
                (rawDisplayName != null && rawDisplayName.trim().isNotEmpty)
                    ? rawDisplayName
                    : fallbackName;

            return {
              'user_id': userId,
              'external_id': externalId,
              'display_name': displayName,
              'avatar_url': profile?['avatar_url'],
            };
          }).toList();

      if (!mounted) return;
      setState(() {
        _myPathwayUserId = myPathwayUserId;
        _users = userList;
        _filteredUsers = List<Map<String, dynamic>>.from(userList);
        _followedExternalIds = followedUsers;
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

  Future<void> _toggleFollowForUser(Map<String, dynamic> user) async {
    if (_myPathwayUserId == null) return;

    final targetPathwayUserId = user['user_id'] as int;
    final targetExternalId = user['external_id'] as String;
    final isFollowing = _followedExternalIds.contains(targetExternalId);

    try {
      if (isFollowing) {
        await supabase
            .schema('pathway')
            .from('user_subscriptions')
            .delete()
            .eq('subscriber_user_id', _myPathwayUserId!)
            .eq('target_user_id', targetPathwayUserId);

        if (!mounted) return;
        setState(() {
          _followedExternalIds.remove(targetExternalId);

          // if this is the "following" page, remove the row right away
          if (widget.mode == 'following') {
            _users.removeWhere(
              (row) => row['external_id'] == targetExternalId,
            );
            _filteredUsers.removeWhere(
              (row) => row['external_id'] == targetExternalId,
            );
          }
        });
      } else {
        await supabase
            .schema('pathway')
            .from('user_subscriptions')
            .insert({
              'subscriber_user_id': _myPathwayUserId,
              'target_user_id': targetPathwayUserId,
            });

        if (!mounted) return;
        setState(() {
          _followedExternalIds.add(targetExternalId);
        });
      }
    } catch (e) {
      debugPrint('Failed to toggle follow from list: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update follow status: $e'),
        ),
      );
    }
  }

  String get _title {
    return widget.mode == 'followers' ? 'Followers' : 'Following';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          _title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterUsers,
                      decoration: InputDecoration(
                        hintText: 'Search',
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child:
                        _filteredUsers.isEmpty
                            ? Center(
                              child: Text(
                                'No $_title yet',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 15,
                                ),
                              ),
                            )
                            : ListView.separated(
                              itemCount: _filteredUsers.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(height: 2),
                              itemBuilder: (context, index) {
                                final user = _filteredUsers[index];
                                final avatarUrl = user['avatar_url'] as String?;
                                final displayName =
                                    user['display_name'] as String;
                                final externalId = user['external_id'] as String;

                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => OtherUserProfilePage(
                                              userId: externalId,
                                              displayName: displayName,
                                            ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: Colors.grey.shade200,
                                          backgroundImage:
                                              avatarUrl != null &&
                                                      avatarUrl.isNotEmpty
                                                  ? NetworkImage(avatarUrl)
                                                  : null,
                                          child:
                                              (avatarUrl == null ||
                                                      avatarUrl.isEmpty)
                                                  ? const Icon(
                                                    Icons.person,
                                                    color: Colors.grey,
                                                  )
                                                  : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                displayName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '@$displayName',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        _FollowStyleButton(
                                          isFollowing:
                                              _followedExternalIds.contains(
                                                externalId,
                                              ),
                                          onTap: () => _toggleFollowForUser(user),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }
}

class _FollowStyleButton extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback onTap;

  const _FollowStyleButton({
    required this.isFollowing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 92,
        height: 36,
        decoration: BoxDecoration(
          color: isFollowing ? Colors.grey.shade200 : const Color(0xFF4C5DF4),
          borderRadius: BorderRadius.circular(10),
          border: isFollowing ? Border.all(color: Colors.grey.shade300) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: TextStyle(
            color: isFollowing ? Colors.black87 : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}