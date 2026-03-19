import 'package:flutter/material.dart';
import 'features/auth/presentation/login_screen.dart';
import 'package:google_fonts/google_fonts.dart'; // Added Google Fonts package for custom font
import 'core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/utils/accessibility_controller.dart';
import 'package:provider/provider.dart';
import '/features/auth/data/user_repository.dart'; 
import 'package:pathway/models/accessibility_settings.dart';

ThemeData buildPathwayTheme({required Brightness brightness}) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: brightness,
  ).copyWith(
    primary: AppColors.primary,
    onPrimary: Colors.white,
  );

  final base = ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    brightness: brightness
  );

  return base.copyWith(
    scaffoldBackgroundColor: colorScheme.surface, //AppColors.background

    textTheme: GoogleFonts.robotoTextTheme(base.textTheme).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),

    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: colorScheme.primary, //AppColors.primary,
      iconTheme: IconThemeData(color: colorScheme.onPrimary, size: 22), //color: Colors.white
      titleTextStyle: GoogleFonts.roboto(
        color: colorScheme.onPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 25,
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surface,
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
        borderSide: BorderSide(color: colorScheme.primary, width: 2), // color: AppColors.primary
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary, // backgroundColor: AppColors.primary
        foregroundColor: colorScheme.onPrimary, // foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary; // return AppColors.primary
        }
        return null;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary.withValues(alpha: 0.4);  // AppColors.primary.withValues(alpha: 0.4)
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
  await a11y.loadFromDatabase();

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
          /*
          // Your original theme (keep all your styling!)
          final baseTheme = buildPathwayTheme();

          // Apply a11y on top of it
          final themed = _applyA11yToTheme(baseTheme, s);
          */

          final lightBase = buildPathwayTheme(brightness: Brightness.light);
          final darkBase  = buildPathwayTheme(brightness: Brightness.dark);

          final themedLight = _applyA11yToTheme(lightBase, s);
          final themedDark  = _applyA11yToTheme(darkBase, s);

          return MaterialApp(
            title: 'Pathway',
            theme: themedLight,
            darkTheme: themedDark,
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
    final cs = t.colorScheme;

    final hc = cs.copyWith(
      primary: Colors.black,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
      outline: Colors.black,
    );

    t = t.copyWith(
      colorScheme: hc,
      scaffoldBackgroundColor: Colors.white,
      dividerColor: Colors.black,
      iconTheme: const IconThemeData(color: Colors.black),
      cardTheme: t.cardTheme.copyWith(color: Colors.white),
      appBarTheme: t.appBarTheme.copyWith(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: t.appBarTheme.titleTextStyle?.copyWith(color: Colors.white),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.grey.shade400;
          }
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.black;
          }
          return Colors.grey.shade400;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.black),
      )
    );
  }

  if (s.dyslexiaFont) {
      t = t.copyWith(
        textTheme: t.textTheme.apply(fontFamily: 'OpenDyslexic'),
        appBarTheme: t.appBarTheme.copyWith(
          titleTextStyle: t.appBarTheme.titleTextStyle?.copyWith(
            fontFamily: 'OpenDyslexic',
          ),
        ),
      );
    }

  if (s.boldText) {
    TextStyle? bump(TextStyle? st) {
      if (st == null) return null;
      final w = st.fontWeight ?? FontWeight.w400;

      // bump one step, but don’t blow up already-bold headings too much
      FontWeight next;
      if (w.index <= FontWeight.w500.index) {
        next = FontWeight.w700;
      } else {
        next = w;
      }

      return st.copyWith(fontWeight: next);
    }

    final tt = t.textTheme;
    t = t.copyWith(
      textTheme: tt.copyWith(
        displayLarge: bump(tt.displayLarge),
        displayMedium: bump(tt.displayMedium),
        displaySmall: bump(tt.displaySmall),
        headlineLarge: bump(tt.headlineLarge),
        headlineMedium: bump(tt.headlineMedium),
        headlineSmall: bump(tt.headlineSmall),
        titleLarge: bump(tt.titleLarge),
        titleMedium: bump(tt.titleMedium),
        titleSmall: bump(tt.titleSmall),
        bodyLarge: bump(tt.bodyLarge),
        bodyMedium: bump(tt.bodyMedium),
        bodySmall: bump(tt.bodySmall),
        labelLarge: bump(tt.labelLarge),
        labelMedium: bump(tt.labelMedium),
        labelSmall: bump(tt.labelSmall),
      ),
    );
  }

  return t;
}