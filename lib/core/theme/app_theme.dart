import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_ui_tokens.dart';

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme = _buildTheme(Brightness.light);
  static ThemeData darkTheme = _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = _buildColorScheme(isDark);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: _buildTextTheme(colorScheme),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: AppUiTokens.appBarHeight,
        titleTextStyle: AppTextStyles.headlineMd.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppUiTokens.cardRadiusLarge),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppUiTokens.buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: AppTextStyles.bodyMd.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        prefixIconColor: colorScheme.outline,
        suffixIconColor: colorScheme.outline,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppUiTokens.cardRadiusSmall),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppUiTokens.cardRadiusSmall),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppUiTokens.cardRadiusSmall),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppUiTokens.cardRadiusSmall),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppUiTokens.cardRadiusSmall),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppUiTokens.cardRadiusMedium),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: AppTextStyles.bodyMd.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppUiTokens.cardRadiusSmall),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.65),
        space: 1,
        thickness: 1,
      ),
    );
  }

  static ColorScheme _buildColorScheme(bool isDark) {
    if (!isDark) {
      // ── Light ────────────────────────────────────────────────────────────
      return ColorScheme(
        brightness: Brightness.light,
        // Surfaces
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        surfaceDim: AppColors.surfaceDim,
        surfaceBright: AppColors.surfaceBright,
        surfaceContainerLowest: AppColors.surfaceContainerLowest,
        surfaceContainerLow: AppColors.surfaceContainerLow,
        surfaceContainer: AppColors.surfaceContainer,
        surfaceContainerHigh: AppColors.surfaceContainerHigh,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
        // Primary
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        primaryFixed: AppColors.primaryFixed,
        primaryFixedDim: AppColors.primaryFixedDim,
        onPrimaryFixed: AppColors.onPrimaryFixed,
        onPrimaryFixedVariant: AppColors.onPrimaryFixedVariant,
        // Secondary
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        secondaryFixed: AppColors.secondaryFixed,
        secondaryFixedDim: AppColors.secondaryFixedDim,
        onSecondaryFixed: AppColors.onSecondaryFixed,
        onSecondaryFixedVariant: AppColors.onSecondaryFixedVariant,
        // Tertiary
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        tertiaryFixed: AppColors.tertiaryFixed,
        tertiaryFixedDim: AppColors.tertiaryFixedDim,
        onTertiaryFixed: AppColors.onTertiaryFixed,
        onTertiaryFixedVariant: AppColors.onTertiaryFixedVariant,
        // Error
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        // Outline
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        // Inverse
        inverseSurface: AppColors.inverseSurface,
        onInverseSurface: AppColors.inverseOnSurface,
        inversePrimary: AppColors.inversePrimary,
        // Misc
        scrim: Colors.black,
        shadow: Colors.black,
        surfaceTint: AppColors.surfaceTint,
      );
    }

    // ── Dark ───────────────────────────────────────────────────────────────
    // Surface scale: darkest → lightest as elevation increases.
    // Base:  #1A1C1A  →  containers step up toward #2D302D
    const darkSurface           = Color(0xFF1A1C1A);
    const darkSurfaceDim        = Color(0xFF121412);
    const darkSurfaceBright     = Color(0xFF383A38);
    const darkContainerLowest   = Color(0xFF0F110F);
    const darkContainerLow      = Color(0xFF1A1C1A);
    const darkContainer         = Color(0xFF1E211E);
    const darkContainerHigh     = Color(0xFF252825);
    const darkContainerHighest  = Color(0xFF2D302D);

    const darkOnSurface         = Color(0xFFE2E3DE);
    const darkOnSurfaceVariant  = Color(0xFFC1C9C0);
    const darkOutline           = Color(0xFF8B9A8D);
    const darkOutlineVariant    = Color(0xFF404942);

    return ColorScheme(
      brightness: Brightness.dark,
      // Surfaces
      surface: darkSurface,
      onSurface: darkOnSurface,
      onSurfaceVariant: darkOnSurfaceVariant,
      surfaceDim: darkSurfaceDim,
      surfaceBright: darkSurfaceBright,
      surfaceContainerLowest: darkContainerLowest,
      surfaceContainerLow: darkContainerLow,
      surfaceContainer: darkContainer,
      surfaceContainerHigh: darkContainerHigh,
      surfaceContainerHighest: darkContainerHighest,
      // Primary — keep brand green but use the lighter inverse variant
      primary: AppColors.inversePrimary,              // #4BE092 — readable on dark
      onPrimary: AppColors.onPrimaryFixed,            // #002110
      primaryContainer: AppColors.primaryContainer,   // #2ECA7F
      onPrimaryContainer: AppColors.onPrimaryFixed,   // #002110
      primaryFixed: AppColors.primaryFixed,           // #6CFDAC
      primaryFixedDim: AppColors.primaryFixedDim,     // #4BE092
      onPrimaryFixed: AppColors.onPrimaryFixed,
      onPrimaryFixedVariant: AppColors.onPrimaryFixedVariant,
      // Secondary
      secondary: AppColors.secondaryFixedDim,         // #FFB695
      onSecondary: AppColors.onSecondaryFixed,        // #351000
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryFixed,
      secondaryFixed: AppColors.secondaryFixed,
      secondaryFixedDim: AppColors.secondaryFixedDim,
      onSecondaryFixed: AppColors.onSecondaryFixed,
      onSecondaryFixedVariant: AppColors.onSecondaryFixedVariant,
      // Tertiary
      tertiary: AppColors.tertiaryFixedDim,           // #FFB597
      onTertiary: AppColors.onTertiaryFixed,          // #360F00
      tertiaryContainer: AppColors.tertiaryContainer, // #FF976A
      onTertiaryContainer: AppColors.onTertiaryFixed,
      tertiaryFixed: AppColors.tertiaryFixed,
      tertiaryFixedDim: AppColors.tertiaryFixedDim,
      onTertiaryFixed: AppColors.onTertiaryFixed,
      onTertiaryFixedVariant: AppColors.onTertiaryFixedVariant,
      // Error
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
      errorContainer: const Color(0xFF93000A),
      onErrorContainer: const Color(0xFFFFDAD6),
      // Outline
      outline: darkOutline,
      outlineVariant: darkOutlineVariant,
      // Inverse (same as light — used for snackbars / tooltips)
      inverseSurface: AppColors.inverseOnSurface,
      onInverseSurface: AppColors.inverseSurface,
      inversePrimary: AppColors.primary,
      // Misc
      scrim: Colors.black,
      shadow: Colors.black,
      surfaceTint: AppColors.inversePrimary,
    );
  }

  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge: AppTextStyles.displayLg.copyWith(
        color: colorScheme.onSurface,
      ),
      headlineLarge: AppTextStyles.headlineLg.copyWith(
        color: colorScheme.onSurface,
      ),
      headlineMedium: AppTextStyles.headlineMd.copyWith(
        color: colorScheme.onSurface,
      ),
      bodyLarge: AppTextStyles.bodyLg.copyWith(color: colorScheme.onSurface),
      bodyMedium: AppTextStyles.bodyMd.copyWith(color: colorScheme.onSurface),
      labelLarge: AppTextStyles.labelMd.copyWith(color: colorScheme.onSurface),
      labelSmall: AppTextStyles.labelSm.copyWith(color: colorScheme.onSurface),
    );
  }
}
