class VenueImageModel {
  final String imageId;
  final int venueId;
  final String imagePath;
  final bool isPrimary;
  final String? uploadedBy;
  final DateTime? createdAt;

  VenueImageModel({
    required this.imageId,
    required this.venueId,
    required this.imagePath,
    required this.isPrimary,
    this.uploadedBy,
    this.createdAt,
  });

  factory VenueImageModel.fromMap(Map<String, dynamic> map) {
    return VenueImageModel(
      imageId: map['image_id'].toString(),
      venueId: (map['venue_id'] as num).toInt(),
      imagePath: map['image_path'].toString(),
      isPrimary: map['is_primary'] == true,
      uploadedBy: map['uploaded_by']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }
}