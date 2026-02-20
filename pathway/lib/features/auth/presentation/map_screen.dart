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

  // Data State
  List<Map<String, dynamic>> _allVenues = [];
  List<Map<String, dynamic>> _filteredVenues = [];

  // Search Logic
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVenues();
    // This listener ensures that every keystroke updates the master list
    _searchController.addListener(_runFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Grabs raw data from Supabase
  Future<void> _loadVenues() async {
    try {
      final data = await _supabase.schema('pathway').from('venues').select();

      setState(() {
        _allVenues = List<Map<String, dynamic>>.from(data);
        _runFilter(); // Apply search filter immediately to new data
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading venues: $e');
      setState(() => _isLoading = false);
    }
  }

  ///  Logic to narrow down venues based on name or city
  void _runFilter() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        _filteredVenues = _allVenues;
      } else {
        _filteredVenues = _allVenues.where((venue) {
          final String name = (venue['name'] ?? "").toString().toLowerCase();
          final String city = (venue['city'] ?? "").toString().toLowerCase();
          return name.contains(query) || city.contains(query);
        }).toList();
      }
    });
  }

  /// Toggle Favorite Status
  Future<void> _handleFavoriteToggle(VenueModel venue) async {
    final bool newStatus = !venue.isSaved;
    try {
      await _supabase
          .schema('pathway')
          .from('venues')
          .update({'is_saved': newStatus})
          .eq('venue_id', venue.id);

      await _loadVenues(); // Refresh data
    } catch (e) {
      debugPrint('Favorite Toggle Error: $e');
    }
  }

  /// Create New Venue
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
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Venue Name"),
            ),
            TextField(
              controller: cityController,
              decoration: const InputDecoration(labelText: "City"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
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

  /// Update Existing Venue
  Future<void> _showEditVenueForm(
    BuildContext context,
    Map<String, dynamic> venue,
  ) async {
    final nameController = TextEditingController(text: venue['name']);
    final cityController = TextEditingController(text: venue['city']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Venue"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: cityController,
              decoration: const InputDecoration(labelText: "City"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _supabase
                  .schema('pathway')
                  .from('venues')
                  .update({
                    'name': nameController.text,
                    'city': cityController.text,
                  })
                  .eq('venue_id', venue['venue_id']);

              if (mounted) Navigator.pop(context);
              _loadVenues();
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  ///  Delete Venue
  Future<void> _showDeleteConfirmation(
    BuildContext context,
    dynamic venueId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Venue?"),
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
      await _supabase
          .schema('pathway')
          .from('venues')
          .delete()
          .eq('venue_id', venueId);
      _loadVenues();
    }
  }

  /// Displays the filtered list
  void _showDiscoveryTray() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // StatefulBuilder allows the tray to update while it is open
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // This function forces the modal to repaint when the search controller changes
            void syncListener() {
              if (mounted) setModalState(() {});
            }

            _searchController.addListener(syncListener);

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 245, 245, 250),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Text(
                    "Discovery",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  // Visual Feedback of Search Results
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _searchController.text.isEmpty
                          ? "Showing all venues"
                          : "Found ${_filteredVenues.length} results for '${_searchController.text}'",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),

                  Expanded(
                    child: _filteredVenues.isEmpty
                        ? const Center(child: Text("No matches found."))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            itemCount: _filteredVenues.length,
                            itemBuilder: (context, i) {
                              final venueModel = VenueModel.fromJson(
                                _filteredVenues[i],
                              );
                              return VenueCard(
                                venue: venueModel,
                                onFavoriteToggle: () async {
                                  await _handleFavoriteToggle(venueModel);
                                  setModalState(() {});
                                },
                                onEdit: () async {
                                  await _showEditVenueForm(
                                    context,
                                    _filteredVenues[i],
                                  );
                                  await _loadVenues(); // <— add
                                  setModalState(
                                    () {},
                                  ); // <— keep (now runs after data refresh)
                                },

                                onDelete: () async {
                                  await _showDeleteConfirmation(
                                    context,
                                    _filteredVenues[i]['venue_id'],
                                  );
                                  await _loadVenues(); // <— add
                                  setModalState(() {});
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
                Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Text('Map coming soon — Discovery tray is active'),
                  ),
                ),
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
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 8),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: "Search venue or city...",
                                border: InputBorder.none,
                                icon: Icon(
                                  Icons.search,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _showDiscoveryTray,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Colors.deepPurple,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.explore,
                              color: Colors.white,
                            ),
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
