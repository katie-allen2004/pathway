import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/features/venues/data/venue_model.dart';
import '/features/venues/presentation/widgets/venue_card.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _allVenues = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVenues();
  }

  ///gets  data from Supabase
  Future<void> _loadVenues() async {
    try {
      final data = await _supabase
          .schema('pathway')
          .from('venues')
          .select();

      setState(() {
        _allVenues = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading venues: $e');
      setState(() => _isLoading = false);
    }
  }

  /// the is_saved status in Supabase
  Future<void> _handleFavoriteToggle(VenueModel venue) async {
    //Calculate the new status (flip current)
    final bool currentStatus = venue.isSaved ?? false;
    final bool newStatus = !currentStatus;

    debugPrint("Changing ${venue.name} heart from $currentStatus to $newStatus");

    try {
      //  update Supabase
      await _supabase
          .schema('pathway')
          .from('venues')
          .update({'is_saved': newStatus})
          .eq('venue_id', venue.id);

      //  re-fetch data so the UI reflects the change
      await _loadVenues();
      debugPrint("Database sync complete.");
    } catch (e) {
      debugPrint('Favorite Toggle Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating favorite: $e")),
        );
      }
    }
  }

  ///a new venue
  Future<void> _showAddVenueDialog() async {
    final nameController = TextEditingController();
    final cityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Venue"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Venue Name")),
            TextField(controller: cityController, decoration: const InputDecoration(labelText: "City")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await _supabase.schema('pathway').from('venues').insert({
                  'name': nameController.text,
                  'city': cityController.text,
                  'is_saved': false, 
                });
                if (mounted) Navigator.pop(context);
                _loadVenues();
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  /// This will Edit name/city
  Future<void> _showEditVenueForm(BuildContext context, Map<String, dynamic> venue) async {
    final nameController = TextEditingController(text: venue['name']);
    final cityController = TextEditingController(text: venue['city']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Venue"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: cityController, decoration: const InputDecoration(labelText: "City")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await _supabase.schema('pathway').from('venues').update({
                'name': nameController.text,
                'city': cityController.text,
              }).eq('venue_id', venue['venue_id']);
              
              if (mounted) Navigator.pop(context);
              _loadVenues();
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  /// this will will delete
  Future<void> _showDeleteConfirmation(BuildContext context, dynamic venueId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Venue?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _supabase.schema('pathway').from('venues').delete().eq('venue_id', venueId);
      _loadVenues();
    }
  }

  /// This is the discovery try: a list of venues: since we have no integrated map for now 
  void _showDiscoveryTray() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 245, 245, 250),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10)),
            ),
            const Text("Discovery", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: _allVenues.length,
                itemBuilder: (context, i) {
                  final venueModel = VenueModel.fromJson(_allVenues[i]);
                  
                  // This print will tell you exactly what's coming from the DB
                  debugPrint("Rendering ${venueModel.name}: isSaved = ${venueModel.isSaved}");

                  return VenueCard(
                    venue: venueModel, 
                    onFavoriteToggle: () => _handleFavoriteToggle(venueModel),
                    onEdit: () => _showEditVenueForm(context, _allVenues[i]), 
                    onDelete: () => _showDeleteConfirmation(context, _allVenues[i]['venue_id']),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: _showAddVenueDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Container(color: Colors.grey[200], child: const Center(child: Text("Map View"))),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                            ),
                            child: const TextField(
                              decoration: InputDecoration(hintText: "Search...", border: InputBorder.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _showDiscoveryTray,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
                            child: const Icon(Icons.explore, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}