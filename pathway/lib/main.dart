import 'package:flutter/material.dart';
import 'features/auth/presentation/login_screen.dart';
import 'package:google_fonts/google_fonts.dart'; // Added Google Fonts package for custom font
import 'core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

ThemeData buildPathwayTheme() {
  final base = ThemeData(useMaterial3: true);

  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  );

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,

    textTheme: GoogleFonts.robotoTextTheme(base.textTheme).copyWith(
      bodyMedium: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
      )
    ),

    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: AppColors.primary,
      iconTheme: const IconThemeData(color: Colors.white, size: 22),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 25,
      ),
    ),

    cardTheme: const CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.card)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.input),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return null;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary.withValues(alpha: 0.4);
        }
        return null;
      }),
    ),
  );
}
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
      theme: buildPathwayTheme(),
      home: const LoginScreen(),
    );
  }
}
