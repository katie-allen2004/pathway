import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pathway/features/auth/data/user_repository.dart'; 

class ReportUserDialog extends StatefulWidget {
  final String reportedUserId;

  const ReportUserDialog({super.key, required this.reportedUserId});

  @override
  State<ReportUserDialog> createState() => _ReportUserDialogState();
}

class _ReportUserDialogState extends State<ReportUserDialog> {
  String? _selectedReason;
  final _commentController = TextEditingController();
  bool _isSubmitting = false; 

  final List<String> _reasons = [
    'Foul Language',
    'Discriminatory Remarks',
    'Harassment',
    'Spam',
    'Other'
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Report User"),
      content: SingleChildScrollView( // small screens 
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // reason 
            ..._reasons.map((r) => RadioListTile<String>(
              title: Text(r),
              value: r,
              groupValue: _selectedReason,
              onChanged: (val) => setState(() => _selectedReason = val),
            )),
            
            const SizedBox(height: 10),
            
            // elab box
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Elaboration",
                hintText: _selectedReason == 'Other' 
                    ? "Please specify the issue..." 
                    : "Additional details (optional)",
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context), 
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          //intercept 
          onPressed: (_selectedReason == null || _isSubmitting) ? null : _submitReport,
          child: _isSubmitting 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text("Submit"),
        ),
      ],
    );
  }

  Future<void> _submitReport() async {
    setState(() => _isSubmitting = true);
    
    try {
      await context.read<UserRepository>().reportUser(
        reportedUserId: widget.reportedUserId,
        reason: _selectedReason!,
        comment: _commentController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Report submitted successfully.")),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }
}