import 'package:flutter/material.dart';
import 'package:pathway/core/theme/theme.dart';
import 'package:pathway/core/widgets/widgets.dart';
import 'package:url_launcher/url_launcher.dart';


class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  // Manually set list of FAQ items. May be extended to backend in the future.
  final List<_FaqItem> _faqItems = [
    _FaqItem(
      q: 'How do I change my profile photo?',
      a: 'Open Edit profile → tap the camera icon on your avatar and choose a photo.',
    ),
    _FaqItem(
      q: 'How do I block or mute someone?',
      a: 'Go to Settings → Blocked & muted. From there you can unblock or unmute users.',
    ),
    _FaqItem(
      q: 'How do I delete my account?',
      a: 'Go to Settings → Security → Delete account. This will permanently remove your data.',
    ),
    _FaqItem(
      q: 'How do I report a problem with a venue?',
      a: 'Open the venue page, tap Report (flag) and fill out the form. We review reports manually.',
    ),
  ];

  // Initialize _query as an empty string
  String _query = '';

  // Method: filter _faqItems based on _query
  List<_FaqItem> get _filteredFaq {
    // If quyery is empty, return all items
    if (_query.trim().isEmpty) return _faqItems;

    // Otherwise, filter items where question or answer contains the query (case-insensitive)
    final q = _query.toLowerCase();
    return _faqItems.where((f) {
      return f.q.toLowerCase().contains(q) || f.a.toLowerCase().contains(q);
    }).toList();
  }

  // Method: open email client with pre-filled recipient and subject
   Future<void> _openMail(String to, String subject) async {
     final uri = Uri(
       scheme: 'mailto',
       path: to,
       queryParameters: {'subject': subject},
     );
     if (!await launchUrl(uri)) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open email client.')));
     }
   }

  @override
  Widget build(BuildContext context) {
    // Set theme and color scheme for easy access
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: PathwayAppBar(
        height: 100,
        centertitle: false,
        title: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Text('Help', style: theme.appBarTheme.titleTextStyle),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.page,
          children: [
            Text('Frequently asked questions', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),

            // Search field
            TextFormField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search FAQs or keywords',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              // When the text changes, update _query and trigger UI update
              onChanged: (v) => setState(() => _query = v),
            ),

            const SizedBox(height: 12),

            // FAQ list (expandable)
            Card(
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // If there are no matching FAQs, show display 'No results found'
                    if (_filteredFaq.isEmpty) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: Text('No results found', style: theme.textTheme.bodyMedium),
                      ),
                    // Otherwise, show the list of matching FAQs as ExpansionTiles
                    ] else ..._filteredFaq.map((f) {
                      return ExpansionTile(
                        title: Text(f.q, style: theme.textTheme.bodyMedium),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0, right: 8.0, bottom: 12.0),
                            child: Text(f.a, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.75))),
                          )
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Contact quick actions
            Card(
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Contact us', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.email_rounded),
                      title: const Text('Email support'),
                      subtitle: Text('kaitlyn.allen01@student.csulb.edu', style: theme.textTheme.bodySmall),
                      onTap: () {
                        _openMail('kaitlyn.allen01@student.csulb.edu', 'Support request');
                      },
                    ),

                    const Divider(height: 1),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.privacy_tip_rounded),
                      title: const Text('Privacy policy'),
                      subtitle: const Text('View privacy policy'),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open privacy policy (TODO)')));
                      },
                    ),
                  ],
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

// Simple data class to represent a FAQ item with a question and answer
class _FaqItem {
  final String q;
  final String a;
  const _FaqItem({required this.q, required this.a});
}