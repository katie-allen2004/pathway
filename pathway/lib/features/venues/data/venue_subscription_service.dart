import 'package:supabase_flutter/supabase_flutter.dart';

class VenueSubscriptionService {
  final _client = Supabase.instance.client;

  // get current pathway user id from auth user
  Future<int> _getCurrentUserId() async {
    final authUser = _client.auth.currentUser;

    if (authUser == null) {
      throw Exception('no logged in user');
    }

    final user = await _client
        .schema('pathway')
        .from('users')
        .select('user_id')
        .eq('external_id', authUser.id)
        .maybeSingle();

    if (user == null) {
      throw Exception('user not found in pathway users table');
    }

    return user['user_id'] as int;
  }

  // check if user is subscribed
  Future<bool> isSubscribed(String venueId) async {
    final userId = await _getCurrentUserId();

    final response = await _client
        .schema('pathway')
        .from('venue_subscriptions')
        .select()
        .eq('user_id', userId)
        .eq('venue_id', int.parse(venueId))
        .maybeSingle();

    return response != null;
  }

  // subscribe to venue
  Future<void> subscribe(String venueId) async {
    final userId = await _getCurrentUserId();

    await _client
        .schema('pathway')
        .from('venue_subscriptions')
        .insert({
      'user_id': userId,
      'venue_id': int.parse(venueId),
    });
  }

  // unsubscribe from venue
  Future<void> unsubscribe(String venueId) async {
    final userId = await _getCurrentUserId();

    await _client
        .schema('pathway')
        .from('venue_subscriptions')
        .delete()
        .eq('user_id', userId)
        .eq('venue_id', int.parse(venueId));
  }

  // get all subscribed venues
  Future<List<dynamic>> getSubscribedVenues() async {
    final userId = await _getCurrentUserId();

    final response = await _client
        .schema('pathway')
        .from('venue_subscriptions')
        .select('venues(*)')
        .eq('user_id', userId);

    return response.map((e) => e['venues']).toList();
  }
}