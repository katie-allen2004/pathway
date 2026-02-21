import 'package:flutter/material.dart';
import 'features/auth/presentation/login_screen.dart';
import 'package:google_fonts/google_fonts.dart'; // Added Google Fonts package for custom font
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /* 
  Keep in case of future reimplementation of environment variables for supabase credentials
  
  final supabaseUrlRaw = const String.fromEnvironment('SUPABASE_URL');
  final supabaseUrl = supabaseUrlRaw.replaceFirst(RegExp(r'\/$'), ''); // remove trailing slash
  final supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY'); 
  
  */

  final supabaseUrl = 'https://bpdsfialugbzmorsjjbj.supabase.co';
  final supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJwZHNmaWFsdWdiem1vcnNqamJqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk3NDAxNzksImV4cCI6MjA4NTMxNjE3OX0.2HQND6IaMGLlAn-cee1gVoyYNiQQibN6nxnjvtrQHfE';

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  debugPrint('SUPABASE_URL=$supabaseUrl');

  runApp(const PathwayApp());
}

class PathwayApp extends StatelessWidget {
  const PathwayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pathway',
      theme: ThemeData(
        scaffoldBackgroundColor: Color.fromARGB(
          255,
          233,
          234,
          247,
        ), // Set standard background color for all screens
        appBarTheme: const AppBarTheme(
          // Set theme of icons in AppBar
          iconTheme: IconThemeData(color: Colors.white, size: 22),
          // Set theme of title text in AppBar
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 25,
          ),
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        textTheme:
            GoogleFonts.robotoTextTheme(), // Set Roboto as the default font for the app
      ),
      home: const LoginScreen(),
    );
  }
}
