class InAppNotification {
  final String title;
  final String body;
  final String? route;
  final Duration duration;

  const InAppNotification({
    required this.title,
    required this.body,
    this.route,
    this.duration = const Duration(seconds: 4)
  });
}