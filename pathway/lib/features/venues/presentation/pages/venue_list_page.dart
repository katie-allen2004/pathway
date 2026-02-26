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

  Key _refreshKey = UniqueKey();

  Future<void> _refresh() async {
    setState(() {
      _refreshKey = UniqueKey();
    });
  }

  Future<void> _handleDelete(int venueId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Venue?"),
        content: const Text("This action cannot be undone and will remove the venue from the map."),
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
        await _supabase
            .schema('pathway')
            .from('venues')
            .delete()
            .eq('venue_id', venueId);
            
        _refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Delete Error: $e")),
          );
        }
      }
    }
  }

  void _handleEdit(VenueModel venue) {
    debugPrint("Editing venue: ${venue.name}");
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = _supabase.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFE9ECF7), // match detail page
      appBar: AppBar(
        title: const Text("Discovery", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<VenueModel>>(
          key: _refreshKey,
          future: _repo.fetchAllVenues(), 
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No venues found in your area."));
            }

            final venues = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              itemCount: venues.length,
              itemBuilder: (context, i) {
                final venueData = venues[i];
                final bool isOwner = venueData.createdByUserId == currentUserId;

                return VenueCard(
                  venue: venueData,
                  isOwner: isOwner,
                  onFavoriteToggle: (updatedVenue) async {
                    // update the db background
                    await _repo.toggleSave(updatedVenue.id, venueData.isSaved);
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