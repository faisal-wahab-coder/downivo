import 'package:flutter/material.dart';

import 'udm_colors.dart';

/// Resolved Zfile semantic tokens for the active brightness.
@immutable
class ZfileSwatch {
  const ZfileSwatch({required this.icon, required this.background});

  final Color icon;
  final Color background;

  static ZfileSwatch lerp(ZfileSwatch a, ZfileSwatch b, double t) {
    return ZfileSwatch(
      icon: Color.lerp(a.icon, b.icon, t)!,
      background: Color.lerp(a.background, b.background, t)!,
    );
  }
}

@immutable
class ZfileTokens extends ThemeExtension<ZfileTokens> {
  const ZfileTokens({
    required this.canvas,
    required this.surface,
    required this.surfaceElevated,
    required this.header,
    required this.onboarding,
    required this.heroStart,
    required this.heroEnd,
    required this.heading,
    required this.body,
    required this.muted,
    required this.onAccent,
    required this.onGradientHeading,
    required this.onGradientBody,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.primaryContainer,
    required this.secondary,
    required this.secondaryDark,
    required this.secondaryLight,
    required this.secondaryContainer,
    required this.border,
    required this.borderSubtle,
    required this.iconInactive,
    required this.iconActiveBg,
    required this.iconActiveFg,
    required this.chartBarDefault,
    required this.chartBarActive,
    required this.chartTrack,
    required this.chartFill,
    required this.categories,
    required this.thumbnailGradients,
    required this.cardShadow,
    required this.floatingShadow,
    required this.buttonGlow,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceElevated;
  final Color header;
  final Color onboarding;
  final Color heroStart;
  final Color heroEnd;
  final Color heading;
  final Color body;
  final Color muted;
  final Color onAccent;
  final Color onGradientHeading;
  final Color onGradientBody;
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color primaryContainer;
  final Color secondary;
  final Color secondaryDark;
  final Color secondaryLight;
  final Color secondaryContainer;
  final Color border;
  final Color borderSubtle;
  final Color iconInactive;
  final Color iconActiveBg;
  final Color iconActiveFg;
  final Color chartBarDefault;
  final Color chartBarActive;
  final Color chartTrack;
  final Color chartFill;
  final Map<String, ZfileSwatch> categories;
  final List<List<Color>> thumbnailGradients;
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> floatingShadow;
  final List<BoxShadow> buttonGlow;

  static ZfileTokens of(BuildContext context) {
    return Theme.of(context).extension<ZfileTokens>() ?? light;
  }

  ZfileSwatch swatch(String key) => categories[key] ?? categories['other']!;

  List<Color> gradientFor(String seed) {
    final gradients = thumbnailGradients;
    if (gradients.isEmpty) return [primary, primaryDark];
    final index = seed.hashCode & 0x7fffffff;
    return gradients[index % gradients.length];
  }

  static const light = ZfileTokens(
    canvas: UdmColors.canvas,
    surface: UdmColors.surface,
    surfaceElevated: UdmColors.surfaceElevated,
    header: UdmColors.header,
    onboarding: UdmColors.onboarding,
    heroStart: Color(0xFF8B6BF2),
    heroEnd: Color(0xFF5F3FDB),
    heading: UdmColors.heading,
    body: UdmColors.body,
    muted: UdmColors.muted,
    onAccent: UdmColors.onAccent,
    onGradientHeading: UdmColors.onGradientHeading,
    onGradientBody: UdmColors.onGradientBody,
    primary: UdmColors.primary,
    primaryDark: UdmColors.primaryDark,
    primaryLight: UdmColors.primaryLight,
    primaryContainer: UdmColors.primaryContainer,
    secondary: UdmColors.secondary,
    secondaryDark: UdmColors.secondaryDark,
    secondaryLight: UdmColors.secondaryLight,
    secondaryContainer: UdmColors.secondaryContainer,
    border: UdmColors.border,
    borderSubtle: UdmColors.borderSubtle,
    iconInactive: UdmColors.iconInactive,
    iconActiveBg: UdmColors.iconActiveBg,
    iconActiveFg: UdmColors.iconActiveFg,
    chartBarDefault: UdmColors.chartBarDefault,
    chartBarActive: UdmColors.chartBarActive,
    chartTrack: UdmColors.chartTrack,
    chartFill: UdmColors.chartFill,
    categories: {
      'images': ZfileSwatch(
        icon: UdmColors.imagesIcon,
        background: UdmColors.imagesBackground,
      ),
      'videos': ZfileSwatch(
        icon: UdmColors.videosIcon,
        background: UdmColors.videosBackground,
      ),
      'audio': ZfileSwatch(
        icon: UdmColors.audioIcon,
        background: UdmColors.audioBackground,
      ),
      'documents': ZfileSwatch(
        icon: UdmColors.documentsIcon,
        background: UdmColors.documentsBackground,
      ),
      'apps': ZfileSwatch(
        icon: UdmColors.appsIcon,
        background: UdmColors.appsBackground,
      ),
      'other': ZfileSwatch(
        icon: UdmColors.otherIcon,
        background: UdmColors.otherBackground,
      ),
    },
    thumbnailGradients: [
      [Color(0xFF7B5EF5), Color(0xFF3A2E8F)],
      [Color(0xFFE84EA0), Color(0xFF5B2E8F)],
      [Color(0xFF3ED0D6), Color(0xFF4A5FE0)],
      [Color(0xFF5F3FDB), Color(0xFF1E1533)],
      [Color(0xFFC93BD1), Color(0xFF5C2C8F)],
      [Color(0xFFE8546B), Color(0xFF8B2E8F)],
    ],
    cardShadow: [
      BoxShadow(
        color: Color(0x146C4CE0),
        offset: Offset(0, 8),
        blurRadius: 20,
      ),
    ],
    floatingShadow: [
      BoxShadow(
        color: Color(0x1F211D33),
        offset: Offset(0, 12),
        blurRadius: 32,
      ),
    ],
    buttonGlow: [
      BoxShadow(
        color: Color(0x5922D3B0),
        offset: Offset(0, 6),
        blurRadius: 16,
      ),
    ],
  );

  static const dark = ZfileTokens(
    canvas: UdmColors.darkCanvas,
    surface: UdmColors.darkSurface,
    surfaceElevated: UdmColors.darkSurfaceElevated,
    header: UdmColors.darkHeader,
    onboarding: UdmColors.darkOnboarding,
    heroStart: Color(0xFF6B4FE0),
    heroEnd: Color(0xFF382A82),
    heading: UdmColors.darkHeading,
    body: UdmColors.darkBody,
    muted: UdmColors.darkMuted,
    onAccent: UdmColors.onAccent,
    onGradientHeading: UdmColors.onGradientHeading,
    onGradientBody: UdmColors.darkOnGradientBody,
    primary: UdmColors.darkPrimary,
    primaryDark: UdmColors.darkPrimaryDark,
    primaryLight: UdmColors.darkPrimaryLight,
    primaryContainer: UdmColors.darkPrimaryContainer,
    secondary: UdmColors.darkSecondary,
    secondaryDark: UdmColors.darkSecondaryDark,
    secondaryLight: UdmColors.darkSecondaryLight,
    secondaryContainer: UdmColors.darkSecondaryContainer,
    border: UdmColors.darkBorder,
    borderSubtle: UdmColors.darkBorderSubtle,
    iconInactive: UdmColors.darkIconInactive,
    iconActiveBg: UdmColors.darkIconActiveBg,
    iconActiveFg: UdmColors.iconActiveFg,
    chartBarDefault: UdmColors.darkChartBarDefault,
    chartBarActive: UdmColors.darkChartBarActive,
    chartTrack: UdmColors.darkChartTrack,
    chartFill: UdmColors.darkChartFill,
    categories: {
      'images': ZfileSwatch(
        icon: UdmColors.darkImagesIcon,
        background: UdmColors.darkImagesBackground,
      ),
      'videos': ZfileSwatch(
        icon: UdmColors.darkVideosIcon,
        background: UdmColors.darkVideosBackground,
      ),
      'audio': ZfileSwatch(
        icon: UdmColors.darkAudioIcon,
        background: UdmColors.darkAudioBackground,
      ),
      'documents': ZfileSwatch(
        icon: UdmColors.darkDocumentsIcon,
        background: UdmColors.darkDocumentsBackground,
      ),
      'apps': ZfileSwatch(
        icon: UdmColors.darkAppsIcon,
        background: UdmColors.darkAppsBackground,
      ),
      'other': ZfileSwatch(
        icon: UdmColors.darkOtherIcon,
        background: UdmColors.darkOtherBackground,
      ),
    },
    thumbnailGradients: [
      [Color(0xFF6B4FE0), Color(0xFF241A5C)],
      [Color(0xFFB33A85), Color(0xFF3D1F5F)],
      [Color(0xFF2AA0AE), Color(0xFF33409E)],
      [Color(0xFF4A2FAE), Color(0xFF150F26)],
      [Color(0xFF9A2CA3), Color(0xFF3D1D5F)],
      [Color(0xFFB03B4E), Color(0xFF5C1F5F)],
    ],
    cardShadow: [
      BoxShadow(
        color: Color(0x59000000),
        offset: Offset(0, 8),
        blurRadius: 20,
      ),
    ],
    floatingShadow: [
      BoxShadow(
        color: Color(0x80000000),
        offset: Offset(0, 12),
        blurRadius: 32,
      ),
    ],
    buttonGlow: [
      BoxShadow(
        color: Color(0x662EE6C0),
        offset: Offset(0, 6),
        blurRadius: 18,
      ),
    ],
  );

  @override
  ZfileTokens copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceElevated,
    Color? header,
    Color? onboarding,
    Color? heroStart,
    Color? heroEnd,
    Color? heading,
    Color? body,
    Color? muted,
    Color? onAccent,
    Color? onGradientHeading,
    Color? onGradientBody,
    Color? primary,
    Color? primaryDark,
    Color? primaryLight,
    Color? primaryContainer,
    Color? secondary,
    Color? secondaryDark,
    Color? secondaryLight,
    Color? secondaryContainer,
    Color? border,
    Color? borderSubtle,
    Color? iconInactive,
    Color? iconActiveBg,
    Color? iconActiveFg,
    Color? chartBarDefault,
    Color? chartBarActive,
    Color? chartTrack,
    Color? chartFill,
    Map<String, ZfileSwatch>? categories,
    List<List<Color>>? thumbnailGradients,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? floatingShadow,
    List<BoxShadow>? buttonGlow,
  }) {
    return ZfileTokens(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      header: header ?? this.header,
      onboarding: onboarding ?? this.onboarding,
      heroStart: heroStart ?? this.heroStart,
      heroEnd: heroEnd ?? this.heroEnd,
      heading: heading ?? this.heading,
      body: body ?? this.body,
      muted: muted ?? this.muted,
      onAccent: onAccent ?? this.onAccent,
      onGradientHeading: onGradientHeading ?? this.onGradientHeading,
      onGradientBody: onGradientBody ?? this.onGradientBody,
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      secondary: secondary ?? this.secondary,
      secondaryDark: secondaryDark ?? this.secondaryDark,
      secondaryLight: secondaryLight ?? this.secondaryLight,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      iconInactive: iconInactive ?? this.iconInactive,
      iconActiveBg: iconActiveBg ?? this.iconActiveBg,
      iconActiveFg: iconActiveFg ?? this.iconActiveFg,
      chartBarDefault: chartBarDefault ?? this.chartBarDefault,
      chartBarActive: chartBarActive ?? this.chartBarActive,
      chartTrack: chartTrack ?? this.chartTrack,
      chartFill: chartFill ?? this.chartFill,
      categories: categories ?? this.categories,
      thumbnailGradients: thumbnailGradients ?? this.thumbnailGradients,
      cardShadow: cardShadow ?? this.cardShadow,
      floatingShadow: floatingShadow ?? this.floatingShadow,
      buttonGlow: buttonGlow ?? this.buttonGlow,
    );
  }

  @override
  ZfileTokens lerp(ThemeExtension<ZfileTokens>? other, double t) {
    if (other is! ZfileTokens) return this;
    return ZfileTokens(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      header: Color.lerp(header, other.header, t)!,
      onboarding: Color.lerp(onboarding, other.onboarding, t)!,
      heroStart: Color.lerp(heroStart, other.heroStart, t)!,
      heroEnd: Color.lerp(heroEnd, other.heroEnd, t)!,
      heading: Color.lerp(heading, other.heading, t)!,
      body: Color.lerp(body, other.body, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      onGradientHeading:
          Color.lerp(onGradientHeading, other.onGradientHeading, t)!,
      onGradientBody: Color.lerp(onGradientBody, other.onGradientBody, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primaryContainer:
          Color.lerp(primaryContainer, other.primaryContainer, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryDark: Color.lerp(secondaryDark, other.secondaryDark, t)!,
      secondaryLight: Color.lerp(secondaryLight, other.secondaryLight, t)!,
      secondaryContainer:
          Color.lerp(secondaryContainer, other.secondaryContainer, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      iconInactive: Color.lerp(iconInactive, other.iconInactive, t)!,
      iconActiveBg: Color.lerp(iconActiveBg, other.iconActiveBg, t)!,
      iconActiveFg: Color.lerp(iconActiveFg, other.iconActiveFg, t)!,
      chartBarDefault: Color.lerp(chartBarDefault, other.chartBarDefault, t)!,
      chartBarActive: Color.lerp(chartBarActive, other.chartBarActive, t)!,
      chartTrack: Color.lerp(chartTrack, other.chartTrack, t)!,
      chartFill: Color.lerp(chartFill, other.chartFill, t)!,
      categories: {
        for (final key in categories.keys)
          key: ZfileSwatch.lerp(
            categories[key]!,
            other.categories[key] ?? categories[key]!,
            t,
          ),
      },
      thumbnailGradients: [
        for (var i = 0; i < thumbnailGradients.length; i++)
          [
            Color.lerp(
              thumbnailGradients[i][0],
              other.thumbnailGradients[i][0],
              t,
            )!,
            Color.lerp(
              thumbnailGradients[i][1],
              other.thumbnailGradients[i][1],
              t,
            )!,
          ],
      ],
      cardShadow: [
        BoxShadow.lerp(cardShadow.first, other.cardShadow.first, t)!,
      ],
      floatingShadow: [
        BoxShadow.lerp(floatingShadow.first, other.floatingShadow.first, t)!,
      ],
      buttonGlow: [
        BoxShadow.lerp(buttonGlow.first, other.buttonGlow.first, t)!,
      ],
    );
  }
}

/// Category key used by file thumbnails and list icon wells.
String zfileCategoryKey({String? mimeType, String? fileName}) {
  final mime = (mimeType ?? '').toLowerCase();
  final name = (fileName ?? '').toLowerCase();
  bool ext(List<String> extensions) => extensions.any(name.endsWith);
  if (mime.startsWith('video/') ||
      ext(const ['.mp4', '.mkv', '.mov', '.webm'])) {
    return 'videos';
  }
  if (mime.startsWith('audio/') ||
      ext(const ['.mp3', '.m4a', '.wav', '.ogg', '.flac'])) {
    return 'audio';
  }
  if (mime.startsWith('image/') ||
      ext(const ['.jpg', '.jpeg', '.png', '.webp', '.gif'])) {
    return 'images';
  }
  if (ext(const [
    '.pdf',
    '.doc',
    '.docx',
    '.txt',
    '.xls',
    '.xlsx',
    '.ppt',
    '.pptx',
  ])) {
    return 'documents';
  }
  if (ext(const ['.apk', '.ipa'])) return 'apps';
  return 'other';
}
