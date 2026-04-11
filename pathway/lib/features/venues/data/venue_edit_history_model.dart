class VenueEditHistoryModel {
  final String editId;
  final int venueId;
  final String editedBy;
  final String fieldName;
  final String? oldValue;
  final String? newValue;
  final DateTime? createdAt;

  VenueEditHistoryModel({
    required this.editId,
    required this.venueId,
    required this.editedBy,
    required this.fieldName,
    this.oldValue,
    this.newValue,
    this.createdAt,
  });

  factory VenueEditHistoryModel.fromMap(Map<String, dynamic> map) {
    return VenueEditHistoryModel(
      editId: map['edit_id'].toString(),
      venueId: (map['venue_id'] as num).toInt(),
      editedBy: map['edited_by'].toString(),
      fieldName: map['field_name'].toString(),
      oldValue: map['old_value']?.toString(),
      newValue: map['new_value']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }
}