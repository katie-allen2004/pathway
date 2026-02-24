import 'package:flutter/material.dart';
import 'package:pathway/core/theme/theme.dart';
import 'package:pathway/core/widgets/widgets.dart';

class BlockedMutedPage extends StatefulWidget {
  const BlockedMutedPage({super.key});

  @override
  State<BlockedMutedPage> createState() => _BlockedMutedPageState();
}

class _BlockedMutedPageState extends State<BlockedMutedPage> {
  // Replace these with Supabase fetch later.
  List<SafetyUser> blocked = const [
    SafetyUser(id: '2', displayName: 'Jane Doe', avatarUrl: null),
  ];
  // Temp user for UI display purposes - replace with real data later
  List<SafetyUser> muted = const [
    SafetyUser(id: '1', displayName: 'Alex Johnson', avatarUrl: null),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PathwayAppBar(
          height: 130,
          centertitle: false,
          title: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('Blocked & muted users', style: theme.appBarTheme.titleTextStyle),
          ),
          actions: const [],
        ),
        body: Column(
          children: [
            // Tab bar
            Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: const TabBar(
                tabs: [
                  Tab(text: 'Blocked'),
                  Tab(text: 'Muted'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _UsersList(
                    users: blocked,
                    emptyTitle: 'No blocked users',
                    emptySubtitle: 'People you block will appear here.',
                    actionLabel: 'Unblock',
                    onAction: (u) {
                      setState(() => blocked = blocked.where((x) => x.id != u.id).toList());
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Unblocked ${u.displayName}')),
                      );
                    },
                  ),
                  _UsersList(
                    users: muted,
                    emptyTitle: 'No muted users',
                    emptySubtitle: 'Muted accounts won\'t send you notifications.',
                    actionLabel: 'Unmute',
                    onAction: (u) {
                      setState(() => muted = muted.where((x) => x.id != u.id).toList());
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Unmuted ${u.displayName}')),
                      );
                    },
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

class _UsersList extends StatelessWidget {
  final List<SafetyUser> users;
  final String emptyTitle;
  final String emptySubtitle;
  final String actionLabel;
  final ValueChanged<SafetyUser> onAction;

  const _UsersList({
    required this.users,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return _EmptyState(title: emptyTitle, subtitle: emptySubtitle);
    }

    return ListView.separated(
      padding: AppSpacing.page,
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final u = users[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: (u.avatarUrl != null && u.avatarUrl!.isNotEmpty)
                  ? NetworkImage(u.avatarUrl!)
                  : null,
              child: (u.avatarUrl == null || u.avatarUrl!.isEmpty)
                  ? const Icon(Icons.person_rounded, color: Colors.white)
                  : null,
            ),
            title: Text(u.displayName),
            trailing: TextButton(
              onPressed: () => onAction(u),
              child: Text(actionLabel),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Padding(
        padding: AppSpacing.page,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block_rounded, size: 52, color: cs.onSurface.withValues(alpha: 0.35)),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.65)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class SafetyUser {
  final String id;
  final String displayName;
  final String? avatarUrl;

  const SafetyUser({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });
}