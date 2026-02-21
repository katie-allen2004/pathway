import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/features/venues/data/venue_repository.dart';
import '/features/venues/data/venue_model.dart';
import '/features/venues/presentation/widgets/venue_card.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _supabase = Supabase.instance.client;
  final _repo = VenueRepository();

  // ✅ Clean state: use models directly
  List<VenueModel> _allVenues = [];
  List<VenueModel> _filteredVenues = [];

  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVenues();
    _searchController.addListener(_runFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVenues() async {
    try {
      final venues = await _repo.fetchVenues();

      setState(() {
        _allVenues = venues;
        _filteredVenues = venues; // default show all
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading venues: $e');
      setState(() => _isLoading = false);
    }
  }

  void _runFilter() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        _filteredVenues = _allVenues;
      } else {
        _filteredVenues = _allVenues.where((v) {
          final name = v.name.toLowerCase();
          final address = (v.addressLine1 ?? '').toLowerCase();
          return name.contains(query) || address.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _handleFavoriteToggle(VenueModel venue) async {
    // ✅ use repository helper (less repeated code)
    await _repo.toggleSave(venue.id, venue.isSaved);
    await _loadVenues();
  }

  Future<void> _showAddVenueDialog() async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();

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
              controller: addressController,
              decoration: const InputDecoration(labelText: "Address"),
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
              if (nameController.text.trim().isEmpty) return;

              final navigator = Navigator.of(context);

              await _supabase.from('venues').insert({
                'name': nameController.text.trim(),
                'address': addressController.text.trim(),
              });

              if (!mounted) return;
              navigator.pop();
              await _loadVenues();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditVenueForm(BuildContext context, VenueModel venue) async {
    final nameController = TextEditingController(text: venue.name);
    final addressController = TextEditingController(text: venue.addressLine1 ?? '');

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
              controller: addressController,
              decoration: const InputDecoration(labelText: "Address"),
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
              final navigator = Navigator.of(context);

              // ✅ FIX: this must be UPDATE, not INSERT
              await _supabase.from('venues').update({
                'name': nameController.text.trim(),
                'address': addressController.text.trim(),
              }).eq('id', venue.id);

              if (!mounted) return;
              navigator.pop();
              await _loadVenues();
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, String venueId) async {
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
      await _supabase.from('venues').delete().eq('id', venueId);
      if (!mounted) return;
      await _loadVenues();
    }
  }

  void _showDiscoveryTray() {
    void Function()? syncListener;

    final sheetFuture = showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            syncListener = () {
              if (mounted) setModalState(() {});
            };
            _searchController.addListener(syncListener!);

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
                              final v = _filteredVenues[i];
                              return VenueCard(
                                venue: v,
                                onFavoriteToggle: () async {
                                  await _handleFavoriteToggle(v);
                                  setModalState(() {});
                                },
                                onEdit: () async {
                                  await _showEditVenueForm(context, v);
                                  setModalState(() {});
                                },
                                onDelete: () async {
                                  await _showDeleteConfirmation(context, v.id);
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

    sheetFuture.whenComplete(() {
      if (syncListener != null) {
        _searchController.removeListener(syncListener!);
      }
    });
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
                                hintText: "Search venue or address...",
                                border: InputBorder.none,
                                icon: Icon(Icons.search, color: Colors.deepPurple),
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