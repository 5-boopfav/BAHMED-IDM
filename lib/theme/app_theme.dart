import 'package:material_ui/material_ui.dart';

class AppTheme {
  AppTheme._();

  static const Color neon = Color(0xFF00E5FF);
  static const Color darkBackground = Color(0xFF080B14);
  static const Color darkSurface = Color(0xFF121827);

  static const Color lightBackground = Color(0xFFF3F6FA);
  static const Color lightSurface = Color(0xFFFFFFFF);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: neon,
        secondary: Color(0xFF7C4DFF),
        surface: darkSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF007C91),
        secondary: Color(0xFF7048E8),
        surface: lightSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}
