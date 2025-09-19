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
        return const Color(0xFFD9B88A);
      case AppThemeMode.violet:
        return const Color(0xFF6750A4);
      case AppThemeMode.green:
        return const Color(0xFF386A20);
      case AppThemeMode.blue:
        return const Color(0xFF1976D2);
      case AppThemeMode.orange:
        return const Color(0xFFFF8C00);
      case AppThemeMode.red:
        return const Color(0xFFD32F2F);
      case AppThemeMode.system:
        return const Color(0xFF6750A4);
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
  ThemeNotifier() : super(AppThemeMode.original) {
    _loadTheme();
  }

  static const String _themeKey = 'selected_theme';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 0;
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
  // Original Theme (Current warm theme)
  static ThemeData get originalTheme => _buildTheme(
        primaryColor: const Color(0xFFD9B88A),
        secondaryColor: const Color(0xFFF6C84A),
        surfaceColor: const Color(0xFFF9E8D4),
        backgroundColor: const Color(0xFFFEF1E1),
        cardColor: const Color(0xFFFEF1E1),
      );

  // Material 3 Violet Theme
  static ThemeData get violetTheme => _buildTheme(
        primaryColor: const Color(0xFF6750A4),
        secondaryColor: const Color(0xFFE8DEF8),
        surfaceColor: const Color(0xFFFDF7FF),
        backgroundColor: const Color(0xFFFFFBFF),
        cardColor: const Color(0xFFFDF7FF),
      );

  // Material 3 Green Theme
  static ThemeData get greenTheme => _buildTheme(
        primaryColor: const Color(0xFF386A20),
        secondaryColor: const Color(0xFFDDEDD0),
        surfaceColor: const Color(0xFFF8FFF0),
        backgroundColor: const Color(0xFFFDFFEF),
        cardColor: const Color(0xFFF8FFF0),
      );

  // Material 3 Blue Theme
  static ThemeData get blueTheme => _buildTheme(
        primaryColor: const Color(0xFF1976D2),
        secondaryColor: const Color(0xFFD1E4FF),
        surfaceColor: const Color(0xFFF1F8FF),
        backgroundColor: const Color(0xFFFCFCFF),
        cardColor: const Color(0xFFF1F8FF),
      );

  // Material 3 Orange Theme
  static ThemeData get orangeTheme => _buildTheme(
        primaryColor: const Color(0xFFFF8C00),
        secondaryColor: const Color(0xFFFFE0B2),
        surfaceColor: const Color(0xFFFFF8F0),
        backgroundColor: const Color(0xFFFFFBF7),
        cardColor: const Color(0xFFFFF8F0),
      );

  // Material 3 Red Theme
  static ThemeData get redTheme => _buildTheme(
        primaryColor: const Color(0xFFD32F2F),
        secondaryColor: const Color(0xFFFFCDD2),
        surfaceColor: const Color(0xFFFFF5F5),
        backgroundColor: const Color(0xFFFFFEFE),
        cardColor: const Color(0xFFFFF5F5),
      );

  static ThemeData _buildTheme({
    required Color primaryColor,
    required Color secondaryColor,
    required Color surfaceColor,
    required Color backgroundColor,
    required Color cardColor,
  }) {
    final textColor = const Color(0xFF2F2B28);
    final mutedColor = const Color(0xFF6B5E53);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: surfaceColor,
        surfaceContainer: cardColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  static ThemeData getTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.original:
        return originalTheme;
      case AppThemeMode.violet:
        return violetTheme;
      case AppThemeMode.green:
        return greenTheme;
      case AppThemeMode.blue:
        return blueTheme;
      case AppThemeMode.orange:
        return orangeTheme;
      case AppThemeMode.red:
        return redTheme;
      case AppThemeMode.system:
        return violetTheme; // Default fallback
    }
  }
}
