class ReviewModel {
  final int id;
  final int venueId;
  final String userId; // auth uuid
  final int rating;
  final String? text;
  final DateTime? createdAt;

  ReviewModel({
    required this.id,
    required this.venueId,
    required this.userId,
    required this.rating,
    this.text,
    this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: (map['review_id'] as num?)?.toInt() ?? 0,
      venueId: (map['venue_id'] as num?)?.toInt() ?? 0,
      userId: map['user_id']?.toString() ?? '',
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      text: map['review_text']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }
}