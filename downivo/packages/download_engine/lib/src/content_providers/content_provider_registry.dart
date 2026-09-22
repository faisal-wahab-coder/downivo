import 'package:dio/dio.dart';

import '../web_request_proxy.dart';
import 'dailymotion_uri.dart';
import 'audio_download_option.dart';
import 'models/discovered_resource.dart';
import 'media_extractor.dart';
import 'platform_social_resolver.dart';
import 'social_http_headers.dart';
import 'social_platform.dart';
import 'social_url_utils.dart';

/// Resolves social and content page URLs to direct media downloads.
class ContentProviderRegistry {
  ContentProviderRegistry({Dio? dio}) : this._using(dio ?? createEngineDio());

  ContentProviderRegistry._using(Dio dio)
      : _dio = dio,
        _platformResolver = PlatformSocialResolver(dio: dio);

  final Dio _dio;
  final PlatformSocialResolver _platformResolver;

  static bool canHandle(Uri uri) => SocialPlatform.fromUri(uri) != null;

  static String? platformLabel(Uri uri) => SocialPlatform.fromUri(uri)?.label;

  Future<DiscoveredResource?> discover(Uri pageUrl) async {
    final platform = SocialPlatform.fromUri(pageUrl);
    if (platform == null) return null;

    final fromPlatform = await _platformResolver.discover(pageUrl, platform);
    if (fromPlatform != null) {
      return AudioDownloadOption.decorate(
        fromPlatform.copyWith(pageUrl: pageUrl.toString()),
      );
    }

    if (platform == SocialPlatform.reddit &&
        !RedditUri.isDownloadable(pageUrl)) {
      return null;
    }

    if (platform == SocialPlatform.pinterest &&
        !PinterestUri.isDownloadable(pageUrl)) {
      return null;
    }

    if (platform == SocialPlatform.vimeo &&
        !VimeoUri.isDownloadable(pageUrl)) {
      return null;
    }

    if (platform == SocialPlatform.twitch &&
        !TwitchUri.isDownloadable(pageUrl)) {
      return null;
    }

    if (platform == SocialPlatform.linkedin &&
        !LinkedInUri.isDownloadable(pageUrl)) {
      return null;
    }

    if (platform == SocialPlatform.telegram &&
        !TelegramUri.isDownloadable(pageUrl)) {
      return null;
    }

    if (platform == SocialPlatform.snapchat &&
        !SnapchatUri.isDownloadable(pageUrl)) {
      return null;
    }

    if (platform == SocialPlatform.threads &&
        !ThreadsUri.isDownloadable(pageUrl)) {
      return null;
    }

    if (platform == SocialPlatform.whatsapp &&
        !WhatsAppUri.isDownloadable(pageUrl)) {
      return null;
    }

    if (platform == SocialPlatform.dailymotion &&
        !DailymotionUri.isDownloadable(pageUrl)) {
      return null;
    }

    if (platform == SocialPlatform.soundcloud) {
      return null;
    }

    final targets = SocialUrlUtils.fetchTargets(pageUrl, platform);
    for (final target in targets) {
      final html = await _fetchHtml(target, platform);
      if (html == null || html.isEmpty) continue;

      final discovered = MediaExtractor.extract(
        pageUrl: pageUrl,
        html: html,
        platform: platform,
      );
      if (discovered != null) {
        return AudioDownloadOption.decorate(
          discovered.copyWith(pageUrl: pageUrl.toString()),
        );
      }
    }
    return null;
  }

  /// Returns all downloadable resources for the given URL.
  /// For carousel posts this returns every image/video in the post.
  /// The UI should present these to the user for selection before downloading.
  Future<List<DiscoveredResource>> discoverAll(Uri pageUrl) async {
    final platform = SocialPlatform.fromUri(pageUrl);
    if (platform == null) return const [];

    final fromPlatform = await _platformResolver.discoverAll(pageUrl, platform);
    if (fromPlatform.isNotEmpty) {
      return AudioDownloadOption.decorateAll([
        for (final resource in fromPlatform)
          resource.copyWith(pageUrl: pageUrl.toString()),
      ]);
    }

    if (platform == SocialPlatform.reddit &&
        !RedditUri.isDownloadable(pageUrl)) {
      return const [];
    }

    if (platform == SocialPlatform.pinterest &&
        !PinterestUri.isDownloadable(pageUrl)) {
      return const [];
    }

    if (platform == SocialPlatform.vimeo &&
        !VimeoUri.isDownloadable(pageUrl)) {
      return const [];
    }

    if (platform == SocialPlatform.twitch &&
        !TwitchUri.isDownloadable(pageUrl)) {
      return const [];
    }

    if (platform == SocialPlatform.linkedin &&
        !LinkedInUri.isDownloadable(pageUrl)) {
      return const [];
    }

    if (platform == SocialPlatform.telegram &&
        !TelegramUri.isDownloadable(pageUrl)) {
      return const [];
    }

    if (platform == SocialPlatform.snapchat &&
        !SnapchatUri.isDownloadable(pageUrl)) {
      return const [];
    }

    if (platform == SocialPlatform.threads &&
        !ThreadsUri.isDownloadable(pageUrl)) {
      return const [];
    }

    if (platform == SocialPlatform.whatsapp &&
        !WhatsAppUri.isDownloadable(pageUrl)) {
      return const [];
    }

    if (platform == SocialPlatform.dailymotion &&
        !DailymotionUri.isDownloadable(pageUrl)) {
      return const [];
    }

    if (platform == SocialPlatform.soundcloud) {
      return const [];
    }

    // Fallback to HTML extraction (single item only).
    final targets = SocialUrlUtils.fetchTargets(pageUrl, platform);
    for (final target in targets) {
      final html = await _fetchHtml(target, platform);
      if (html == null || html.isEmpty) continue;

      final discovered = MediaExtractor.extract(
        pageUrl: pageUrl,
        html: html,
        platform: platform,
      );
      if (discovered != null) {
        return [
          AudioDownloadOption.decorate(
            discovered.copyWith(pageUrl: pageUrl.toString()),
          ),
        ];
      }
    }
    return const [];
  }

  Future<String?> _fetchHtml(Uri url, SocialPlatform platform) async {
    try {
      final response = await _dio.get<String>(
        url.toString(),
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: true,
          validateStatus: (status) => status != null && status >= 200 && status < 400,
          headers: SocialHttpHeaders.forPageFetch(url, platform),
        ),
      );
      return response.data;
    } on DioException catch (error) {
      if (error.response?.statusCode == 403 || error.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }
}
