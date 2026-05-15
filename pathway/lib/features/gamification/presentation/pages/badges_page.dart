import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pathway/features/gamification/presentation/widgets/badges_section.dart';
import 'package:pathway/core/widgets/widgets.dart';
import 'package:pathway/core/services/accessibility_controller.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a11y = context.watch<AccessibilityController>().settings;

    return Scaffold(
      appBar: PathwayAppBar(
        height: 100,
        centertitle: false,
        title: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Text(
            'Badges',
            style: theme.appBarTheme.titleTextStyle,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: const SingleChildScrollView(
              child: BadgesSection(),
            ),
          ),
        ),
      ),
    );
  }
}