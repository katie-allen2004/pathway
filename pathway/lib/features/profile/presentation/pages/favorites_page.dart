import 'package:flutter/material.dart';
import '/features/venues/data/venue_repository.dart';
import '/features/venues/data/venue_model.dart';
import '/features/venues/presentation/widgets/venue_card.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text("Favorites")),
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
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text("No favorites yet.")),
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