/// Compile-time + runtime observability configuration.
class AnalyticsConfig {
  const AnalyticsConfig({
    required this.posthogApiKey,
    required this.posthogHost,
    required this.analyticsEnabled,
    required this.crashReportingEnabled,
  });

  final String posthogApiKey;
  final String posthogHost;
  final bool analyticsEnabled;
  final bool crashReportingEnabled;

  bool get hasPosthog => posthogApiKey.isNotEmpty;

  factory AnalyticsConfig.fromEnvironment({
    required bool analyticsEnabled,
    required bool crashReportingEnabled,
  }) {
    return AnalyticsConfig(
      posthogApiKey: const String.fromEnvironment('POSTHOG_API_KEY'),
      posthogHost: const String.fromEnvironment(
        'POSTHOG_HOST',
        defaultValue: 'https://us.i.posthog.com',
      ),
      analyticsEnabled: analyticsEnabled,
      crashReportingEnabled: crashReportingEnabled,
    );
  }
}

class RemoteAppConfig {
  const RemoteAppConfig({
    this.maintenanceMode = false,
    this.maxConcurrentDownloads = 3,
    this.defaultQuality,
    this.resolverEnabled = const {},
  });

  final bool maintenanceMode;
  final int maxConcurrentDownloads;
  final String? defaultQuality;
  final Map<String, bool> resolverEnabled;

  static const defaults = RemoteAppConfig();

  bool isResolverEnabled(String analyticsPlatform) {
    return resolverEnabled[analyticsPlatform] ?? true;
  }

  RemoteAppConfig copyWith({
    bool? maintenanceMode,
    int? maxConcurrentDownloads,
    String? defaultQuality,
    Map<String, bool>? resolverEnabled,
  }) {
    return RemoteAppConfig(
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      maxConcurrentDownloads:
          maxConcurrentDownloads ?? this.maxConcurrentDownloads,
      defaultQuality: defaultQuality ?? this.defaultQuality,
      resolverEnabled: resolverEnabled ?? this.resolverEnabled,
    );
  }
}

abstract final class RemoteConfigKeys {
  static const maintenanceMode = 'maintenance_mode';
  static const maxConcurrentDownloads = 'max_concurrent_downloads';
  static const defaultQuality = 'default_quality';

  static const resolverFlags = <String, String>{
    'youtube': 'youtube_resolver_enabled',
    'youtube_shorts': 'youtube_shorts_resolver_enabled',
    'tiktok': 'tiktok_resolver_enabled',
    'instagram': 'instagram_resolver_enabled',
    'facebook': 'facebook_resolver_enabled',
    'x': 'x_resolver_enabled',
    'reddit': 'reddit_resolver_enabled',
    'pinterest': 'pinterest_resolver_enabled',
    'linkedin': 'linkedin_resolver_enabled',
    'threads': 'threads_resolver_enabled',
    'soundcloud': 'soundcloud_resolver_enabled',
    'vimeo': 'vimeo_resolver_enabled',
    'twitch': 'twitch_resolver_enabled',
    'telegram': 'telegram_resolver_enabled',
    'snapchat': 'snapchat_resolver_enabled',
    'whatsapp': 'whatsapp_resolver_enabled',
    'dailymotion': 'dailymotion_resolver_enabled',
  };
}
