import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pathway/features/gamification/data/badge_model.dart';
import 'package:pathway/features/gamification/data/badge_tab_data.dart';
import 'package:pathway/features/venues/data/venue_repository.dart';

class BadgesSection extends StatelessWidget {
  const BadgesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final repository = VenueRepository();

    if (userId == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('Not logged in', style: TextStyle(fontSize: 16)),
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
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Failed to load badges',
                style: TextStyle(fontSize: 16),
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
                const Padding(
                  padding: EdgeInsets.only(top: 30),
                  child: Center(
                    child: Text(
                      'No badges found yet.',
                      style: TextStyle(fontSize: 16),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1FF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$earnedCount / $totalCount badges earned',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E2D6B),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF4F67D6)),
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
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1B2559),
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
    final baseColor = _parseHexColor(badge.colorHex) ?? const Color(0xFF9AA8D6);

    return Opacity(
      opacity: isLocked ? 0.72 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          color: isLocked ? const Color(0xFFE9EAF1) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF18295E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    badge.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isLocked ? _lockedText(badge) : _earnedText(badge),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                      color: Color(0xFF18295E),
                    ),
                  ),
                ],
              ),
            ),

            if (isLocked)
              const Padding(
                padding: EdgeInsets.only(left: 8, top: 4),
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.grey,
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
    final displayColor = isLocked ? Colors.grey.shade400 : color;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: displayColor.withOpacity(0.14),
        shape: BoxShape.circle,
        border: Border.all(color: displayColor.withOpacity(0.22), width: 1.8),
      ),
      child: Icon(_iconFromKey(badge.iconKey), color: displayColor, size: 30),
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
