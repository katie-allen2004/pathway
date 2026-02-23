import 'package:supabase_flutter/supabase_flutter.dart';

class VenueModel {
  final int id;
  final String? name;
  final String? city;
  final String? zipCode;
  final String? description;
  final String? category;
  final String? addressLine1;
  final bool? isSaved;
  final String? createdByUserId;
  final String? imagePath; 

  final List<String> tags; 
  final double averageRating; 
  final int totalReviews; 

  VenueModel({
    required this.id,
    this.name,
    this.city,
    this.zipCode,
    this.description,
    this.category,
    this.addressLine1,
    this.isSaved,
    this.createdByUserId,
    this.imagePath,
    this.tags = const [],
    this.averageRating = 0.0,
    this.totalReviews = 0,
  });

  String get imageUrl {
    if (imagePath == null || imagePath!.isEmpty) {
      return 'https://via.placeholder.com/400x200?text=No+Image+Available';
    }
    return Supabase.instance.client.storage
        .from('avatars')
        .getPublicUrl(imagePath!);
  }

  double get rating => averageRating;

  factory VenueModel.fromJson(Map<String, dynamic> json) {
    // process Tags
    List<String> extractedTags = [];
    if (json['venue_tags'] != null) {
      final List rawVenueTags = json['venue_tags'] as List;
      for (var vt in rawVenueTags) {
        final tagTable = vt['accessibility_tags'] as Map<String, dynamic>?;
        if (tagTable != null && tagTable['tag_name'] != null) {
          extractedTags.add(tagTable['tag_name'].toString());
        }
      }
    }

    // process Ratings/Reviews
    double avg = 0.0;
    int count = 0;
    if (json['venue_reviews'] != null) {
      final List reviews = json['venue_reviews'] as List;
      count = reviews.length;
      if (count > 0) {
        final total = reviews.fold<double>(
          0.0, 
          (sum, r) => sum + (r['rating'] as num? ?? 0).toDouble()
        );
        avg = total / count;
      }
    }

    return VenueModel(
      //  mapping 'venue_id' from Supabase to 'id' in local model
      id: json['venue_id'] as int,
      name: json['name'],
      city: json['city'],
      zipCode: json['zip'], 
      description: json['description'],
      category: json['category'],
      addressLine1: json['address_line_1'], 
      isSaved: json['is_saved'] ?? false,
      createdByUserId: json['created_by_user_id'],
      imagePath: json['image_path'], 
      tags: extractedTags,
      averageRating: avg,
      totalReviews: count,
    );
  }
}