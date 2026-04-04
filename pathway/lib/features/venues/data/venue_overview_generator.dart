import 'review_model.dart';
import '../../reviews/data/review_moderator.dart';

// Generates a short AI-style text summary for a venue based on its reviews.
class VenueOverviewGenerator {
  // Small word-score map.
  // Based on a simplified AFINN-style sentiment lexicon.
  static const Map<String, int> _wordScores = {
    // positive words
    'great': 3, 'excellent': 3, 'amazing': 3, 'wonderful': 3, 'fantastic': 3,
    'good': 2, 'nice': 2, 'love': 2, 'friendly': 2, 'helpful': 2,
    'clean': 2, 'accessible': 2, 'comfortable': 2, 'welcoming': 2, 'beautiful': 2,
    'perfect': 3, 'recommend': 2, 'easy': 1, 'spacious': 2, 'convenient': 2,
    'awesome': 3, 'superb': 3, 'pleasant': 2, 'enjoyed': 2, 'liked': 1,
    'happy': 2, 'satisfied': 2, 'best': 3, 'safe': 2, 'smooth': 1,
    // negative words
    'bad': -2, 'terrible': -3, 'awful': -3, 'horrible': -3, 'poor': -2,
    'dirty': -2, 'rude': -2, 'slow': -1, 'difficult': -2, 'inconvenient': -2,
    'inaccessible': -3, 'broken': -2, 'missing': -1, 'narrow': -1, 'steep': -1,
    'cramped': -2, 'crowded': -1, 'noisy': -1, 'unfriendly': -2, 'disappointing': -2,
    'worst': -3, 'avoid': -2, 'dislike': -2, 'hate': -3, 'unhelpful': -2,
    'unsafe': -3, 'dangerous': -3, 'outdated': -1, 'neglected': -2,
  };

  // Aspect keyword groups — these map to topics visitors commonly care about.
  static const Map<String, List<String>> _aspects = {
    'accessibility': [
      'wheelchair', 'ramp', 'accessible', 'elevator', 'lift', 'step',
      'entrance', 'disabled', 'mobility', 'railing', 'stepfree',
    ],
    'atmosphere': [
      'atmosphere', 'vibe', 'cozy', 'welcoming', 'warm', 'noisy',
      'quiet', 'crowded', 'spacious', 'comfortable', 'environment',
    ],
    'staff': [
      'staff', 'service', 'friendly', 'helpful', 'rude', 'attentive',
      'employee', 'worker', 'team', 'host', 'manager',
    ],
    'cleanliness': [
      'clean', 'dirty', 'tidy', 'mess', 'smell', 'hygiene',
      'bathroom', 'restroom', 'toilet', 'spotless',
    ],
  };

  /// Main method
  static String generateOverview(List<ReviewModel> reviews) {
    if (reviews.isEmpty) {
      return 'No reviews yet. Be the first to share your experience!';
    }

    // Get the average star rating across all reviews
    final avgRating = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

    // Only work with reviews that have written text
    final textReviews = reviews
        .where((r) => r.text != null && r.text!.trim().isNotEmpty)
        .toList();

    final buffer = StringBuffer();

    // Opening sentence based on average rating
    if (avgRating >= 4.0) {
      buffer.write('Visitors generally love this venue. ');
    } else if (avgRating >= 3.0) {
      buffer.write('Visitors have mixed opinions about this venue. ');
    } else {
      buffer.write('Most visitors have had a disappointing experience here. ');
    }

    if (textReviews.isEmpty) {
      buffer.write('No written reviews yet.');
      return buffer.toString().trim();
    }

    // Aspect feedback (what topics came up positively/negatively)
    final aspectLine = _getAspectFeedback(textReviews);
    if (aspectLine.isNotEmpty) {
      buffer.write('$aspectLine ');
    }

    // Common themes across reviews
    final themeLine = _buildThemeLine(textReviews);
    if (themeLine.isNotEmpty) {
      buffer.write('$themeLine ');
    }

    // Top-scored quotes from different reviews
    final quotes = _findTopSentences(textReviews, max: 2);
    if (quotes.isNotEmpty) {
      buffer.write('In their own words: ');
      for (final q in quotes) {
        final capped = q[0].toUpperCase() + q.substring(1);
        buffer.write('"$capped" ');
      }
    }

    return buffer.toString().trim();
  }

  // Scores every sentence in every review and returns the top [max] sentences, making sure they come from different reviews so the summary isn't dominated by a single person.
  static List<String> _findTopSentences(List<ReviewModel> reviews, {int max = 2}) {
    // Each entry: (sentence, score, reviewIndex)
    final candidates = <(String, double, int)>[];

    for (int i = 0; i < reviews.length; i++) {
      final review = reviews[i];
      final sentences = review.text!.split(RegExp(r'[.!?]+'));
      for (final sentence in sentences) {
        final trimmed = sentence.trim();
        if (trimmed.length < 20) continue;
        final score = _scoreSentence(trimmed, review.rating);
        if (score > 0) candidates.add((trimmed, score, i));
      }
    }

    // Sort by score descending
    candidates.sort((a, b) => b.$2.compareTo(a.$2));

    // Pick top sentences, one per review
    final picked = <String>[];
    final usedReviews = <int>{};
    for (final c in candidates) {
      if (picked.length >= max) break;
      if (usedReviews.contains(c.$3)) continue;
      picked.add(c.$1);
      usedReviews.add(c.$3);
    }

    return picked;
  }

  // Finds the most frequently used meaningful words across all reviews and
  // builds a short sentence like "Reviewers frequently mention words like
  // spacious, welcoming and clean."
  static String _buildThemeLine(List<ReviewModel> reviews) {
    final wordCount = <String, int>{};

    for (final review in reviews) {
      // Use a set so one word only counts once per review
      final words = ReviewModerator.preprocessText(review.text!).toSet();
      for (final word in words) {
        // Only count words that carry sentiment
        if (_wordScores.containsKey(word)) {
          wordCount[word] = (wordCount[word] ?? 0) + 1;
        }
      }
    }

    if (wordCount.isEmpty) return '';

    // Sort by frequency, keep top 4 most-mentioned words
    final sorted = wordCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topWords = sorted
        .where((e) => e.value > 1) // must appear in at least 2 reviews
        .take(4)
        .map((e) => e.key)
        .toList();

    if (topWords.isEmpty) return '';

    return 'Reviewers frequently mention: ${_joinWords(topWords)}.';
  }

  // Scores a single sentence: sentiment * rating weight
  static double _scoreSentence(String sentence, int rating) {
    final words = ReviewModerator.preprocessText(sentence);
    double total = 0;
    for (final word in words) {
      total += _wordScores[word] ?? 0;
    }
    // Weight it by how positive the overall review rating was
    return total * (rating / 5.0);
  }

  // Counts which aspects were mentioned positively vs negatively across reviews.
  // Returns a sentence like "Praised for accessibility and staff."
  static String _getAspectFeedback(List<ReviewModel> reviews) {
    // Track a net score for each aspect (positive reviews push it up, negative push it down)
    final Map<String, int> aspectScore = {for (final k in _aspects.keys) k: 0};

    for (final review in reviews) {
      final words = ReviewModerator.preprocessText(review.text!);
      // +1 for a good review, -1 for a bad one, 0 for neutral
      final boost = review.rating >= 4 ? 1 : review.rating <= 2 ? -1 : 0;
      if (boost == 0) continue;

      for (final entry in _aspects.entries) {
        for (final keyword in entry.value) {
          if (words.contains(keyword)) {
            aspectScore[entry.key] = aspectScore[entry.key]! + boost;
            break; // Only count each aspect once per review
          }
        }
      }
    }

    final praised = <String>[];
    final criticized = <String>[];
    for (final entry in aspectScore.entries) {
      if (entry.value > 0) praised.add(entry.key);
      if (entry.value < 0) criticized.add(entry.key);
    }

    if (praised.isEmpty && criticized.isEmpty) return '';

    final buffer = StringBuffer();
    if (praised.isNotEmpty) {
      buffer.write('Praised for ${_joinWords(praised)}.');
    }
    if (criticized.isNotEmpty) {
      buffer.write(' Some concerns about ${_joinWords(criticized)}.');
    }
    return buffer.toString().trim();
  }

  // Joins a list of words naturally
  static String _joinWords(List<String> words) {
    if (words.length == 1) return words[0];
    if (words.length == 2) return '${words[0]} and ${words[1]}';
    return '${words.sublist(0, words.length - 1).join(', ')} and ${words.last}';
  }
}
