import 'package:flutter/material.dart';
import 'package:shared_types/shared_types.dart';

import 'udm_colors.dart';

abstract final class AppTheme {
  static ThemeData light({Color? seedColor}) {
    return _baseTheme(_lightScheme(seedColor ?? UdmColors.electricBlue));
  }

  static ThemeData dark({Color? seedColor}) {
    return _baseTheme(_darkScheme(seedColor ?? UdmColors.signalCyan));
  }

  static ThemeData fromPreference(
    ThemeModePreference preference, {
    Color? seedColor,
    Brightness platformBrightness = Brightness.light,
  }) {
    return switch (preference) {
      ThemeModePreference.light => light(seedColor: seedColor),
      ThemeModePreference.dark => dark(seedColor: seedColor),
      ThemeModePreference.system => platformBrightness == Brightness.dark
          ? dark(seedColor: seedColor)
          : light(seedColor: seedColor),
    };
  }

  static ColorScheme _darkScheme(Color primary) {
    return ColorScheme.dark(
      primary: primary,
      onPrimary: UdmColors.onAccent,
      primaryContainer: UdmColors.cyanDim,
      onPrimaryContainer: UdmColors.porcelain,
      secondary: UdmColors.fogSteel,
      onSecondary: UdmColors.voidGraphite,
      secondaryContainer: UdmColors.raisedSlate,
      onSecondaryContainer: UdmColors.porcelain,
      tertiary: UdmColors.cautionAmber,
      onTertiary: UdmColors.onAccent,
      error: UdmColors.faultCoral,
      onError: UdmColors.porcelain,
      surface: UdmColors.voidGraphite,
      onSurface: UdmColors.porcelain,
      onSurfaceVariant: UdmColors.fogSteel,
      surfaceContainerLowest: UdmColors.insetWell,
      surfaceContainerLow: UdmColors.raisedSlate,
      surfaceContainer: UdmColors.raisedSlate,
      surfaceContainerHigh: const Color(0xFF222834),
      surfaceContainerHighest: const Color(0xFF2A3140),
      outline: UdmColors.hairline,
      outlineVariant: UdmColors.hairline,
    );
  }

  static ColorScheme _lightScheme(Color primary) {
    return ColorScheme.light(
      primary: primary,
      onPrimary: UdmColors.onAccent,
      primaryContainer: const Color(0xFFD6E4FF),
      onPrimaryContainer: UdmColors.ink,
      secondary: UdmColors.slateMute,
      onSecondary: UdmColors.whiteSurface,
      secondaryContainer: const Color(0xFFE8ECF1),
      onSecondaryContainer: UdmColors.ink,
      tertiary: UdmColors.cautionAmber,
      onTertiary: UdmColors.ink,
      error: UdmColors.faultCoral,
      onError: UdmColors.whiteSurface,
      surface: UdmColors.paper,
      onSurface: UdmColors.ink,
      onSurfaceVariant: UdmColors.slateMute,
      surfaceContainerLowest: UdmColors.whiteSurface,
      surfaceContainerLow: UdmColors.whiteSurface,
      surfaceContainer: UdmColors.whiteSurface,
      surfaceContainerHigh: const Color(0xFFEEF1F4),
      surfaceContainerHighest: const Color(0xFFE4E9EE),
      outline: UdmColors.lightHairline,
      outlineVariant: UdmColors.lightHairline,
    );
  }

  static ThemeData _baseTheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final baseline = ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
    );
    final textTheme = baseline.textTheme;

    return baseline.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme.copyWith(
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        titleSmall: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          fontSize: 12,
          color: scheme.onSurfaceVariant,
        ),
        labelSmall: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          fontSize: 11,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 80,
        backgroundColor: scheme.surface,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        selectedIconTheme: IconThemeData(color: scheme.primary),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.7)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline.withValues(alpha: 0.7),
        space: 1,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? UdmColors.insetWell : scheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.surfaceContainerHigh,
        contentTextStyle: TextStyle(color: scheme.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.outline.withValues(alpha: 0.45),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
