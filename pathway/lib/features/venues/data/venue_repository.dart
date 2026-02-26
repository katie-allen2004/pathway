import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'venue_model.dart';

class VenueRepository {
  final _client = Supabase.instance.client;

  /// pathway schema 
  Future<List<VenueModel>> fetchAllVenues() async {
    try {
      final userId = _client.auth.currentUser?.id;
      final query = _client
          .schema('pathway')
          .from('venues')
          .select('''
            *, 
            venue_tags(
              tag_id, 
              accessibility_tags(tag_name)
            ),
            venue_reviews(rating),
            user_favorites!left(user_id)
          ''');
      final response = await query.eq(///dummy  value 
        'user_favorites.user_id', 
        userId ?? '00000000-0000-0000-0000-000000000000'
      );

      return (response as List).map((json) => VenueModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error in fetchAllVenues: $e');
      return [];
    }
  }

  /// fetches a venue
  Future<VenueModel?> fetchVenueById(int venueId) async {
    try {
      final userId = _client.auth.currentUser?.id;

      final response = await _client
          .schema('pathway')
          .from('venues')
          .select('''
            *, 
            venue_tags(
              tag_id, 
              accessibility_tags(tag_name)
            ),
            venue_reviews(rating),
            user_favorites!left(user_id)
          ''')
          .eq('venue_id', venueId)
          .eq('user_favorites.user_id', userId ?? '00000000-0000-0000-0000-000000000000')
          .maybeSingle();

      if (response == null) return null;
      return VenueModel.fromJson(response);
    } catch (e) {
      debugPrint('Error in fetchVenueById: $e');
      return null;
    }
  }

  /// updates venue details and syncs table tags
  Future<void> updateVenue({
    required int venueId,
    required Map<String, dynamic> venueData,
    required List<int> tagIds,
  }) async {
    try {
      await _client
          .schema('pathway')
          .from('venues')
          .update(venueData)
          .eq('venue_id', venueId);

      await _client
          .schema('pathway')
          .from('venue_tags')
          .delete()
          .eq('venue_id', venueId);
      
      // insert new tags
      if (tagIds.isNotEmpty) {
        final List<Map<String, dynamic>> inserts = tagIds.map((id) => {
          'venue_id': venueId, 
          'tag_id': id
        }).toList();

        await _client
            .schema('pathway')
            .from('venue_tags')
            .insert(inserts);
      }
    } catch (e) {
      debugPrint('Error in updateVenue: $e');
      throw Exception('Failed to update venue: $e');
    }
  }

  /// edit form to pre-select chips
  Future<List<int>> getVenueTagIds(int venueId) async {
    try {
      final data = await _client
          .schema('pathway')
          .from('venue_tags')
          .select('tag_id')
          .eq('venue_id', venueId);
      
      return (data as List).map((item) => item['tag_id'] as int).toList();
    } catch (e) {
      debugPrint('Error in getVenueTagIds: $e');
      return [];
    }
  }

  Future<void> toggleSave(int venueId, bool isCurrentlySaved) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception("User must be logged in to favorite");

      if (isCurrentlySaved) {
        await _client
            .schema('pathway')
            .from('user_favorites')
            .delete()
            .match({
              'user_id': userId,
              'venue_id': venueId,
            });
      } else {
        await _client
            .schema('pathway')
            .from('user_favorites')
            .upsert({
              'user_id': userId,
              'venue_id': venueId,
            }, onConflict: 'user_id, venue_id'); 
      }
    } catch (e) {
      debugPrint('Error in toggleSave: $e');
      throw Exception('Could not update favorite status');
    }
  }

  /// checks if a venue already exists at these exact coordinates
  Future<bool> venueExists({required double lat, required double lng}) async {
    try {
      final response = await _client
          .schema('pathway')
          .from('venues')
          .select('venue_id')
          .eq('latitude', lat)
          .eq('longitude', lng)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      debugPrint('Error in venueExists: $e');
      return false;
    }
  }
}