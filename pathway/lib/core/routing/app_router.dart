import 'package:flutter/material.dart';

Future<dynamic> routePage(BuildContext context, Widget page) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => page),
  );
}