import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Material 3 design tokens for the tennis logger. Colours, typography, and
/// shapes are sourced from the `material_synthesis` design pack.
class AppColors {
  // Primary — Court Green
  static const primary = Color(0xFF154212);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFA1D494);
  static const onPrimaryContainer = Color(0xFF002201);

  // Secondary — Clay Orange
  static const secondary = Color(0xFFA23F00);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFFFDBCD);
  static const onSecondaryContainer = Color(0xFF351000);

  // Tertiary
  static const tertiary = Color(0xFF3A3939);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFF515050);
  static const onTertiaryContainer = Color(0xFFC5C2C2);

  // Surface roles — drives tonal elevation in M3
  static const surface = Color(0xFFF7F9FF);
  static const onSurface = Color(0xFF181C20);
  static const surfaceVariant = Color(0xFFDFE3E8);
  static const onSurfaceVariant = Color(0xFF42493E);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF1F4FA);
  static const surfaceContainer = Color(0xFFEBEEF4);
  static const surfaceContainerHigh = Color(0xFFE5E8EE);
  static const surfaceContainerHighest = Color(0xFFDFE3E8);

  // Outline
  static const outline = Color(0xFF72796E);
  static const outlineVariant = Color(0xFFC2C9BB);

  // Error
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  // Background mirrors surface in M3
  static const background = surface;
  static const onBackground = onSurface;
}

const ColorScheme _scheme = ColorScheme(
  brightness: Brightness.light,
  primary: AppColors.primary,
  onPrimary: AppColors.onPrimary,
  primaryContainer: AppColors.primaryContainer,
  onPrimaryContainer: AppColors.onPrimaryContainer,
  secondary: AppColors.secondary,
  onSecondary: AppColors.onSecondary,
  secondaryContainer: AppColors.secondaryContainer,
  onSecondaryContainer: AppColors.onSecondaryContainer,
  tertiary: AppColors.tertiary,
  onTertiary: AppColors.onTertiary,
  tertiaryContainer: AppColors.tertiaryContainer,
  onTertiaryContainer: AppColors.onTertiaryContainer,
  error: AppColors.error,
  onError: AppColors.onError,
  errorContainer: AppColors.errorContainer,
  onErrorContainer: AppColors.onErrorContainer,
  surface: AppColors.surface,
  onSurface: AppColors.onSurface,
  surfaceContainerLowest: AppColors.surfaceContainerLowest,
  surfaceContainerLow: AppColors.surfaceContainerLow,
  surfaceContainer: AppColors.surfaceContainer,
  surfaceContainerHigh: AppColors.surfaceContainerHigh,
  surfaceContainerHighest: AppColors.surfaceContainerHighest,
  onSurfaceVariant: AppColors.onSurfaceVariant,
  outline: AppColors.outline,
  outlineVariant: AppColors.outlineVariant,
);

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: _scheme,
    scaffoldBackgroundColor: AppColors.surface,
    canvasColor: AppColors.surface,
    textTheme: _buildTextTheme(),
    inputDecorationTheme: _inputDecorationTheme,
    filledButtonTheme: _filledButtonTheme,
    outlinedButtonTheme: _outlinedButtonTheme,
    textButtonTheme: _textButtonTheme,
    iconButtonTheme: _iconButtonTheme,
    cardTheme: _cardTheme,
    bottomSheetTheme: _bottomSheetTheme,
    navigationBarTheme: _navigationBarTheme,
    dividerTheme: const DividerThemeData(
      color: AppColors.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    splashFactory: InkSparkle.splashFactory,
  );
}

TextTheme _buildTextTheme() {
  TextStyle hg(double size, FontWeight weight, double height,
      {double letterSpacing = 0}) {
    return GoogleFonts.hankenGrotesk(
      fontSize: size,
      fontWeight: weight,
      height: height / size,
      letterSpacing: letterSpacing,
      color: AppColors.onSurface,
    );
  }

  TextStyle inter(double size, FontWeight weight, double height,
      {double letterSpacing = 0}) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      height: height / size,
      letterSpacing: letterSpacing,
      color: AppColors.onSurface,
    );
  }

  return TextTheme(
    displayLarge: hg(57, FontWeight.w400, 64, letterSpacing: -0.25),
    displayMedium: hg(45, FontWeight.w400, 52),
    displaySmall: hg(36, FontWeight.w400, 44),
    headlineLarge: hg(32, FontWeight.w400, 40),
    headlineMedium: hg(28, FontWeight.w400, 36),
    headlineSmall: hg(24, FontWeight.w400, 32),
    titleLarge: hg(22, FontWeight.w500, 28),
    titleMedium: inter(16, FontWeight.w500, 24, letterSpacing: 0.15),
    titleSmall: inter(14, FontWeight.w500, 20, letterSpacing: 0.1),
    bodyLarge: inter(16, FontWeight.w400, 24, letterSpacing: 0.5),
    bodyMedium: inter(14, FontWeight.w400, 20, letterSpacing: 0.25),
    bodySmall: inter(12, FontWeight.w400, 16, letterSpacing: 0.4),
    labelLarge: inter(14, FontWeight.w500, 20, letterSpacing: 0.1),
    labelMedium: inter(12, FontWeight.w500, 16, letterSpacing: 0.5),
    labelSmall: inter(11, FontWeight.w500, 16, letterSpacing: 0.5),
  );
}

final InputDecorationTheme _inputDecorationTheme = InputDecorationTheme(
  filled: true,
  fillColor: AppColors.surfaceContainerHighest,
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  border: const UnderlineInputBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
    borderSide: BorderSide(color: AppColors.outlineVariant, width: 1),
  ),
  enabledBorder: const UnderlineInputBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
    borderSide: BorderSide(color: AppColors.outlineVariant, width: 1),
  ),
  focusedBorder: const UnderlineInputBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
    borderSide: BorderSide(color: AppColors.primary, width: 2),
  ),
  errorBorder: const UnderlineInputBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
    borderSide: BorderSide(color: AppColors.error, width: 1),
  ),
  focusedErrorBorder: const UnderlineInputBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
    borderSide: BorderSide(color: AppColors.error, width: 2),
  ),
  labelStyle: GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurfaceVariant,
    letterSpacing: 0.5,
  ),
  floatingLabelStyle: GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
    letterSpacing: 0.5,
  ),
  hintStyle: GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
  ),
);

final FilledButtonThemeData _filledButtonTheme = FilledButtonThemeData(
  style: FilledButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.onPrimary,
    minimumSize: const Size(0, 48),
    shape: const StadiumBorder(),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    textStyle: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
    ),
  ),
);

final OutlinedButtonThemeData _outlinedButtonTheme = OutlinedButtonThemeData(
  style: OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    side: const BorderSide(color: AppColors.outline, width: 1),
    minimumSize: const Size(0, 48),
    shape: const StadiumBorder(),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    textStyle: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
    ),
  ),
);

final TextButtonThemeData _textButtonTheme = TextButtonThemeData(
  style: TextButton.styleFrom(
    foregroundColor: AppColors.primary,
    minimumSize: const Size(0, 40),
    shape: const StadiumBorder(),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    textStyle: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
  ),
);

final IconButtonThemeData _iconButtonTheme = IconButtonThemeData(
  style: IconButton.styleFrom(
    foregroundColor: AppColors.onSurfaceVariant,
    minimumSize: const Size(48, 48),
  ),
);

final CardThemeData _cardTheme = CardThemeData(
  color: AppColors.surfaceContainerLow,
  surfaceTintColor: Colors.transparent,
  elevation: 0,
  margin: EdgeInsets.zero,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
);

const BottomSheetThemeData _bottomSheetTheme = BottomSheetThemeData(
  backgroundColor: AppColors.surfaceContainerLow,
  surfaceTintColor: Colors.transparent,
  showDragHandle: false,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
);

const NavigationBarThemeData _navigationBarTheme = NavigationBarThemeData(
  backgroundColor: AppColors.surface,
  indicatorColor: AppColors.secondaryContainer,
  surfaceTintColor: Colors.transparent,
  elevation: 0,
  height: 80,
  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
);

/// Score numerals — JetBrains Mono with tabular figures.
TextStyle scoreDisplayStyle({
  double size = 45,
  Color color = AppColors.onSurface,
  FontWeight weight = FontWeight.w700,
}) =>
    GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.05,
      letterSpacing: 0.5,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

/// All-caps eyebrow labels (e.g. `MY SERVE?`, `TENNIS LOGGER`).
TextStyle eyebrowStyle({Color color = AppColors.onSurfaceVariant}) =>
    GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.2,
      color: color,
    );

/// Backwards-compat alias retained for legacy call sites.
TextStyle get scoreTextStyle => scoreDisplayStyle();
