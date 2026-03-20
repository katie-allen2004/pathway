import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pathway/core/services/notification_controller.dart';
import 'package:pathway/models/notification.dart';
import 'package:pathway/core/routing/app_router.dart';

class InAppNotificationHost extends StatefulWidget {
  final Widget child;

  const InAppNotificationHost({
    super.key,
    required this.child,
  });

  @override
  State<InAppNotificationHost> createState() => _InAppNotificationHostState();
}

class _InAppNotificationHostState extends State<InAppNotificationHost> {
  OverlayEntry? _overlayEntry;
  StreamSubscription<InAppNotification>? _subscription;
  bool _isShowing = false;

  @override
  void initState() {
    super.initState();

    _subscription = InAppNotificationController.instance.stream.listen((n) {
      _showBanner(n);
    });
  }

  // _showBanner: Helper that displays a given notification
  void _showBanner(InAppNotification notification) {
    if (!mounted) return;

    // Close any open banners
    _overlayEntry?.remove();
    _overlayEntry = null;

    // Create overlay using context
    final overlay = AppRouter.navigatorKey.currentState?.overlay;
    if (overlay == null) {
      debugPrint('No overlay found');
      return;
    }

    // Create OverlayEntry using notification and onDismissed action
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return _TopBanner(
          notification: notification,
          onDismissed: _removeBanner,
        );
      },
    );

    // insert _overlayEntry into overlay and set _isShowing state to true
    overlay.insert(_overlayEntry!);
    _isShowing = true;
  }

  // _removeBanner: Helper that removes currently displayed banner
  void _removeBanner() {
    // If no banner is showing, return
    if (!_isShowing) return;

    // Otherwise, remove overlay entry, set it to null, and set _isShowing state to false
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isShowing = false;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _removeBanner();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _TopBanner extends StatefulWidget {
  final InAppNotification notification;
  final VoidCallback onDismissed;

  const _TopBanner({
    required this.notification,
    required this.onDismissed,
  });

  @override
  State<_TopBanner> createState() => _TopBannerState();
}

class _TopBannerState extends State<_TopBanner>
  with SingleTickerProviderStateMixin {
    late final AnimationController _controller;
    late final Animation<Offset> _slide;
    Timer? _timer;

    @override
    void initState() {
      super.initState();

      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 250),
        reverseDuration: const Duration(milliseconds: 200),
      );

      _slide = Tween<Offset>(
        begin: const Offset(0, -1.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));

      _controller.forward();

      _timer = Timer(widget.notification.duration, () async {
        if (!mounted) return;
        await _controller.reverse();
        widget.onDismissed();
      });
    }

    @override
    void dispose() {
      _timer?.cancel();
      _controller.dispose();
      super.dispose();
    }

    Future<void> _dismissNow() async {
      _timer?.cancel();
      await _controller.reverse();
      widget.onDismissed();
    }

    @override
    Widget build(BuildContext context) {
      final topPadding = MediaQuery.of(context).padding.top;

      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          bottom: false,
          child: SlideTransition(
            position: _slide,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: () async {
                  final route = widget.notification.route;
                  await _dismissNow();

                  if (route != null) {
                    AppRouter.navigatorKey.currentState?.pushNamed(route);
                  }
                },

                child: Container(
                  margin: EdgeInsets.fromLTRB(12, topPadding > 0 ? 8 : 12, 12, 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 16,
                        offset: Offset(0, 8),
                        color: Colors.black26,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_rounded, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.notification.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.notification.body,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _dismissNow,
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ),
        ),
      );
    }
  }