import 'package:supabase_flutter/supabase_flutter.dart';

class UserRepository {
  final _client = Supabase.instance.client;

  /// use case 11
  /// options 
  Future<void> reportUser({
    required String reportedUserId,
    required String reason,
    String? comment,
  }) async {
    final currentUserId = _client.auth.currentUser?.id;
    
    // self reporting 
    if (currentUserId == null) throw Exception("User must be logged in.");
    if (currentUserId == reportedUserId) throw Exception("You cannot report yourself.");

    try {
      await _client
          .schema('pathway')
          .from('user_reports')
          .insert({
            'reporter_user_id': currentUserId,
            'reported_user_id': reportedUserId,
            'reason': reason,
            'comment': comment,
          });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception("You have already reported this user.");
      }
      rethrow;
    }
  }

  /// case 11
  Future<List<Map<String, dynamic>>> fetchAllReports() async {
    try {
      final response = await _client
          .schema('pathway')
          .from('user_reports')
          .select('''
            *,
            reporter:reporter_user_id(id),
            reported:reported_user_id(id)
          ''')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception("Failed to load reports: $e");
    }
  }
  Future<bool> checkUserReportExists(String reportedUserId) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return false;

    final response = await _client
        .schema('pathway')
        .from('user_reports')
        .select('report_id')
        .eq('reporter_user_id', currentUserId)
        .eq('reported_user_id', reportedUserId)
        .maybeSingle();

    return response != null;
  }
}