import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// shell of model for incoming notifications 
// (backend logic)
class AppNotification {
  final int notificationId;
  final int recipientUserId;
  final int? actorUserId;
  final String type; // dm / user_post / venue_post
  final int? venueId;
  final int? reviewId;
  final int? conversationId;
  final int? messageId;
  final DateTime createdAt;
  final DateTime? readAt;

  AppNotification({
    required this.notificationId,
    required this.recipientUserId,
    required this.type,
    required this.createdAt,
    this.actorUserId,
    this.venueId,
    this.reviewId,
    this.conversationId,
    this.messageId,
    this.readAt,
  });

  factory AppNotification.fromRow(Map<String, dynamic> row) {
    return AppNotification(
      notificationId: row['notification_id'] as int,
      recipientUserId: row['recipient_user_id'] as int,
      actorUserId: row['actor_user_id'] as int?,
      type: row['type'] as String,
      venueId: row['venue_id'] as int?,
      reviewId: row['review_id'] as int?,
      conversationId: row['conversation_id'] as int?,
      messageId: row['message_id'] as int?,
      createdAt: DateTime.parse(row['created_at'] as String),
      readAt: row['read_at'] == null ? null : DateTime.parse(row['read_at'] as String),
    );
  }
}

// figures out self pathway user_id
// subscribes to realtime INSERTs in pathway.notifications for self
// exposes a stream + unread count for UI to use
class NotificationRealtimeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  RealtimeChannel? _channel;
  final _controller = StreamController<AppNotification>.broadcast();

  // UI can listen to this stream and show any alert it wants (badge/toast/list)
  Stream<AppNotification> get stream => _controller.stream;

  // simple unread count (UI can display a badge with this)
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  int? _myPathwayUserId;

  // call once after login
  Future<void> start() async {
    // get the current user's pathway user_id using the pathway.me view
    final me = await _supabase.schema('pathway').from('me').select('user_id').maybeSingle();
    if (me == null) {
      throw Exception('No pathway.me row found. Make sure auth->pathway trigger is working.');
    }

    _myPathwayUserId = me['user_id'] as int;

    // load unread count
    await refreshUnreadCount();

    // subscribe to realtime inserts for self notifications only
    final uid = _myPathwayUserId!;
    _channel = _supabase.channel('notifications:$uid')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'pathway',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'recipient_user_id',
          value: uid.toString(),
        ),
        callback: (payload) async {
          final row = payload.newRecord;
          if (row == null) return;

          final notif = AppNotification.fromRow(row);
          _controller.add(notif);

          // update badge count
          if (notif.readAt == null) {
            unreadCount.value = unreadCount.value + 1;
          }
        },
      )
      .subscribe();
  }

  // call on logout or app dispose
  Future<void> stop() async {
    if (_channel != null) {
      await _supabase.removeChannel(_channel!);
      _channel = null;
    }
    _myPathwayUserId = null;
    unreadCount.value = 0;
  }

  // refresh unread count from DB (on app start or after marking read)
  Future<void> refreshUnreadCount() async {
    final uid = _myPathwayUserId;
    if (uid == null) return;

    final res = await _supabase
        .schema('pathway')
        .from('notifications')
        .select('notification_id')
        .eq('recipient_user_id', uid)
        .isFilter('read_at', null);

    unreadCount.value = (res as List).length;
  }

  // mark one notification read 
  Future<void> markRead(int notificationId) async {
    await _supabase
        .schema('pathway')
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('notification_id', notificationId);

    // keep badge accurate
    await refreshUnreadCount();
  }

  // delete a notification
  Future<void> deleteNotification(int notificationId) async {
    await _supabase
        .schema('pathway')
        .from('notifications')
        .delete()
        .eq('notification_id', notificationId);

    await refreshUnreadCount();
  }
}