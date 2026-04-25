import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pathway/core/theme/theme.dart';
import 'package:pathway/core/widgets/widgets.dart';
import 'package:provider/provider.dart';
import 'package:pathway/core/services/accessibility_controller.dart';

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
    final cs = theme.colorScheme;
    final a11y = context.watch<AccessibilityController>().settings;

    final tabBg = a11y.highContrast ? Colors.white : cs.surface;
    final tabSelectedBg = a11y.highContrast ? Colors.black : cs.primary;
    final tabSelectedFg = Colors.white;
    final tabUnselectedFg = a11y.highContrast ? Colors.black : cs.primary;
    final tabBorder = a11y.highContrast ? Colors.black : cs.primary;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PathwayAppBar(
          height: 100,
          centertitle: false,
          title: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Blocked & muted', 
              style: theme.appBarTheme.titleTextStyle
            ),
          ),
        ),
        body: Column(
          children: [
            Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _BlockedMutedTabs(
                  backgroundColor: tabBg,
                  selectedBackgroundColor: tabSelectedBg,
                  selectedForegroundColor: tabSelectedFg,
                  unselectedForegroundColor: tabUnselectedFg,
                  borderColor: tabBorder,
                ),
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

class _BlockedMutedTabs extends StatelessWidget {
  final Color backgroundColor;
  final Color selectedBackgroundColor;
  final Color selectedForegroundColor;
  final Color unselectedForegroundColor;
  final Color borderColor;

  const _BlockedMutedTabs({
    required this.backgroundColor,
    required this.selectedBackgroundColor,
    required this.selectedForegroundColor,
    required this.unselectedForegroundColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
    final theme = Theme.of(context);
    final a11y = context.watch<AccessibilityController>().settings;

    if (controller == null) return const SizedBox.shrink();

    const labels = ['Blocked', 'Muted'];

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final currentIndex = controller.index;

        return Row(
          children: List.generate(labels.length, (index) {
            final selected = index == currentIndex;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == labels.length - 1 ? 0 : 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => controller.animateTo(index),
                  child: AnimatedContainer(
                    duration: a11y.reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? selectedBackgroundColor : backgroundColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: borderColor,
                        width: a11y.highContrast ? 2 : 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        labels[index],
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: selected
                              ? selectedForegroundColor
                              : unselectedForegroundColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.watch<AccessibilityController>().settings;

    final cardColor = a11y.highContrast ? Colors.white : cs.surface;
    final borderColor = a11y.highContrast
        ? Colors.black
        : cs.outline.withValues(alpha: 0.18);

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
              Text(
                'Failed to load: ${snap.error}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: a11y.highContrast
                      ? Colors.black
                      : cs.onSurface.withValues(alpha: 0.82),
                ),
              ),
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
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.card),
                side: BorderSide(
                  color: borderColor,
                  width: a11y.highContrast ? 2 : 1,
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: a11y.highContrast
                      ? Colors.white
                      : cs.surfaceContainerHighest,
                  backgroundImage:
                      (u.avatarUrl != null && u.avatarUrl!.isNotEmpty)
                          ? NetworkImage(u.avatarUrl!)
                          : null,
                  child: (u.avatarUrl == null || u.avatarUrl!.isEmpty)
                      ? Icon(
                          Icons.person_rounded,
                          color: a11y.highContrast
                              ? Colors.black
                              : cs.onSurface.withValues(alpha: 0.75),
                        )
                      : null,
                ),
                title: Text(
                  u.displayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: TextButton(
                  onPressed: () => onAction(u),
                  child: Text(
                    actionLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: a11y.highContrast ? Colors.black : cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
    final a11y = context.watch<AccessibilityController>().settings;

    final mutedColor = a11y.highContrast
        ? Colors.black
        : cs.onSurface.withValues(alpha: 0.72);

    return Center(
      child: Padding(
        padding: AppSpacing.page,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.block_rounded,
              size: 52,
              color: a11y.highContrast
                  ? Colors.black
                  : cs.onSurface.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: a11y.highContrast ? Colors.black : cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: mutedColor
              ),
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