import 'package:flutter/material.dart';
import '../../data/venue_subscription_service.dart';

class SubscribeVenueButton extends StatefulWidget {
  final String venueId;

  const SubscribeVenueButton({
    super.key,
    required this.venueId,
  });

  @override
  State<SubscribeVenueButton> createState() =>
      _SubscribeVenueButtonState();
}

class _SubscribeVenueButtonState
    extends State<SubscribeVenueButton> {
  final _service = VenueSubscriptionService();

  bool _isSubscribed = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  // load current subscription state
  Future<void> _loadStatus() async {
    try {
      final result = await _service.isSubscribed(widget.venueId);

      if (!mounted) return;

      setState(() {
        _isSubscribed = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      debugPrint('subscription load error: $e');
    }
  }

  // toggle subscribe/unsubscribe
  Future<void> _toggleSubscription() async {
    setState(() => _loading = true);

    try {
      if (_isSubscribed) {
        await _service.unsubscribe(widget.venueId);
      } else {
        await _service.subscribe(widget.venueId);
      }

      await _loadStatus();
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      debugPrint('subscription toggle error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('subscription failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 36,
        width: 36,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

  return SizedBox(
    height: 44,
    child: OutlinedButton.icon(
      onPressed: _toggleSubscription,
      icon: Icon(
        _isSubscribed
            ? Icons.notifications_active
            : Icons.notifications_none,
        size: 18,
      ),
      label: Text(_isSubscribed ? 'Subscribed' : 'Subscribe'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
  }
}