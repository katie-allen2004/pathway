import 'package:supabase_flutter/supabase_flutter.dart';

class VenueModel {
  final int id;
  final String name;
  final String status; 
  final String? modNotes; 
  final String? city;
  final String? zipCode;
  final String? description;
  final String? category;
  final String? addressLine1;
  final bool isSaved;
  final String? createdByUserId;
  final String? imagePath;
  final List<String> tags;
  final double averageRating;
  final int totalReviews;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? operatingHours; 

  VenueModel({
    required this.id,
    required this.name,
    required this.status,
    this.modNotes,
    this.city,
    this.zipCode,
    this.description,
    this.category,
    this.addressLine1,
    this.isSaved = false,
    this.createdByUserId,
    this.imagePath,
    this.tags = const [],
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.latitude,
    this.longitude,
    this.operatingHours,
  });

  String get imageUrl {
    if (imagePath == null || imagePath!.isEmpty) {
      return 'https://via.placeholder.com/400x200?text=No+Image+Available';
    }
    if (imagePath!.startsWith('http')) return imagePath!;
    return Supabase.instance.client.storage.from('avatars').getPublicUrl(imagePath!);
  }

  VenueModel copyWith({
    bool? isSaved,
    String? name,
    String? status,
    String? modNotes,
    String? city,
    String? zipCode,
    String? description,
    String? addressLine1,
    String? imagePath,
    List<String>? tags,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? operatingHours, 
  }) {
    return VenueModel(
      id: id,
      name: name ?? this.name,
      status: status ?? this.status,
      modNotes: modNotes ?? this.modNotes,
      city: city ?? this.city,
      zipCode: zipCode ?? this.zipCode,
      description: description ?? this.description,
      category: category,
      addressLine1: addressLine1 ?? this.addressLine1,
      isSaved: isSaved ?? this.isSaved,
      createdByUserId: createdByUserId,
      imagePath: imagePath ?? this.imagePath,
      tags: tags ?? this.tags,
      averageRating: averageRating,
      totalReviews: totalReviews,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      operatingHours: operatingHours ?? this.operatingHours,
    );
  }

  /// map from supabase
  factory VenueModel.fromJson(Map<String, dynamic> json, {bool? isSaved}) {
    List<String> extractedTags = [];
    if (json['tags'] is List) {
      extractedTags = List<String>.from(json['tags']);
    } else if (json['venue_tags'] != null) {
      final List rawVenueTags = json['venue_tags'] as List;
      for (var vt in rawVenueTags) {
        final tagTable = vt['accessibility_tags'] as Map<String, dynamic>?;
        if (tagTable != null && tagTable['tag_name'] != null) {
          extractedTags.add(tagTable['tag_name'].toString());
        }
      }
    }

    double avg = 0.0;
    int count = 0;
    if (json['venue_reviews'] != null) {
      final List reviews = json['venue_reviews'] as List;
      count = reviews.length;
      if (count > 0) {
        final total = reviews.fold<double>(
          0.0,
          (sum, r) => sum + (r['rating'] as num? ?? 0).toDouble(),
        );
        avg = total / count;
      }
    }

    bool favoriteCalculated = false;
    if (json['user_favorites'] != null) {
      final List favs = json['user_favorites'] as List;
      favoriteCalculated = favs.isNotEmpty;
    }

    return VenueModel(
      id: (json['venue_id'] as num?)?.toInt() ?? 0,
      name: json['name'] ?? 'Unknown Venue',
      status: json['status'] ?? 'pending',
      modNotes: json['moderator_notes'] ?? json['mod_notes'] ?? json['modNotes'],
      city: json['city'],
      zipCode: json['zip_code'] ?? json['zip'],
      description: json['description'],
      category: json['category'],
      addressLine1: json['address_line1'] ?? json['address'],
      isSaved: isSaved ?? favoriteCalculated,
      createdByUserId: json['created_by_user_id'] ?? json['created_by'],
      imagePath: json['image_path'],
      tags: extractedTags,
      averageRating: (json['average_rating'] as num? ?? avg).toDouble(),
      totalReviews: (json['total_reviews'] as int? ?? count),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      operatingHours: json['operating_hours'] as Map<String, dynamic>?, 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'status': status,
      'moderator_notes': modNotes,
      'city': city,
      'zip_code': zipCode,
      'description': description,
      'address_line1': addressLine1,
      'image_path': imagePath,
      'latitude': latitude,
      'longitude': longitude,
      'operating_hours': operatingHours, 
    };
  }
}