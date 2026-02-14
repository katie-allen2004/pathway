import 'package:flutter/material.dart';
import 'features/auth/presentation/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/home/presentation/pages/home_page.dart';



  Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final supabaseUrlRaw = const String.fromEnvironment('SUPABASE_URL');
  final supabaseUrl = supabaseUrlRaw.replaceFirst(RegExp(r'\/$'), ''); // remove trailing slash
  final supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  print('SUPABASE_URL=' + supabaseUrl);

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
        appBarTheme: const AppBarTheme(
          iconTheme: IconThemeData(
            color: Colors.white,
            size: 22,
          ),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 25,
          ),
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        textTheme: GoogleFonts.robotoTextTheme(),
      ),
      home: const HomePage(),
    );
  }
}