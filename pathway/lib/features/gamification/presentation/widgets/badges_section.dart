import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import 'package:pathway/features/gamification/data/badge_model.dart';
import 'package:pathway/features/gamification/data/badge_tab_data.dart';
import 'package:pathway/features/venues/data/venue_repository.dart';
import 'package:pathway/core/services/accessibility_controller.dart';

class BadgesSection extends StatelessWidget {
  const BadgesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.watch<AccessibilityController>().settings;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    final repository = VenueRepository();

    if (userId == null) {
      return Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Not logged in', 
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              color: a11y.highContrast ? Colors.black : cs.onSurface,
            ),
          ),
        ),
      );
    }

    return FutureBuilder<BadgeTabData>(
      future: repository.fetchBadgeTabData(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Failed to load badges',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                  color: a11y.highContrast ? Colors.black : cs.onSurface,
                ),
              ),
            ),
          );
        }

        final data = snapshot.data ?? BadgeTabData(earned: [], locked: []);
        final totalCount = data.earned.length + data.locked.length;
        final progress = totalCount == 0
            ? 0.0
            : data.earned.length / totalCount;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProgressCard(
                earnedCount: data.earned.length,
                totalCount: totalCount,
                progress: progress,
              ),
              const SizedBox(height: 22),

              if (data.earned.isNotEmpty) ...[
                const _SectionTitle('Earned'),
                const SizedBox(height: 10),
                ...data.earned.map(
                  (b) => _BadgeCard(badge: b, isLocked: false),
                ),
                const SizedBox(height: 20),
              ],

              if (data.locked.isNotEmpty) ...[
                const _SectionTitle('Locked'),
                const SizedBox(height: 10),
                ...data.locked.map((b) => _BadgeCard(badge: b, isLocked: true)),
              ],

              if (data.earned.isEmpty && data.locked.isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 30),
                  child: Center(
                    child: Text(
                      'No badges found yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        color: a11y.highContrast ? Colors.black : cs.onSurface,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int earnedCount;
  final int totalCount;
  final double progress;

  const _ProgressCard({
    required this.earnedCount,
    required this.totalCount,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.watch<AccessibilityController>().settings;

    final cardBg = a11y.highContrast
        ? Colors.white
        : cs.primary.withValues(alpha: 0.10);

    final borderColor = a11y.highContrast
        ? Colors.black
        : cs.primary.withValues(alpha: 0.20);

    final textColor = a11y.highContrast ? Colors.black : cs.onSurface;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor,
          width: a11y.highContrast ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$earnedCount / $totalCount badges earned',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: a11y.highContrast
                  ? Colors.white
                  : cs.surface,
              valueColor: AlwaysStoppedAnimation<Color>(
                a11y.highContrast ? Colors.black : cs.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.watch<AccessibilityController>().settings;

    return Text(
      text,
      style: theme.textTheme.titleMedium?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: a11y.highContrast ? Colors.black : cs.onSurface,
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final BadgeModel badge;
  final bool isLocked;

  const _BadgeCard({required this.badge, required this.isLocked});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.watch<AccessibilityController>().settings;

    final baseColor = _parseHexColor(badge.colorHex) ?? cs.primary;

    final cardColor = a11y.highContrast
        ? Colors.white
        : (isLocked ? cs.surfaceContainerHighest : cs.surface);

    final borderColor = a11y.highContrast
        ? Colors.black
        : cs.outline.withValues(alpha: 0.18);

    final titleColor = a11y.highContrast ? Colors.black : cs.onSurface;
    final bodyColor = a11y.highContrast
        ? Colors.black
        : cs.onSurface.withValues(alpha: 0.76);

    return Opacity(
      opacity: isLocked ? 0.78 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: borderColor,
            width: a11y.highContrast ? 2 : 1,
          ),
          boxShadow: a11y.highContrast
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BadgeIconBubble(
              badge: badge,
              color: baseColor,
              isLocked: isLocked,
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badge.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    badge.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      color: bodyColor,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isLocked ? _lockedText(badge) : _earnedText(badge),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                      color: titleColor,
                    ),
                  ),
                ],
              ),
            ),

            if (isLocked)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: a11y.highContrast
                      ? Colors.black
                      : cs.onSurface.withValues(alpha: 0.55),
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _earnedText(BadgeModel badge) {
    switch (badge.code) {
      case 'first_review':
        return "You've taken the first step toward helping others!";
      case 'five_reviews':
        return "Your reviews are building real momentum in the community.";
      case 'ten_reviews':
        return "You're becoming a trusted voice in Pathway.";
      case 'community_helper':
        return "Your contributions are helping others in the community.";
      default:
        return "You've unlocked another milestone in Pathway.";
    }
  }

  static String _lockedText(BadgeModel badge) {
    switch (badge.code) {
      case 'five_reviews':
        return "You're building momentum with your reviews.";
      case 'ten_reviews':
        return "Keep contributing to reach this milestone.";
      case 'community_helper':
        return "Write 15 reviews to unlock this badge.";
      default:
        return "Keep contributing to unlock this milestone.";
    }
  }

  static Color? _parseHexColor(String? hex) {
    if (hex == null) return null;
    var cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) cleaned = 'FF$cleaned';
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return null;
    return Color(value);
  }
}

class _BadgeIconBubble extends StatelessWidget {
  final BadgeModel badge;
  final Color color;
  final bool isLocked;

  const _BadgeIconBubble({
    required this.badge,
    required this.color,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    final a11y = context.watch<AccessibilityController>().settings;

    final displayColor = a11y.highContrast
        ? Colors.black
        : (isLocked ? Colors.grey.shade500 : color);

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: a11y.highContrast
            ? Colors.white
            : displayColor.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(
          color: a11y.highContrast
              ? Colors.black
              : displayColor.withValues(alpha: 0.22),
          width: 1.8,
        ),
      ),
      child: Icon(
        _iconFromKey(badge.iconKey), 
        color: displayColor, 
        size: 30
      ),
    );
  }

  static IconData _iconFromKey(String? key) {
    switch (key) {
      case 'badge_pathfinder':
        return Icons.emoji_events_rounded;
      case 'badge_explorer':
        return Icons.explore_rounded;
      case 'badge_community':
        return Icons.favorite_rounded;
      default:
        return Icons.star_rounded;
    }
  }
}
