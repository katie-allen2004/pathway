import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/features/venues/data/venue_repository.dart';
import '/features/venues/data/venue_model.dart';
import '../widgets/venue_card.dart';

class VenueListPage extends StatefulWidget {
  const VenueListPage({super.key});

  @override
  State<VenueListPage> createState() => _VenueListPageState();
}

class _VenueListPageState extends State<VenueListPage> {
  final VenueRepository _repo = VenueRepository();
  final _supabase = Supabase.instance.client;

  // Key to force FutureBuilder to reload
  Key _refreshKey = UniqueKey();

  Future<void> _refresh() async {
    setState(() {
      _refreshKey = UniqueKey();
    });
  }

  /// Handles deletion using the integer venue_id
  Future<void> _handleDelete(int venueId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Venue?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Ensure you use your specific schema if required
        await _supabase
            .from('venues')
            .delete()
            .eq('venue_id', venueId); // venueId is int
        _refresh();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Delete Error: $e")),
        );
      }
    }
  }

  void _handleEdit(VenueModel venue) {
    // Navigation to edit page would go here
    debugPrint("Editing venue ID: ${venue.id}");
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = _supabase.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Discovery"),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<VenueModel>>(
          key: _refreshKey,
          // Updated to match the method name in your new Repository
          future: _repo.fetchAllVenues(), 
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No venues found"));
            }

            final venues = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: venues.length,
              itemBuilder: (context, i) {
                final venueData = venues[i];
                // Ownership check (assuming created_by_user_id is a UUID String)
                final bool isOwner = venueData.createdByUserId == currentUserId;

                return VenueCard(
                  venue: venueData,
                  isOwner: isOwner,
                  onFavoriteToggle: () async {
                    // ID is an int, isSaved is a bool. Perfect.
                    await _repo.toggleSave(venueData.id, venueData.isSaved);
                    _refresh();
                  },
                  onEdit: isOwner ? () => _handleEdit(venueData) : null,
                  onDelete: isOwner ? () => _handleDelete(venueData.id) : null,
                );
              },
            );
          },
        ),
      ),
    );
  }
}