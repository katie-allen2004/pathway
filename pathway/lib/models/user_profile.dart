class UserProfile {
  final String id;
  final String userName;
  final String bio;
  final String? avatarUrl;

  UserProfile({
    required this.id,
    required this.userName, 
    required this.bio,
    this.avatarUrl,});

factory UserProfile.fromJson(Map<String, dynamic> json) {
  return UserProfile(
    id: json['user_id']?.toString() ?? '', 
    // This checks for the three most common variations in your project
    userName: json['display_name']  ?? 'Unknown User', 
    bio: json['bio'] ?? '',
    avatarUrl: (json['avatar_url'] as String?)?.trim().isEmpty == true
          ? null
          : (json['avatar_url'] as String?),
  );
}
}