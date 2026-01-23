import 'package:flutter/material.dart';
import 'features/auth/presentation/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const PathwayApp()); // Run main
}

class PathwayApp extends StatelessWidget {
  const PathwayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pathway',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        textTheme: GoogleFonts.robotoTextTheme(),
      ),
      home: const LoginScreen(),
    );
  }
}