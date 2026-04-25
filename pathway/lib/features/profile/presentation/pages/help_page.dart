import 'package:flutter/material.dart';
import 'package:pathway/core/theme/theme.dart';
import 'package:pathway/core/widgets/widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pathway/core/services/accessibility_controller.dart';


class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  // Manually set list of FAQ items.
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
    final a11y = context.watch<AccessibilityController>().settings;

    final cardColor = a11y.highContrast ? Colors.white : cs.surface;
    final borderColor = a11y.highContrast
        ? Colors.black
        : cs.outline.withValues(alpha: 0.18);

    final mutedTextColor = a11y.highContrast
        ? Colors.black
        : cs.onSurface.withValues(alpha: 0.78);

    final dividerColor = a11y.highContrast
        ? Colors.black
        : cs.outline.withValues(alpha: 0.18);

    return Scaffold(
      appBar: PathwayAppBar(
        height: 100,
        centertitle: false,
        title: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Text(
            'Help', 
            style: theme.appBarTheme.titleTextStyle
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.page,
          children: [
            Text(
              'Frequently asked questions', 
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            // Search field
            TextFormField(
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.search,
                  color: a11y.highContrast ? Colors.black : cs.primary,
                ),
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: mutedTextColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              // When the text changes, update _query and trigger UI update
              onChanged: (v) => setState(() => _query = v),
            ),

            const SizedBox(height: 12),

            // FAQ list (expandable)
            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.card),
                side: BorderSide(
                  color: borderColor,
                  width: a11y.highContrast ? 2 : 1,
                ),
              ),
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // If there are no matching FAQs, show display 'No results found'
                    if (_filteredFaq.isEmpty) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          'No results found', 
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: mutedTextColor,
                          ),
                        ),
                      ),
                    // Otherwise, show the list of matching FAQs as ExpansionTiles
                    ] else ..._filteredFaq.map((f) {
                      return Theme(
                        data: theme.copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          iconColor: a11y.highContrast ? Colors.black : cs.primary,
                          collapsedIconColor:
                              a11y.highContrast ? Colors.black : cs.primary,
                          title: Text(
                            f.q,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 16.0,
                                right: 8.0,
                                bottom: 12.0,
                              ),
                              child: Text(
                                f.a,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: mutedTextColor,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Contact quick actions
            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.card),
                side: BorderSide(
                  color: borderColor,
                  width: a11y.highContrast ? 2 : 1,
                ),
              ),
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact us', 
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.email_rounded,
                        color: a11y.highContrast ? Colors.black : cs.primary,
                      ),
                      title: Text(
                        'Email support',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'kaitlyn.allen01@student.csulb.edu',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: mutedTextColor,
                        ),
                      ),
                      onTap: () {
                        _openMail(
                          'kaitlyn.allen01@student.csulb.edu',
                          'Support request',
                        );
                      },
                    ),

                    Divider(color: dividerColor, height: 1),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.privacy_tip_rounded,
                        color: a11y.highContrast ? Colors.black : cs.primary,
                      ),
                      title: Text(
                        'Privacy policy',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'View privacy policy',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: mutedTextColor,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: a11y.highContrast ? Colors.black : cs.onSurface,
                      ),
                      onTap: () {
                        context.push('/profile/privacy-policy');
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