import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart' as latlng;
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '/features/venues/data/venue_repository.dart';
import '/features/venues/data/venue_model.dart';
import '/features/venues/presentation/widgets/venue_card.dart';
import '/core/services/storage_service.dart';
import '/features/profile/presentation/pages/profile_page.dart'; 
import '/core/services/geo_code.dart'; 
import '/features/venues/presentation/pages/venue_detail_page.dart'; 
import 'package:pathway/core/services/accessibility_controller.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:icon_decoration/icon_decoration.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _supabase = Supabase.instance.client;

  final _repo = VenueRepository();
  final StorageService _storageService = StorageService();
  final GeocodingService _geocodingService = GeocodingService();
  Set<Marker> _markers = {};
  LatLng? _tempNewVenueLatLng;
  latlng.LatLng? _currentPosition;
  final fmap.MapController _fmapController = fmap.MapController();
  VenueModel? _selectedVenue;

  Map<String, Map<String, String>> _tempOperatingHours = {
    "mon": {"open": "09:00", "close": "17:00"},
    "tue": {"open": "09:00", "close": "17:00"},
    "wed": {"open": "09:00", "close": "17:00"},
    "thu": {"open": "09:00", "close": "17:00"},
    "fri": {"open": "09:00", "close": "17:00"},
    "sat": {"open": "Closed", "close": "Closed"},
    "sun": {"open": "Closed", "close": "Closed"},
  };

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
  Future<void> _determinePosition() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location services are disabled.")),
      );
    }
    return;
  }

  // handle perrmissions
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;
  }

  // Get current position
  final position = await Geolocator.getCurrentPosition();
  
  setState(() {
    _currentPosition = latlng.LatLng(position.latitude, position.longitude);
  });

  // users spot 
  _fmapController.move(_currentPosition!, 15.0);
}

  Future<void> _selectTime(BuildContext context, String day, String type, StateSetter setDialogState) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setDialogState(() {
        final now = DateTime.now();
        final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
        _tempOperatingHours[day]![type] = DateFormat("HH:mm").format(dt);
      });
    }
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
                _markers = venues.map((v) => Marker(
          markerId: MarkerId(v.id.toString()),
          position: LatLng(v.latitude ?? 0, v.longitude ?? 0),
          infoWindow: InfoWindow(title: v.name),
        )).toSet();

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

void _showSubmissionConfirmation() {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  final a11y = context.read<AccessibilityController>().settings;
  // dark mode: black bg, white text, orange accent (hourglass)
  // high contrast: white bg, black text, black accent (hourglass)
  // normal: white bg, black text, orange accent (hourglass)

  final isDark = a11y.darkMode;
  final isHighContrast = a11y.highContrast;

  final dialogBg = isDark ? Colors.black : Colors.white;
  final primaryText = isDark ? Colors.white : Colors.black;
  final secondaryText = isDark ? Colors.white70 : Colors.black54;
  final accentColor = isHighContrast ? Colors.black : Colors.orange;

  showDialog(
    context: context,
    barrierDismissible: false, // user clicks button
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: dialogBg,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hourglass_empty_rounded, 
              color: accentColor, 
              size: 50
          ),
          const SizedBox(height: 20),
          Text(
            "Venue Submitted!",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: primaryText,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Thank you for contributing! We're reviewing your submission to ensure all details are correct. It will appear on the map once it has been approved.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: secondaryText,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark || isHighContrast ? accentColor : cs.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Awesome"),
          ),
        ],
      ),
    ),
  );
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
  final descController = TextEditingController(text: existingVenue?.description);
  final addressController = TextEditingController();
  final latController = TextEditingController(text: existingVenue?.latitude?.toString());
  final lngController = TextEditingController(text: existingVenue?.longitude?.toString());

  List<int> selectedTagIds = [];
  String? uploadedImageName = existingVenue?.imagePath;
  bool isUploading = false;
  bool isLoadingTags = isEditing;
  bool _startedLoadingEditTags = false;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        final a11y = context.watch<AccessibilityController>().settings;

        final borderColor = a11y.highContrast 
            ? Colors.black
            : a11y.darkMode
                ? Colors.white
                : cs.primary;

        void refresh() {
          if (context.mounted) setDialogState(() {});
        }

        nameController.addListener(refresh);
        cityController.addListener(refresh);
        zipController.addListener(refresh);

        if (isEditing && !_startedLoadingEditTags) {
          _startedLoadingEditTags = true;
          _repo.getVenueTagIds(existingVenue!.id).then((ids) {
            setDialogState(() {
              selectedTagIds = ids;
              isLoadingTags = false;
            });
          }).catchError((e) {
            debugPrint("Edit tag load error: $e");
            setDialogState(() => isLoadingTags = false);
          });
        }
        
        final bool canSave = !isUploading && 
                     nameController.text.trim().isNotEmpty &&
                     cityController.text.trim().isNotEmpty &&
                     zipController.text.trim().isNotEmpty &&
                     addressController.text.trim().isNotEmpty;
                     latController.text.trim().isNotEmpty && 
                     lngController.text.trim().isNotEmpty;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: a11y.highContrast ? Colors.white : a11y.darkMode ? Colors.black : cs.background,
          title: Text(isEditing ? "Edit & Re-submit" : "Add New Venue"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: isUploading
                      ? null
                      : () async {
                          setDialogState(() => isUploading = true);
                          final fileName = await _storageService.pickAndUploadImage();
                          setDialogState(() {
                            uploadedImageName = fileName;
                            isUploading = false;
                          });
                        },

                  // dark mode: black bg, white text, light gray background for photo
                  // high contrast: white bg, black text, black outline for add photo and larger text
                  // normal: white bg, black text, primary color for accents
                  child: Container(
                    height: 120,
                    width: double.infinity,                    
                    decoration: BoxDecoration(
                      color: (a11y.highContrast ? Colors.white : a11y.darkMode ? Colors.black45  : cs.primary.withValues(alpha: 0.05)), //Colors.deepPurple.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: a11y.highContrast ? Colors.black : a11y.darkMode ? Colors.white : cs.primary.withValues(alpha: 0.1)),
                      //Colors.deepPurple.withOpacity(0.1)),
                    ),
                    child: isUploading
                        ? const Center(child: CircularProgressIndicator())
                        : (uploadedImageName == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, color: a11y.highContrast ? Colors.black : a11y.darkMode ? Colors.white : cs.primary),
                                  Text("Add Photo", style: theme.textTheme.bodyMedium?.copyWith(
                                    color: a11y.highContrast ? Colors.black : a11y.darkMode ? Colors.white : cs.primary,
                                    fontSize: a11y.highContrast ? 15 : 12,
                                  )//TextStyle(fontSize: 12)),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle, color: (a11y.highContrast ? Colors.black : Colors.green)),
                                    Text("Photo Ready", style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: (a11y.highContrast ? 15 : 12),
                                      color: (a11y.highContrast ? Colors.black : a11y.darkMode ? Colors.white : cs.primary),
                                    )
                                  ),
                                  ],
                                ),
                              )),
                  ),
                ),
                const SizedBox(height: 10),
                TypeAheadField<Map<String, dynamic>>(
                  debounceDuration: const Duration(milliseconds: 500),
                  onSelected: (suggestion) {
                    addressController.text = suggestion['display_name'] ?? '';
                    latController.text = suggestion['lat'].toString();
                    lngController.text = suggestion['lon'].toString();
                    
                    final double lat = double.tryParse(suggestion['lat'].toString()) ?? 0.0;
                    final double lon = double.tryParse(suggestion['lon'].toString()) ?? 0.0;
                    
                    // center map on location 
                    _fmapController.move(latlng.LatLng(lat, lon), 15.0);
                    setDialogState(() {}); 
                  },
                  suggestionsCallback: (pattern) async {
                    return await _geocodingService.getAddressSuggestions(pattern);
                  },
                  itemBuilder: (context, suggestion) {
                    return ListTile(
                      leading: Icon(Icons.location_on, color: (a11y.highContrast ? Colors.black : cs.primary)),
                      title: Text(suggestion['display_name'] ?? 'Unknown Address'),
                    );
                  },
                  builder: (context, controller, focusNode) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: "Full Address",
                        prefixIcon: Icon(Icons.location_on),
                        hintText: "Start typing an address...",

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: borderColor,
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: borderColor,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Venue Name", 
                    prefixIcon: const Icon(Icons.business_rounded, size: 20),
                    errorText: nameController.text.isEmpty ? 'Required' : null,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: borderColor,
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: borderColor,
                            width: 2,
                          ),
                        ),
                  ),
                ),

                const SizedBox(height: 10), // spacing

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: latController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: "Latitude",
                          hintText: "e.g. 33.7701",
                          prefixIcon: Icon(Icons.map_outlined, size: 20),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: borderColor,
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: borderColor,
                            width: 2,
                          ),
                        ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: lngController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: "Longitude",
                          hintText: "e.g. -118.1937",
                          prefixIcon: Icon(Icons.explore_outlined, size: 20),

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: borderColor,
                            ),
                          ),

                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: borderColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: cityController,
                  decoration: InputDecoration(
                    labelText: "City", 
                    prefixIcon: const Icon(Icons.location_city_rounded, size: 20),
                    errorText: cityController.text.isEmpty ? 'Required' : null,

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: borderColor,
                        ),
                      ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: borderColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                TextField(
                  controller: zipController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Zip Code", 
                    prefixIcon: const Icon(Icons.map_rounded, size: 20),
                    errorText: zipController.text.isEmpty ? 'Required' : null,

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: borderColor,
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: borderColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                
                // operating hours.
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Set Hours (Mon-Fri):", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectTime(context, "mon", "open", setDialogState),
                        icon: const Icon(Icons.login),
                        label: Text(
                          "Open: ${_tempOperatingHours['mon']!['open']}",
                          style: TextStyle(
                            color: (a11y.darkMode ? Colors.white : Colors.black),
                          )),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectTime(context, "mon", "close", setDialogState),
                        icon: const Icon(Icons.logout),
                        label: Text(
                          "Close: ${_tempOperatingHours['mon']!['close']}",
                          style: TextStyle(
                            color: (a11y.darkMode ? Colors.white : Colors.black),
                          )),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: "Description", 
                    prefixIcon: Icon(Icons.description_rounded, size: 20),
                    
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: borderColor,
                      ),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: borderColor,
                        width: 2,
                      ),
                    ),
                    ),
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Accessibility Features:", style: TextStyle(fontWeight: FontWeight.bold)),
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
                            label: Text(tag['tag_name'], style: const TextStyle(fontSize: 11)),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              setDialogState(() {
                                if (selected) selectedTagIds.add(id);
                                else selectedTagIds.remove(id);
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
              // dark mode: white bg, black text, light gray border
              // high contrast: white bg, black text, black border and larger text
              // normal: white bg, gray text, primary color border
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel", 
                style: TextStyle(
                  color: a11y.highContrast ? Colors.black : a11y.darkMode ? Colors.white : cs.primary,)),
            ),
            ElevatedButton(
              onPressed: !canSave
                  ? null
                  : () async {
                      try {
                        // coordinates
                        final double lat = double.tryParse(latController.text.trim()) ?? 0.0;
                        final double lng = double.tryParse(lngController.text.trim()) ?? 0.0;

                        if (!isEditing) {
                          final exists = await _repo.venueExists(lat: lat, lng: lng);
                          if (exists) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("A venue already exists at these coordinates.")),
                              );
                            }
                            return; 
                          }
                        }

            final data = {
              'name': nameController.text.trim(),
              'city': cityController.text.trim(),
              'zip': zipController.text.trim(),
              'description': descController.text.trim(),
              'image_path': uploadedImageName,
              'address_line1': addressController.text.trim(),
              'status': 'pending',
              'latitude': lat, 
              'longitude': lng, 
              'operating_hours': _tempOperatingHours,
              'moderator_notes': isEditing ? existingVenue.modNotes : null,
            };

            if (isEditing) {
              await _repo.updateVenue(
                venueId: existingVenue.id,
                venueData: data,
                tagIds: selectedTagIds,
              );
            } else {
              await _repo.createVenue(
                venueData: data,
                tagIds: selectedTagIds,
              );
            }

            if (context.mounted) {
              Navigator.pop(context);
              _showSubmissionConfirmation();
            }
            await _refreshVenues();
          } catch (e) {
            debugPrint("Error saving venue: $e");
          }
        },
  style: ElevatedButton.styleFrom(
    backgroundColor: Theme.of(context).colorScheme.primary,
    foregroundColor: Colors.white, 
    disabledBackgroundColor: Colors.grey[300],
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
  child: Text(
    isEditing ? "Re-submit" : "Save", 
    style: const TextStyle(fontWeight: FontWeight.bold),
  ),
),
          ],
        );
      },
    ),
  );
}

  void _showDiscoveryTray() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.read<AccessibilityController>().settings;

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
              decoration: BoxDecoration(
                color: a11y.highContrast ? Colors.white : cs.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                border: a11y.highContrast
                    ? const Border(top: BorderSide(color: Colors.black, width: 2))
                    : null,
              ),
              child: Column(
                children: [
                  // drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: a11y.highContrast ? Colors.black : Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  Text(
                    "Discovery",
                    style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: a11y.highContrast ? Colors.black : null,
                    ),
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final a11y = context.watch<AccessibilityController>().settings;

    return Scaffold(
      floatingActionButton: AnimatedPadding(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.only(bottom: _selectedVenue != null ? 140 : 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: "locateBtn",
              backgroundColor: a11y.highContrast || a11y.darkMode ? Colors.black : Colors.white,
              onPressed: _determinePosition,
              child: Icon(Icons.gps_fixed, 
                color: a11y.highContrast ? Colors.white : cs.primary),
            ),
            const SizedBox(height: 10),
            FloatingActionButton(
              heroTag: "addBtn",
              backgroundColor: a11y.highContrast ? Colors.black : cs.primary,
              onPressed: () => _showAddVenueDialog(),
              child: Icon(Icons.add, 
                color: a11y.highContrast ? Colors.white : a11y.darkMode ? Colors.black : cs.onPrimary),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                fmap.FlutterMap(
                  mapController: _fmapController,
                  options: fmap.MapOptions(
                    initialCenter: latlng.LatLng(33.7701, -118.1937),
                    initialZoom: 12,
                    // deselect maker when tapping on map. 
                    onTap: (_, __) => setState(() => _selectedVenue = null),
                  ),
                  children: [
                    fmap.TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.pathway.app',
                    ),
                    fmap.MarkerLayer(
                      markers: [
                        // current pos 
                        if (_currentPosition != null)
                          fmap.Marker(
                            point: _currentPosition!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.blueAccent,
                              size: 30,
                            ),
                          ),
                        // Merged filtered venues with your custom _getMarkerIcon logic
                        ..._filteredVenues.map((v) {
                          return fmap.Marker(
                            point: latlng.LatLng(v.latitude ?? 0, v.longitude ?? 0),
                            width: 50,
                            height: 50,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedVenue = v),
                              child: _getMarkerIcon(v),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ],
                ),
                // head structure 
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            context.push('/profile');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              shape: BoxShape.circle,
                              boxShadow: a11y.highContrast
                                  ? []
                                  : const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                              border: a11y.highContrast ? Border.all(color: Colors.black, width: 2) : null,
                            ),
                            child: Icon(
                              Icons.person,
                              color: a11y.highContrast ? Colors.black : cs.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: a11y.highContrast
                                  ? []
                                  : const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                              border: a11y.highContrast ? Border.all(color: Colors.black, width: 2) : null,
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: "Search venue...",
                                hintStyle: theme.textTheme.bodyMedium,
                                border: InputBorder.none,
                                icon: Icon(
                                  Icons.search,
                                  color: a11y.highContrast ? Colors.black : cs.primary,
                                ),
                              ),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: a11y.boldText ? FontWeight.w700 : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _showDiscoveryTray,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: a11y.highContrast ? Colors.black : cs.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.explore,
                              color: a11y.highContrast ? Colors.white : a11y.darkMode ? Colors.black : cs.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // mini card 
                if (_selectedVenue != null)
                  Positioned(
                    bottom: 30, left: 20, right: 20,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: a11y.darkMode ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: a11y.highContrast ? Border.all(color: Colors.black, width: 2) : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              context.push('/map/venue/${_selectedVenue!.id}');
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 90, height: 90,
                                    decoration: BoxDecoration(
                                      color: cs.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: _selectedVenue!.imagePath != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(15),
                                            child: Image.network(
                                              _storageService.getPublicUrl(_selectedVenue!.imagePath!),
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  const Icon(Icons.image_not_supported, color: Colors.grey),
                                            ),
                                          )
                                        : Icon(Icons.storefront, color: cs.primary, size: 40),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _selectedVenue!.name,
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: cs.onSurface, 
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          _selectedVenue!.addressLine1 ?? "No address listed",
                                          style: TextStyle(color: a11y.highContrast ? Colors.black : Colors.grey[600], fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.accessible, size: 16, color: a11y.highContrast ? Colors.black : Colors.green[700]),
                                            const SizedBox(width: 4),
                                            Text(
                                              "${_selectedVenue!.tags.length} Features",
                                              style: TextStyle(
                                                color: a11y.highContrast ? Colors.black : Colors.green[700],
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios, size: 18, color: a11y.highContrast ? Colors.black : Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  // scoring helper 
  Widget _getMarkerIcon(VenueModel venue) {
    final a11y = context.watch<AccessibilityController>().settings;
    final specialTags = [
      'wheelchair accessible',
      'accessible restroom',
      'accessible parking'
    ];
    final vTags = venue.tags.map((t) => t.toLowerCase().trim()).toList();
    int score = specialTags.where((tag) => vTags.contains(tag)).length;

    if (score >= 3) {
      return DecoratedIcon(
      icon: Icon(Icons.location_on, color: Color(0xFFFFD700),  size: 45),
      decoration: IconDecoration(
        border: IconBorder(
          color: (a11y.highContrast ? Colors.black : Color.fromARGB(255, 165, 108, 2)), 
          width: (a11y.highContrast ? 5 : 3))
        )
      );
    }
    if (score == 2) {
      return DecoratedIcon(
      icon: Icon(Icons.location_on, color: Colors.blueAccent, size: 42),
      decoration: IconDecoration(
        border: IconBorder(
          color: (a11y.highContrast ? Colors.black : const Color.fromARGB(255, 19, 34, 148)), 
          width: (a11y.highContrast ? 5 : 3))
        )
    );
    }
    if (score == 1) {
      return DecoratedIcon(
        icon: Icon(Icons.location_on, color: Colors.redAccent, size: 40),
        decoration: IconDecoration(
        border: IconBorder(
          color: (a11y.highContrast ? Colors.black : const Color.fromARGB(255, 135, 16, 16)), 
          width: (a11y.highContrast ? 5 : 3))
        )
      );
    }

    return Icon(
      Icons.location_on_outlined,
      color: Colors.grey.withValues(alpha: 0.5),
      size: 35,
    );
  }
}