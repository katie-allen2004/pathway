import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pathway/core/theme/theme.dart';
import 'package:pathway/core/widgets/widgets.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final _formKey = GlobalKey<FormState>();
  final _messageCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  String _category = 'support';
  bool _sending = false;

  // Initialize database connection
  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _messageCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  // Method: Submit support ticket to database
  Future<void> _submit() async {
    // If validation fails, show errors and return early
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Set sending state to true to disable button and show progress indicator
    setState(() => _sending = true);
    try {
      // Insert new support ticket into 'support_tickets' table
      final userId = supabase.auth.currentUser?.id;
      await supabase
          .schema('pathway')
          .from('support_tickets')
          .insert({
            'user_id': userId,
            'category': _category,
            'message': _messageCtrl.text.trim(),
            'contact': _contactCtrl.text.trim().isEmpty ? null : _contactCtrl.text.trim(),
          });

      // On success, show confirmation and clear form
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent — thanks!')),
      );
      _messageCtrl.clear();
      _contactCtrl.clear();
    } catch (e) {
      // On error, show failure message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Send failed: $e')),
      );
    } finally {
      // Reset sending state to re-enable button
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: PathwayAppBar(
        height: 100,
        centertitle: false,
        title: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Text('Contact us', style: theme.appBarTheme.titleTextStyle),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.page,
          children: [
            Card(
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('How can we help?', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        // When the category changes, update _category and trigger UI update
                        initialValue: _category,
                        items: const [
                          DropdownMenuItem(value: 'support', child: Text('Support')),
                          DropdownMenuItem(value: 'bug', child: Text('Bug report')),
                          DropdownMenuItem(value: 'feature', child: Text('Feature request')),
                          DropdownMenuItem(value: 'other', child: Text('Other')),
                        ],
                        onChanged: (v) => setState(() => _category = v ?? 'support'),
                        decoration: const InputDecoration(labelText: 'Category'),
                      ),
                      const SizedBox(height: 12),
                      // Message field with validation (at least 8 characters)
                      TextFormField(
                        controller: _messageCtrl,
                        minLines: 4,
                        maxLines: 8,
                        validator: (v) => (v == null || v.trim().length < 8) ? 'Please enter at least 8 characters' : null,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Contact field with optional email validation
                      TextFormField(
                        controller: _contactCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Contact email (optional)',
                          hintText: 'you@example.com',
                          border: OutlineInputBorder(),
                        ),
                        // If not empty, must be a valid email format
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final re = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          if (!re.hasMatch(v.trim())) return 'Enter a valid email or leave blank';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Submit button with loading state
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _sending ? null : _submit,
                          child: _sending
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Send message'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}