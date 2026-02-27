import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pathway/core/theme/theme.dart';
import 'package:pathway/core/widgets/widgets.dart';

class BlockedMutedPage extends StatefulWidget {
  const BlockedMutedPage({super.key});

  @override
  State<BlockedMutedPage> createState() => _BlockedMutedPageState();
}

class _BlockedMutedPageState extends State<BlockedMutedPage> {
  final supabase = Supabase.instance.client;

  late Future<List<_RelationshipRow>> _blockedFuture;
  late Future<List<_RelationshipRow>> _mutedFuture;

  @override
  void initState() {
    super.initState();
    _blockedFuture = _fetch(type: 'blocked');
    _mutedFuture = _fetch(type: 'muted');
  }

  Future<List<_RelationshipRow>> _fetch({required String type}) async {
    final data = await supabase
        .from('v_relationships_with_profiles')
        .select('id, type, created_at, target_auth_id, display_name, avatar_url')
        .eq('type', type)
        .order('created_at', ascending: false);

    final list = (data as List)
        .map((e) => _RelationshipRow.fromMap(e as Map<String, dynamic>))
        .toList();

    return list;
  }

  Future<void> _refresh() async {
    setState(() {
      _blockedFuture = _fetch(type: 'blocked');
      _mutedFuture = _fetch(type: 'muted');
    });
    await Future.wait([_blockedFuture, _mutedFuture]);
  }

  Future<void> _removeRelationship(_RelationshipRow row) async {
    try {
      await supabase
          .from('user_relationships')
          .delete()
          .eq('id', row.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(row.type == 'blocked'
              ? 'Unblocked ${row.displayName}'
              : 'Unmuted ${row.displayName}'),
        ),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PathwayAppBar(
          height: 100,
          centertitle: false,
          title: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('Blocked & muted', style: theme.appBarTheme.titleTextStyle),
          ),
        ),
        body: Column(
          children: [
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
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: TabBarView(
                  children: [
                    _RelationshipsList(
                      future: _blockedFuture,
                      emptyTitle: 'No blocked users',
                      emptySubtitle: 'People you block will appear here.',
                      actionLabel: 'Unblock',
                      onAction: _removeRelationship,
                    ),
                    _RelationshipsList(
                      future: _mutedFuture,
                      emptyTitle: 'No muted users',
                      emptySubtitle: 'Muted accounts won’t send you notifications.',
                      actionLabel: 'Unmute',
                      onAction: _removeRelationship,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RelationshipsList extends StatelessWidget {
  final Future<List<_RelationshipRow>> future;
  final String emptyTitle;
  final String emptySubtitle;
  final String actionLabel;
  final ValueChanged<_RelationshipRow> onAction;

  const _RelationshipsList({
    required this.future,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_RelationshipRow>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return ListView(
            children: [
              SizedBox(height: 120),
              Center(child: CircularProgressIndicator()),
            ],
          );
        }
        if (snap.hasError) {
          return ListView(
            padding: AppSpacing.page,
            children: [
              Text('Failed to load: ${snap.error}'),
            ],
          );
        }

        final users = snap.data ?? const [];
        if (users.isEmpty) {
          return ListView(
            children: [
              const SizedBox(height: 120),
              _EmptyState(title: emptyTitle, subtitle: emptySubtitle),
            ],
          );
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
            Icon(Icons.block_rounded, size: 52, color: cs.onSurface.withOpacity(0.35)),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.65)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RelationshipRow {
  final String id; // uuid as string
  final String type; // 'blocked' | 'muted'
  final String targetAuthId; // uuid as string
  final String displayName;
  final String? avatarUrl;

  const _RelationshipRow({
    required this.id,
    required this.type,
    required this.targetAuthId,
    required this.displayName,
    required this.avatarUrl,
  });

  factory _RelationshipRow.fromMap(Map<String, dynamic> m) {
    return _RelationshipRow(
      id: m['id'].toString(),
      type: m['type'] as String,
      targetAuthId: m['target_auth_id'].toString(),
      displayName: (m['display_name'] as String?) ?? 'User',
      avatarUrl: m['avatar_url'] as String?,
    );
  }
}