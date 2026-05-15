import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pathway/core/services/accessibility_controller.dart';
import 'package:pathway/features/venues/data/review_model.dart';
import 'package:pathway/features/venues/data/venue_repository.dart';

/// Vote type enum for type safety
enum ReviewVoteType {
  helpful('helpful', 'Helpful', Icons.thumb_up_outlined, Icons.thumb_up),
  outdated('outdated', 'Outdated', Icons.schedule_outlined, Icons.schedule),
  inaccurate(
    'inaccurate',
    'Inaccurate',
    Icons.report_outlined,
    Icons.report,
  );

  final String value;
  final String label;
  final IconData outlinedIcon;
  final IconData filledIcon;

  const ReviewVoteType(
    this.value,
    this.label,
    this.outlinedIcon,
    this.filledIcon,
  );

  static ReviewVoteType? fromString(String? value) {
    if (value == null) return null;
    for (final type in ReviewVoteType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

/// Interactive voting buttons for review credibility
/// Displays vote counts and allows users to vote (except on their own reviews)
class ReviewVoteButtons extends StatefulWidget {
  final ReviewModel review;
  final bool isOwnReview;
  final VoidCallback? onVoteChanged;

  const ReviewVoteButtons({
    super.key,
    required this.review,
    this.isOwnReview = false,
    this.onVoteChanged,
  });

  @override
  State<ReviewVoteButtons> createState() => _ReviewVoteButtonsState();
}

class _ReviewVoteButtonsState extends State<ReviewVoteButtons> {
  late ReviewModel _currentReview;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentReview = widget.review;
  }

  @override
  void didUpdateWidget(ReviewVoteButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.review.id != widget.review.id) {
      _currentReview = widget.review;
    }
  }

  Future<void> _handleVote(ReviewVoteType voteType) async {
    if (widget.isOwnReview) {
      _showMessage('You cannot vote on your own review');
      return;
    }

    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = VenueRepository();
      final result = await repo.submitReviewVote(
        reviewId: _currentReview.id,
        voteType: voteType.value,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // Refresh vote data
        final voteData = await repo.fetchVoteDataForReview(_currentReview.id);
        
        if (!mounted) return;

        setState(() {
          _currentReview = ReviewModel(
            id: _currentReview.id,
            venueId: _currentReview.venueId,
            userId: _currentReview.userId,
            username: _currentReview.username,
            rating: _currentReview.rating,
            text: _currentReview.text,
            createdAt: _currentReview.createdAt,
            helpfulCount: voteData['helpful_count'] ?? 0,
            outdatedCount: voteData['outdated_count'] ?? 0,
            inaccurateCount: voteData['inaccurate_count'] ?? 0,
            totalVotes: voteData['total_votes'] ?? 0,
            currentUserVote: voteData['current_user_vote'],
          );
        });

        widget.onVoteChanged?.call();
      } else {
        setState(() {
          _errorMessage = result['message']?.toString() ??
              'Failed to submit vote';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.watch<AccessibilityController>().settings;

    final currentVote = ReviewVoteType.fromString(_currentReview.currentUserVote);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: cs.errorContainer,
              borderRadius: BorderRadius.circular(8),
              border: a11y.highContrast
                  ? Border.all(color: cs.error, width: 2)
                  : null,
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: cs.error, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: cs.error,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        Row(
          children: [
            Text(
              'Was this review helpful?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
            if (_currentReview.totalVotes > 0) ...[
              const SizedBox(width: 8),
              Text(
                '${_currentReview.totalVotes} ${_currentReview.totalVotes == 1 ? 'vote' : 'votes'}',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ],
        ),
        
        const SizedBox(height: 8),
        
        if (widget.isOwnReview)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You cannot vote on your own review',
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ReviewVoteType.values.map((voteType) {
              final isSelected = currentVote == voteType;
              final count = _getCountForType(voteType);
              
              return _VoteButton(
                voteType: voteType,
                count: count,
                isSelected: isSelected,
                isSubmitting: _isSubmitting,
                onPressed: () => _handleVote(voteType),
                a11y: a11y,
                colorScheme: cs,
              );
            }).toList(),
          ),
      ],
    );
  }

  int _getCountForType(ReviewVoteType voteType) {
    switch (voteType) {
      case ReviewVoteType.helpful:
        return _currentReview.helpfulCount;
      case ReviewVoteType.outdated:
        return _currentReview.outdatedCount;
      case ReviewVoteType.inaccurate:
        return _currentReview.inaccurateCount;
    }
  }
}

/// Individual vote button widget
class _VoteButton extends StatelessWidget {
  final ReviewVoteType voteType;
  final int count;
  final bool isSelected;
  final bool isSubmitting;
  final VoidCallback onPressed;
  final dynamic a11y;
  final ColorScheme colorScheme;

  const _VoteButton({
    required this.voteType,
    required this.count,
    required this.isSelected,
    required this.isSubmitting,
    required this.onPressed,
    required this.a11y,
    required this.colorScheme,
  });

  Color _getButtonColor() {
    if (!isSelected) {
      return colorScheme.surfaceContainerHighest;
    }
    
    switch (voteType) {
      case ReviewVoteType.helpful:
        return colorScheme.primaryContainer;
      case ReviewVoteType.outdated:
        return colorScheme.tertiaryContainer;
      case ReviewVoteType.inaccurate:
        return colorScheme.errorContainer;
    }
  }

  Color _getTextColor() {
    if (!isSelected) {
      return colorScheme.onSurface.withValues(alpha: 0.7);
    }
    
    switch (voteType) {
      case ReviewVoteType.helpful:
        return colorScheme.onPrimaryContainer;
      case ReviewVoteType.outdated:
        return colorScheme.onTertiaryContainer;
      case ReviewVoteType.inaccurate:
        return colorScheme.onErrorContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = _getButtonColor();
    final textColor = _getTextColor();

    return Material(
      color: buttonColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: isSubmitting ? null : onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: a11y.highContrast && isSelected
                ? Border.all(color: textColor, width: 2)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? voteType.filledIcon : voteType.outlinedIcon,
                size: 16,
                color: textColor,
              ),
              const SizedBox(width: 6),
              Text(
                voteType.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: textColor,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
