class VenueModel {
  final String id; // uuid
  final String name;
  final String? addressLine1;
  final String? city;
  final String? description;
  final bool isSaved;

  VenueModel({
    required this.id,
    required this.name,
    this.addressLine1,
    this.city,
    this.description,
    this.isSaved = false,
  });
 factory VenueModel.fromJson(
  Map<String, dynamic> json, {
  bool isSaved = false,
}) {
  return VenueModel(
    id: (json['id'] ?? '').toString(),
    name: (json['name'] ?? 'Unnamed Venue').toString(),
    addressLine1: (json['address'] ?? '').toString(),
    city: '', // not in DB yet
    description: '', // not in DB yet
    isSaved: isSaved,
  );
}}
