import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/features/venues/data/venue_repository.dart';
import '/features/venues/data/venue_model.dart';
import '/features/venues/presentation/widgets/venue_card.dart';
import '/core/services/storage_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _supabase = Supabase.instance.client;
  final _repo = VenueRepository();
  final StorageService _storageService = StorageService();

  // --- Data State ---
  List<VenueModel> _allVenues = [];
  List<VenueModel> _filteredVenues = [];
  List<Map<String, dynamic>> _allAvailableTags = [];
  
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(_runFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Targets the 'pathway' schema for all initial data
  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch tags from the pathway schema
      final tagData = await _supabase
          .schema('pathway')
          .from('accessibility_tags')
          .select();

      // 2. Fetch Venues (Ensure VenueRepository also uses .schema('pathway'))
      final venues = await _repo.fetchAllVenues();

      setState(() {
        _allAvailableTags = List<Map<String, dynamic>>.from(tagData);
        _allVenues = venues;
        _filteredVenues = venues;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshVenues() async {
    try {
      final venues = await _repo.fetchAllVenues();
      setState(() {
        _allVenues = venues;
        _runFilter();
      });
    } catch (e) {
      debugPrint('Refresh Error: $e');
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
          final city = (v.city ?? "").toLowerCase();
          final matchesTag = v.tags.any((tag) => tag.toLowerCase().contains(query));
          return name.contains(query) || city.contains(query) || matchesTag;
        }).toList();
      }
    });
  }

  Future<void> _handleFavoriteToggle(VenueModel venue) async {
    try {
      await _repo.toggleSave(venue.id, venue.isSaved);
      await _refreshVenues();
    } catch (e) {
      debugPrint('Favorite Toggle Error: $e');
    }
  }

  Future<void> _handleDelete(int venueId) async {
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
      await _supabase
          .schema('pathway')
          .from('venues')
          .delete()
          .eq('venue_id', venueId);
      _refreshVenues();
    }
  }

  // --- Add Venue Dialog ---

  Future<void> _showAddVenueDialog() async {
    final nameController = TextEditingController();
    final cityController = TextEditingController();
    final zipController = TextEditingController();
    final descController = TextEditingController();
    List<int> selectedTagIds = []; 
    String? uploadedImageName; 
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final bool canSave = !isUploading && nameController.text.trim().isNotEmpty;

          return AlertDialog(
            title: const Text("Add New Venue"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: isUploading ? null : () async {
                      setDialogState(() => isUploading = true);
                      final fileName = await _storageService.pickAndUploadImage();
                      setDialogState(() {
                        uploadedImageName = fileName;
                        isUploading = false;
                      });
                    },
                    child: Container(
                      height: 100, width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.deepPurple.withOpacity(0.1)),
                      ),
                      child: isUploading 
                        ? const Center(child: CircularProgressIndicator())
                        : (uploadedImageName == null 
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [Icon(Icons.add_a_photo, color: Colors.deepPurple), Text("Add Photo", style: TextStyle(fontSize: 12))],
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [Icon(Icons.check_circle, color: Colors.green), Text("Photo Uploaded", style: TextStyle(fontSize: 12))],
                              )),
                    ),
                  ),
                  TextField(
                    controller: nameController, 
                    decoration: const InputDecoration(labelText: "Venue Name"),
                    onChanged: (val) => setDialogState(() {}),
                  ),
                  TextField(controller: cityController, decoration: const InputDecoration(labelText: "City")),
                  TextField(controller: zipController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Zip Code")),
                  TextField(controller: descController, maxLines: 2, decoration: const InputDecoration(labelText: "Description")),
                  const SizedBox(height: 15),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Accessibility Features:", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _allAvailableTags.map((tag) {
                      final id = tag['tag_id'] as int;
                      final isSelected = selectedTagIds.contains(id);
                      return FilterChip(
                        label: Text(tag['tag_name'], style: const TextStyle(fontSize: 11)),
                        selected: isSelected,
                        selectedColor: Colors.deepPurple.withOpacity(0.2),
                        checkmarkColor: Colors.deepPurple,
                        onSelected: (bool selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedTagIds.add(id);
                            } else {
                              selectedTagIds.remove(id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: !canSave ? null : () async {
                  try {
                    // Save to pathway.venues
                    final newVenue = await _supabase
                        .schema('pathway')
                        .from('venues')
                        .insert({
                          'name': nameController.text.trim(),
                          'city': cityController.text.trim(),
                          'zip': zipController.text.trim(), 
                          'description': descController.text.trim(),
                          'image_path': uploadedImageName, 
                          'created_by_user_id': _supabase.auth.currentUser?.id,
                        })
                        .select()
                        .single();

                    // Save to pathway.venue_tags
                    if (selectedTagIds.isNotEmpty) {
                      final tagInserts = selectedTagIds.map((tId) => {
                        'venue_id': newVenue['venue_id'], 
                        'tag_id': tId
                      }).toList();
                      
                      await _supabase
                          .schema('pathway')
                          .from('venue_tags')
                          .insert(tagInserts);
                    }

                    if (context.mounted) Navigator.pop(context);
                    await _refreshVenues();
                  } catch (e) {
                    debugPrint("Error saving venue: $e");
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDiscoveryTray() {
    final String? currentUserId = _supabase.auth.currentUser?.id;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5FA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8), 
                    width: 40, height: 4, 
                    decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10))
                  ),
                  const Text("Discovery", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                              final bool isOwner = v.createdByUserId == currentUserId;
                              return VenueCard(
                                venue: v,
                                isOwner: isOwner,
                                onFavoriteToggle: () async {
                                  await _handleFavoriteToggle(v);
                                  setModalState(() {});
                                },
                                onDelete: isOwner ? () async {
                                  await _handleDelete(v.id);
                                  setModalState(() {});
                                } : null,
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
                Container(color: Colors.grey[200], child: const Center(child: Text('Map coming soon'))),
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
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: "Search venue...", 
                                border: InputBorder.none, 
                                icon: Icon(Icons.search, color: Colors.deepPurple)
                              ),
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