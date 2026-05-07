class ReviewModel {
  final int id;
  final int venueId;
  final String userId;
  final String? username;
  final int rating;
  final String? text;
  final DateTime? createdAt;

  // Vote credibility data
  final int helpfulCount;
  final int outdatedCount;
  final int inaccurateCount;
  final int totalVotes;
  final String? currentUserVote; // 'helpful', 'outdated', 'inaccurate', or null
  final bool isFlagged;

  // Media attachments
  final List<String> photos;
  final List<String> videos;

  ReviewModel({
    required this.id,
    required this.venueId,
    required this.userId,
    this.username,
    required this.rating,
    this.text,
    this.createdAt,
    this.helpfulCount = 0,
    this.outdatedCount = 0,
    this.inaccurateCount = 0,
    this.totalVotes = 0,
    this.currentUserVote,
    this.isFlagged = false,
    this.photos = const [],
    this.videos = const [],
  });

  static bool _isVideo(String url) {
    final lower = url.toLowerCase().split('?').first;
    return lower.endsWith('.mp4') || lower.endsWith('.mov') ||
        lower.endsWith('.avi') || lower.endsWith('.webm');
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    // Calculate if flagged based on vote counts
    final outdated = (map['outdated_count'] as num?)?.toInt() ?? 0;
    final inaccurate = (map['inaccurate_count'] as num?)?.toInt() ?? 0;
    final flagged = outdated >= 3 || inaccurate >= 3;

    // Parse media attachments
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
      username: map['username']?.toString(),
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      text: map['review_text']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      helpfulCount: (map['helpful_count'] as num?)?.toInt() ?? 0,
      outdatedCount: outdated,
      inaccurateCount: inaccurate,
      totalVotes: (map['total_votes'] as num?)?.toInt() ?? 0,
      currentUserVote: map['current_user_vote']?.toString(),
      isFlagged: flagged,
      photos: photos,
      videos: videos,
    );
  }
  
  /// Returns true if this review has enough negative votes to warrant attention
  bool get needsModeration => isFlagged;
  
  /// Returns a credibility score from 0-100 based on votes
  /// Higher is better (more helpful, fewer negative votes)
  int get credibilityScore {
    if (totalVotes == 0) return 50; // Neutral score for no votes
    
    // Weight helpful positively, negative votes negatively
    final score = ((helpfulCount * 2.0) - (outdatedCount + inaccurateCount)) / totalVotes;
    
    // Normalize to 0-100 scale
    final normalized = ((score + 2) / 4 * 100).clamp(0, 100);
    return normalized.round();
  }
}
