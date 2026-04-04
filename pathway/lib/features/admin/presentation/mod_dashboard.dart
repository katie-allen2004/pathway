import 'package:flutter/material.dart';
import 'package:pathway/core/widgets/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'mod_decision_log.dart';
import 'package:pathway/features/venues/presentation/pages/venue_suggestions_page.dart';

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
    final status = suggestion['status']?.toString().toLowerCase() ?? 'pending';
    final venueId = suggestion['venue_id'];
    final fieldName = suggestion['field_name']?.toString() ?? 'Unknown';
    final proposedValue = suggestion['proposed_value']?.toString() ?? '';
    final createdAt = suggestion['created_at']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  style: TextStyle(
                    color: isHistory ? Colors.grey : Colors.orange,
                    fontWeight: FontWeight.bold,
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
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Suggested value:",
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              proposedValue.isEmpty ? 'No value provided' : proposedValue,
              style: const TextStyle(fontSize: 14),
            ),
            if (createdAt != null) ...[
              const SizedBox(height: 8),
              Text(
                "Submitted: $createdAt",
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
            const Divider(height: 24),
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
                        backgroundColor: Colors.green,
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
    final notesController = TextEditingController();

    if (status == 'rejected') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Reject ${venue['name']}"),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 6, // tabs
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
              child: const TabBar(
                isScrollable: true,
                indicatorColor: Colors.deepPurple,
                labelColor: Colors.deepPurple,
                tabs: [
                  Tab(text: 'Venues Pending'),
                  Tab(text: 'Venue History'),
                  Tab(text: 'Suggestions Pending'),
                  Tab(text: 'Suggestion History'),
                  Tab(text: 'Reports Pending'),
                  Tab(text: 'Report History'),
                ],
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

  Widget _buildEmptyState([String message = "No records found"]) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // venue card
  Widget _buildVenueCard(Map<String, dynamic> venue, bool isHistory) {
    final status = venue['status'] ?? 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  style: TextStyle(
                    color: isHistory ? Colors.grey : Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              venue['name'] ?? 'Unnamed',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              "${venue['city'] ?? ''}",
              style: const TextStyle(color: Colors.grey),
            ),

            if (isHistory && venue['moderator_notes'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Notes: ${venue['moderator_notes']}",
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],

            const Divider(height: 24),

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
                      backgroundColor: Colors.green,
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
    final String status =
        report['status']?.toString().toLowerCase() ?? 'pending';
    final bool isPending = status == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
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
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.bold,
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              "${report['description'] ?? 'No details provided.'}",
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              "Type: ${report['target_type'] ?? 'Unknown'}",
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const Divider(height: 32),

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
                        backgroundColor: Colors.redAccent,
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

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'resolved':
        color = Colors.red;
        break;
      case 'dismissed':
        color = Colors.green;
        break;
      case 'approved':
        color = Colors.blue;
        break;
      case 'rejected':
        color = Colors.redAccent;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
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
