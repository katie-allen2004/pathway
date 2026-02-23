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
  final StorageService _storageService = StorageService();

  // --- data State ---
  List<Map<String, dynamic>> _allVenues = [];
  List<Map<String, dynamic>> _filteredVenues = [];
  List<Map<String, dynamic>> _allAvailableTags = []; 

  // --- search Logic ---
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
      final venueData = await _supabase
          .schema('pathway')
          .from('venues')
          .select('''
        *,
        venue_tags (
          accessibility_tags (
            tag_name
          )
        ),
        venue_reviews (
          rating,
          review_text
        )
      ''');

      final tagData = await _supabase
          .schema('pathway')
          .from('accessibility_tags')
          .select();

      setState(() {
        _allVenues = List<Map<String, dynamic>>.from(venueData);
        _allAvailableTags = List<Map<String, dynamic>>.from(tagData);
        _runFilter();
      final venues = await _repo.fetchVenues();

      setState(() {
        _allVenues = venues;
        _filteredVenues = venues; // default show all
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _runFilter() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        _filteredVenues = _allVenues;
      } else {
        _filteredVenues = _allVenues.where((venueMap) {
          final venue = VenueModel.fromJson(venueMap);
          final String name = (venue.name ?? "").toLowerCase();
          final String city = (venue.city ?? "").toLowerCase();
          
          final bool matchesTag = venue.tags.any(
            (tag) => tag.toLowerCase().contains(query)
          );

          return name.contains(query) || city.contains(query) || matchesTag;
        _filteredVenues = _allVenues.where((v) {
          final name = v.name.toLowerCase();
          final address = (v.addressLine1 ?? '').toLowerCase();
          return name.contains(query) || address.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _handleFavoriteToggle(VenueModel venue) async {
    final bool newStatus = !(venue.isSaved ?? false);
    try {
      await _supabase
          .schema('pathway')
          .from('venues')
          .update({'is_saved': newStatus})
          .eq('venue_id', venue.id);

      await _loadVenues();
    } catch (e) {
      debugPrint('Favorite Toggle Error: $e');
    }
    // ✅ use repository helper (less repeated code)
    await _repo.toggleSave(venue.id, venue.isSaved);
    await _loadVenues();
  }

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
          return AlertDialog(
            title: const Text("Add New Venue"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 12),
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: "Venue Name")),
                  TextField(controller: cityController, decoration: const InputDecoration(labelText: "City")),
                  TextField(controller: zipController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Zip Code")),
                  TextField(controller: descController, maxLines: 2, decoration: const InputDecoration(labelText: "Description")),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text("Accessibility Features:", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  
                  Wrap(
                    spacing: 8,
                    children: _allAvailableTags.map((tag) {
                      final id = tag['tag_id'] as int;
                      final isSelected = selectedTagIds.contains(id);
                      return FilterChip(
                        label: Text(tag['tag_name'], style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          setDialogState(() {
                            selected ? selectedTagIds.add(id) : selectedTagIds.remove(id);
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
                onPressed: (isUploading || nameController.text.isEmpty) ? null : () async {
                  try {
                    final newVenue = await _supabase.schema('pathway').from('venues').upsert({
                      'name': nameController.text,
                      'city': cityController.text,
                      'zip': zipController.text, 
                      'description': descController.text,
                      'image_path': uploadedImageName, 
                      'created_by_user_id': _supabase.auth.currentUser?.id,
                    }, onConflict: 'venue_id').select().single();

                    final newId = newVenue['venue_id'];

                    if (selectedTagIds.isNotEmpty) {
                      final tagInserts = selectedTagIds.map((tId) => {'venue_id': newId, 'tag_id': tId}).toList();
                      await _supabase.schema('pathway').from('venue_tags').insert(tagInserts);
                    }

                    if (mounted) Navigator.pop(context);
                    _loadVenues();
                  } catch (e) {
                    debugPrint("Save Error: $e");
                  }
                },
                child: const Text("Save Venue"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showEditVenueForm(BuildContext context, Map<String, dynamic> venue) async {
    final nameController = TextEditingController(text: venue['name']);
    final cityController = TextEditingController(text: venue['city']);
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
              await _supabase.schema('pathway').from('venues').update({
                'name': nameController.text,
                'city': cityController.text,
              }).eq('venue_id', venue['venue_id']);
              if (mounted) Navigator.pop(context);
              _loadVenues();
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

  Future<void> _showDeleteConfirmation(BuildContext context, int venueId) async {
  Future<void> _showDeleteConfirmation(BuildContext context, String venueId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Venue?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
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
    final String? currentUserId = _supabase.auth.currentUser?.id;

    showModalBottomSheet(

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
                color: Color(0xFFF5F5FA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10))),
                  const Text("Discovery", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
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
                              final venueModel = VenueModel.fromJson(_filteredVenues[i]);
                              final bool isOwner = venueModel.createdByUserId == currentUserId;

                              return VenueCard(
                                venue: venueModel,
                                isOwner: isOwner,
                                onFavoriteToggle: () async {
                                  await _handleFavoriteToggle(venueModel);
                                  setModalState(() {});
                                },
                                onEdit: isOwner ? () async {
                                  await _showEditVenueForm(context, _filteredVenues[i]);
                                  setModalState(() {});
                                } : null,
                                onDelete: isOwner ? () async {
                                  await _showDeleteConfirmation(context, venueModel.id);
                                  setModalState(() {});
                                } : null,
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
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]),
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(hintText: "Search venue...", border: InputBorder.none, icon: Icon(Icons.search, color: Colors.deepPurple)),
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