class VenueDraftModel {
  final String draftId;
  final String userId;
  final String? venueName;
  final String? description;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? category;
  final String? imagePath;
  final String? operatingHours;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VenueDraftModel({
    required this.draftId,
    required this.userId,
    this.venueName,
    this.description,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.zipCode,
    this.category,
    this.imagePath,
    this.operatingHours,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory VenueDraftModel.fromMap(Map<String, dynamic> map) {
    return VenueDraftModel(
      draftId: map['draft_id'].toString(),
      userId: map['user_id'].toString(),
      venueName: map['venue_name'],
      description: map['description'],
      addressLine1: map['address_line1'],
      addressLine2: map['address_line2'],
      city: map['city'],
      state: map['state'],
      zipCode: map['zip_code'],
      category: map['category'],
      imagePath: map['image_path'],
      operatingHours: map['operating_hours'],
      status: map['status'],
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'])
          : null,
    );
  }
}