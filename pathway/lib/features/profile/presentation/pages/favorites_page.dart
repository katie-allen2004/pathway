import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/features/venues/data/venue_repository.dart';
import '/features/venues/data/venue_model.dart';
import '/features/venues/presentation/widgets/venue_card.dart';
import 'package:pathway/core/widgets/widgets.dart';
import 'package:pathway/core/services/accessibility_controller.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final _repo = VenueRepository();
  late Future<List<VenueModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchFavoritedVenues();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _repo.fetchFavoritedVenues();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.watch<AccessibilityController>().settings;

    return Scaffold(
      appBar: PathwayAppBar(
        height: 100,
        centertitle: false,
        title: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Text(
            'Favorites',
            style: theme.appBarTheme.titleTextStyle,
          ),
        ),
      ),
      body: FutureBuilder<List<VenueModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: _refresh,
            child: list.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Icon(
                        Icons.favorite_border_rounded,
                        size: 48,
                        color: a11y.highContrast
                            ? Colors.black
                            : cs.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          "No favorites yet.",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: a11y.highContrast
                                ? Colors.black
                                : cs.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          "Save venues to keep track of places you want to revisit.",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: a11y.highContrast
                                ? Colors.black
                                : cs.onSurface.withValues(alpha: 0.72),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final v = list[i];
                      return VenueCard(
                        venue: v,
                        isOwner: false, // optional
                        onFavoriteToggle: (_) async {
                          await _refresh();
                        },
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}