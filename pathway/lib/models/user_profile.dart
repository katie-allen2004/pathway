class UserProfile {
  final String id;
  final String userName;
  final String bio;

  UserProfile({
    required this.id,
    required this.userName, 
    required this.bio,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] ?? json['user_id'])?.toString() ?? '', 
      
      userName: json['display_name'] ?? 'Unknown User', 
      
      bio: json['bio'] ?? '',
    );
  }
}