import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_types/shared_types.dart';

import '../spacing.dart';
import 'udm_colors.dart';
import 'zfile_tokens.dart';

abstract final class AppTheme {
  static ThemeData light({Color? seedColor}) {
    return _baseTheme(
      _lightScheme(seedColor),
      seedColor == null ? ZfileTokens.light : ZfileTokens.light.copyWith(primary: seedColor),
    );
  }

  static ThemeData dark({Color? seedColor}) {
    return _baseTheme(
      _darkScheme(seedColor),
      seedColor == null ? ZfileTokens.dark : ZfileTokens.dark.copyWith(primary: seedColor),
    );
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

  static ColorScheme _darkScheme(Color? seed) {
    final tokens = ZfileTokens.dark;
    final primary = seed ?? tokens.primary;
    return ColorScheme.dark(
      primary: primary,
      onPrimary: tokens.onAccent,
      primaryContainer: tokens.primaryContainer,
      onPrimaryContainer: tokens.primaryLight,
      secondary: tokens.secondary,
      onSecondary: tokens.onAccent,
      secondaryContainer: tokens.secondaryContainer,
      onSecondaryContainer: tokens.onAccent,
      tertiary: UdmColors.cautionAmber,
      onTertiary: tokens.onAccent,
      tertiaryContainer: UdmColors.darkImagesBackground,
      onTertiaryContainer: UdmColors.darkImagesIcon,
      error: UdmColors.faultCoral,
      onError: tokens.onGradientHeading,
      surface: tokens.canvas,
      onSurface: tokens.heading,
      onSurfaceVariant: tokens.body,
      surfaceContainerLowest: tokens.surface,
      surfaceContainerLow: tokens.surface,
      surfaceContainer: tokens.surfaceElevated,
      surfaceContainerHigh: tokens.surfaceElevated,
      surfaceContainerHighest: tokens.border,
      outline: tokens.border,
      outlineVariant: tokens.borderSubtle,
    );
  }

  static ColorScheme _lightScheme(Color? seed) {
    final tokens = ZfileTokens.light;
    final primary = seed ?? tokens.primary;
    return ColorScheme.light(
      primary: primary,
      onPrimary: tokens.onGradientHeading,
      primaryContainer: tokens.primaryContainer,
      onPrimaryContainer: tokens.primaryDark,
      secondary: tokens.secondary,
      onSecondary: tokens.onAccent,
      secondaryContainer: tokens.secondaryContainer,
      onSecondaryContainer: tokens.onAccent,
      tertiary: UdmColors.cautionAmber,
      onTertiary: tokens.onAccent,
      tertiaryContainer: UdmColors.imagesBackground,
      onTertiaryContainer: tokens.heading,
      error: UdmColors.faultCoral,
      onError: tokens.onGradientHeading,
      surface: tokens.canvas,
      onSurface: tokens.heading,
      onSurfaceVariant: tokens.body,
      surfaceContainerLowest: tokens.surface,
      surfaceContainerLow: tokens.surface,
      surfaceContainer: tokens.surface,
      surfaceContainerHigh: tokens.surface,
      surfaceContainerHighest: tokens.border,
      outline: tokens.border,
      outlineVariant: tokens.borderSubtle,
    );
  }

  static ThemeData _baseTheme(ColorScheme scheme, ZfileTokens tokens) {
    const headingFamily = 'Poppins';
    const bodyFamily = 'Inter';
    final headingFallbacks = const ['Arial'];
    final bodyFallbacks = const ['Arial'];

    TextStyle poppins({
      required double size,
      required FontWeight weight,
      double height = 1.3,
      Color? color,
    }) {
      return TextStyle(
        fontFamily: headingFamily,
        fontFamilyFallback: headingFallbacks,
        package: 'design_system',
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: color,
      );
    }

    TextStyle inter({
      required double size,
      required FontWeight weight,
      double height = 1.4,
      Color? color,
    }) {
      return TextStyle(
        fontFamily: bodyFamily,
        fontFamilyFallback: bodyFallbacks,
        package: 'design_system',
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: color,
      );
    }

    final buttonLabel = poppins(size: 14, weight: FontWeight.w600, height: 1);
    final isDark = scheme.brightness == Brightness.dark;

    final baseline = ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      fontFamily: bodyFamily,
      package: 'design_system',
      scaffoldBackgroundColor: tokens.canvas,
      extensions: [tokens],
    );

    return baseline.copyWith(
      textTheme: TextTheme(
        displaySmall: poppins(
          size: 24,
          weight: FontWeight.w700,
          height: 1.25,
          color: tokens.heading,
        ),
        headlineMedium: poppins(
          size: 24,
          weight: FontWeight.w700,
          height: 1.25,
          color: tokens.heading,
        ),
        headlineSmall: poppins(
          size: 22,
          weight: FontWeight.w700,
          height: 1.2,
          color: tokens.heading,
        ),
        titleLarge: poppins(
          size: 16,
          weight: FontWeight.w600,
          color: tokens.heading,
        ),
        titleMedium: poppins(
          size: 15,
          weight: FontWeight.w600,
          color: tokens.heading,
        ),
        titleSmall: poppins(
          size: 13,
          weight: FontWeight.w600,
          height: 1.4,
          color: tokens.heading,
        ),
        bodyLarge: inter(
          size: 14,
          weight: FontWeight.w400,
          height: 1.5,
          color: tokens.heading,
        ),
        bodyMedium: inter(
          size: 13,
          weight: FontWeight.w400,
          height: 1.5,
          color: tokens.body,
        ),
        bodySmall: inter(
          size: 12,
          weight: FontWeight.w400,
          color: tokens.body,
        ),
        labelLarge: buttonLabel,
        labelMedium: inter(
          size: 12,
          weight: FontWeight.w500,
          color: tokens.heading,
        ),
        labelSmall: inter(
          size: 11,
          weight: FontWeight.w400,
          color: tokens.muted,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: tokens.canvas,
        foregroundColor: tokens.heading,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
        titleTextStyle: poppins(
          size: 16,
          weight: FontWeight.w600,
          color: tokens.heading,
        ),
        iconTheme: IconThemeData(color: tokens.heading),
        toolbarHeight: UdmSpacing.topNavHeight,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: UdmSpacing.bottomNavHeight,
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: tokens.iconActiveBg,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UdmRadius.navActive),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return inter(
            size: 10,
            weight: selected ? FontWeight.w600 : FontWeight.w400,
            height: 1.2,
            color: selected ? tokens.heading : tokens.iconInactive,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? tokens.iconActiveFg : tokens.iconInactive,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: tokens.surface,
        indicatorColor: tokens.iconActiveBg,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UdmRadius.navActive),
        ),
        selectedIconTheme: IconThemeData(color: tokens.iconActiveFg),
        unselectedIconTheme: IconThemeData(color: tokens.iconInactive),
        selectedLabelTextStyle: inter(
          size: 11,
          weight: FontWeight.w600,
          color: tokens.heading,
        ),
        unselectedLabelTextStyle: inter(
          size: 11,
          weight: FontWeight.w400,
          color: tokens.iconInactive,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: isDark ? 8 : 2,
        shadowColor: isDark ? const Color(0xFF000000) : UdmColors.primary,
        surfaceTintColor: Colors.transparent,
        color: tokens.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UdmRadius.stat),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.border,
        space: 1,
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: tokens.iconInactive,
        textColor: tokens.heading,
        titleTextStyle: poppins(
          size: 13,
          weight: FontWeight.w600,
          height: 1.4,
          color: tokens.heading,
        ),
        subtitleTextStyle: inter(
          size: 11,
          weight: FontWeight.w400,
          color: tokens.muted,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surface,
        hintStyle: inter(size: 14, weight: FontWeight.w400, color: tokens.muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UdmRadius.md),
          borderSide: BorderSide(color: tokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UdmRadius.md),
          borderSide: BorderSide(color: tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UdmRadius.md),
          borderSide: BorderSide(color: tokens.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UdmRadius.md),
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.secondary,
          foregroundColor: tokens.onAccent,
          disabledBackgroundColor: tokens.secondary.withValues(alpha: 0.4),
          disabledForegroundColor: tokens.onAccent.withValues(alpha: 0.5),
          minimumSize: const Size(44, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: buttonLabel,
          shape: const StadiumBorder(),
          elevation: 6,
          shadowColor: tokens.buttonGlow.first.color,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.primary,
          minimumSize: const Size(44, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: buttonLabel.copyWith(color: tokens.primary),
          shape: const StadiumBorder(),
          side: BorderSide(color: tokens.primary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.primary,
          textStyle: buttonLabel.copyWith(color: tokens.primary),
          shape: const StadiumBorder(),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tokens.secondary,
        foregroundColor: tokens.onAccent,
        elevation: 6,
        focusElevation: 8,
        hoverElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UdmRadius.navActive),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return tokens.primary;
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return isDark ? tokens.onAccent : tokens.onGradientHeading;
            }
            return tokens.heading;
          }),
          iconColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return isDark ? tokens.onAccent : tokens.onGradientHeading;
            }
            return tokens.body;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return BorderSide(color: tokens.primary);
            }
            return BorderSide(color: tokens.body.withValues(alpha: 0.45));
          }),
          textStyle: WidgetStatePropertyAll(
            poppins(size: 13, weight: FontWeight.w600, height: 1.2),
          ),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return tokens.primary;
          return tokens.iconInactive;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return tokens.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(
          isDark ? tokens.onAccent : tokens.onGradientHeading,
        ),
        side: BorderSide(color: tokens.iconInactive, width: 1.5),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? tokens.onAccent : tokens.onGradientHeading;
          }
          return tokens.body;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return tokens.primary;
          return Colors.transparent;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return tokens.primary;
          return tokens.iconInactive;
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.surface,
        selectedColor: tokens.secondaryContainer,
        disabledColor: tokens.borderSubtle,
        labelStyle: inter(size: 12, weight: FontWeight.w500, color: tokens.heading),
        secondaryLabelStyle: inter(
          size: 12,
          weight: FontWeight.w500,
          color: tokens.onAccent,
        ),
        side: BorderSide(color: tokens.border),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: tokens.secondary,
        labelColor: tokens.heading,
        unselectedLabelColor: tokens.body,
        dividerColor: tokens.border,
        labelStyle: poppins(size: 14, weight: FontWeight.w600, height: 1),
        unselectedLabelStyle: poppins(size: 14, weight: FontWeight.w500, height: 1),
        indicatorSize: TabBarIndicatorSize.label,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: tokens.surfaceElevated,
        contentTextStyle: inter(
          size: 13,
          weight: FontWeight.w400,
          color: tokens.heading,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UdmRadius.md),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.chartFill,
        linearTrackColor: tokens.chartTrack,
        circularTrackColor: tokens.chartTrack,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: tokens.surfaceElevated,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(UdmRadius.sheet)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: poppins(
          size: 16,
          weight: FontWeight.w600,
          color: tokens.heading,
        ),
        contentTextStyle: inter(
          size: 13,
          weight: FontWeight.w400,
          height: 1.5,
          color: tokens.body,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UdmRadius.xl),
        ),
      ),
      iconTheme: IconThemeData(color: tokens.iconInactive),
      primaryIconTheme: IconThemeData(color: tokens.primary),
    );
  }
}
