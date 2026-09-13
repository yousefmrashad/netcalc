import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:netcalc_app/screens/home_page.dart';
import 'package:netcalc_app/services/data_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DataRepository.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // Fallback colors if the device doesn't support dynamic theming
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          lightColorScheme = lightDynamic.harmonized();
          darkColorScheme = darkDynamic.harmonized();
        } else {
          lightColorScheme = ColorScheme.fromSeed(
            seedColor: Colors.teal,
            brightness: Brightness.light,
          );
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: Colors.teal,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          title: 'Savings Tracker',
          debugShowCheckedModeBanner: false,
          themeMode:
              ThemeMode.system, // Automatically uses device's Light/Dark mode
          theme: _buildTheme(lightColorScheme),
          darkTheme: _buildTheme(darkColorScheme),
          home: const HomePage(),
        );
      },
    );
  }

  // Helper to build the theme so we don't repeat code for light/dark
  ThemeData _buildTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.onSurface.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
      ),
    );
  }
}
