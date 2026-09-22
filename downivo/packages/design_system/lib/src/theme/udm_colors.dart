import 'package:flutter/material.dart';

/// Zfile color tokens from `zfile_design.json`.
///
/// Light values are the default names. Dark values use a `dark` prefix.
/// Older names (`electricBlue`, `signalCyan`, `paper`, …) point at these
/// tokens so existing widgets follow the same system.
abstract final class UdmColors {
  static const canvas = Color(0xFFF5F4FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceElevated = Color(0xFFFFFFFF);
  static const header = Color(0xFF6C4CE0);
  static const onboarding = Color(0xFF6C4CE0);

  static const heading = Color(0xFF211D33);
  static const body = Color(0xFF8B879C);
  static const muted = Color(0xFFB3AFC4);
  static const onAccent = Color(0xFF12233A);
  static const onGradientHeading = Color(0xFFFFFFFF);
  static const onGradientBody = Color(0xCCFFFFFF);

  static const primary = Color(0xFF6C4CE0);
  static const primaryDark = Color(0xFF5636C4);
  static const primaryLight = Color(0xFF8E6FF7);
  static const primaryContainer = Color(0xFFEFE9FE);
  static const secondary = Color(0xFF22D3B0);
  static const secondaryDark = Color(0xFF12B597);
  static const secondaryLight = Color(0xFF7CEFDB);
  static const secondaryContainer = Color(0xFFD8FBF4);

  static const border = Color(0xFFEDEBF5);
  static const borderSubtle = Color(0xFFF5F4FA);

  static const iconInactive = Color(0xFF8B879C);
  static const iconActiveBg = Color(0xFF22D3B0);
  static const iconActiveFg = Color(0xFF12233A);

  static const chartBarDefault = Color(0xFFB6A6F7);
  static const chartBarActive = Color(0xFF6C4CE0);
  static const chartTrack = Color(0xFFEDEBF5);
  static const chartFill = Color(0xFF22D3B0);

  static const cautionAmber = Color(0xFFF5A623);
  static const faultCoral = Color(0xFFE8546B);
  static const successMoss = Color(0xFF12B597);

  static const darkCanvas = Color(0xFF141020);
  static const darkSurface = Color(0xFF1E1830);
  static const darkSurfaceElevated = Color(0xFF241D3B);
  static const darkHeader = Color(0xFF4C3AAE);
  static const darkOnboarding = Color(0xFF4C3AAE);
  static const darkHeading = Color(0xFFF2F0FA);
  static const darkBody = Color(0xFFA79FC0);
  static const darkMuted = Color(0xFF746C8F);
  static const darkOnGradientBody = Color(0xBFFFFFFF);
  static const darkPrimary = Color(0xFF8E6FF7);
  static const darkPrimaryDark = Color(0xFF6C4CE0);
  static const darkPrimaryLight = Color(0xFFB3A0FF);
  static const darkPrimaryContainer = Color(0xFF2C2450);
  static const darkSecondary = Color(0xFF2EE6C0);
  static const darkSecondaryDark = Color(0xFF22D3B0);
  static const darkSecondaryLight = Color(0xFF7CEFDB);
  static const darkSecondaryContainer = Color(0xFF143830);
  static const darkBorder = Color(0xFF342C4D);
  static const darkBorderSubtle = Color(0xFF2A2440);
  static const darkIconInactive = Color(0xFF746C8F);
  static const darkIconActiveBg = Color(0xFF2EE6C0);
  static const darkChartBarDefault = Color(0xFF4B4270);
  static const darkChartBarActive = Color(0xFF8E6FF7);
  static const darkChartTrack = Color(0xFF342C4D);
  static const darkChartFill = Color(0xFF2EE6C0);

  static const imagesIcon = Color(0xFFF5A623);
  static const imagesBackground = Color(0xFFFDF0DD);
  static const videosIcon = Color(0xFF22B8D6);
  static const videosBackground = Color(0xFFDEF6FB);
  static const audioIcon = Color(0xFF8E6FF7);
  static const audioBackground = Color(0xFFEFE9FE);
  static const documentsIcon = Color(0xFF5B5BE0);
  static const documentsBackground = Color(0xFFE7E7FC);
  static const appsIcon = Color(0xFFEC4899);
  static const appsBackground = Color(0xFFFCE5F1);
  static const otherIcon = Color(0xFF9CA3AF);
  static const otherBackground = Color(0xFFEFEFF3);

  static const darkImagesIcon = Color(0xFFFFC56B);
  static const darkImagesBackground = Color(0xFF4A3214);
  static const darkVideosIcon = Color(0xFF5CEBFA);
  static const darkVideosBackground = Color(0xFF145868);
  static const darkAudioIcon = Color(0xFFC4B5FD);
  static const darkAudioBackground = Color(0xFF3A2D6E);
  static const darkDocumentsIcon = Color(0xFFA8A6FF);
  static const darkDocumentsBackground = Color(0xFF2E2C86);
  static const darkAppsIcon = Color(0xFFFF9EC8);
  static const darkAppsBackground = Color(0xFF5A2444);
  static const darkOtherIcon = Color(0xFFD2CEE0);
  static const darkOtherBackground = Color(0xFF34304A);

  static const voidGraphite = darkCanvas;
  static const raisedSlate = darkSurface;
  static const insetWell = darkCanvas;
  static const porcelain = darkHeading;
  static const fogSteel = darkBody;
  static const hairline = darkBorder;
  static const electricBlue = primary;
  static const electricBlueDim = primaryDark;
  static const signalCyan = secondary;
  static const cyanDim = secondaryDark;
  static const paper = canvas;
  static const whiteSurface = surface;
  static const ink = heading;
  static const slateMute = body;
  static const lightHairline = border;
}

abstract final class UdmBreakpoints {
  static const double tablet = 600;
  static const double desktop = 840;
}
