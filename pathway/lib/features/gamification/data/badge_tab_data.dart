import 'package:pathway/features/gamification/data/badge_model.dart';

class BadgeTabData {
  final List<BadgeModel> earned;
  final List<BadgeModel> locked;

  BadgeTabData({
    required this.earned,
    required this.locked,
  });
}