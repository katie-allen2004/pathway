import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'venue_model.dart';

class VenueRepository {
  final _client = Supabase.instance.client;

  /// Fetches all venues from the 'pathway' schema.
  /// Includes tag joins and maps the column-based 'is_saved' status.
  Future<List<VenueModel>> fetchAllVenues() async {
    try {
      final List<dynamic> data = await _client
          .schema('pathway')
          .from('venues')
          .select('''
            *, 
            venue_tags(
              tag_id, 
              accessibility_tags(tag_name)
            )
          ''');

      if (data.isEmpty) return [];

      return data.map((json) {
        // 1. Map nested tags from the junction table to a flat List<String>
        final List venueTags = json['venue_tags'] ?? [];
        final List<String> tagNames = venueTags
            .where((vt) => vt['accessibility_tags'] != null)
            .map((vt) => vt['accessibility_tags']['tag_name'].toString())
            .toList();

        // 2. Prepare the map for VenueModel.fromJson
        final venueMap = Map<String, dynamic>.from(json);
        venueMap['tags'] = tagNames;

        return VenueModel.fromJson(venueMap);
      }).toList();
    } catch (e) {
      debugPrint('Error in fetchAllVenues: $e');
      return []; // Return empty list to prevent UI crashes
    }
  }

  /// Fetches a single venue by ID from the 'pathway' schema.
  Future<VenueModel?> fetchVenueById(int venueId) async {
    try {
      final response = await _client
          .schema('pathway')
          .from('venues')
          .select('''
            *, 
            venue_tags(
              tag_id, 
              accessibility_tags(tag_name)
            )
          ''')
          .eq('venue_id', venueId)
          .maybeSingle();

      if (response == null) return null;

      final List venueTags = response['venue_tags'] ?? [];
      final List<String> tagNames = venueTags
          .where((vt) => vt['accessibility_tags'] != null)
          .map((vt) => vt['accessibility_tags']['tag_name'].toString())
          .toList();

      final venueMap = Map<String, dynamic>.from(response);
      venueMap['tags'] = tagNames;

      return VenueModel.fromJson(venueMap);
    } catch (e) {
      debugPrint('Error in fetchVenueById: $e');
      return null;
    }
  }

  /// Toggles the 'is_saved' boolean column in the 'pathway.venues' table.
  /// Note: This updates the global record in the 'pathway' schema.
  Future<void> toggleSave(int venueId, bool currentStatus) async {
    try {
      await _client
          .schema('pathway')
          .from('venues')
          .update({'is_saved': !currentStatus})
          .eq('venue_id', venueId);
    } catch (e) {
      debugPrint('Error in toggleSave: $e');
      throw Exception('Could not update favorite status');
    }
  }
}