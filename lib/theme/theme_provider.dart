// lib/theme/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  original,
  violet,
  green,
  blue,
  orange,
  red,
  system,
}

extension AppThemeModeExtension on AppThemeMode {
  String get displayName {
    switch (this) {
      case AppThemeMode.original:
        return 'Original Theme';
      case AppThemeMode.violet:
        return 'Violet Palette';
      case AppThemeMode.green:
        return 'Green Palette';
      case AppThemeMode.blue:
        return 'Blue Palette';
      case AppThemeMode.orange:
        return 'Orange Palette';
      case AppThemeMode.red:
        return 'Red Palette';
      case AppThemeMode.system:
        return 'System Default';
    }
  }

  Color get primaryColor {
    switch (this) {
      case AppThemeMode.original:
        return const Color(0xFFE8C189); // slightly brighter warm
      case AppThemeMode.violet:
        return const Color(0xFFABA3FF); // updated violet
      case AppThemeMode.green:
        return const Color(0xFFAFFF99); // updated green
      case AppThemeMode.blue:
        return const Color(0xFFABBFFF); // updated blue
      case AppThemeMode.orange:
        return const Color(0xFFFF7A04); // updated orange
      case AppThemeMode.red:
        return const Color(0xFFFF725E); // updated red
      case AppThemeMode.system:
        return const Color(0xFFABA3FF);
    }
  }

  IconData get icon {
    switch (this) {
      case AppThemeMode.original:
        return Icons.palette_outlined;
      case AppThemeMode.violet:
        return Icons.color_lens;
      case AppThemeMode.green:
        return Icons.eco;
      case AppThemeMode.blue:
        return Icons.water_drop;
      case AppThemeMode.orange:
        return Icons.wb_sunny;
      case AppThemeMode.red:
        return Icons.favorite;
      case AppThemeMode.system:
        return Icons.phone_android;
    }
  }
}

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  ThemeNotifier() : super(AppThemeMode.violet) {
    _loadTheme();
  }

  static const String _themeKey = 'selected_theme';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex =
        prefs.getInt(_themeKey) ?? 1; // Default to violet (index 1)
    state = AppThemeMode.values[themeIndex];
  }

  Future<void> setTheme(AppThemeMode theme) async {
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, theme.index);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier();
});

class AppThemes {
  // Original Theme - Preserved with warm colors from app.md (#F9E8D4 background)
  static ThemeData get originalTheme => _buildTheme(
        primaryColor: const Color(0xFFE8C189), // from app.md, brighter
        secondaryColor: const Color(0xFFF9D166), // brighter secondary
        surfaceColor: const Color(0xFFFFF0DB), // lighter base (calendar color)
        backgroundColor: const Color(0xFFFFF6EE), // brighter warm background
        // Make cards match the calendar/base surface color in the original theme
        cardColor: const Color(0xFFFFF0DB),
        brightness: Brightness.light,
      );

  // Material 3 Violet Theme - Pure white/black system-aware
  static ThemeData violetTheme(Brightness systemBrightness) => _buildTheme(
        primaryColor: const Color(0xFFABA3FF),
        secondaryColor: const Color(0xFFF0EDFF),
        surfaceColor: systemBrightness == Brightness.light
            ? const Color(0xFFFBF8FF)
            : const Color(0xFF121212), // Material 3 dark surface
        backgroundColor: systemBrightness == Brightness.light
            ? const Color(0xFFFEFAFF)
            : Colors.black, // Pure white/black
        cardColor: systemBrightness == Brightness.light
            ? const Color(0xFFFBF8FF)
            : const Color(0xFF1E1E1E), // Material 3 dark card
        brightness: systemBrightness,
      );

  // Material 3 Green Theme - Pure white/black system-aware
  static ThemeData greenTheme(Brightness systemBrightness) => _buildTheme(
        primaryColor: const Color(0xFFAFFF99),
        secondaryColor: const Color(0xFFF0FFE3),
        surfaceColor: systemBrightness == Brightness.light
            ? const Color(0xFFF7FFF6)
            : const Color(0xFF121212),
        backgroundColor: systemBrightness == Brightness.light
            ? const Color(0xFFF8FFF9)
            : Colors.black,
        cardColor: systemBrightness == Brightness.light
            ? const Color(0xFFF7FFF6)
            : const Color(0xFF1E1E1E),
        brightness: systemBrightness,
      );

  // Material 3 Blue Theme - Pure white/black system-aware
  static ThemeData blueTheme(Brightness systemBrightness) => _buildTheme(
        primaryColor: const Color(0xFFABBFFF),
        secondaryColor: const Color(0xFFEAF3FF),
        surfaceColor: systemBrightness == Brightness.light
            ? const Color(0xFFF6FBFF)
            : const Color(0xFF121212),
        backgroundColor: systemBrightness == Brightness.light
            ? const Color(0xFFF8FCFF)
            : Colors.black,
        cardColor: systemBrightness == Brightness.light
            ? const Color(0xFFF6FBFF)
            : const Color(0xFF1E1E1E),
        brightness: systemBrightness,
      );

  // Material 3 Orange Theme - Pure white/black system-aware
  static ThemeData orangeTheme(Brightness systemBrightness) => _buildTheme(
        primaryColor: const Color(0xFFFF7A04),
        secondaryColor: const Color(0xFFFFE6CC),
        surfaceColor: systemBrightness == Brightness.light
            ? const Color(0xFFFFFBF6)
            : const Color(0xFF121212),
        backgroundColor: systemBrightness == Brightness.light
            ? const Color(0xFFFFFCFA)
            : Colors.black,
        cardColor: systemBrightness == Brightness.light
            ? const Color(0xFFFFFBF6)
            : const Color(0xFF1E1E1E),
        brightness: systemBrightness,
      );

  // Material 3 Red Theme - Pure white/black system-aware
  static ThemeData redTheme(Brightness systemBrightness) => _buildTheme(
        primaryColor: const Color(0xFFFF725E),
        secondaryColor: const Color(0xFFFFE4DF),
        surfaceColor: systemBrightness == Brightness.light
            ? const Color(0xFFFFFBFB)
            : const Color(0xFF121212),
        backgroundColor: systemBrightness == Brightness.light
            ? const Color(0xFFFFFCFC)
            : Colors.black,
        cardColor: systemBrightness == Brightness.light
            ? const Color(0xFFFFFBFB)
            : const Color(0xFF1E1E1E),
        brightness: systemBrightness,
      );

  static ThemeData _buildTheme({
    required Color primaryColor,
    required Color secondaryColor,
    required Color surfaceColor,
    required Color backgroundColor,
    required Color cardColor,
    Brightness? brightness,
  }) {
    final actualBrightness = brightness ?? Brightness.light;

    // Enhanced text colors for better visibility with brighter backgrounds
    final textColor = actualBrightness == Brightness.light
        ? const Color(
            0xFF111014) // slightly darker text for brighter light backgrounds
        : const Color(0xFFECE8ED); // slightly lighter text for dark mode
    final mutedColor = actualBrightness == Brightness.light
        ? const Color(0xFF5A5560) // muted but higher contrast in light mode
        : const Color(0xFFBFB6C3); // muted but readable in dark mode

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: actualBrightness,
        surface: surfaceColor,
        surfaceContainer: cardColor,
        onSurface: textColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      textTheme: TextTheme(
        displayLarge: TextStyle(color: textColor),
        displayMedium: TextStyle(color: textColor),
        displaySmall: TextStyle(color: textColor),
        headlineLarge: TextStyle(color: textColor),
        headlineMedium: TextStyle(color: textColor),
        headlineSmall: TextStyle(color: textColor),
        titleLarge: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: textColor),
        bodyMedium: TextStyle(color: textColor),
        bodySmall: TextStyle(color: mutedColor),
        labelLarge: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(color: mutedColor),
        labelSmall: TextStyle(color: mutedColor),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shadowColor: actualBrightness == Brightness.light
            ? Colors.black.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: mutedColor.withValues(alpha: 0.3),
          disabledForegroundColor: mutedColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
          animationDuration: const Duration(milliseconds: 200),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
        focusElevation: 8,
        hoverElevation: 8,
        highlightElevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        iconSize: 24,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: primaryColor.withValues(alpha: 0.2),
        elevation: 3,
        labelTextStyle: WidgetStateTextStyle.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            );
          }
          return TextStyle(
            color: mutedColor,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primaryColor, size: 24);
          }
          return IconThemeData(color: mutedColor, size: 24);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: mutedColor.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: mutedColor.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: TextStyle(color: mutedColor),
        hintStyle: TextStyle(color: mutedColor),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      iconTheme: IconThemeData(color: textColor),
      primaryIconTheme: IconThemeData(color: textColor),
    );
  }

  static ThemeData getTheme(AppThemeMode mode, [Brightness? systemBrightness]) {
    final brightness = systemBrightness ?? Brightness.light;

    switch (mode) {
      case AppThemeMode.original:
        return originalTheme;
      case AppThemeMode.violet:
        return violetTheme(brightness);
      case AppThemeMode.green:
        return greenTheme(brightness);
      case AppThemeMode.blue:
        return blueTheme(brightness);
      case AppThemeMode.orange:
        return orangeTheme(brightness);
      case AppThemeMode.red:
        return redTheme(brightness);
      case AppThemeMode.system:
        return violetTheme(brightness); // Default fallback
    }
  }
}
