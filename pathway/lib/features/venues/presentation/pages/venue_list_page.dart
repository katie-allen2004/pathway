import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/features/venues/data/venue_repository.dart';
import '/features/venues/data/venue_model.dart'; // IMPORTANT: Need this import
import '../widgets/venue_card.dart';

class VenueListPage extends StatefulWidget {
  const VenueListPage({super.key});

  @override
  State<VenueListPage> createState() => _VenueListPageState();
}

class _VenueListPageState extends State<VenueListPage> {
  final VenueRepository _repo = VenueRepository();
  final _supabase = Supabase.instance.client;

  Future<void> _refresh() async {
    setState(() {}); // the FutureBuilder to run again
  }

  //  for Deleting
  Future<void> _handleDelete(dynamic venueId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Venue?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _supabase.schema('pathway').from('venues').delete().eq('venue_id', venueId);
      _refresh();
    }
  }

  void _handleEdit(VenueModel venue) {
    debugPrint("Editing ${venue.name}"); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Discovery")),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<VenueModel>>( // Added  typing
          future: _repo.fetchVenues(),
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

            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, i) {
                final venueData = snapshot.data![i];
                
                return VenueCard(
                  venue: venueData, 
                  onFavoriteToggle: () => _repo.toggleSave(
                    venueData.id, 
                    venueData.isSaved ?? false
                  ).then((_) => _refresh()),
                  onEdit: () => _handleEdit(venueData), 
                  onDelete: () => _handleDelete(venueData.id), 
                );
              },
            );
          },
        ),
      ),
    );
  }
}