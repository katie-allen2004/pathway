import 'package:flutter/material.dart';
import 'features/auth/presentation/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  print('SUPABASE_URL=' + const String.fromEnvironment('SUPABASE_URL'));


  runApp(const PathwayApp());
}

class PathwayApp extends StatelessWidget {
  const PathwayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pathway',
      theme: ThemeData(
        scaffoldBackgroundColor: Color.fromARGB(255, 233, 234, 247),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        textTheme: GoogleFonts.robotoTextTheme(),
      ),
      home: const LoginScreen(),
    );
  }
}