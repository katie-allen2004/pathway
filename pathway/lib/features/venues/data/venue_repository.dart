import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'venue_model.dart';
import 'review_model.dart';
import 'package:pathway/features/gamification/data/badge_model.dart';
import 'venue_suggestion_model.dart';
import 'package:pathway/features/gamification/data/badge_tab_data.dart';
import 'venue_edit_history_model.dart';

class VenueRepository {
  final _client = Supabase.instance.client;

  /// Fetch all venues, include joined data (tags, reviews, favorites left join)
  /// UPDATED: Now filters for 'approved' status to show only verified venues on the map
  Future<List<VenueModel>> fetchAllVenues() async {
    try {
      // current user id is used only to calculate saved status client-side (joined rows exist)
      //COMMENTED OUT FOR NOW DUE TO WARNINGS: final userId = _client.auth.currentUser?.id;

      final query = _client
          .schema('pathway')
          .from('venues')
          .select('''
            *,
            venue_tags(
              tag_id,
              accessibility_tags(tag_name)
            ),
            venue_reviews(review_id, user_id, rating, review_text, is_visible, created_at),
            user_favorites!left(user_id)
          ''')
          .eq('status', 'approved') // verified venues only
          .eq('venue_reviews.is_visible', true); // Filter hidden reviews

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

  /// NEW: Fetch venues awaiting moderation
  Future<List<VenueModel>> fetchPendingVenues() async {
    try {
      final response = await _client
          .schema('pathway')
          .from('venues')
          .select('''
            *,
            venue_tags(tag_id, accessibility_tags(tag_name))
          ''')
          .eq('status', 'pending'); // mod queue

      return (response as List)
          .map((json) => VenueModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error in fetchPendingVenues: $e');
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
            venue_reviews(review_id, user_id, rating, review_text, is_visible, created_at),
            user_favorites!left(user_id)
          ''')
          .eq('venue_id', venueId)
          .eq('venue_reviews.is_visible', true) // Filter hidden reviews
          // Do NOT filter by user_favorites.user_id here either; the left join will include zero or one favorites rows.
          .maybeSingle();

      if (response == null) return null;
      return VenueModel.fromJson(response as Map<String, dynamic>);
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
    try {
      dynamic query = _client
          .schema('pathway')
          .from('venue_reviews')
          .select('''
          review_id,
          venue_id,
          user_id,
          rating,
          review_text,
          created_at,
          is_visible
        ''')
          .eq('venue_id', venueId)
          .eq('is_visible', true);

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
      final reviewRows = (res as List).cast<Map<String, dynamic>>();

      if (reviewRows.isEmpty) return [];

      final userIds = reviewRows
          .map((r) => r['user_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();

      final profileRes = await _client
          .schema('pathway')
          .from('profiles')
          .select('user_id, display_name')
          .inFilter('user_id', userIds);

      final profileRows = (profileRes as List).cast<Map<String, dynamic>>();

      final usernameByUserId = <String, String>{};
      for (final row in profileRows) {
        final userId = row['user_id']?.toString();
        final displayName = row['display_name']?.toString().trim();

        if (userId != null && displayName != null && displayName.isNotEmpty) {
          usernameByUserId[userId] = displayName;
        }
      }

      return reviewRows.map((row) {
        final copy = Map<String, dynamic>.from(row);
        copy['username'] = usernameByUserId[row['user_id']?.toString()];
        return ReviewModel.fromMap(copy);
      }).toList();
    } catch (e) {
      debugPrint('Error in fetchVenueReviews: $e');
      return [];
    }
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

  Future<void> addVenueReview({
    required int venueId,
    required int rating,
    String? text,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception("Not signed in.");
    }

    await _client.schema('pathway').from('venue_reviews').insert({
      'venue_id': venueId,
      'user_id': user.id,
      'rating': rating,
      'review_text': (text ?? '').trim(),
      'is_visible': true,
    });

    // Award badges
    try {
      await _client.rpc('evaluate_user_badges', params: {'p_user_id': user.id});
    } catch (e) {
      debugPrint('evaluate_user_badges failed: $e');
    }
  }

  /// Fetch badges for a single user (for Profile)
  Future<List<BadgeModel>> fetchBadgesForUser(String userId) async {
    try {
      final res = await _client
          .schema('pathway')
          .from('user_badges')
          .select('badges(*)')
          .eq('user_id', userId);

      final rows = (res as List).cast<Map<String, dynamic>>();
      return rows
          .map((r) => BadgeModel.fromMap(r['badges'] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error in fetchBadgesForUser: $e');
      return [];
    }
  }

  Future<List<BadgeModel>> fetchAllBadges() async {
    try {
      final res = await _client
          .schema('pathway')
          .from('badges')
          .select()
          .order('badge_id', ascending: true);

      final rows = (res as List).cast<Map<String, dynamic>>();
      return rows.map(BadgeModel.fromMap).toList();
    } catch (e) {
      debugPrint('Error in fetchAllBadges: $e');
      return [];
    }
  }

  Future<BadgeTabData> fetchBadgeTabData(String userId) async {
    try {
      final allBadges = await fetchAllBadges();
      final earnedBadges = await fetchBadgesForUser(userId);

      final earnedIds = earnedBadges.map((b) => b.badgeId).toSet();

      final lockedBadges = allBadges
          .where((b) => !earnedIds.contains(b.badgeId))
          .toList();

      return BadgeTabData(earned: earnedBadges, locked: lockedBadges);
    } catch (e) {
      debugPrint('Error in fetchBadgeTabData: $e');
      return BadgeTabData(earned: [], locked: []);
    }
  }

  /// Fetch badges for many users (returns map userId -> list of badges)
  Future<Map<String, List<BadgeModel>>> fetchBadgesForUsers(
    List<String> userIds,
  ) async {
    try {
      if (userIds.isEmpty) return {};

      final res = await _client
          .schema('pathway')
          .from('user_badges')
          .select('user_id, badges(*)')
          .inFilter('user_id', userIds);

      final rows = (res as List).cast<Map<String, dynamic>>();
      final Map<String, List<BadgeModel>> map = {};

      for (final row in rows) {
        final uid = row['user_id'] as String;
        final badge = BadgeModel.fromMap(row['badges'] as Map<String, dynamic>);
        map.putIfAbsent(uid, () => []).add(badge);
      }

      return map;
    } catch (e) {
      debugPrint('Error in fetchBadgesForUsers: $e');
      return {};
    }
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

  // ---------------------------
  // Moderation Logic
  // ---------------------------
  Future<void> submitVenueSuggestion({
    required int venueId,
    required String fieldName,
    required String proposedValue,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User must be logged in to suggest edits.');
    }

    final cleanedValue = proposedValue.trim();
    if (cleanedValue.isEmpty) {
      throw Exception('Suggested value cannot be empty.');
    }

    await _client.schema('pathway').from('venue_suggestions').insert({
      'venue_id': venueId,
      'user_id': userId,
      'field_name': fieldName,
      'proposed_value': cleanedValue,
      'status': 'pending',
    });
  }

  Future<List<VenueSuggestionModel>> fetchPendingVenueSuggestions() async {
    try {
      final res = await _client
          .schema('pathway')
          .from('venue_suggestions')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: true);

      final rows = (res as List).cast<Map<String, dynamic>>();
      return rows.map(VenueSuggestionModel.fromMap).toList();
    } catch (e) {
      debugPrint('Error in fetchPendingVenueSuggestions: $e');
      return [];
    }
  }

  Future<void> approveVenueSuggestion(String suggestionId) async {
    try {
      await _client.rpc(
        'approve_venue_suggestion',
        params: {'p_suggestion_id': suggestionId},
      );
    } catch (e) {
      debugPrint('Error in approveVenueSuggestion: $e');
      rethrow;
    }
  }

  Future<void> rejectVenueSuggestion(String suggestionId) async {
    try {
      await _client.rpc(
        'reject_venue_suggestion',
        params: {'p_suggestion_id': suggestionId},
      );
    } catch (e) {
      debugPrint('Error in rejectVenueSuggestion: $e');
      rethrow;
    }
  }

  Future<List<VenueEditHistoryModel>> fetchVenueEditHistory(int venueId) async {
  try {
    final res = await _client
        .schema('pathway')
        .from('venue_edit_history')
        .select()
        .eq('venue_id', venueId)
        .order('created_at', ascending: false);

    final rows = (res as List).cast<Map<String, dynamic>>();
    return rows.map(VenueEditHistoryModel.fromMap).toList();
  } catch (e) {
    debugPrint('Error fetching edit history: $e');
    return [];
  }
}

  Future<void> reportContent({
    required String targetType,
    required dynamic targetId,
    required String reportedUserId,
    required String reason,
    String? description,
  }) async {
    try {
      final reporterId = _client.auth.currentUser?.id;
      if (reporterId == null)
        throw Exception("User must be logged in to report.");

      await _client.schema('pathway').from('user_reports').insert({
        'reporter_user_id': reporterId,
        'reported_user_id': reportedUserId,
        'target_type': targetType,
        'target_id': targetId.toString(),
        'reason': reason,
        'description': description,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error in reportContent: $e');
      rethrow;
    }
  }

  Future<void> resolveAndHideReview({
    required dynamic reportId,
    required int reviewId,
    required bool shouldHide,
  }) async {
    try {
      if (shouldHide) {
        await _client
            .schema('pathway')
            .from('venue_reviews')
            .update({'is_visible': false})
            .eq('review_id', reviewId);
      }
      await _client
          .schema('pathway')
          .from('user_reports')
          .update({'status': 'resolved'})
          .eq('report_id', reportId);
    } catch (e) {
      debugPrint('Error in resolveAndHideReview: $e');
      rethrow;
    }
  }

  Future<void> restoreReview({
    required dynamic reportId,
    required int reviewId,
  }) async {
    try {
      await _client
          .schema('pathway')
          .from('venue_reviews')
          .update({'is_visible': true})
          .eq('review_id', reviewId);
      await _client
          .schema('pathway')
          .from('user_reports')
          .update({'status': 'dismissed'})
          .eq('report_id', reportId);
    } catch (e) {
      debugPrint('Error in restoreReview: $e');
      rethrow;
    }
  }

  Future<String> fetchReportedReviewText(int reviewId) async {
    try {
      final data = await _client
          .schema('pathway')
          .from('venue_reviews')
          .select('review_text')
          .eq('review_id', reviewId)
          .maybeSingle();
      return data?['review_text']?.toString() ?? "[No text content found]";
    } catch (e) {
      debugPrint('Error fetching reported review: $e');
      return "[Error loading content]";
    }
  }
}
