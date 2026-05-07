import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pathway/core/services/accessibility_controller.dart';
import 'package:pathway/features/venues/data/review_model.dart';

/// Visual banner that appears on reviews flagged as potentially outdated or inaccurate
/// Shows when a review has 3+ outdated or inaccurate votes
class FlaggedReviewBanner extends StatelessWidget {
  final ReviewModel review;

  const FlaggedReviewBanner({
    super.key,
    required this.review,
  });

  String _getFlagMessage() {
    final outdated = review.outdatedCount;
    final inaccurate = review.inaccurateCount;
    
    if (outdated >= 3 && inaccurate >= 3) {
      return 'This review has been flagged by the community as potentially outdated and inaccurate';
    } else if (outdated >= 3) {
      return 'This review has been flagged by the community as potentially outdated';
    } else if (inaccurate >= 3) {
      return 'This review has been flagged by the community as potentially inaccurate';
    }
    
    return 'This review has been flagged for review';
  }

  IconData _getFlagIcon() {
    if (review.inaccurateCount >= 3) {
      return Icons.report_problem;
    }
    return Icons.flag_outlined;
  }

  @override
  Widget build(BuildContext context) {
    if (!review.isFlagged) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.watch<AccessibilityController>().settings;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: a11y.highContrast
              ? cs.error
              : cs.error.withValues(alpha: 0.5),
          width: a11y.highContrast ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _getFlagIcon(),
            color: cs.error,
            size: 20,
            semanticLabel: 'Warning',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community Alert',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getFlagMessage(),
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onErrorContainer,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (review.outdatedCount >= 3) ...[
                      _FlagStatChip(
                        icon: Icons.schedule,
                        label: 'Outdated',
                        count: review.outdatedCount,
                        colorScheme: cs,
                        a11y: a11y,
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (review.inaccurateCount >= 3) ...[
                      _FlagStatChip(
                        icon: Icons.report_outlined,
                        label: 'Inaccurate',
                        count: review.inaccurateCount,
                        colorScheme: cs,
                        a11y: a11y,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small chip showing vote count for flagged reviews
class _FlagStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final ColorScheme colorScheme;
  final dynamic a11y;

  const _FlagStatChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.colorScheme,
    required this.a11y,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: colorScheme.error,
          ),
          const SizedBox(width: 4),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

/// Optional credibility indicator badge
/// Shows a simple visual indicator of review credibility score
class ReviewCredibilityIndicator extends StatelessWidget {
  final ReviewModel review;

  const ReviewCredibilityIndicator({
    super.key,
    required this.review,
  });

  String _getCredibilityLabel(int score) {
    if (score >= 75) return 'Highly trusted';
    if (score >= 50) return 'Trusted';
    if (score >= 25) return 'Mixed feedback';
    return 'Low credibility';
  }

  Color _getCredibilityColor(int score, ColorScheme cs) {
    if (score >= 75) return Colors.green.shade700;
    if (score >= 50) return Colors.blue.shade700;
    if (score >= 25) return Colors.orange.shade700;
    return cs.error;
  }

  IconData _getCredibilityIcon(int score) {
    if (score >= 75) return Icons.verified;
    if (score >= 50) return Icons.check_circle_outline;
    if (score >= 25) return Icons.info_outline;
    return Icons.warning_amber_outlined;
  }

  @override
  Widget build(BuildContext context) {
    // Only show if there are votes
    if (review.totalVotes < 3) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
    final score = review.credibilityScore;
    final color = _getCredibilityColor(score, cs);

    return Tooltip(
      message: _getCredibilityLabel(score),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getCredibilityIcon(score),
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              '$score%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
