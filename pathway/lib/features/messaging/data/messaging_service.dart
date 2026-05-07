import 'package:supabase_flutter/supabase_flutter.dart';

class MessagingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<int?> getCurrentPathwayUserId() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return null;

    final row = await _supabase
        .schema('pathway')
        .from('users')
        .select('user_id')
        .eq('external_id', authUser.id)
        .maybeSingle();

    return row?['user_id'] as int?;
  }

  Future<int?> getPathwayUserIdFromExternalId(String externalId) async {
    final row = await _supabase
        .schema('pathway')
        .from('users')
        .select('user_id')
        .eq('external_id', externalId)
        .maybeSingle();

    return row?['user_id'] as int?;
  }

  Future<int?> findExistingDmConversation(int me, int other) async {
    final myMemberships = await _supabase
        .schema('pathway')
        .from('conversation_members')
        .select('conversation_id')
        .eq('user_id', me);

    final conversationIds = (myMemberships as List)
        .map<int>((row) => row['conversation_id'] as int)
        .toList();

    if (conversationIds.isEmpty) return null;

    for (final conversationId in conversationIds) {
      final convoRow = await _supabase
          .schema('pathway')
          .from('conversations')
          .select('conversation_id, is_group')
          .eq('conversation_id', conversationId)
          .maybeSingle();

      if (convoRow == null) continue;
      if (convoRow['is_group'] == true) continue;

      final members = await _supabase
          .schema('pathway')
          .from('conversation_members')
          .select('user_id')
          .eq('conversation_id', conversationId);

      final memberIds =
          (members as List).map<int>((row) => row['user_id'] as int).toList();

      final isExactDm =
          memberIds.length == 2 &&
          memberIds.contains(me) &&
          memberIds.contains(other);

      if (isExactDm) {
        return conversationId;
      }
    }

    return null;
  }

  Future<int> createDmConversation({
    required int me,
    required int other,
    required String title,
  }) async {
    final convoRow = await _supabase
        .schema('pathway')
        .from('conversations')
        .insert({
          'is_group': false,
          'title': title,
        })
        .select('conversation_id')
        .single();

    final conversationId = convoRow['conversation_id'] as int;

    await _supabase
        .schema('pathway')
        .from('conversation_members')
        .insert([
          {
            'conversation_id': conversationId,
            'user_id': me,
          },
          {
            'conversation_id': conversationId,
            'user_id': other,
          },
        ]);

    return conversationId;
  }

  Future<int> openOrCreateDm({
    required int otherPathwayUserId,
    required String title,
  }) async {
    final me = await getCurrentPathwayUserId();
    if (me == null) {
      throw Exception('Could not find current user');
    }

    final existing = await findExistingDmConversation(me, otherPathwayUserId);
    if (existing != null) return existing;

    return createDmConversation(
      me: me,
      other: otherPathwayUserId,
      title: title,
    );
  }

  Future<int?> findExistingExactGroupConversation(List<int> memberIds) async {
    final sortedTarget = [...memberIds]..sort();

    final myMemberships = await _supabase
        .schema('pathway')
        .from('conversation_members')
        .select('conversation_id')
        .eq('user_id', sortedTarget.first);

    final conversationIds = (myMemberships as List)
        .map<int>((row) => row['conversation_id'] as int)
        .toList();

    for (final conversationId in conversationIds) {
      final convoRow = await _supabase
          .schema('pathway')
          .from('conversations')
          .select('conversation_id, is_group')
          .eq('conversation_id', conversationId)
          .maybeSingle();

      if (convoRow == null) continue;
      if (convoRow['is_group'] != true) continue;

      final members = await _supabase
          .schema('pathway')
          .from('conversation_members')
          .select('user_id')
          .eq('conversation_id', conversationId);

      final sortedExisting =
          (members as List).map<int>((row) => row['user_id'] as int).toList()
            ..sort();

      if (sortedExisting.length == sortedTarget.length) {
        bool same = true;
        for (int i = 0; i < sortedExisting.length; i++) {
          if (sortedExisting[i] != sortedTarget[i]) {
            same = false;
            break;
          }
        }
        if (same) return conversationId;
      }
    }

    return null;
  }

  Future<int> createGroupConversation({
    required List<int> memberIds,
    required String title,
  }) async {
    final convoRow = await _supabase
        .schema('pathway')
        .from('conversations')
        .insert({
          'is_group': true,
          'title': title,
        })
        .select('conversation_id')
        .single();

    final conversationId = convoRow['conversation_id'] as int;

    await _supabase
        .schema('pathway')
        .from('conversation_members')
        .insert(
          memberIds
              .map(
                (id) => {
                  'conversation_id': conversationId,
                  'user_id': id,
                },
              )
              .toList(),
        );

    return conversationId;
  }

  Future<int> openOrCreateExactGroup({
    required List<int> memberIds,
    required String title,
  }) async {
    final sortedIds = [...memberIds]..sort();

    final existing = await findExistingExactGroupConversation(sortedIds);
    if (existing != null) return existing;

    return createGroupConversation(
      memberIds: sortedIds,
      title: title,
    );
  }

      Future<List<Map<String, dynamic>>> getFollowedUsers() async {
    final me = await getCurrentPathwayUserId();
    if (me == null) return [];

    // people i follow
    final followingRows = await _supabase
        .schema('pathway')
        .from('user_subscriptions')
        .select('target_user_id')
        .eq('subscriber_user_id', me);

    final followingIds = (followingRows as List)
        .map<int>((row) => row['target_user_id'] as int)
        .toSet();

    if (followingIds.isEmpty) return [];

    // people who follow me
    final followerRows = await _supabase
        .schema('pathway')
        .from('user_subscriptions')
        .select('subscriber_user_id')
        .eq('target_user_id', me);

    final followerIds = (followerRows as List)
        .map<int>((row) => row['subscriber_user_id'] as int)
        .toSet();

    // intersection = mutual follows only
    final mutualIds = followingIds.intersection(followerIds).toList();

    if (mutualIds.isEmpty) return [];

    final userRows = await _supabase
        .schema('pathway')
        .from('users')
        .select('user_id, external_id, email')
        .inFilter('user_id', mutualIds);

    final externalIds = (userRows as List)
        .map<String>((row) => row['external_id'] as String)
        .toList();

    final profileRows = externalIds.isEmpty
        ? <dynamic>[]
        : await _supabase
            .schema('pathway')
            .from('profiles')
            .select('user_id, display_name, avatar_url')
            .inFilter('user_id', externalIds);

    final profileMap = <String, Map<String, dynamic>>{};
    for (final row in (profileRows as List)) {
      profileMap[row['user_id'] as String] = row as Map<String, dynamic>;
    }

    return (userRows as List).map<Map<String, dynamic>>((row) {
      final externalId = row['external_id'] as String;
      final email = row['email'] as String?;
      final profile = profileMap[externalId];

      final rawDisplayName = profile?['display_name'] as String?;
      final displayName =
          (rawDisplayName != null && rawDisplayName.trim().isNotEmpty)
              ? rawDisplayName
              : ((email != null && email.contains('@'))
                  ? email.split('@').first
                  : 'User');

      return {
        'user_id': row['user_id'],
        'external_id': externalId,
        'display_name': displayName,
        'avatar_url': profile?['avatar_url'],
      };
    }).toList();
  }
}