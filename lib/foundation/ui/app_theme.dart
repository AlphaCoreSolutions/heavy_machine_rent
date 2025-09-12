import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand tokens
class AppColors {
  // Light
  static const primary = Color(0xFF12B76A);
  static const primaryContainer = Color(0xFFD1FADF);
  static const onPrimary = Colors.white;
  static const onPrimaryContainer = Color(0xFF052E1C);

  static const secondary = Color(0xFF16A34A);
  static const tertiary = Color(0xFF0EA5A4);

  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF5F7F9);
  static const background = Color(0xFFFFFFFF);
  static const outline = Color(0xFFD0D5DD);
  static const outlineVariant = Color(0xFFEAECF0);

  // Dark
  static const primaryDark = Color(0xFF34D399);
  static const primaryContainerDark = Color(0xFF00492B);
  static const onPrimaryDark = Color(0xFF003822);
  static const onPrimaryContainerDark = Color(0xFFA7F3D0);

  static const surfaceDark = Color(0xFF10151C);
  static const surfaceVariantDark = Color(0xFF151B23);
  static const backgroundDark = Color(0xFF0B0F14);
  static const outlineDark = Color(0xFF2A3240);
  static const outlineVariantDark = Color(0xFF1F2530);

  // Signals
  static const success = primary;
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF0EA5E9);
}

/// Fonts
TextTheme _textTheme(ColorScheme scheme) {
  final base = GoogleFonts.interTextTheme();
  return base
      // Default: non-headings on onSurfaceVariant
      .apply(displayColor: scheme.onSurface, bodyColor: scheme.onSurfaceVariant)
      .copyWith(
        // Headings stay strong
        titleLarge: base.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: scheme.onSurface,
        ),
        headlineSmall: base.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: scheme.onSurface,
        ),

        // IMPORTANT: Inputs usually render with bodyLarge. Make it high-contrast.
        bodyLarge: base.bodyLarge?.copyWith(
          height: 1.25,
          color: scheme.onSurface, // <- typed text will be clear
        ),

        // (Keep these a bit softer if you want)
        bodyMedium: base.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        bodySmall: base.bodySmall?.copyWith(color: scheme.onSurfaceVariant),

        labelLarge: base.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      );
}

class AppTheme {
  static ThemeData light() {
    final scheme = const FlexSchemeColor(
      primary: AppColors.primary,
      primaryContainer: AppColors.primaryContainer,
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiary,
      appBarColor: AppColors.surface,
      error: AppColors.error,
    );

    final theme = FlexThemeData.light(
      useMaterial3: true,
      colors: scheme,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 10,
      fontFamily: GoogleFonts.inter().fontFamily,
      subThemesData: const FlexSubThemesData(
        defaultRadius: 16,
        elevatedButtonRadius: 14,
        filledButtonRadius: 14,
        outlinedButtonRadius: 14,
        segmentedButtonRadius: 14,
        bottomSheetRadius: 24,
        dialogRadius: 20,
        cardRadius: 18,
        inputDecoratorFocusedHasBorder: true,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorRadius: 14,
        thinBorderWidth: 1.2,
        thickBorderWidth: 1.6,
        tintedDisabledControls: true,
        splashType: FlexSplashType.inkSparkle,
      ),
      visualDensity: VisualDensity.comfortable,
    );

    // Fine-tune text to scheme colors
    return theme.copyWith(
      textTheme: _textTheme(theme.colorScheme),
      scaffoldBackgroundColor: AppColors.background, // or backgroundDark
      inputDecorationTheme: InputDecorationTheme(
        // keep borders per your FlexSubThemesData; here we just color text/hints
        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        floatingLabelStyle: TextStyle(color: theme.colorScheme.onSurface),
        prefixIconColor: theme.colorScheme.onSurfaceVariant,
        suffixIconColor: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  static ThemeData dark() {
    final schemeDark = const FlexSchemeColor(
      primary: AppColors.primaryDark,
      primaryContainer: AppColors.primaryContainerDark,
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiary,
      appBarColor: AppColors.surfaceDark,
      error: AppColors.error,
    );

    final theme = FlexThemeData.dark(
      useMaterial3: true,
      colors: schemeDark,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 14,
      fontFamily: GoogleFonts.inter().fontFamily,
      subThemesData: const FlexSubThemesData(
        defaultRadius: 16,
        bottomSheetRadius: 24,
        dialogRadius: 20,
        cardRadius: 18,
        inputDecoratorRadius: 14,
        tintedDisabledControls: true,
        splashType: FlexSplashType.inkSparkle,
      ),
      appBarBackground: AppColors.surfaceDark,
      scaffoldBackground: AppColors.backgroundDark,
    );

    return theme.copyWith(
      textTheme: _textTheme(theme.colorScheme),
      scaffoldBackgroundColor: AppColors.backgroundDark,
    );
  }
}
