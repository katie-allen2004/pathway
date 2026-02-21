import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/venue_model.dart';

class VenueRepository {
  final _supa = Supabase.instance.client;

  Future<List<VenueModel>> fetchVenues() async {
    final user = _supa.auth.currentUser;
    if (user == null) return [];

    final venues = await _supa
        .from('venues')
        .select('id, name, address, rating, created_at');

    final savedRows = await _supa
        .from('saved_venues')
        .select('venue_id')
        .eq('user_id', user.id);

    final savedIds = (savedRows as List)
        .map((r) => (r['venue_id'] ?? '').toString())
        .toSet();

    // map venues into VenueModel, marking isSaved based on savedIds
    return (venues as List).map((json) {
      final id = (json['id'] ?? '').toString();
      return VenueModel.fromJson(
        Map<String, dynamic>.from(json),
        isSaved: savedIds.contains(id),
      );
    }).toList();
  }

  Future<void> toggleSave(String venueId, bool currentlySaved) async {
    final user = _supa.auth.currentUser;
    if (user == null) return;

    if (currentlySaved) {
      await _supa
          .from('saved_venues')
          .delete()
          .eq('venue_id', venueId)
          .eq('user_id', user.id);
    } else {
      await _supa.from('saved_venues').insert({
        'venue_id': venueId,
        'user_id': user.id,
      });
    }
  }

  Future<VenueModel> fetchVenueById(String venueId) async {
    final user = _supa.auth.currentUser;
    if (user == null) {
      throw Exception('Not logged in');
    }

    final data = await _supa
        .from('venues')
        .select('id, name, address')
        .eq('id', venueId)
        .single();

    final saved = await _supa
        .from('saved_venues')
        .select('id')
        .eq('venue_id', venueId)
        .eq('user_id', user.id);

    final isSaved = (saved as List).isNotEmpty;

    return VenueModel.fromJson(
      Map<String, dynamic>.from(data),
      isSaved: isSaved,
    );
  }
}
