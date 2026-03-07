import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../models/user_profile.dart';
import 'package:pathway/core/theme/theme.dart';
import 'package:pathway/core/widgets/widgets.dart';

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

  // Initialize state variables
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<UserProfile> _searchResults = [];
  bool _isQuerying = false;

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
    // If the search query is empty, clear results and return early
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    // Otherwise, set state to isQuerying
    setState(() {
      _isQuerying = true;
    });
    try {
      // Search db for display_name that matches or is similar to the query
      final data = await _supabase
          .schema('pathway')
          .from('profiles')
          .select('user_id, display_name, bio, avatar_url')
          .or('display_name.ilike.%$query%,bio.ilike.%$query%')
          .limit(20);
      // Map the results to UserProfile models
      final List<UserProfile> results = (data as List)
          .map((json) => UserProfile.fromJson(json))
          .toList();
      // Update state with the search results and set isQuerying to false
      setState(() {
        _searchResults = results;
        _isQuerying = false;
      });
      // If a search error occurs, catch it and print to console, then set isQuerying to false
    } catch (e, st) {
      debugPrint('Search Error: $e\n$st');
      setState(() => _isQuerying = false);
    }
  }

  // Method: Open conversation screen, either with an existing conversation or starting a new one with a selected user
  void _openConversation({_Conversation? conversation, UserProfile? startWith}) {
    // Initialize a conversation object. If an existing conversation is provided, use it. Otherwise, create a new one-to-one conversation using the selected user's info or default values.
    final conv = conversation ??
        _Conversation.oneToOne(
          id: startWith?.id ?? 'new-${DateTime.now().millisecondsSinceEpoch}',
          title: startWith?.userName ?? 'New chat',
          avatarUrls: [startWith?.avatarUrl],
          lastMessage: '',
          lastSender: null,
          lastActivity: DateTime.now(),
          unread: 0,
        );

    // Navigate to the ConversationScreen, passing the conversation object as an argument
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConversationScreen(conversation: conv),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the current theme for styling
    final theme = Theme.of(context);
    return Scaffold(
      appBar: PathwayAppBar(
        height: 100,
        centertitle: false,
        title: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          // If in search mode, show a TextField for input. Otherwise, show the default title "Messages"
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
          // IconButton to toggle search mode. Shows a search icon when not searching, and a close icon when in search mode. Tapping it will toggle the search state and clear results if exiting search mode.
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

      // Action button to compose a new conversation
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _openConversation();
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.create_rounded, color: Colors.white),
      ),

      // If state is in Searching mode, set body to _buildSearchList. Otherwise, set it to _buildInbox mode.
      body: _isSearching ? _buildSearchList() : _buildInbox(),
    );
  }

  // _buildSearchList Widget: Build list of users based on query
  Widget _buildSearchList() {
    // If in _isQuerying state, show a CircularProgressIndicator
    if (_isQuerying) return const Center(child: CircularProgressIndicator());
    // If there is text in the _searchController but _searchResults is empty (i.e., no users with that name were found), display an error message.
    if (_searchController.text.isNotEmpty && _searchResults.isEmpty) {
      return Center(child: Text("No profiles found.", style: Theme.of(context).textTheme.bodyMedium));
    }
    // Otherwise (i.e., if the search is complete and at least one user was found), display a list of those users
    return ListView.separated(
      padding: AppSpacing.page,
      itemCount: _searchResults.length, // itemCount = number of users found by the query
      separatorBuilder: (_, _) => const SizedBox(height: 8), // define separatorBuilder to a SizedBox of height 8
      itemBuilder: (context, i) { // build a set of items 
        final user = _searchResults[i]; // current user instance is whatever user is at index i
        return Card( // for each user instance, return a card
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
            subtitle: (user.bio != null && user.bio!.isNotEmpty)  // Include user's bio if exists
                ? Text(user.bio!, maxLines: 1, overflow: TextOverflow.ellipsis)
                : null,

            // Add a message button to quickly start a chat with a searched user
            trailing: IconButton(
              tooltip: 'Message',
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              onPressed: () => _openConversation(startWith: user),
            ),

            // Allow user to select row and view other user's profile
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OtherUserProfilePage( // Build other user's profile page
                    userId: user.id,
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

  // _buildInbox Widget: Display all open conversations the signed-in user has
  Widget _buildInbox() {
    return ListView.separated(
      padding: AppSpacing.page,
      itemCount: _mockConversations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final convo = _mockConversations[i]; // for now, parse _mockConversations for each conversation (hook up to Supabase later)
        return _ConversationTile( // for each conversation, return a _ConversationTile
          conversation: convo,
          onTap: () => _openConversation(conversation: convo), // tapping on the conversation opens that conversation
          onLongPress: () { // holding on the conversation opens a modal with conversation actions
            showModalBottomSheet(
              context: context,
              builder: (_) => _conversationActions(convo),
            );
          },
        );
      },
    );
  }

  // _conversationActions Widget: Lists actions the user can enact upon a conversation
  Widget _conversationActions(_Conversation convo) {
    return SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: Icon(convo.muted ? Icons.volume_up : Icons.volume_off), // Let user mute or unmute a conversation
            title: Text(convo.muted ? 'Unmute' : 'Mute'),
            onTap: () => Navigator.of(context).pop(), // Hook up to Supabase later
          ),
          ListTile(
            leading: const Icon(Icons.notifications_off_rounded), // Let user disable notifications from that conversation
            title: const Text('Disable notifications'),
            onTap: () => Navigator.of(context).pop(), // Hook up to Supabase later
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded), // Let user delete conversation
            title: const Text('Delete conversation'),
            onTap: () => Navigator.of(context).pop(), // Hook up to Supabase later
          ),
        ],
      ),
    );
  }
}

// Model: _Conversation defines necessary attributes for a conversation
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

  // Factory: Calling _Conversation.oneToOne allows users to create a one-to-one conversation with another user
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

  // Factory: Calling _Conversation.group allows users to create group chats with other users
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

// Class: _ConversationTile defines a singular conversation tile in the _buildInbox body of the Conversations screen
class _ConversationTile extends StatelessWidget {
  final _Conversation conversation;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _ConversationTile({
    required this.conversation,
    this.onTap,
    this.onLongPress,
  });

  // Helper: _formatTime takes the DateTime of the last message's sent time and displays a shorthand version to the user
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
    // Build _ConversationTile
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final preview = conversation.lastSender != null
        ? '${conversation.lastSender}: ${conversation.lastMessage}'
        : conversation.lastMessage;

    final iconColor = cs.onSurface.withValues(alpha: 0.6);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        // Define onTap and onLongPress actions for the tile
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          contentPadding: AppSpacing.cardPadding,
          minVerticalPadding: 10,
          horizontalTitleGap: 12,
          leading: SizedBox(
            // if there are multiple users in the conversation, the width is 76. otherwise, the width is 60
            width: 52,
            height: 52,
            child: Align(
              // Display stack of avatars for each user in the conversation
              alignment: Alignment.centerLeft,
              child: _AvatarStack(
                avatarUrls: conversation.avatarUrls,
                size: 52, // 52
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
                      constraints: const BoxConstraints(maxWidth: 44), // 1–2 icons only
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

          // Display preview message as subtitle
          subtitle: Text(
            preview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis, // Overflowed text is displayed with ellipsis
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),

          // Display time since last activity and potentially number of unread messages
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center, // centered vertically
            crossAxisAlignment: CrossAxisAlignment.end, // centered at the end horizontally
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                // Display time since last activity
                _formatTime(conversation.lastActivity),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 6),
              // If there are any unread messages, display the number of which within a purple rounded box
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

/// Avatar stack used by both single and group conversations
class _AvatarStack extends StatelessWidget {
  final List<String?> avatarUrls;
  final double size;
  final bool isGroup;
  final bool online;

  const _AvatarStack({required this.avatarUrls, this.size = 48, this.isGroup = false, this.online = false});

@override
Widget build(BuildContext context) {
  // onlineDot Widget: Creates a container with a green dot to show that another user is online
  Widget onlineDot(double s) => Container(
        width: s * 0.26,
        height: s * 0.26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.green,
          border: Border.all(color: Colors.white, width: 2),
        ),
      );

  // avatarAt Widget: Display
  Widget avatarAt(String? url, double s) {
    if (url == null || url.isEmpty) {
      // If no avatarUrl exists, fill with blank avatar
      return CircleAvatar(
        radius: s / 2,
        child: Icon(Icons.person_rounded, color: Colors.white, size: s * 0.55),
      );
    }
    // Otherwise, fill with avatar
    return CircleAvatar(
      radius: s / 2,
      backgroundImage: NetworkImage(url),
    );
  }

  return LayoutBuilder(
    builder: (context, constraints) {
      final s = constraints.biggest.shortestSide; // The shortest side of the biggest size within the given constraints
      final safeS = (s.isFinite && s > 0) ? s : size; // Fallback: If parent gives unbounded/0, fall back on size

      final urls = avatarUrls; // List of all avatarUrls

      // If chat isn't a group and/or the length of the list of urls is less than or equal to 1:
      if (!isGroup || urls.length <= 1) {
        final url = urls.isNotEmpty ? urls.first : null; // if url isn't empty, use the first url in urls. otherwise, url = null

        // Return a chat with that single user's avatar
        return SizedBox(
          width: safeS,
          height: safeS,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Center(child: avatarAt(url, safeS)),
              if (online) // If that user is online, place an onlineDot in the bottom right corner
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: onlineDot(safeS),
                ),
            ],
          ),
        );
      }

      // If there is more than 1 avatar/the conversation is a group chat:
      final avatars = urls.take(4).toList(); // Take only 4 urls and place them in a list
      while (avatars.length < 4) {
        avatars.add(null); // If there are less than 4 avatarUrls, fill the rest of the list with null until length = 4
      }

      // Set gap and inset between avatars
      final gap = (safeS * 0.045).clamp(1.0, 3.0);
      final inset = (safeS * 0.06).clamp(1.5, 4.0);
      // Set inner zone and cell
      final inner = safeS - inset * 2;
      final cell = ((inner - gap) / 2).clamp(0.0, safeS); // clamp prevents negatives

      return SizedBox(
        width: safeS,
        height: safeS,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            ClipOval(
              child: Container(
                color: Colors.transparent, // divider color
                padding: EdgeInsets.all(inset),
                child: SizedBox(
                  width: inner,
                  height: inner,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: cell,
                        child: Row( // Fill first row with 2 avatars
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
                        child: Row( // Fill second row with 2 avatars
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

            if (online) // If any user online, place an onlineDot in the bottom right corner
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

/// Simple conversation screen showing mock messages
class ConversationScreen extends StatelessWidget {
  final _Conversation conversation;

  const ConversationScreen({required this.conversation, super.key});

  // Display mock messages (replace with real ones later)
  List<_Message> get _messages => [
        _Message(id: 'm1', author: 'Alex Johnson', authorId: 'u1', text: 'Hey, you coming?', createdAt: DateTime.now().subtract(const Duration(minutes: 90)), mine: false),
        _Message(id: 'm2', author: 'You', authorId: 'me', text: 'Yes, I will be there in 10 minutes.', createdAt: DateTime.now().subtract(const Duration(minutes: 85)), mine: true),
        _Message(id: 'm3', author: conversation.lastSender ?? conversation.title, authorId: 'u2', text: conversation.lastMessage, createdAt: conversation.lastActivity, mine: false),
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: PathwayAppBar(
        height: 80,
        title: Row(children: [ // Place avatar stack, group chat name, then number of messages
          _AvatarStack(avatarUrls: conversation.avatarUrls, size: 36, isGroup: conversation.avatarUrls.length > 1, online: conversation.online),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(conversation.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            Text('${_messages.length} messages', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
          ])
        ]),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              reverse: false,
              padding: AppSpacing.page,
              itemCount: _messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) { // Build message items using _messages
                final m = _messages[i];
                return Align(
                  alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78), // Container is based on context
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: m.mine ? AppColors.primary : Colors.grey.shade200, // If message is from user, box is primary color. Otherwise, it is a light gray
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!m.mine) Text(m.author, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)), // If not msg from user, display other user's name
                        const SizedBox(height: 6),
                        Text(m.text, style: TextStyle(color: m.mine ? Colors.white : Colors.black87)),
                        const SizedBox(height: 6),
                        Text(_timeLabel(m.createdAt), style: theme.textTheme.bodySmall?.copyWith(color: m.mine ? Colors.white70 : Colors.black45)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Response area UI
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: Row(
                children: [
                  IconButton(onPressed: () {}, icon: const Icon(Icons.add_rounded)), // Hook up to add photos/videos later
                  Expanded(
                    child: TextField( // Message box: User can type in message and send it to other user(s)
                      decoration: InputDecoration(
                        hintText: 'Message ${conversation.title}',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(backgroundColor: AppColors.primary, child: IconButton(onPressed: () {}, icon: const Icon(Icons.send_rounded, color: Colors.white))), // Set up to send message later
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeLabel(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}

// _Message class: Defines necessary characteristics of a Message
class _Message {
  final String id;
  final String author;
  final String authorId;
  final String text;
  final DateTime createdAt;
  final bool mine;
  _Message({required this.id, required this.author, required this.authorId, required this.text, required this.createdAt, this.mine = false});
}