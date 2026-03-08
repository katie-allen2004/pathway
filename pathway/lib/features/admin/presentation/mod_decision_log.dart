import 'package:flutter/material.dart';
import '/features/venues/data/venue_repository.dart'; 

class ModerationDecisionDialog extends StatefulWidget {
  final Map<String, dynamic> report;

  const ModerationDecisionDialog({super.key, required this.report});

  @override
  State<ModerationDecisionDialog> createState() => _ModerationDecisionDialogState();
}

class _ModerationDecisionDialogState extends State<ModerationDecisionDialog> {
  final _repo = VenueRepository();
  bool _isLoading = true;
  String _reviewContent = "";
  bool _isProcessingAction = false;

  @override
  void initState() {
    super.initState();
    _loadReviewText();
  }

  Future<void> _loadReviewText() async {
    final targetIdStr = widget.report['target_id']?.toString() ?? '0';
    final reviewId = int.tryParse(targetIdStr) ?? 0;
    
    final text = await _repo.fetchReportedReviewText(reviewId);
    
    if (mounted) {
      setState(() {
        _reviewContent = text;
        _isLoading = false;
      });
    }
  }

  /// handle to dismiss report or hide content 
  Future<void> _handleAction(bool shouldHide) async {
    setState(() => _isProcessingAction = true);
    
    final reportId = widget.report['report_id'];
    final targetIdStr = widget.report['target_id']?.toString() ?? '0';
    final reviewId = int.tryParse(targetIdStr) ?? 0;

    try {
      await _repo.resolveAndHideReview(
        reportId: reportId,
        reviewId: reviewId,
        shouldHide: shouldHide,
      );
      
      if (mounted) Navigator.pop(context, true); 
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  /// restores hidden review 
  Future<void> _handleRestore() async {
    setState(() => _isProcessingAction = true);
    
    final reportId = widget.report['report_id'];
    final targetIdStr = widget.report['target_id']?.toString() ?? '0';
    final reviewId = int.tryParse(targetIdStr) ?? 0;

    try {
      await _repo.restoreReview(
        reportId: reportId,
        reviewId: reviewId,
      );
      
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  void _showError(dynamic e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Action failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // determines the current status 
    final String status = widget.report['status'] ?? 'pending';
    final bool isHandled = status == 'resolved' || status == 'dismissed';

    return AlertDialog(
      title: Text(isHandled ? "Revisit Moderation" : "Review Moderation"),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: _isLoading 
        ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Reported Content:", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  _reviewContent,
                  style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 16),
              Text("Reason: ${widget.report['reason']}", 
                style: const TextStyle(fontWeight: FontWeight.w500)),
              if (widget.report['description'] != null && widget.report['description'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text("Details: ${widget.report['description']}", 
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ),
              const SizedBox(height: 8),
              Chip(
                label: Text("Current Status: ${status.toUpperCase()}"),
                backgroundColor: isHandled ? Colors.blue[50] : Colors.orange[50],
                labelStyle: TextStyle(
                  fontSize: 10, 
                  fontWeight: FontWeight.bold,
                  color: isHandled ? Colors.blue[700] : Colors.orange[700]
                ),
              ),
            ],
          ),
      actions: [
        TextButton(
          onPressed: _isProcessingAction ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),

        if (!isHandled) ...[
          // dismiss or hide 
          TextButton(
            onPressed: _isProcessingAction ? null : () => _handleAction(false),
            child: const Text("Dismiss Report"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            onPressed: _isProcessingAction ? null : () => _handleAction(true),
            child: _isProcessingAction 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text("Hide & Resolve"),
          ),
        ] else ...[
          // restore option 
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
            onPressed: _isProcessingAction ? null : () => _handleRestore(),
            child: _isProcessingAction
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text("Restore & Mark Dismissed"),
          ),
        ],
      ],
    );
  }
}