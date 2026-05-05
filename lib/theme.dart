import 'package:flutter/material.dart';

// Material You color tokens — teal/green tennis theme
class AppColors {
  static const primary = Color(0xFF006B5B);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF79F8E4);
  static const onPrimaryContainer = Color(0xFF00201B);
  static const secondary = Color(0xFF4B6360);
  static const secondaryContainer = Color(0xFFCDE8E3);
  static const onSecondaryContainer = Color(0xFF051F1C);
  static const tertiary = Color(0xFF456179);
  static const tertiaryContainer = Color(0xFFCCE5FF);
  static const surface = Color(0xFFF4FBF8);
  static const surfaceVariant = Color(0xFFDAE5E1);
  static const onSurface = Color(0xFF171D1B);
  static const onSurfaceVar = Color(0xFF3F4946);
  static const outline = Color(0xFF6F7976);
  static const outlineVariant = Color(0xFFBEC9C5);
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onError = Color(0xFFFFFFFF);

  static const chipNull = Color(0xFFE8F0EE);
  static const chipNullText = Color(0xFF6F7976);
  static const chipYes = Color(0xFFC8F5D0);
  static const chipYesText = Color(0xFF0A3D1E);
  static const chipNo = Color(0xFFFFD7D5);
  static const chipNoText = Color(0xFF5D1313);
  static const chipYesMark = Color(0xFF34A853);
  static const chipNoMark = Color(0xFFBA1A1A);
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onPrimary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onPrimary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onSurface,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onSurface,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceContainerHighest: AppColors.surfaceVariant,
      onSurfaceVariant: AppColors.onSurfaceVar,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColors.onSurface,
      onInverseSurface: AppColors.surface,
      inversePrimary: AppColors.primaryContainer,
    ),
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: AppColors.surface,
  );
}
