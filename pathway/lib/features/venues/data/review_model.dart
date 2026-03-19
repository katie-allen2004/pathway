class ReviewModel {
  final int id;
  final int venueId;
  final String userId; // auth uuid
  final int rating;
  final String? text;
  final DateTime? createdAt;
  final List<String> photos;
  final List<String> videos;

  ReviewModel({
    required this.id,
    required this.venueId,
    required this.userId,
    required this.rating,
    this.text,
    this.createdAt,
    this.photos = const [],
    this.videos = const [],
  });

  static bool _isVideo(String url) {
    final lower = url.toLowerCase().split('?').first;
    return lower.endsWith('.mp4') || lower.endsWith('.mov') ||
        lower.endsWith('.avi') || lower.endsWith('.webm');
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    final List<String> photos = [];
    final List<String> videos = [];
    if (map['review_photos'] is List) {
      for (final p in map['review_photos'] as List) {
        final url = p['url']?.toString();
        if (url == null) continue;
        if (ReviewModel._isVideo(url)) {
          videos.add(url);
        } else {
          photos.add(url);
        }
      }
    }

    return ReviewModel(
      id: (map['review_id'] as num?)?.toInt() ?? 0,
      venueId: (map['venue_id'] as num?)?.toInt() ?? 0,
      userId: map['user_id']?.toString() ?? '',
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      text: map['review_text']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      photos: photos,
      videos: videos,
    );
  }
}