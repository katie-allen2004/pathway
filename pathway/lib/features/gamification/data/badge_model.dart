class BadgeModel {
  final int badgeId;
  final String code;
  final String name;
  final String description;
  final String? iconKey;
  final String? colorHex;

  BadgeModel({
    required this.badgeId,
    required this.code,
    required this.name,
    required this.description,
    this.iconKey,
    this.colorHex,
  });

  factory BadgeModel.fromMap(Map<String, dynamic> map) {
    return BadgeModel(
      badgeId: (map['badge_id'] as num).toInt(),
      code: map['code'] as String,
      name: map['badge_name'] as String,
      description: (map['description'] ?? '') as String,
      iconKey: map['icon_key'] as String?,
      colorHex: map['color_hex'] as String?,
    );
  }
}