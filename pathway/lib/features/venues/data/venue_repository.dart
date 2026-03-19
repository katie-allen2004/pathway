import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'venue_model.dart';
import 'review_model.dart';

class VenueRepository {
  final _client = Supabase.instance.client;

  /// Fetch all venues, include joined data (tags, reviews, favorites left join)
  Future<List<VenueModel>> fetchAllVenues() async {
    try {
      // current user id is used only to calculate saved status client-side (joined rows exist)
      //COMMENTED OUT FOR NOW DUE TO WARNINGS: final userId = _client.auth.currentUser?.id;

      final query = _client.schema('pathway').from('venues').select('''
            *,
            venue_tags(
              tag_id,
              accessibility_tags(tag_name)
            ),
            venue_reviews(rating),
            user_favorites!left(user_id)
          ''');

      // Do NOT filter by user_favorites.user_id here — that'll hide venues that are not favorited.
      final response = await query;
      debugPrint("fetchAllVenues: got ${(response as List).length} rows");

      return (response as List)
          .map((json) => VenueModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error in fetchAllVenues: $e');
      return [];
    }
  }

  /// fetch a single venue by integer venue_id
  Future<VenueModel?> fetchVenueById(int venueId) async {
    try {
      // COMMENTED OUT FOR NOW DUE TO WARNINGS: final userId = _client.auth.currentUser?.id;

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
          // Do NOT filter by user_favorites.user_id here either; the left join will include zero or one favorites rows.
          .maybeSingle();

      if (response == null) return null;
      return VenueModel.fromJson(response);
    } catch (e) {
      debugPrint('Error in fetchVenueById: $e');
      return null;
    }
  }

  /// update venue row and sync tags in venue_tags
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

      // remove existing tag links for this venue
      await _client
          .schema('pathway')
          .from('venue_tags')
          .delete()
          .eq('venue_id', venueId);

      // re-insert new tag links
      if (tagIds.isNotEmpty) {
        final inserts = tagIds
            .map((id) => {'venue_id': venueId, 'tag_id': id})
            .toList();
        await _client.schema('pathway').from('venue_tags').insert(inserts);
      }
    } catch (e) {
      debugPrint('Error in updateVenue: $e');
      throw Exception('Failed to update venue: $e');
    }
  }

  /// helper to fetch tag ids for pre-selecting chips in edit form
  Future<List<int>> getVenueTagIds(int venueId) async {
    try {
      final data = await _client
          .schema('pathway')
          .from('venue_tags')
          .select('tag_id')
          .eq('venue_id', venueId);

      return (data as List)
          .map((item) => (item['tag_id'] as num).toInt())
          .toList();
    } catch (e) {
      debugPrint('Error in getVenueTagIds: $e');
      return [];
    }
  }

  /// toggle save (favorite) for the signed-in user and venue_id
  Future<void> toggleSave(int venueId, bool isCurrentlySaved) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception("User must be logged in to favorite");

      if (isCurrentlySaved) {
        await _client.schema('pathway').from('user_favorites').delete().match({
          'user_id': userId,
          'venue_id': venueId,
        });
      } else {
        await _client.schema('pathway').from('user_favorites').upsert({
          'user_id': userId,
          'venue_id': venueId,
        }, onConflict: 'user_id, venue_id');
      }
    } catch (e) {
      debugPrint('Error in toggleSave: $e');
      throw Exception('Could not update favorite status');
    }
  }

  /// check duplicate by exact coordinates (lat/lng)
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

  // 1) Fetch tags (so MapScreen doesn't query Supabase directly)
  Future<List<Map<String, dynamic>>> fetchAllTags() async {
    try {
      final data = await _client
          .schema('pathway')
          .from('accessibility_tags')
          .select();
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      debugPrint('Error in fetchAllTags: $e');
      return [];
    }
  }

  // 2) Create venue + tags in one place (schema-safe)
  Future<int> createVenue({
    required Map<String, dynamic> venueData,
    required List<int> tagIds,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;

      final inserted = await _client
          .schema('pathway')
          .from('venues')
          .insert({...venueData, 'created_by_user_id': userId})
          .select('venue_id')
          .single();

      final int newVenueId = (inserted['venue_id'] as num).toInt();

      if (tagIds.isNotEmpty) {
        final tagInserts = tagIds
            .map((tId) => {'venue_id': newVenueId, 'tag_id': tId})
            .toList();

        await _client.schema('pathway').from('venue_tags').insert(tagInserts);
      }

      return newVenueId;
    } catch (e) {
      debugPrint('Error in createVenue: $e');
      rethrow;
    }
  }

  // 3) Delete venue (and rely on DB cascade OR manually delete tags first)
  Future<void> deleteVenue(int venueId) async {
    try {
      // If your DB does NOT have cascade constraints, uncomment these two lines:
      // await _client.schema('pathway').from('venue_tags').delete().eq('venue_id', venueId);
      // await _client.schema('pathway').from('user_favorites').delete().eq('venue_id', venueId);

      await _client
          .schema('pathway')
          .from('venues')
          .delete()
          .eq('venue_id', venueId);
    } catch (e) {
      debugPrint('Error in deleteVenue: $e');
      rethrow;
    }
  }

  // ---------------------------
  // Reviews
  // ---------------------------

  Future<List<ReviewModel>> fetchVenueReviews(
    int venueId, {
    String sortMode = 'newest',
  }) async {
    dynamic query = _client
        .schema('pathway')
        .from('venue_reviews')
        .select('*, review_photos(url)')
        .eq('venue_id', venueId);

    switch (sortMode) {
      case 'oldest':
        query = query
            .order('created_at', ascending: true)
            .order('review_id', ascending: true);
        break;

      case 'highest':
        query = query
            .order('rating', ascending: false)
            .order('created_at', ascending: false);
        break;

      case 'lowest':
        query = query
            .order('rating', ascending: true)
            .order('created_at', ascending: false);
        break;

      default:
        query = query
            .order('created_at', ascending: false)
            .order('review_id', ascending: false);
    }

    final res = await query;

    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map(ReviewModel.fromMap).toList();
  }

  Future<List<VenueModel>> fetchFavoritedVenues() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception("Not logged in");

      final res = await _client
          .schema('pathway')
          .from('venues')
          .select('''
          *,
          venue_tags(
            tag_id,
            accessibility_tags(tag_name)
          ),
          venue_reviews(rating),
          user_favorites!inner(user_id)
        ''')
          .eq('user_favorites.user_id', userId);

      return (res as List)
          .map((json) => VenueModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("Error in fetchFavoritedVenues: $e");
      return [];
    }
  }

  Future<int> addVenueReview({
    required int venueId,
    required int rating,
    String? text,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("Not signed in.");

    final result = await _client
        .schema('pathway')
        .from('venue_reviews')
        .insert({
          'venue_id': venueId,
          'user_id': user.id,
          'rating': rating,
          'review_text': (text ?? '').trim(),
        })
        .select('review_id')
        .single();

    return (result['review_id'] as num).toInt();
  }

  // Upload bytes to Supabase storage and return the public URL.
  // Review media (photos + videos) go to the 'reviews' bucket.
  // Profile/venue images go to the 'avatars' bucket.
  Future<String> uploadToStorage(String path, Uint8List bytes, {String? contentType}) async {
    final bucket = path.startsWith('reviews/') ? 'reviews' : 'avatars';
    await _client.storage.from(bucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(upsert: true, contentType: contentType),
    );
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  // Get the public URL for a storage path.
  String getPublicUrl(String path) {
    if (path.startsWith('http')) return path;
    return _client.storage.from('avatars').getPublicUrl(path);
  }

  // Update the image_path column of a venue.
  Future<void> updateVenueImagePath(int venueId, String imagePath) async {
    await _client
        .schema('pathway')
        .from('venues')
        .update({'image_path': imagePath})
        .eq('venue_id', venueId);
  }

  // Update the video_path column of a venue.
  Future<void> updateVenueVideoPath(int venueId, String videoPath) async {
    await _client
        .schema('pathway')
        .from('venues')
        .update({'video_path': videoPath})
        .eq('venue_id', venueId);
  }

  // Insert a photo URL linked to a review.
  Future<void> addReviewPhoto(int reviewId, String url) async {
    await _client.schema('pathway').from('review_photos').insert({
      'review_id': reviewId,
      'url': url,
    });
  }

  Future<void> deleteReview(int reviewId) async {
    await _client
        .schema('pathway')
        .from('venue_reviews')
        .delete()
        .eq('review_id', reviewId);
  }

  Future<void> updateReview({
    required int reviewId,
    required int rating,
    String? text,
  }) async {
    await _client
        .schema('pathway')
        .from('venue_reviews')
        .update({'rating': rating, 'review_text': (text ?? '').trim()})
        .eq('review_id', reviewId);
  }
}
