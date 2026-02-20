import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/venue_model.dart';

class VenueRepository {
  final _supa = Supabase.instance.client;

  Future<List<VenueModel>> fetchVenues() async {
    final response = await _supa
        .from('pathway.venues')
        .select('*, pathway.saved_venues(id)');
    return (response as List).map((json) {
      final isSaved = (json['saved_venues'] as List).isNotEmpty;
      return VenueModel.fromJson(json, isSaved: isSaved);
    }).toList();
  }

  Future<void> toggleSave(int venueId, bool currentlySaved) async {
    if (currentlySaved) {
      await _supa.from('pathway.saved_venues').delete().match({
        'venue_id': venueId,
      });
    } else {
      await _supa.from('pathway.saved_venues').insert({'venue_id': venueId});
    }
  }

  Future<VenueModel> fetchVenueById(int venueId) async {
    final data = await _supa
        .from('pathway.venues')
        .select('*')
        .eq('venue_id', venueId)
        .single();

    return VenueModel.fromJson(data);
  }
}
