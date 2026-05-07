import 'package:flutter/material.dart';
import 'package:pathway/core/widgets/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import 'mod_decision_log.dart';
import 'package:pathway/core/services/accessibility_controller.dart';
import 'package:pathway/core/theme/theme.dart';
import 'package:pathway/features/venues/data/venue_repository.dart';

class ModeratorDashboard extends StatefulWidget {
  const ModeratorDashboard({super.key});

  @override
  State<ModeratorDashboard> createState() => _ModeratorDashboardState();
}

class _ModeratorDashboardState extends State<ModeratorDashboard> {
  final _supabase = Supabase.instance.client;

  Widget _buildSuggestionStream({required bool isHistory}) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getVenueSuggestions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allSuggestions = snapshot.data ?? [];
        final filtered = allSuggestions.where((s) {
          final status = s['status']?.toString().toLowerCase() ?? 'pending';
          return isHistory ? (status != 'pending') : (status == 'pending');
        }).toList();

        if (filtered.isEmpty) {
          return _buildEmptyState(
            isHistory
                ? "No suggestion history found"
                : "No pending suggestions",
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, i) =>
              _buildSuggestionCard(filtered[i], isHistory),
        );
      },
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion, bool isHistory) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.watch<AccessibilityController>().settings;

    final status = suggestion['status']?.toString().toLowerCase() ?? 'pending';
    final venueId = suggestion['venue_id'];
    final fieldName = suggestion['field_name']?.toString() ?? 'Unknown';
    final proposedValue = suggestion['proposed_value']?.toString() ?? '';
    final createdAt = suggestion['created_at']?.toString();

    final cardColor = a11y.highContrast ? Colors.white : cs.surface;
    final borderColor = a11y.highContrast
        ? Colors.black
        : cs.outline.withValues(alpha: 0.18);

    final mutedColor = a11y.highContrast
        ? Colors.black
        : cs.onSurface.withValues(alpha: 0.72);

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: borderColor,
          width: a11y.highContrast ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isHistory
                      ? "Past suggestion decision"
                      : "New venue suggestion",
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isHistory
                        ? mutedColor
                        : (a11y.highContrast ? Colors.black : Colors.orange),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Venue ID: $venueId",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              "Field: ${_prettySuggestionField(fieldName)}",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: a11y.highContrast ? Colors.black : cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Suggested value:",
              style: theme.textTheme.labelMedium?.copyWith(
                color: mutedColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              proposedValue.isEmpty ? 'No value provided' : proposedValue,
              style: theme.textTheme.bodyMedium,
            ),
            if (createdAt != null) ...[
              const SizedBox(height: 8),
              Text(
                "Submitted: $createdAt",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: mutedColor,
                ),
              ),
            ],
            Divider(
              height: 24,
              color: a11y.highContrast
                  ? Colors.black
                  : cs.outline.withValues(alpha: 0.18),
            ),
            if (!isHistory) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectSuggestion(suggestion),
                      child: const Text("Reject"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approveSuggestion(suggestion),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            a11y.highContrast ? Colors.black : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Approve"),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _prettySuggestionField(String field) {
    switch (field) {
      case 'venue_name':
        return 'Venue Name';
      case 'address':
        return 'Address';
      case 'description':
        return 'Description';
      case 'phone_number':
        return 'Phone Number';
      case 'website_url':
        return 'Website URL';
      case 'accessibility_notes':
        return 'Accessibility Notes';
      default:
        return field;
    }
  }

  Stream<List<Map<String, dynamic>>> _getVenueSuggestions() {
    return _supabase
        .schema('pathway')
        .from('venue_suggestions')
        .stream(primaryKey: ['suggestion_id'])
        .order('created_at');
  }

  Stream<List<Map<String, dynamic>>> _getReports() {
    return _supabase
        .schema('pathway')
        .from('user_reports')
        .stream(primaryKey: ['report_id'])
        .order('created_at');
  }

  Stream<List<Map<String, dynamic>>> _getAllVenues() {
    return _supabase
        .schema('pathway')
        .from('venues')
        .stream(primaryKey: ['venue_id'])
        .order('created_at');
  }

  Future<void> _approveSuggestion(Map<String, dynamic> suggestion) async {
    final suggestionId = suggestion['suggestion_id'];
    if (suggestionId == null) return;

    try {
      await _supabase.rpc(
        'approve_venue_suggestion',
        params: {'p_suggestion_id': suggestionId},
      );

      if (mounted) {
        _showSnackBar("Suggestion approved successfully!", isError: false);
      }
    } catch (e) {
      debugPrint("Approve suggestion error: $e");
      if (mounted) {
        _showSnackBar("Failed to approve suggestion.", isError: true);
      }
    }
  }

  Future<void> _rejectSuggestion(Map<String, dynamic> suggestion) async {
    final suggestionId = suggestion['suggestion_id'];
    if (suggestionId == null) return;

    try {
      await _supabase.rpc(
        'reject_venue_suggestion',
        params: {'p_suggestion_id': suggestionId},
      );

      if (mounted) {
        _showSnackBar("Suggestion rejected successfully!", isError: false);
      }
    } catch (e) {
      debugPrint("Reject suggestion error: $e");
      if (mounted) {
        _showSnackBar("Failed to reject suggestion.", isError: true);
      }
    }
  }

  Future<String> _getDisplayName(String userId) async {
    try {
      final data = await _supabase
          .schema('pathway')
          .from('profiles')
          .select('display_name')
          .eq('user_id', userId)
          .maybeSingle();
      return data?['display_name'] ?? 'Unknown User';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _openModerationDialog(Map<String, dynamic> report) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ModerationDecisionDialog(report: report),
    );

    if (result == true && mounted) {
      _showSnackBar("Action updated successfully", isError: false);
    }
  }

  Future<void> _handleVenueAction(
    Map<String, dynamic> venue,
    String status,
  ) async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.read<AccessibilityController>().settings;

    final notesController = TextEditingController();

    if (status == 'rejected') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.card),
            side: BorderSide(
              color: a11y.highContrast
                  ? Colors.black
                  : cs.outline.withValues(alpha: 0.2),
              width: a11y.highContrast ? 2 : 1,
            ),
          ),
          title: Text(
            "Reject ${venue['name']}",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextField(
            controller: notesController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText:
                  "Reason for rejection (e.g. duplicate, blurry photo)...",
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: a11y.highContrast ? Colors.black : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                "Confirm Rejection",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    try {
      await _supabase
          .schema('pathway')
          .from('venues')
          .update({
            'status': status,
            'moderator_notes': notesController.text.trim(),
          })
          .eq('venue_id', venue['venue_id']);

      if (mounted) {
        _showSnackBar("Venue $status successfully!", isError: false);
      }
    } catch (e) {
      debugPrint("Update Error: $e");
      _showSnackBar("Failed to update venue.", isError: true);
    }
  }

  Future<void> _updateReportStatus(
    Map<String, dynamic> report,
    String newStatus,
  ) async {
    final dynamic reportId = report['report_id'];
    if (reportId == null) return;

    try {
      await _supabase
          .schema('pathway')
          .from('user_reports')
          .update({'status': newStatus.toLowerCase()})
          .eq('report_id', reportId);

      if (mounted) {
        _showSnackBar(
          "Report marked as ${newStatus.toLowerCase()}",
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) _showSnackBar("Update failed", isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    final a11y = context.read<AccessibilityController>().settings;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError 
          ? (a11y.highContrast ? Colors.black : Colors.redAccent)
          : (a11y.highContrast ? Colors.black : Colors.green),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
      length: 7, // tabs
      child: Scaffold(
        appBar: PathwayAppBar(
          height: 100,
          centertitle: false,
          title: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Admin Moderation',
              style: theme.appBarTheme.titleTextStyle,
            ),
          ),
        ),
        body: Column(
          children: [
            Material(
              color: theme.scaffoldBackgroundColor,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _ModeratorTabs(
                  backgroundColor: tabBg,
                  selectedBackgroundColor: tabSelectedBg,
                  selectedForegroundColor: tabSelectedFg,
                  unselectedForegroundColor: tabUnselectedFg,
                  borderColor: tabBorder,
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildVenueStream(isHistory: false),
                  _buildVenueStream(isHistory: true),
                  _buildSuggestionStream(isHistory: false),
                  _buildSuggestionStream(isHistory: true),
                  _buildReportStream(isHistory: false),
                  _buildReportStream(isHistory: true),
                  _buildFlaggedReviewsStream(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // builds venue
  Widget _buildVenueStream({required bool isHistory}) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getAllVenues(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final allVenues = snapshot.data ?? [];
        final filtered = allVenues.where((v) {
          final s = v['status'] ?? 'pending';
          return isHistory ? (s != 'pending') : (s == 'pending');
        }).toList();

        if (filtered.isEmpty)
          return _buildEmptyState(
            isHistory ? "No history found" : "No pending venues",
          );

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, i) => _buildVenueCard(filtered[i], isHistory),
        );
      },
    );
  }

  //report list
  Widget _buildReportStream({required bool isHistory}) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getReports(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final reports = snapshot.data ?? [];
        return _buildReportList(reports, isHistory: isHistory);
      },
    );
  }

  // Flagged reviews list
  Widget _buildFlaggedReviewsStream() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: VenueRepository().fetchFlaggedReviews(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final flaggedReviews = snapshot.data ?? [];

        if (flaggedReviews.isEmpty) {
          return _buildEmptyState("No flagged reviews");
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Trigger rebuild to refetch data
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: flaggedReviews.length,
            itemBuilder: (context, i) => _buildFlaggedReviewCard(flaggedReviews[i]),
          ),
        );
      },
    );
  }

  Widget _buildFlaggedReviewCard(Map<String, dynamic> review) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.watch<AccessibilityController>().settings;

    final reviewId = review['review_id'];
    final venueName = review['venue_name'] ?? 'Unknown Venue';
    final authorName = review['author_name'] ?? 'Unknown User';
    final rating = review['rating'] ?? 0;
    final reviewText = review['review_text'] ?? '';
    final helpfulCount = review['helpful_count'] ?? 0;
    final outdatedCount = review['outdated_count'] ?? 0;
    final inaccurateCount = review['inaccurate_count'] ?? 0;
    final createdAt = review['created_at']?.toString();

    final cardColor = a11y.highContrast ? Colors.white : cs.surface;
    final borderColor = a11y.highContrast
        ? Colors.red
        : cs.error.withValues(alpha: 0.5);

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: borderColor,
          width: a11y.highContrast ? 2 : 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flag,
                  color: cs.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Flagged Review',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: cs.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Venue and author info
            Text(
              'Venue: $venueName',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Author: $authorName',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    size: 16,
                    color: Colors.amber,
                  );
                }),
                const SizedBox(width: 8),
                if (createdAt != null)
                  Text(
                    createdAt,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Review text
            if (reviewText.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  reviewText,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Vote counts
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _VoteCountChip(
                  icon: Icons.thumb_up,
                  label: 'Helpful',
                  count: helpfulCount,
                  color: Colors.green,
                ),
                _VoteCountChip(
                  icon: Icons.schedule,
                  label: 'Outdated',
                  count: outdatedCount,
                  color: Colors.orange,
                ),
                _VoteCountChip(
                  icon: Icons.report,
                  label: 'Inaccurate',
                  count: inaccurateCount,
                  color: cs.error,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showSnackBar('Review inspection feature coming soon', isError: false);
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('View Full Review'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.primary,
                      side: BorderSide(color: cs.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      _showSnackBar('Review action feature coming soon', isError: false);
                    },
                    icon: const Icon(Icons.gavel, size: 18),
                    label: const Text('Take Action'),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.error,
                      foregroundColor: cs.onError,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState([String message = "No records found"]) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.watch<AccessibilityController>().settings;

    final muted = a11y.highContrast
        ? Colors.black
        : cs.onSurface.withValues(alpha: 0.68);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 64,
            color: a11y.highContrast
                ? Colors.black
                : cs.onSurface.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // venue card
  Widget _buildVenueCard(Map<String, dynamic> venue, bool isHistory) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.watch<AccessibilityController>().settings;

    final status = venue['status'] ?? 'pending';

    final cardColor = a11y.highContrast ? Colors.white : cs.surface;
    final borderColor = a11y.highContrast
        ? Colors.black
        : cs.outline.withValues(alpha: 0.18);

    final mutedColor = a11y.highContrast
        ? Colors.black
        : cs.onSurface.withValues(alpha: 0.72);

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: borderColor,
          width: a11y.highContrast ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isHistory ? "Past decision" : "New venue request",
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isHistory
                        ? mutedColor
                        : (a11y.highContrast ? Colors.black : Colors.orange),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              venue['name'] ?? 'Unnamed',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              "${venue['city'] ?? ''}",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: mutedColor,
              ),
            ),

            if (isHistory && venue['moderator_notes'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: a11y.highContrast
                      ? Colors.white
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: a11y.highContrast
                        ? Colors.black
                        : cs.outline.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  "Notes: ${venue['moderator_notes']}",
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],

            Divider(
              height: 24,
              color: a11y.highContrast
                  ? Colors.black
                  : cs.outline.withValues(alpha: 0.18),
            ),

            // approve/reject
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleVenueAction(venue, 'rejected'),
                    child: Text(
                      status == 'rejected' ? "Already Rejected" : "Reject",
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleVenueAction(venue, 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          a11y.highContrast ? Colors.black : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      status == 'approved' ? "Already Approved" : "Approve",
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportList(
    List<Map<String, dynamic>> reports, {
    required bool isHistory,
  }) {
    final filtered = reports.where((r) {
      final status = r['status']?.toString().toLowerCase() ?? 'pending';
      return isHistory ? (status != 'pending') : (status == 'pending');
    }).toList();

    if (filtered.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildReportCard(filtered[index]),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.watch<AccessibilityController>().settings;

    final String status =
        report['status']?.toString().toLowerCase() ?? 'pending';
    final bool isPending = status == 'pending';

    final cardColor = a11y.highContrast ? Colors.white : cs.surface;
    final borderColor = a11y.highContrast
        ? Colors.black
        : cs.outline.withValues(alpha: 0.18);

    final mutedColor = a11y.highContrast
        ? Colors.black
        : cs.onSurface.withValues(alpha: 0.72);

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: borderColor,
          width: a11y.highContrast ? 2 : 1,
        ),
      ),
      elevation: a11y.highContrast ? 0 : 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FutureBuilder<String>(
                  future: _getDisplayName(report['reported_user_id'] ?? ''),
                  builder: (context, snapshot) => Text(
                    "REPORTED: ${snapshot.data ?? '...'}",
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: a11y.highContrast ? Colors.black : Colors.blueGrey,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "${report['reason']}",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${report['description'] ?? 'No details provided.'}",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: mutedColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Type: ${report['target_type'] ?? 'Unknown'}",
              style: theme.textTheme.bodySmall?.copyWith(
                color: mutedColor,
              ),
            ),
            Divider(
              height: 32,
              color: a11y.highContrast
                  ? Colors.black
                  : cs.outline.withValues(alpha: 0.18),
            ),

            if (isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateReportStatus(report, 'dismissed'),
                      child: const Text("Dismiss"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _openModerationDialog(report),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            a11y.highContrast ? Colors.black : Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Take Action"),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openModerationDialog(report),
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text("Review Details"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ModeratorTabs extends StatelessWidget {
  final Color backgroundColor;
  final Color selectedBackgroundColor;
  final Color selectedForegroundColor;
  final Color unselectedForegroundColor;
  final Color borderColor;

  const _ModeratorTabs({
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

    const labels = [
      'Venues Pending',
      'Venue History',
      'Suggestions Pending',
      'Suggestion History',
      'Reports Pending',
      'Report History',
      'Flagged Reviews',
    ];

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final currentIndex = controller.index;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(labels.length, (index) {
              final selected = index == currentIndex;

              return Padding(
                padding: EdgeInsets.only(
                  right: index == labels.length - 1 ? 0 : 8,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => controller.animateTo(index),
                  child: AnimatedContainer(
                    duration: a11y.reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          selected ? selectedBackgroundColor : backgroundColor,
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
              );
            }),
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final a11y = context.watch<AccessibilityController>().settings;

    Color color;
    switch (status.toLowerCase()) {
      case 'pending':
        color = a11y.highContrast ? Colors.black : Colors.orange;
        break;
      case 'resolved':
        color = a11y.highContrast ? Colors.black : Colors.red;
        break;
      case 'dismissed':
        color = a11y.highContrast ? Colors.black : Colors.green;
        break;
      case 'approved':
        color = a11y.highContrast ? Colors.black : Colors.blue;
        break;
      case 'rejected':
        color = a11y.highContrast ? Colors.black : Colors.redAccent;
        break;
      default:
        color = a11y.highContrast ? Colors.black : Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: a11y.highContrast ? Colors.white : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Small chip showing vote counts on flagged reviews
class _VoteCountChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _VoteCountChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
