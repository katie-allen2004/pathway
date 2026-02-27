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

  List<VenueModel> _allVenues = [];
  List<VenueModel> _filteredVenues = [];
  List<Map<String, dynamic>> _allAvailableTags = [];

  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _showSavedOnly = false;

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

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final tagData = await _repo.fetchAllTags();

      final venues = await _repo.fetchAllVenues();

      setState(() {
        _allAvailableTags = tagData;
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
      Iterable<VenueModel> list = _allVenues;

      if (_showSavedOnly) {
        list = list.where((v) => v.isSaved);
      }

      if (query.isNotEmpty) {
        list = list.where((v) {
          final name = v.name.toLowerCase();
          final city = (v.city ?? "").toLowerCase();
          final matchesTag = v.tags.any(
            (tag) => tag.toLowerCase().contains(query),
          );
          return name.contains(query) || city.contains(query) || matchesTag;
        });
      }

      _filteredVenues = list.toList();
    });
  }

  /// favorite toggle logic
  Future<void> _handleFavoriteToggle(VenueModel venue) async {
    final originalVenue = venue;
    final bool originalStatus = venue.isSaved;

    // ui updated
    setState(() {
      final index = _allVenues.indexWhere((v) => v.id == venue.id);
      if (index != -1) {
        _allVenues[index] = venue.copyWith(isSaved: !originalStatus);
      }
      _runFilter();
    });

    try {
      // database call
      await _repo.toggleSave(venue.id, originalStatus);
    } catch (e) {
      debugPrint('Favorite Toggle Error: $e');
      setState(() {
        final index = _allVenues.indexWhere((v) => v.id == venue.id);
        if (index != -1) {
          _allVenues[index] = originalVenue;
        }
        _runFilter();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Could not update favorite. Check connection."),
          ),
        );
      }
    }
  }

  Future<void> _handleDelete(int venueId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Venue?"),
        content: const Text("This will permanently remove this venue."),
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

    if (confirmed != true) return;

    try {
      await _repo.deleteVenue(venueId);
      await _refreshVenues();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Venue deleted.")));
      }
    } catch (e) {
      debugPrint("Delete Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
      }
    }
  }

  Future<void> _showAddVenueDialog({VenueModel? existingVenue}) async {
    final isEditing = existingVenue != null;

    final nameController = TextEditingController(text: existingVenue?.name);
    final cityController = TextEditingController(text: existingVenue?.city);
    final zipController = TextEditingController(text: existingVenue?.zipCode);
    final descController = TextEditingController(
      text: existingVenue?.description,
    );
    final latController = TextEditingController(
      text: existingVenue?.latitude?.toString(),
    );
    final lngController = TextEditingController(
      text: existingVenue?.longitude?.toString(),
    );

    List<int> selectedTagIds = [];
    String? uploadedImageName = existingVenue?.imagePath;
    bool isUploading = false;
    bool isLoadingTags = isEditing;
    bool _startedLoadingEditTags = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Load selected tags once when editing
          if (isEditing && !_startedLoadingEditTags) {
            _startedLoadingEditTags = true;

            _repo
                .getVenueTagIds(existingVenue!.id)
                .then((ids) {
                  setDialogState(() {
                    selectedTagIds = ids;
                    isLoadingTags = false;
                  });
                })
                .catchError((e) {
                  debugPrint("Edit tag load error: $e");
                  setDialogState(() {
                    isLoadingTags = false;
                  });
                });
          }
          final bool canSave =
              !isUploading && nameController.text.trim().isNotEmpty;

          return AlertDialog(
            title: Text(isEditing ? "Edit Venue" : "Add New Venue"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: isUploading
                        ? null
                        : () async {
                            setDialogState(() => isUploading = true);
                            final fileName = await _storageService
                                .pickAndUploadImage();
                            setDialogState(() {
                              uploadedImageName = fileName;
                              isUploading = false;
                            });
                          },
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.deepPurple.withOpacity(0.1),
                        ),
                      ),
                      child: isUploading
                          ? const Center(child: CircularProgressIndicator())
                          : (uploadedImageName == null
                                ? const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo,
                                        color: Colors.deepPurple,
                                      ),
                                      Text(
                                        "Add Photo",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      ),
                                      Text(
                                        "Photo Uploaded",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  )),
                    ),
                  ),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Venue Name"),
                  ),
                  TextField(
                    controller: cityController,
                    decoration: const InputDecoration(labelText: "City"),
                  ),
                  TextField(
                    controller: zipController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Zip Code"),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: latController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(labelText: "Lat"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: lngController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(labelText: "Lng"),
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: "Description"),
                  ),
                  const SizedBox(height: 15),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Accessibility Features:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  isLoadingTags
                      ? const Center(child: CircularProgressIndicator())
                      : Wrap(
                          spacing: 8,
                          children: _allAvailableTags.map((tag) {
                            final id = (tag['tag_id'] as num).toInt();
                            final isSelected = selectedTagIds.contains(id);
                            return FilterChip(
                              label: Text(
                                tag['tag_name'],
                                style: const TextStyle(fontSize: 11),
                              ),
                              selected: isSelected,
                              onSelected: (bool selected) {
                                setDialogState(() {
                                  if (selected)
                                    selectedTagIds.add(id);
                                  else
                                    selectedTagIds.remove(id);
                                });
                              },
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: !canSave
                    ? null
                    : () async {
                        debugPrint('--- SCHEMA TEST START ---');

                        try {
                          final test = await Supabase.instance.client
                              .schema('pathway')
                              .from('venues')
                              .select('city')
                              .limit(1);
                          debugPrint('TEST pathway.venues select(city): $test');
                        } catch (e) {
                          debugPrint(
                            'TEST pathway.venues select(city) error: $e',
                          );
                        }

                        try {
                          final test2 = await Supabase.instance.client
                              .schema('pathway')
                              .from('venues')
                              .select('city')
                              .limit(1);
                          debugPrint(
                            'TEST default schema .from(venues) select(city): $test2',
                          );
                        } catch (e) {
                          debugPrint(
                            'TEST default schema .from(venues) select(city) error: $e',
                          );
                        }

                        debugPrint('--- SCHEMA TEST END ---');

                        try {
                          final lat = double.tryParse(
                            latController.text.trim(),
                          );
                          final lng = double.tryParse(
                            lngController.text.trim(),
                          );

                          if (lat == null || lng == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Please enter valid coordinates.",
                                ),
                              ),
                            );
                            return;
                          }

                          final data = {
                            'name': nameController.text.trim(),
                            'city': cityController.text.trim(),
                            'zip': zipController.text.trim(),
                            'description': descController.text.trim(),
                            'image_path': uploadedImageName,
                            'latitude': lat,
                            'longitude': lng,
                          };

                          if (isEditing) {
                            await _repo.updateVenue(
                              venueId: existingVenue.id,
                              venueData: data,
                              tagIds: selectedTagIds,
                            );
                          } else {
                            // duplicate check
                            final exists = await _repo.venueExists(
                              lat: lat,
                              lng: lng,
                            );
                            if (exists) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "A venue already exists here.",
                                    ),
                                  ),
                                );
                              }
                              return;
                            }

                            await _repo.createVenue(
                              venueData: data,
                              tagIds: selectedTagIds,
                            );
                          }

                          if (context.mounted) Navigator.pop(context);
                          await _refreshVenues();
                        } catch (e) {
                          debugPrint("Error saving: $e");
                        }
                      },
                child: Text(isEditing ? "Update" : "Save"),
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
                  // drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const Text(
                    "Discovery",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text("All"),
                        selected: !_showSavedOnly,
                        onSelected: (_) {
                          setModalState(() {
                            _showSavedOnly = false;
                            _runFilter();
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text("Saved"),
                        selected: _showSavedOnly,
                        onSelected: (_) {
                          setModalState(() {
                            _showSavedOnly = true;
                            _runFilter();
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Expanded(
                    child: _filteredVenues.isEmpty
                        ? Center(
                            child: Text(
                              _showSavedOnly
                                  ? "No saved venues yet.\nTap ❤️ on a venue to save it."
                                  : "No matches found.",
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            itemCount: _filteredVenues.length,
                            itemBuilder: (context, i) {
                              final v = _filteredVenues[i];
                              return VenueCard(
                                venue: v,
                                isOwner: v.createdByUserId == currentUserId,
                                onFavoriteToggle: (updatedVenue) async {
                                  await _handleFavoriteToggle(v);
                                  setModalState(() {});
                                },
                                onEdit: v.createdByUserId == currentUserId
                                    ? () {
                                        Navigator.pop(context);
                                        _showAddVenueDialog(existingVenue: v);
                                      }
                                    : null,
                                onDelete: v.createdByUserId == currentUserId
                                    ? () async {
                                        await _handleDelete(v.id);
                                        setModalState(() {});
                                      }
                                    : null,
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
        onPressed: () => _showAddVenueDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // set up for map in the future
                Container(
                  color: Colors.grey[200],
                  child: const Center(child: Text('Map coming soon')),
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
                                hintText: "Search venue...",
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
