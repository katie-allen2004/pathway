class VenueSuggestionModel {
  final String suggestionId;
  final int venueId;
  final String userId;
  final String fieldName;
  final String proposedValue;
  final String status;
  final DateTime? createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  VenueSuggestionModel({
    required this.suggestionId,
    required this.venueId,
    required this.userId,
    required this.fieldName,
    required this.proposedValue,
    required this.status,
    this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  factory VenueSuggestionModel.fromMap(Map<String, dynamic> map) {
    return VenueSuggestionModel(
      suggestionId: map['suggestion_id'].toString(),
      venueId: (map['venue_id'] as num).toInt(),
      userId: map['user_id'].toString(),
      fieldName: map['field_name'].toString(),
      proposedValue: map['proposed_value'].toString(),
      status: map['status'].toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      reviewedAt: map['reviewed_at'] != null
          ? DateTime.tryParse(map['reviewed_at'].toString())
          : null,
      reviewedBy: map['reviewed_by']?.toString(),
    );
  }
}