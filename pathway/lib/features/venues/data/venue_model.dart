// Helps with mapping the sql colums like the venue id and the name to flutter objects
class VenueModel {
  final int id; // Primary Key from SQL
  final String name;
  final String? description;
  final String? city;
  final String? addressLine1; // New field for address line 1
  bool isSaved;

  VenueModel({
    required this.id,
    required this.name,
    this.addressLine1,
    this.description,
    this.city,
    this.isSaved = false,
  });

  factory VenueModel.fromJson(Map<String, dynamic> json, {bool isSaved = false}) {
    return VenueModel(
      id: json['venue_id'],
      name: json['name'] ?? 'Unnamed Venue',
      addressLine1: json['address_line1'], // Map the new field
      description: json['description'],
      city: json['city'],
      isSaved: json['is_saved'] ?? false,
    );
  }
}