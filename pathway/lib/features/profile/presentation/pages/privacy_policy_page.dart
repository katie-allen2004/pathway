import 'package:flutter/material.dart';
import 'package:pathway/core/theme/theme.dart';
import 'package:pathway/core/widgets/widgets.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: PathwayAppBar(
        height: 100,
        centertitle: false,
        title: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Text('Privacy Policy', style: theme.appBarTheme.titleTextStyle),
        ),
      ),
      body: SafeArea(
        child: SelectionArea(
          child: ListView(
            padding: AppSpacing.page,
            children: [
              Text(
                'Effective Date: January 1, 2026',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),

              _PolicySectionCard(
                title: '1. Overview',
                body:
                    'Pathway is committed to protecting your privacy. This policy explains what information we collect, how we use it, and your rights regarding your data.',
              ),

              _PolicySectionCard(
                title: '2. Information We Collect',
                body:
                    'We may collect the following information:\n\n'
                    '• Account information (email address)\n'
                    '• Profile information (display name, avatar)\n'
                    '• Accessibility preferences you choose to share\n'
                    '• Messages and content you submit\n'
                    '• Usage data and interaction logs',
              ),

              _PolicySectionCard(
                title: '3. How We Use Your Information',
                body:
                    'We use your information to:\n\n'
                    '• Provide and improve our services\n'
                    '• Personalize your experience\n'
                    '• Send notifications and updates\n'
                    '• Maintain account security\n'
                    '• Respond to support requests',
              ),

              _PolicySectionCard(
                title: '4. Data Sharing',
                body:
                    'We do not sell your personal data. Information may be shared only when:\n\n'
                    '• Required by law\n'
                    '• Necessary to protect users or prevent abuse\n'
                    '• With service providers that help operate the app',
              ),

              _PolicySectionCard(
                title: '5. Data Security',
                body:
                    'We use secure authentication and database protections to safeguard your information. However, no system is completely secure.',
              ),

              _PolicySectionCard(
                title: '6. Your Rights',
                body:
                    'You may:\n\n'
                    '• Update your profile information\n'
                    '• Request deletion of your account\n'
                    '• Contact us regarding your data',
              ),

              _PolicySectionCard(
                title: '7. Contact Us',
                body:
                    'If you have any questions about this Privacy Policy, please contact us through the Contact Us page.',
              ),

              const SizedBox(height: 8),
              Text(
                'This policy may be updated from time to time. Continued use of the app constitutes acceptance of the revised policy.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _PolicySectionCard extends StatelessWidget {
  final String title;
  final String body;

  const _PolicySectionCard({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: cs.onSurface.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}