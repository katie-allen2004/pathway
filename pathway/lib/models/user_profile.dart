class UserProfile {
  final String userName;
  final String email;
  final String interest;

  UserProfile({
    required this.userName, 
    required this.email, 
    required this.interest});

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userName: json['userName;'] ?? '',
      email: json['email'] ?? '',
      interest: json['interest'] ?? '',
    );
  }
}