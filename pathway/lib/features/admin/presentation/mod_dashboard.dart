import 'package:flutter/material.dart';
import 'package:pathway/core/widgets/widgets.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import 'mod_decision_log.dart'; 

class ModeratorDashboard extends StatefulWidget {
  const ModeratorDashboard({super.key});

  @override
  State<ModeratorDashboard> createState() => _ModeratorDashboardState();
}

class _ModeratorDashboardState extends State<ModeratorDashboard> {
  final _supabase = Supabase.instance.client;

  Stream<List<Map<String, dynamic>>> _getReports() {
    return _supabase
        .schema('pathway')
        .from('user_reports')
        .stream(primaryKey: ['report_id']) 
        .order('created_at');
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

  /// moderation dialog
  Future<void> _openModerationDialog(Map<String, dynamic> report) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ModerationDecisionDialog(report: report),
    );

    if (result == true && mounted) {
      _showSnackBar("Action updated successfully", isError: false);
    }
  }

  Future<void> _updateReportStatus(Map<String, dynamic> report, String newStatus) async {
    final dynamic reportId = report['report_id'];
    if (reportId == null) return;

    try {
      await _supabase
          .schema('pathway')
          .from('user_reports')
          .update({'status': newStatus.toLowerCase()})
          .eq('report_id', reportId);

      if (mounted) {
        _showSnackBar("Report marked as ${newStatus.toLowerCase()}", isError: false);
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
      length: 2,
      child: Scaffold(
        appBar: PathwayAppBar(
          height: 100,
          centertitle: false,
          title: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('Admin Moderation', style: theme.appBarTheme.titleTextStyle),
          ),
        ),
        body: Column(
          children: [
            Material(
              color: theme.scaffoldBackgroundColor,
              child: const TabBar(
                indicatorColor: Colors.blueAccent,
                labelColor: Colors.blueAccent,
                tabs: [Tab(text: 'Pending'), Tab(text: 'History')],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getReports(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                  
                  final reports = snapshot.data ?? [];

                  return TabBarView(
                    children: [
                      _buildReportList(reports, isHistory: false),
                      _buildReportList(reports, isHistory: true),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("No reports found", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildReportList(List<Map<String, dynamic>> reports, {required bool isHistory}) {
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
    final String status = report['status']?.toString().toLowerCase() ?? 'pending';
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
                    style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 12),
            Text("${report['reason']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text("${report['description'] ?? 'No details provided.'}", 
              style: const TextStyle(color: Colors.black54, fontSize: 14)),
            const SizedBox(height: 8),
            Text("Type: ${report['target_type'] ?? 'Unknown'}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
                        backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
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
                  label: const Text("Review / Restore"),
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
      case 'pending': color = Colors.orange; break;
      case 'resolved': color = Colors.red; break;
      case 'dismissed': color = Colors.green; break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}