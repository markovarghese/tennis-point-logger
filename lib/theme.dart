import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Pro Circuit Elite Palette
  static const primary = Color(0xFF154212); // Court Green
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF2D5A27);
  static const onPrimaryContainer = Color(0xFF9DD090);
  
  static const secondary = Color(0xFFA23F00);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFFC7127); // Clay Orange
  static const onSecondaryContainer = Color(0xFF5C2000);

  static const tertiary = Color(0xFF3A3939);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFF515050);
  static const onTertiaryContainer = Color(0xFFC5C2C2);

  static const background = Color(0xFFF9F9F8);
  static const onBackground = Color(0xFF191C1C);
  
  static const surface = Color(0xFFF9F9F8);
  static const surfaceVariant = Color(0xFFE1E3E2);
  static const onSurface = Color(0xFF191C1C);
  static const onSurfaceVariant = Color(0xFF42493E);
  
  static const outline = Color(0xFF72796E);
  static const outlineVariant = Color(0xFFC2C9BB);
  
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);

  // Status Colors
  static const chipYes = primary;
  static const chipNo = secondaryContainer;
  static const chipUnanswered = Colors.transparent;
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
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
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
    ),
    scaffoldBackgroundColor: AppColors.background,
  );

  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.hankenGrotesk(
        textStyle: base.textTheme.displayLarge,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.02 * 48, // -0.02em
      ),
      headlineLarge: GoogleFonts.hankenGrotesk(
        textStyle: base.textTheme.headlineLarge,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.01 * 32, // -0.01em
      ),
      titleMedium: GoogleFonts.inter(
        textStyle: base.textTheme.titleMedium,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class GlassPanel extends StatelessWidget {
  final Widget child;
  final double opacity;
  final double blur;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const GlassPanel({
    super.key,
    required this.child,
    this.opacity = 0.8,
    this.blur = 16.0,
    this.borderRadius = 8.0,
    this.padding = const EdgeInsets.all(16.0),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (color ?? Colors.white).withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class CourtBackground extends StatelessWidget {
  final Widget child;

  const CourtBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _CourtPainter(),
          ),
        ),
        child,
      ],
    );
  }
}

class _CourtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outlineVariant.withValues(alpha: 0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const spacing = 100.0;
    
    // Vertical lines
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    // Horizontal lines
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Add some diagonal pattern like in the spec
    final diagPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.02)
      ..strokeWidth = 10.0
      ..style = PaintingStyle.stroke;

    const diagSpacing = 20.0;
    for (double i = -size.height; i <= size.width; i += diagSpacing) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), diagPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

TextStyle get scoreTextStyle => GoogleFonts.jetBrainsMono(
      fontWeight: FontWeight.w700,
      fontFeatures: [const FontFeature.tabularFigures()],
    );
