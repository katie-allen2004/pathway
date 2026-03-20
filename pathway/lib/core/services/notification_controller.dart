import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pathway/models/notification.dart';

class InAppNotificationController {
  InAppNotificationController._();

  static final InAppNotificationController instance = 
    InAppNotificationController._();

  final StreamController<InAppNotification> _streamController = StreamController<InAppNotification>.broadcast();

  Stream<InAppNotification> get stream => _streamController.stream;

  void show(InAppNotification notification) {
    _streamController.add(notification);
  }

  void dispose() {
    _streamController.close();
  }
}