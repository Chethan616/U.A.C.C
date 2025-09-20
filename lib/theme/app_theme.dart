// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  static const base = Color(0xFFF9E8D4); // Background surfaces
  static const primary = Color(0xFFD9B88A); // Buttons, CTAs
  static const accent = Color(0xFFF6C84A); // Highlights, badges
  static const surface =
      Color(0xFFFEF1E1); // Cards, modals - Updated to new background
  static const text = Color(0xFF2F2B28); // Primary text
  static const muted = Color(0xFF6B5E53); // Secondary text
  static const border = Color(0xFFEADFCB); // Border color
  static const outline =
      Color(0xFFEDA376); // Outline color for boxes and calendars
  static const success = Color(0xFF5BB18E); // Positive state
  static const danger = Color(0xFFE06A4A); // Error state
  static const shadow = Color(0x142F2B28); // rgba(47,43,40,0.08)
}

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.text,
    secondary: AppColors.accent,
    onSecondary: AppColors.text,
    tertiary: AppColors.success,
    onTertiary: Colors.white,
    surface: AppColors.base,
    onSurface: AppColors.text,
    surfaceContainer: AppColors.surface,
    onSurfaceVariant: AppColors.muted,
    error: AppColors.danger,
    onError: Colors.white,
    outline: AppColors.border,
    shadow: AppColors.shadow,
  ),
  // Use the colorScheme.surface as the scaffold background so theme changes
  // propagate consistently. Individual screens should prefer Theme.of(context)
  // tokens rather than hard-coded AppColors.base.
  scaffoldBackgroundColor: AppColors.surface,
  cardColor: AppColors.surface,
  cardTheme: CardThemeData(
    color: AppColors.surface,
    elevation: 2,
    shadowColor: AppColors.shadow,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.text,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(
      color: AppColors.text,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
  ),
  textTheme: TextTheme(
    headlineLarge: TextStyle(
      color: AppColors.text,
      fontWeight: FontWeight.w700,
      fontSize: 32,
    ),
    headlineMedium: TextStyle(
      color: AppColors.text,
      fontWeight: FontWeight.w600,
      fontSize: 28,
    ),
    headlineSmall: TextStyle(
      color: AppColors.text,
      fontWeight: FontWeight.w600,
      fontSize: 24,
    ),
    titleLarge: TextStyle(
      color: AppColors.text,
      fontWeight: FontWeight.w700,
      fontSize: 20,
    ),
    titleMedium: TextStyle(
      color: AppColors.text,
      fontWeight: FontWeight.w600,
      fontSize: 16,
    ),
    titleSmall: TextStyle(
      color: AppColors.text,
      fontWeight: FontWeight.w500,
      fontSize: 14,
    ),
    bodyLarge: TextStyle(
      color: AppColors.text,
      fontSize: 16,
    ),
    bodyMedium: TextStyle(
      color: AppColors.text,
      fontSize: 14,
    ),
    bodySmall: TextStyle(
      color: AppColors.muted,
      fontSize: 12,
    ),
    labelLarge: TextStyle(
      color: AppColors.text,
      fontWeight: FontWeight.w500,
      fontSize: 14,
    ),
    labelMedium: TextStyle(
      color: AppColors.muted,
      fontWeight: FontWeight.w500,
      fontSize: 12,
    ),
    labelSmall: TextStyle(
      color: AppColors.muted,
      fontWeight: FontWeight.w500,
      fontSize: 10,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.text,
      disabledBackgroundColor: AppColors.muted.withValues(alpha: 0.3),
      disabledForegroundColor: AppColors.muted,
      shadowColor: AppColors.shadow,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        letterSpacing: 0.5,
      ),
      animationDuration: Duration(milliseconds: 200),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: BorderSide(color: AppColors.primary, width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.text,
    elevation: 6,
    focusElevation: 8,
    hoverElevation: 8,
    highlightElevation: 12,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    splashColor: AppColors.accent.withValues(alpha: 0.3),
    iconSize: 24,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.danger, width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: AppColors.surface,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.muted,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
  dividerTheme: DividerThemeData(
    color: AppColors.border,
    thickness: 1,
    space: 1,
  ),
);
