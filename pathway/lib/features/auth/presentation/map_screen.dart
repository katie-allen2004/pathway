import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final TextEditingController _venueController = TextEditingController();
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _allVenues = [];
  List<Map<String, dynamic>> _filteredVenues = [];
  Map<String, dynamic>? _selectedVenue;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVenues();
  }

Future<void> _loadVenues() async {
    try {
      final data = await _supabase
          .schema('pathway') // <--- Add this line
          .from('venues')     // <--- Just 'venues', no 'pathway.' prefix
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

  void _searchVenues(String query) {
    if (query.isEmpty) {
      setState(() => _filteredVenues = []);
      return;
    }
    setState(() {
      _filteredVenues = _allVenues.where((v) {
        final name = v['name']?.toLowerCase() ?? ''; //
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _showVenueDetails(Map<String, dynamic> venue) {
    setState(() {
      _selectedVenue = venue;
      _filteredVenues = [];
      _venueController.text = venue['name'] ?? '';
    });

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Using 'name' from venues table
            Text(venue['name'] ?? 'Unknown Venue', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            
            // Concatenating address and city
            Text("${venue['address_line1'] ?? ''}, ${venue['city'] ?? ''}", style: const TextStyle(color: Colors.grey)),
            
            const Divider(height: 30),
            
            // Using 'description' from venues table
            if (venue['description'] != null) ...[
              Text(venue['description']),
              const SizedBox(height: 20),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(context),
                child: const Text("View Pathway to Venue"),
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
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              // Map Placeholder
              Container(color: Colors.grey[300], child: const Center(child: Text("MAP VIEW"))),

              // Search and Results UI
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _venueController,
                        onChanged: _searchVenues,
                        decoration: InputDecoration(
                          hintText: "Search Venues...",
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ),

                    // Search Results List
                    if (_filteredVenues.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _filteredVenues.length,
                            itemBuilder: (context, i) {
                              final v = _filteredVenues[i];
                              return ListTile(
                                leading: const Icon(Icons.place, color: Colors.deepPurple),
                                title: Text(v['name'] ?? ''), //
                                subtitle: Text(v['city'] ?? ''), //
                                onTap: () => _showVenueDetails(v),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}