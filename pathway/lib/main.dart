import 'package:flutter/material.dart';
import 'features/auth/presentation/login_screen.dart';
import 'package:google_fonts/google_fonts.dart'; // Added Google Fonts package for custom font
import 'core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/utils/accessibility_controller.dart';
import 'package:provider/provider.dart';
import '/features/auth/data/user_repository.dart'; 
import 'package:pathway/models/accessibility_settings.dart';

ThemeData buildPathwayTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  );

  final base = ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true
  );

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,

    textTheme: GoogleFonts.robotoTextTheme(base.textTheme)
      .apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      )
      .copyWith(
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

  final a11y = AccessibilityController();
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

  await a11y.load(); // load AccessibilityController()

  runApp(PathwayApp(a11y: a11y));
}

class PathwayApp extends StatelessWidget {
  final AccessibilityController a11y;
  const PathwayApp({super.key, required this.a11y});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<UserRepository>(create: (_) => UserRepository()),
        ChangeNotifierProvider<AccessibilityController>.value(value: a11y),
      ],
      child: Consumer<AccessibilityController>(
        builder: (context, a11y, _) {
          final s = a11y.settings;

          // Your original theme (keep all your styling!)
          final baseTheme = buildPathwayTheme();

          // Apply a11y on top of it
          final themed = _applyA11yToTheme(baseTheme, s);

          return MaterialApp(
            title: 'Pathway',
            theme: themed,
            darkTheme: _applyA11yToTheme(
              buildPathwayTheme().copyWith(brightness: Brightness.dark),
              s,
            ),
            themeMode: _themeModeFromSettings(s),
            builder: (context, child) {
              final mq = MediaQuery.of(context);

              // Global text scaling
              Widget out = MediaQuery(
                data: mq.copyWith(textScaler: TextScaler.linear(s.textScale)),
                child: child ?? const SizedBox.shrink(),
              );

              // Optional: reduce motion globally (small-project friendly)
              if (s.reduceMotion) {
                out = TickerMode(enabled: false, child: out);
              }

              return out;
            },
            home: const LoginScreen(),
          );
        },
      ),
    );
  }

  ThemeMode _themeModeFromSettings(AccessibilitySettings s) {
    // adjust based on whatever you store in settings
    // If you only store s.darkMode boolean:
    return s.darkMode ? ThemeMode.dark : ThemeMode.light;

    // If you later store system/light/dark:
    // return s.themeMode;
  }
}

ThemeData _applyA11yToTheme(ThemeData base, AccessibilitySettings s) {
  var t = base;

  if (s.highContrast) {
    t = t.copyWith(
      colorScheme: t.colorScheme.copyWith(
        primary: Colors.black,
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
      ),
      dividerColor: Colors.black,
    );
  }

  if (s.dyslexiaFont) {
    t = t.copyWith(
      textTheme: t.textTheme.apply(fontFamily: 'AtkinsonHyperlegible'),
    );
  }

  if (s.boldText) {
    // bold everything slightly; keeps headings consistent
    /*t = t.copyWith(
      textTheme: t.textTheme.apply(
        bodyText1: const TextStyle(fontWeight: FontWeight.w700),
        bodyText2: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );*/
  }
  /*
  if (s.largerTouchTargets) {
    t = t.copyWith(
      visualDensity: VisualDensity.standard, // keep stable
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }*/

  return t;
}
/* What was originally returned in .build:
    return MultiProvider(
      providers: [
        Provider<UserRepository>(create: (_) => UserRepository()),
      ],
      child: MaterialApp(
        title: 'Pathway',
        theme: buildPathwayTheme(),
        home: const LoginScreen(),
      ),
    );
  }
}*/