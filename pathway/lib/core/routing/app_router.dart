import 'package:flutter/material.dart';

void routePage(BuildContext context, Widget page) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => page),
  );
}