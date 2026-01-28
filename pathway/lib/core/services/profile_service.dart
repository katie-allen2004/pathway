import 'api_client.dart';
import '/models/user_profile.dart';

class ProfileService {
  final ApiClient apiClient;

  ProfileService({required this.apiClient});

  Future<List<UserProfile>> searchProfiles(String query, String keyword) async 
  {
    final data = await apiClient.get('/search?query=$query&keyword=$keyword');
    return (data as List).map((item) => UserProfile.fromJson(item)).toList();
  }
}