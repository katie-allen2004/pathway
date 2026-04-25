import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../models/user_profile.dart';
import 'package:pathway/core/theme/theme.dart';
import 'package:pathway/core/widgets/widgets.dart';
import 'package:pathway/features/messaging/data/messaging_service.dart';
import 'package:image_picker/image_picker.dart';

//profile page
import 'package:pathway/features/profile/presentation/pages/other_user_profile.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

// ConversationsPage: Main screen showing list of conversations and search functionality
class _ConversationsPageState extends State<ConversationsPage> {
  final _supabase = Supabase.instance.client; // Initialize connection to Supabase
  final _messagingService = MessagingService();

  // Initialize state variables
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<UserProfile> _searchResults = [];
  bool _isQuerying = false;

  // real inbox state
  List<_Conversation> _conversations = [];
  bool _isInboxLoading = true;

  Future<void> _showNewConversationPicker() async {
  try {
    final followedUsers = await _messagingService.getFollowedUsers();

    if (!mounted) return;

    if (followedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are not following anyone yet.')),
      );
      return;
    }

    final result = await showModalBottomSheet<List<Map<String, dynamic>>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _NewConversationSheet(users: followedUsers),
    );

    if (result == null || result.isEmpty) return;

    if (result.length == 1) {
      final user = result.first;
      final conversationId = await _messagingService.openOrCreateDm(
        otherPathwayUserId: user['user_id'] as int,
        title: user['display_name'] as String,
      );

      if (!mounted) return;
      await _loadInbox();
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConversationScreen(
            conversationId: conversationId.toString(),
            title: user['display_name'] as String,
            avatarUrls: [user['avatar_url'] as String?],
            online: false,
          ),
        ),
      );
      await _loadInbox();
      return;
    }

    final me = await _getCurrentPathwayUserId();
    if (me == null) return;

    final memberIds = <int>[
      me,
      ...result.map<int>((u) => u['user_id'] as int),
    ];

    final groupTitle = result
        .map<String>((u) => u['display_name'] as String)
        .take(3)
        .join(', ');

    final avatarUrls = result
        .map<String?>((u) => u['avatar_url'] as String?)
        .take(4)
        .toList();

    final conversationId = await _messagingService.openOrCreateExactGroup(
      memberIds: memberIds,
      title: groupTitle,
    );

    if (!mounted) return;
    await _loadInbox();
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConversationScreen(
          conversationId: conversationId.toString(),
          title: groupTitle,
          avatarUrls: avatarUrls.isEmpty ? [null] : avatarUrls,
          online: false,
        ),
      ),
    );
    await _loadInbox();
  } catch (e, st) {
    debugPrint('Failed to open new conversation picker: $e\n$st');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not create conversation: $e')),
    );
  }
}

  // Dummy conversations to preview the UI (1:1 and groups)
  final List<_Conversation> _mockConversations = [
    _Conversation.oneToOne(
      id: 'c1',
      title: 'Alex Johnson',
      avatarUrls: [null],
      lastMessage: 'See you at 10 — can you bring the map?',
      lastSender: null,
      lastActivity: DateTime.now().subtract(const Duration(minutes: 6)),
      unread: 2,
      muted: false,
      locked: false,
      online: true,
    ),
    _Conversation.group(
      id: 'c2',
      title: 'Weekend Hike (5)',
      avatarUrls: [
        'https://picsum.photos/seed/1/200',
        'https://picsum.photos/seed/2/200',
        'https://picsum.photos/seed/3/200',
      ],
      lastMessage: 'I can bring water and snacks.',
      lastSender: 'Maya',
      lastActivity: DateTime.now().subtract(const Duration(hours: 3)),
      unread: 0,
      muted: true,
      locked: false,
    ),
    _Conversation.group(
      id: 'c3',
      title: 'Work Buddies',
      avatarUrls: [
        'https://picsum.photos/seed/4/200',
        'https://picsum.photos/seed/5/200',
      ],
      lastMessage: 'Shared the doc in #files',
      lastSender: 'Jordan',
      lastActivity: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      unread: 7,
      muted: false,
      locked: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadInbox();
  }

  // Method: Override dispose() to clean up controllers and timers
  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Method: Debounce search input to prevent excessive queries while typing
  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _handleSearch(q));
  }

  // Method: Handle search logic
  Future<void> _handleSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isQuerying = true;
    });

    try {
      // 1) search users by email so everyone can show up
      final userRows = await _supabase
          .schema('pathway')
          .from('users')
          .select('user_id, external_id, email')
          .ilike('email', '%$q%')
          .limit(20);

      final users = userRows as List;

      // collect external ids for matching profiles
      final externalIds = users
          .map<String>((row) => row['external_id'] as String)
          .where((id) => id.isNotEmpty)
          .toList();

      // 2) load profiles for those users
      final profileRows = externalIds.isEmpty
          ? <dynamic>[]
          : await _supabase
              .schema('pathway')
              .from('profiles')
              .select('user_id, display_name, bio, avatar_url')
              .inFilter('user_id', externalIds);

      final profileMap = <String, Map<String, dynamic>>{};
      for (final row in (profileRows as List)) {
        profileMap[row['user_id'] as String] = row as Map<String, dynamic>;
      }

      // 3) also search profiles by display name
      final displayNameRows = await _supabase
          .schema('pathway')
          .from('profiles')
          .select('user_id, display_name, bio, avatar_url')
          .ilike('display_name', '%$q%')
          .limit(20);

      final displayProfiles = displayNameRows as List;
      final displayExternalIds = displayProfiles
          .map<String>((row) => row['user_id'] as String)
          .where((id) => id.isNotEmpty)
          .toList();

      final displayUsersRows = displayExternalIds.isEmpty
          ? <dynamic>[]
          : await _supabase
              .schema('pathway')
              .from('users')
              .select('user_id, external_id, email')
              .inFilter('external_id', displayExternalIds);

      final mergedUserMap = <String, Map<String, dynamic>>{};

      // add email matches first
      for (final row in users) {
        final externalId = row['external_id'] as String;
        final email = row['email'] as String?;
        final profile = profileMap[externalId];

        final rawDisplayName = profile?['display_name'] as String?;
        final fallbackName = (email != null && email.contains('@'))
            ? email.split('@').first
            : 'User';

        mergedUserMap[externalId] = {
          'user_id': row['user_id'],
          'external_id': externalId,
          'display_name': (rawDisplayName != null && rawDisplayName.trim().isNotEmpty)
              ? rawDisplayName
              : fallbackName,
          'bio': profile?['bio'] ?? '',
          'avatar_url': profile?['avatar_url'],
        };
      }

      // add display name matches too
      for (final row in (displayUsersRows as List)) {
        final externalId = row['external_id'] as String;
        final email = row['email'] as String?;
        final profile = displayProfiles.firstWhere(
          (p) => p['user_id'] == externalId,
          orElse: () => <String, dynamic>{},
        );

        final rawDisplayName = profile['display_name'] as String?;
        final fallbackName = (email != null && email.contains('@'))
            ? email.split('@').first
            : 'User';

        mergedUserMap[externalId] = {
          'user_id': row['user_id'],
          'external_id': externalId,
          'display_name': (rawDisplayName != null && rawDisplayName.trim().isNotEmpty)
              ? rawDisplayName
              : fallbackName,
          'bio': profile['bio'] ?? '',
          'avatar_url': profile['avatar_url'],
        };
      }

      final results = mergedUserMap.values
          .map((row) => UserProfile.fromJson(row))
          .toList();

      setState(() {
        _searchResults = results;
        _isQuerying = false;
      });
    } catch (e, st) {
      debugPrint('Search Error: $e\n$st');
      setState(() {
        _isQuerying = false;
      });
    }
  }

  Future<int?> _getCurrentPathwayUserId() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return null;

    final row = await _supabase
        .schema('pathway')
        .from('users')
        .select('user_id')
        .eq('external_id', authUser.id)
        .maybeSingle();

    return row?['user_id'] as int?;
  }

  Future<int?> _findExistingDmConversation(int me, int other) async {
    final myMemberships = await _supabase
        .schema('pathway')
        .from('conversation_members')
        .select('conversation_id')
        .eq('user_id', me);

    final conversationIds = (myMemberships as List)
        .map<int>((row) => row['conversation_id'] as int)
        .toList();

    if (conversationIds.isEmpty) return null;

    for (final conversationId in conversationIds) {
      final convoRow = await _supabase
          .schema('pathway')
          .from('conversations')
          .select('conversation_id, is_group, title')
          .eq('conversation_id', conversationId)
          .maybeSingle();

      if (convoRow == null) continue;
      if (convoRow['is_group'] == true) continue;

      final members = await _supabase
          .schema('pathway')
          .from('conversation_members')
          .select('user_id')
          .eq('conversation_id', conversationId);

      final memberIds =
          (members as List).map<int>((row) => row['user_id'] as int).toList();

      final isExactDm = memberIds.length == 2 &&
          memberIds.contains(me) &&
          memberIds.contains(other);

      if (isExactDm) {
        return conversationId;
      }
    }

    return null;
  }

  Future<int> _createDmConversation({
    required int me,
    required int other,
    required String title,
  }) async {
    final convoRow = await _supabase
        .schema('pathway')
        .from('conversations')
        .insert({
          'is_group': false,
          'title': title,
        })
        .select('conversation_id')
        .single();

    final conversationId = convoRow['conversation_id'] as int;

    await _supabase
        .schema('pathway')
        .from('conversation_members')
        .insert([
          {
            'conversation_id': conversationId,
            'user_id': me,
          },
          {
            'conversation_id': conversationId,
            'user_id': other,
          },
        ]);

    return conversationId;
  }

  Future<void> _loadInbox() async {
    setState(() {
      _isInboxLoading = true;
    });

    try {
      final myUserId = await _getCurrentPathwayUserId();
      if (myUserId == null) {
        if (!mounted) return;
        setState(() {
          _isInboxLoading = false;
        });
        return;
      }

      final membershipRows = await _supabase
          .schema('pathway')
          .from('conversation_members')
          .select('conversation_id')
          .eq('user_id', myUserId);

      final conversationIds = (membershipRows as List)
          .map<int>((row) => row['conversation_id'] as int)
          .toList();

      if (conversationIds.isEmpty) {
        if (!mounted) return;
        setState(() {
          _conversations = [];
          _isInboxLoading = false;
        });
        return;
      }

      final convoRows = await _supabase
          .schema('pathway')
          .from('conversations')
          .select('conversation_id, is_group, title, created_at, image_path')
          .inFilter('conversation_id', conversationIds);

      final built = <_Conversation>[];

      for (final convo in (convoRows as List)) {
        final conversationId = convo['conversation_id'] as int;
        final isGroup = convo['is_group'] as bool? ?? false;
        String title = (convo['title'] as String?)?.trim() ?? '';
        List<String?> avatarUrls = [null];
        final customImagePath = convo['image_path'] as String?;
        bool online = false;

        final messageRows = await _supabase
            .schema('pathway')
            .from('messages')
            .select('message_id, sender_user_id, body, created_at')
            .eq('conversation_id', conversationId)
            .order('created_at', ascending: false)
            .limit(1);

        String lastMessage = '';
        DateTime lastActivity = DateTime.tryParse(
              convo['created_at'] as String? ?? '',
            ) ??
            DateTime.now();

        if ((messageRows as List).isNotEmpty) {
          final latest = messageRows.first;
          lastMessage = latest['body'] as String? ?? '';
          lastActivity =
              DateTime.tryParse(latest['created_at'] as String? ?? '') ??
                  lastActivity;
        }

        if (!isGroup) {
          final memberRows = await _supabase
              .schema('pathway')
              .from('conversation_members')
              .select('user_id')
              .eq('conversation_id', conversationId);

          final otherMemberIds = (memberRows as List)
              .map<int>((row) => row['user_id'] as int)
              .where((id) => id != myUserId)
              .toList();

          if (otherMemberIds.isNotEmpty) {
            final otherUserRow = await _supabase
                .schema('pathway')
                .from('users')
                .select('user_id, external_id, email')
                .eq('user_id', otherMemberIds.first)
                .maybeSingle();

            if (otherUserRow != null) {
              final externalId = otherUserRow['external_id'] as String?;
              final email = otherUserRow['email'] as String?;

              if (externalId != null) {
                final profileRow = await _supabase
                    .schema('pathway')
                    .from('profiles')
                    .select('display_name, avatar_url')
                    .eq('user_id', externalId)
                    .maybeSingle();

                final rawDisplayName = profileRow?['display_name'] as String?;
                title = (rawDisplayName != null && rawDisplayName.trim().isNotEmpty)
                    ? rawDisplayName
                    : ((email != null && email.contains('@'))
                        ? email.split('@').first
                        : 'User');

                avatarUrls = [profileRow?['avatar_url'] as String?];
              }
            }
          }
        } else {
          final memberRows = await _supabase
              .schema('pathway')
              .from('conversation_members')
              .select('user_id')
              .eq('conversation_id', conversationId);

          final memberIds = (memberRows as List)
              .map<int>((row) => row['user_id'] as int)
              .toList();

          final otherIds = memberIds.where((id) => id != myUserId).toList();

          if (title.isEmpty) {
            title = 'Group Chat (${memberIds.length})';
          }

          // use custom group image if one exists
          if (customImagePath != null && customImagePath.isNotEmpty) {
            avatarUrls = [customImagePath];
          } else {
            final avatarList = <String?>[];

            for (final id in otherIds.take(4)) {
              final userRow = await _supabase
                  .schema('pathway')
                  .from('users')
                  .select('external_id')
                  .eq('user_id', id)
                  .maybeSingle();

              final externalId = userRow?['external_id'] as String?;
              if (externalId == null) continue;

              final profileRow = await _supabase
                  .schema('pathway')
                  .from('profiles')
                  .select('avatar_url')
                  .eq('user_id', externalId)
                  .maybeSingle();

              avatarList.add(profileRow?['avatar_url'] as String?);
            }

            avatarUrls = avatarList.isEmpty ? [null] : avatarList;
          }
        }
        built.add(
          isGroup
              ? _Conversation.group(
                  id: conversationId.toString(),
                  title: title,
                  avatarUrls: avatarUrls,
                  lastMessage: lastMessage,
                  lastSender: null,
                  lastActivity: lastActivity,
                  unread: 0,
                  muted: false,
                  locked: false,
                )
              : _Conversation.oneToOne(
                  id: conversationId.toString(),
                  title: title,
                  avatarUrls: avatarUrls,
                  lastMessage: lastMessage,
                  lastSender: null,
                  lastActivity: lastActivity,
                  unread: 0,
                  muted: false,
                  locked: false,
                  online: online,
                ),
        );
      }

      built.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));

      if (!mounted) return;
      setState(() {
        _conversations = built;
        _isInboxLoading = false;
      });
    } catch (e, st) {
      debugPrint('Failed to load inbox: $e\n$st');
      if (!mounted) return;
      setState(() {
        _isInboxLoading = false;
      });
    }
  }

  // Method: Open conversation screen, either with an existing conversation or starting a new one with a selected user
  Future<void> _openConversation({_Conversation? conversation, UserProfile? startWith}) async {
    // existing conversation tapped from inbox
    if (conversation != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConversationScreen(
            conversationId: conversation.id,
            title: conversation.title,
            avatarUrls: conversation.avatarUrls,
            online: conversation.online,
          ),
        ),
      );
      await _loadInbox();
      return;
    }

    // starting a new DM from search/profile
    if (startWith == null) return;

    try {
      final me = await _getCurrentPathwayUserId();
      if (me == null) return;

      final other = int.tryParse(startWith.id);
      if (other == null) return;

      final existingConversationId = await _findExistingDmConversation(me, other);

      final conversationId = existingConversationId ??
          await _createDmConversation(
            me: me,
            other: other,
            title: startWith.userName,
          );

      final conv = _Conversation.oneToOne(
        id: conversationId.toString(),
        title: startWith.userName,
        avatarUrls: [startWith.avatarUrl],
        lastMessage: '',
        lastSender: null,
        lastActivity: DateTime.now(),
        unread: 0,
      );

      if (!mounted) return;
      await _loadInbox();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConversationScreen(
            conversationId: conv.id,
            title: conv.title,
            avatarUrls: conv.avatarUrls,
            online: conv.online,
          ),
        ),
      );
      await _loadInbox();
    } catch (e, st) {
      debugPrint('Open conversation error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open conversation: $e')),
      );
    }
  }

  Future<void> _deleteConversation(_Conversation convo) async {
    final conversationId = int.tryParse(convo.id);
    if (conversationId == null) return;

    try {
      await _supabase
          .schema('pathway')
          .from('conversations')
          .delete()
          .eq('conversation_id', conversationId);

      if (!mounted) return;

      Navigator.of(context).pop(); // close bottom sheet

      await _loadInbox();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conversation deleted')),
      );
    } catch (e, st) {
      debugPrint('Failed to delete conversation: $e\n$st');
      if (!mounted) return;
      Navigator.of(context).pop(); // close bottom sheet even on error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete conversation: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: PathwayAppBar(
        height: 100,
        centertitle: false,
        title: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: "Search profiles...",
                    border: InputBorder.none,
                    fillColor: Colors.white,
                    filled: true,
                    hintStyle: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : Text('Messages', style: Theme.of(context).appBarTheme.titleTextStyle),
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white, size: 30),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchResults = [];
                }
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewConversationPicker,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.create_rounded, color: Colors.white),
      ),
      body: _isSearching ? _buildSearchList() : _buildInbox(),
    );
  }

  Widget _buildSearchList() {
    if (_isQuerying) return const Center(child: CircularProgressIndicator());
    if (_searchController.text.isNotEmpty && _searchResults.isEmpty) {
      return Center(child: Text("No profiles found.", style: Theme.of(context).textTheme.bodyMedium));
    }
    return ListView.separated(
      padding: AppSpacing.page,
      itemCount: _searchResults.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final user = _searchResults[i];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            leading: CircleAvatar(
              radius: 22,
              backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              backgroundColor: Colors.deepPurple.shade50,
              child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                  ? Text(
                      user.userName.isNotEmpty ? user.userName[0] : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            title: Text(
              user.userName,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            subtitle: user.bio.isNotEmpty
                ? Text(user.bio, maxLines: 1, overflow: TextOverflow.ellipsis)
                : null,
            trailing: IconButton(
              tooltip: 'Message',
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              onPressed: () => _openConversation(startWith: user),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OtherUserProfilePage(
                    userId: user.externalId,
                    displayName: user.userName,
                    onMessage: () => _openConversation(startWith: user),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInbox() {
    if (_isInboxLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_conversations.isEmpty) {
      return const Center(child: Text('No conversations yet'));
    }

    return ListView.separated(
      padding: AppSpacing.page,
      itemCount: _conversations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final convo = _conversations[i];
        return _ConversationTile(
          conversation: convo,
          onTap: () => _openConversation(conversation: convo),
          onLongPress: () {
            showModalBottomSheet(
              context: context,
              builder: (_) => _conversationActions(convo),
            );
          },
        );
      },
    );
  }

  Widget _conversationActions(_Conversation convo) {
    return SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: Icon(convo.muted ? Icons.volume_up : Icons.volume_off),
            title: Text(convo.muted ? 'Unmute' : 'Mute'),
            onTap: () => Navigator.of(context).pop(),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded),
            title: const Text('Delete conversation'),
            onTap: () => _deleteConversation(convo),
          ),
        ],
      ),
    );
  }
}

class _Conversation {
  final String id;
  final String title;
  final List<String?> avatarUrls;
  final String lastMessage;
  final String? lastSender;
  final DateTime lastActivity;
  final int unread;
  final bool muted;
  final bool locked;
  final bool online;

  _Conversation({
    required this.id,
    required this.title,
    required this.avatarUrls,
    required this.lastMessage,
    this.lastSender,
    required this.lastActivity,
    this.unread = 0,
    this.muted = false,
    this.locked = false,
    this.online = false,
  });

  factory _Conversation.oneToOne({
    required String id,
    required String title,
    required List<String?> avatarUrls,
    required String lastMessage,
    String? lastSender,
    required DateTime lastActivity,
    int unread = 0,
    bool muted = false,
    bool locked = false,
    bool online = false,
  }) =>
      _Conversation(
        id: id,
        title: title,
        avatarUrls: avatarUrls,
        lastMessage: lastMessage,
        lastSender: lastSender,
        lastActivity: lastActivity,
        unread: unread,
        muted: muted,
        locked: locked,
        online: online,
      );

  factory _Conversation.group({
    required String id,
    required String title,
    required List<String?> avatarUrls,
    required String lastMessage,
    String? lastSender,
    required DateTime lastActivity,
    int unread = 0,
    bool muted = false,
    bool locked = false,
  }) =>
      _Conversation(
        id: id,
        title: title,
        avatarUrls: avatarUrls,
        lastMessage: lastMessage,
        lastSender: lastSender,
        lastActivity: lastActivity,
        unread: unread,
        muted: muted,
        locked: locked,
        online: false,
      );
}

class _ConversationTile extends StatelessWidget {
  final _Conversation conversation;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _ConversationTile({
    required this.conversation,
    this.onTap,
    this.onLongPress,
  });

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final preview = conversation.lastSender != null
        ? '${conversation.lastSender}: ${conversation.lastMessage}'
        : conversation.lastMessage;

    final iconColor = cs.onSurface.withValues(alpha: 0.6);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          contentPadding: AppSpacing.cardPadding,
          minVerticalPadding: 10,
          horizontalTitleGap: 12,
          leading: SizedBox(
            width: 52,
            height: 52,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _AvatarStack(
                avatarUrls: conversation.avatarUrls,
                size: 52,
                isGroup: conversation.avatarUrls.length > 1,
                online: conversation.online,
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  conversation.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (conversation.muted || conversation.locked) ...[
                const SizedBox(width: 6),
                Flexible(
                  fit: FlexFit.loose,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 44),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (conversation.muted)
                            Icon(Icons.volume_off, size: 16, color: iconColor),
                          if (conversation.muted && conversation.locked)
                            const SizedBox(width: 4),
                          if (conversation.locked)
                            Icon(Icons.lock_rounded, size: 16, color: iconColor),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(
            preview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(conversation.lastActivity),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 6),
              if (conversation.unread > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${conversation.unread}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
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

class _AvatarStack extends StatelessWidget {
  final List<String?> avatarUrls;
  final double size;
  final bool isGroup;
  final bool online;

  const _AvatarStack({required this.avatarUrls, this.size = 48, this.isGroup = false, this.online = false});

  @override
  Widget build(BuildContext context) {
    Widget onlineDot(double s) => Container(
          width: s * 0.26,
          height: s * 0.26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green,
            border: Border.all(color: Colors.white, width: 2),
          ),
        );

    Widget avatarAt(String? url, double s) {
      if (url == null || url.isEmpty) {
        return CircleAvatar(
          radius: s / 2,
          child: Icon(Icons.person_rounded, color: Colors.white, size: s * 0.55),
        );
      }
      return CircleAvatar(
        radius: s / 2,
        backgroundImage: NetworkImage(url),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final s = constraints.biggest.shortestSide;
        final safeS = (s.isFinite && s > 0) ? s : size;

        final urls = avatarUrls;

        if (!isGroup || urls.length <= 1) {
          final url = urls.isNotEmpty ? urls.first : null;

          return SizedBox(
            width: safeS,
            height: safeS,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Center(child: avatarAt(url, safeS)),
                if (online)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: onlineDot(safeS),
                  ),
              ],
            ),
          );
        }

        final avatars = urls.take(4).toList();
        while (avatars.length < 4) {
          avatars.add(null);
        }

        final gap = (safeS * 0.045).clamp(1.0, 3.0);
        final inset = (safeS * 0.06).clamp(1.5, 4.0);
        final inner = safeS - inset * 2;
        final cell = ((inner - gap) / 2).clamp(0.0, safeS);

        return SizedBox(
          width: safeS,
          height: safeS,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              ClipOval(
                child: Container(
                  color: Colors.transparent,
                  padding: EdgeInsets.all(inset),
                  child: SizedBox(
                    width: inner,
                    height: inner,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: cell,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(width: cell, height: cell, child: Center(child: avatarAt(avatars[0], cell))),
                              SizedBox(width: gap),
                              SizedBox(width: cell, height: cell, child: Center(child: avatarAt(avatars[1], cell))),
                            ],
                          ),
                        ),
                        SizedBox(height: gap),
                        SizedBox(
                          height: cell,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(width: cell, height: cell, child: Center(child: avatarAt(avatars[2], cell))),
                              SizedBox(width: gap),
                              SizedBox(width: cell, height: cell, child: Center(child: avatarAt(avatars[3], cell))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (online)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: onlineDot(safeS),
                ),
            ],
          ),
        );
      },
    );
  }
}

class ConversationScreen extends StatefulWidget {
  final String conversationId;
  final String title;
  final List<String?> avatarUrls;
  final bool online;

  const ConversationScreen({
    required this.conversationId,
    required this.title,
    required this.avatarUrls,
    this.online = false,
    super.key,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _supabase = Supabase.instance.client;
  final _messagingService = MessagingService();
  final TextEditingController _messageController = TextEditingController();

  late String _title;
  late List<String?> _avatarUrls;

  bool _isLoading = true;
  bool _isSending = false;
  bool _isUpdatingImage = false;

  int? _myPathwayUserId;
  List<_Message> _messages = [];

  @override
  void initState() {
    super.initState();
    _title = widget.title;
    _avatarUrls = List<String?>.from(widget.avatarUrls);
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // show chat edit options
  Future<void> _showEditChatOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text('Rename chat'),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameChatDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Change chat photo'),
                onTap: () {
                  Navigator.pop(context);
                  _changeChatPhoto();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // show dialog to rename chat
  Future<void> _showRenameChatDialog() async {
    final controller = TextEditingController(text: _title);

    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename chat'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Chat name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, controller.text.trim());
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (newTitle == null || newTitle.isEmpty) return;

    final conversationId = int.tryParse(widget.conversationId);
    if (conversationId == null) return;

    try {
      await _messagingService.updateConversationTitle(
        conversationId: conversationId,
        title: newTitle,
      );

      if (!mounted) return;

      setState(() {
        _title = newTitle;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not rename chat: $e')),
      );
    }
  }

  // pick and upload new chat photo
  Future<void> _changeChatPhoto() async {
    final conversationId = int.tryParse(widget.conversationId);
    if (conversationId == null) return;

    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);

      if (file == null) return;

      setState(() {
        _isUpdatingImage = true;
      });

      final bytes = await file.readAsBytes();

      final imageUrl = await _messagingService.updateConversationImage(
        conversationId: conversationId,
        bytes: bytes,
        fileName: file.name,
      );

      if (!mounted) return;

      setState(() {
        _avatarUrls = [imageUrl];
        _isUpdatingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat photo updated')),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUpdatingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update chat photo: $e')),
      );
    }
  }

  Future<int?> _getCurrentPathwayUserId() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return null;

    final row = await _supabase
        .schema('pathway')
        .from('users')
        .select('user_id')
        .eq('external_id', authUser.id)
        .maybeSingle();

    return row?['user_id'] as int?;
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final myUserId = await _getCurrentPathwayUserId();
      final conversationId = int.tryParse(widget.conversationId);

      if (myUserId == null || conversationId == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final rows = await _supabase
          .schema('pathway')
          .from('messages')
          .select('message_id, sender_user_id, body, created_at')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      final loadedMessages = (rows as List).map<_Message>((row) {
        final senderUserId = row['sender_user_id'] as int?;
        return _Message(
          id: row['message_id'].toString(),
          author: senderUserId == myUserId ? 'You' : _title,
          authorId: senderUserId?.toString() ?? '',
          text: row['body'] as String? ?? '',
          createdAt:
              DateTime.tryParse(row['created_at'] as String? ?? '') ??
                  DateTime.now(),
          mine: senderUserId == myUserId,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _myPathwayUserId = myUserId;
        _messages = loadedMessages;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load messages: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final conversationId = int.tryParse(widget.conversationId);
    if (_myPathwayUserId == null || conversationId == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      await _supabase.schema('pathway').from('messages').insert({
        'conversation_id': conversationId,
        'sender_user_id': _myPathwayUserId,
        'body': text,
      });

      _messageController.clear();
      await _loadMessages();
    } catch (e) {
      debugPrint('Failed to send message: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send message: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSending = false;
      });
    }
  }

  String _timeLabel(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: PathwayAppBar(
        height: 80,
        title: Row(
          children: [
            _isUpdatingImage
                ? const SizedBox(
                    height: 36,
                    width: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : _AvatarStack(
                    avatarUrls: _avatarUrls,
                    size: 36,
                    isGroup: _avatarUrls.length > 1,
                    online: widget.online,
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${_messages.length} messages',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: _showEditChatOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('No messages yet'))
                    : ListView.separated(
                        padding: AppSpacing.page,
                        itemCount: _messages.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final m = _messages[i];
                          return Align(
                            alignment: m.mine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.78,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: m.mine
                                    ? AppColors.primary
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!m.mine)
                                    Text(
                                      m.author,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  Text(
                                    m.text,
                                    style: TextStyle(
                                      color: m.mine
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _timeLabel(m.createdAt),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: m.mine
                                          ? Colors.white70
                                          : Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.add_rounded),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Message $_title',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      onPressed: _isSending ? null : _sendMessage,
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message {
  final String id;
  final String author;
  final String authorId;
  final String text;
  final DateTime createdAt;
  final bool mine;
  _Message({required this.id, required this.author, required this.authorId, required this.text, required this.createdAt, this.mine = false});
}

class _NewConversationSheet extends StatefulWidget {
  final List<Map<String, dynamic>> users;

  const _NewConversationSheet({required this.users});

  @override
  State<_NewConversationSheet> createState() => _NewConversationSheetState();
}

class _NewConversationSheetState extends State<_NewConversationSheet> {
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedUserIds = {};
  late List<Map<String, dynamic>> _filteredUsers;

  @override
  void initState() {
    super.initState();
    _filteredUsers = List<Map<String, dynamic>>.from(widget.users);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final q = query.trim().toLowerCase();

    setState(() {
      if (q.isEmpty) {
        _filteredUsers = List<Map<String, dynamic>>.from(widget.users);
      } else {
        _filteredUsers = widget.users.where((user) {
          final name = (user['display_name'] as String).toLowerCase();
          return name.contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'New Conversation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: _filter,
                decoration: InputDecoration(
                  hintText: 'Search followed users',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _filteredUsers.isEmpty
                  ? const Center(child: Text('No users found'))
                  : ListView.separated(
                      itemCount: _filteredUsers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        final userId = user['user_id'] as int;
                        final displayName = user['display_name'] as String;
                        final avatarUrl = user['avatar_url'] as String?;
                        final isSelected = _selectedUserIds.contains(userId);

                        return ListTile(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedUserIds.remove(userId);
                              } else {
                                _selectedUserIds.add(userId);
                              }
                            });
                          },
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
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                )
                              : const Icon(Icons.circle_outlined),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedUserIds.isEmpty
                      ? null
                      : () {
                          final selectedUsers = widget.users
                              .where((u) => _selectedUserIds.contains(u['user_id'] as int))
                              .toList();

                          Navigator.pop(context, selectedUsers);
                        },
                  child: Text(
                    _selectedUserIds.length <= 1
                        ? 'Start conversation'
                        : 'Create group (${_selectedUserIds.length})',
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