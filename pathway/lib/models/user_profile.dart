class UserProfile {
  final String id; // pathway.users.user_id as string
  final String externalId; // auth uuid / pathway.users.external_id
  final String userName;
  final String bio;
  final String? avatarUrl;

  UserProfile({
    required this.id,
    required this.externalId,
    required this.userName,
    required this.bio,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['user_id']?.toString() ?? '',
      externalId: json['external_id']?.toString() ?? '',
      userName: json['display_name'] ?? 'Unknown User',
      bio: json['bio'] ?? '',
      avatarUrl: (json['avatar_url'] as String?)?.trim().isEmpty == true
          ? null
          : (json['avatar_url'] as String?),
    );
  }
}