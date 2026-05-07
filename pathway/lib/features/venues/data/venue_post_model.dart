class VenuePostModel {
  final String postId;
  final int venueId;
  final String userId;
  final String content;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VenuePostModel({
    required this.postId,
    required this.venueId,
    required this.userId,
    required this.content,
    this.createdAt,
    this.updatedAt,
  });

  factory VenuePostModel.fromMap(Map<String, dynamic> map) {
    return VenuePostModel(
      postId: map['post_id'].toString(),
      venueId: (map['venue_id'] as num).toInt(),
      userId: map['user_id'].toString(),
      content: map['content']?.toString() ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }
}