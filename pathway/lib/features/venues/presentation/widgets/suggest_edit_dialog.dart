import 'package:flutter/material.dart';
import 'package:pathway/features/venues/data/venue_repository.dart';

class SuggestEditDialog extends StatefulWidget {
  final int venueId;
  final VenueRepository repository;

  const SuggestEditDialog({
    super.key,
    required this.venueId,
    required this.repository,
  });

  @override
  State<SuggestEditDialog> createState() => _SuggestEditDialogState();
}

class _SuggestEditDialogState extends State<SuggestEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();

  String _selectedField = 'venue_name';
  bool _isSubmitting = false;

  static const Map<String, String> _fieldLabels = {
    'venue_name': 'Venue Name',
    'address': 'Address',
    'description': 'Description',
    'city': 'City',
    'state': 'State',
    'category': 'Category',
    'operating_hours': 'Operating Hours',
  };

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.repository.submitVenueSuggestion(
        venueId: widget.venueId,
        fieldName: _selectedField,
        proposedValue: _valueController.text,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit suggestion: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Suggest an Edit',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedField,
                decoration: const InputDecoration(
                  labelText: 'Field',
                  border: OutlineInputBorder(),
                ),
                items: _fieldLabels.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedField = value;
                        });
                      },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valueController,
                enabled: !_isSubmitting,
                maxLines:
                    _selectedField == 'description' ||
                        _selectedField == 'accessibility_notes'
                    ? 4
                    : 1,
                decoration: const InputDecoration(
                  labelText: 'Suggested Value',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a suggested value.';
                  }
                  if (value.trim().length < 2) {
                    return 'Suggestion is too short.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Your suggestion will be reviewed before any changes are applied.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.black54,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}
