import 'dart:convert';

import 'package:dio/dio.dart';

import 'media_extractor.dart';
import 'models/discovered_resource.dart';
import 'social_http_headers.dart';
import 'social_platform.dart';
import 'social_session_utils.dart';
import 'social_url_utils.dart';
import 'social_url_resolver.dart';

/// Resolves TikTok page URLs to direct MP4 CDN links or photo image URLs.
class TikTokResolver {
  TikTokResolver({Dio? dio})
      : _dio = dio ?? Dio(),
        _urlResolver = SocialUrlResolver(dio: dio);

  final Dio _dio;
  final SocialUrlResolver _urlResolver;

  Future<DiscoveredResource?> discover(Uri pageUrl) async {
    final all = await discoverAll(pageUrl);
    return all.isEmpty ? null : all.first;
  }

  /// Returns all downloadable media from a TikTok post.
  /// For video posts this returns a single-element list.
  /// For photo/carousel posts this returns each image in order.
  Future<List<DiscoveredResource>> discoverAll(Uri pageUrl) async {
    final resolved = await _urlResolver.resolveRedirects(pageUrl);
    final contentId = TikTokUri.videoIdFromUri(resolved) ??
        TikTokUri.videoIdFromUri(pageUrl);
    if (contentId == null) {
      _log('TikTok: no content ID from $pageUrl');
      return const [];
    }

    final isPhoto = TikTokUri.isPhotoPost(resolved) ||
        TikTokUri.isPhotoPost(pageUrl);

    final targets = [
      resolved.replace(queryParameters: const {}),
      if (!isPhoto)
        Uri.parse('https://www.tiktok.com/@_/video/$contentId'),
      Uri.parse('https://m.tiktok.com/v/$contentId.html'),
    ];

    for (final target in targets.toSet()) {
      final page = await _fetchPage(target);
      if (page == null) {
        _log('TikTok: fetch failed for $target');
        continue;
      }
      if (page.html.isEmpty) {
        _log('TikTok: empty HTML from $target');
        continue;
      }

      _log('TikTok: fetched ${page.html.length} chars from $target');

      final headers = page.cookies.isEmpty
          ? null
          : <String, String>{
              'Cookie': SocialSessionUtils.cookieHeader(page.cookies),
            };

      if (isPhoto) {
        final results = _extractPhotoResources(
          html: page.html,
          pageUrl: pageUrl,
          contentId: contentId,
          headers: headers,
        );
        if (results.isNotEmpty) {
          _log('TikTok: found ${results.length} photo(s) from $target');
          return results;
        }
        _log('TikTok: no photo URLs extracted from $target');
        continue;
      }

      final streams = _extractVideoStreams(page.html);
      final mediaUrl = streams.defaultUrl;
      if (mediaUrl == null) {
        _log('TikTok: no video URL extracted from $target');
        continue;
      }

      _log(
        'TikTok: found CDN URL from $target '
        '(watermark=${streams.withWatermark != null} '
        'noWatermark=${streams.withoutWatermark != null})',
      );
      final title = _metaTitle(page.html);
      final formats = streams.toFormats();
      return [
        DiscoveredResource(
          directUrl: mediaUrl,
          fileName: MediaExtractor.buildFileNameForSocial(
            pageUrl: pageUrl,
            platform: SocialPlatform.tiktok,
            mediaUrl: mediaUrl,
            title: title,
            fallbackSlug: contentId,
            mimeHint: 'video/mp4',
          ),
          platform: SocialPlatform.tiktok.label,
          pageUrl: pageUrl.toString(),
          title: title,
          mimeType: 'video/mp4',
          requestHeaders: headers,
          kind: DiscoveredResourceKind.video,
          formats: formats,
        ),
      ];
    }
    _log('TikTok: all targets exhausted for content $contentId');
    return const [];
  }

  // ignore: avoid_print
  static void _log(String message) => print(message);

  static String? videoIdFromUri(Uri uri) => TikTokUri.videoIdFromUri(uri);

  /// Label for the official save stream (burned-in TikTok watermark).
  static const withWatermarkLabel = 'With watermark';

  /// Label for the in-player stream (typically no burned-in watermark).
  static const withoutWatermarkLabel = 'Without watermark';

  /// True when [formats] is the TikTok with/without watermark pair.
  static bool isWatermarkChoice(List<MediaFormat> formats) {
    if (formats.length != 2) return false;
    final labels = formats.map((format) => format.label).toSet();
    return labels.contains(withWatermarkLabel) &&
        labels.contains(withoutWatermarkLabel);
  }

  /// Extracts the default video URL from HTML — exposed for unit tests.
  /// Prefers the no-watermark play stream when both are present.
  static String? extractFromHtmlForTest(String html) =>
      _extractVideoStreams(html).defaultUrl;

  /// Extracts watermark / no-watermark formats from HTML — exposed for tests.
  static List<MediaFormat> extractFormatsFromHtmlForTest(String html) =>
      _extractVideoStreams(html).toFormats();

  /// Extracts photo resources from HTML — exposed for unit tests.
  static List<DiscoveredResource> extractPhotosForTest({
    required String html,
    required Uri pageUrl,
    required String contentId,
  }) {
    return _extractPhotoResources(
      html: html,
      pageUrl: pageUrl,
      contentId: contentId,
      headers: null,
    );
  }

  // ─── Page fetching ──────────────────────────────────────────────────

  Future<_FetchedTikTokPage?> _fetchPage(Uri url) async {
    try {
      final response = await _dio.get<String>(
        url.toString(),
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: true,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 400,
          headers: SocialHttpHeaders.forPageFetch(url, SocialPlatform.tiktok),
        ),
      );
      return _FetchedTikTokPage(
        html: response.data ?? '',
        cookies: SocialSessionUtils.cookiesFromHeaders(response.headers),
      );
    } on DioException {
      return null;
    }
  }

  // ─── Video extraction ───────────────────────────────────────────────

  static _TikTokVideoStreams _extractVideoStreams(String html) {
    String? withWatermark;
    String? playAddr;
    String? playApi;

    void consider(String field, String url) {
      if (!_isVideoPlaybackUrl(url)) return;
      final key = field.toLowerCase().replaceAll('_', '');
      switch (key) {
        case 'downloadaddr':
          withWatermark ??= url;
        case 'playaddr':
          playAddr ??= url;
        case 'playapi':
          playApi ??= url;
      }
    }

    void scan(String source) {
      const fields = [
        'downloadAddr',
        'DownloadAddr',
        'download_addr',
        'playAddr',
        'PlayAddr',
        'play_addr',
        'playApi',
        'play_api',
      ];
      for (final field in fields) {
        final stringPattern = RegExp(
          '"$field"\\s*:\\s*"((?:\\\\.|[^"\\\\])*)"',
          caseSensitive: false,
        );
        for (final match in stringPattern.allMatches(source)) {
          consider(
            field,
            SocialSessionUtils.decodeEmbeddedUrl(match.group(1)!),
          );
        }

        final objectPattern = RegExp(
          '"$field"\\s*:\\s*\\{',
          caseSensitive: false,
        );
        for (final match in objectPattern.allMatches(source)) {
          final end = (match.start + 2500).clamp(0, source.length);
          final window = source.substring(match.start, end);
          final urlMatch = RegExp(
            r'"[Uu]rlList"\s*:\s*\[\s*"((?:\\.|[^"\\])*)"',
            caseSensitive: false,
          ).firstMatch(window);
          if (urlMatch != null) {
            consider(
              field,
              SocialSessionUtils.decodeEmbeddedUrl(urlMatch.group(1)!),
            );
          }
        }
      }
    }

    scan(html);
    for (final scriptId in [
      '__UNIVERSAL_DATA_FOR_REHYDRATION__',
      'SIGI_STATE',
    ]) {
      final json = _scriptJson(html, scriptId);
      if (json != null) scan(json);
    }

    String? fallback;
    if (withWatermark == null && playAddr == null && playApi == null) {
      final pattern = RegExp(
        r'https://(?:\\u002F|[^\s"\\])*(?:tiktokcdn|tiktokv|tiktok)\.com(?:\\u0026|\\u002F|[^\s"\\])*',
        caseSensitive: false,
      );
      for (final match in pattern.allMatches(html)) {
        final url = SocialSessionUtils.decodeEmbeddedUrl(match.group(0)!);
        if (_isVideoPlaybackUrl(url)) {
          fallback = url;
          break;
        }
      }
    }

    return _TikTokVideoStreams(
      withoutWatermark: playAddr ?? playApi,
      withWatermark: withWatermark,
      fallback: fallback,
    );
  }

  static bool _isVideoPlaybackUrl(String url) {
    if (!url.startsWith('http')) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    if (host.contains('sf-i18n-resources') ||
        host.contains('webarch-solution') ||
        url.contains('/obj/tiktok-webarch')) {
      return false;
    }
    return url.contains('/video/tos/') ||
        url.contains('mime_type=video') ||
        host.contains('tiktokcdn.com') && url.contains('.mp4');
  }

  // ─── Photo/carousel extraction (JSON-based, like Instagram) ─────────

  static List<DiscoveredResource> _extractPhotoResources({
    required String html,
    required Uri pageUrl,
    required String contentId,
    required Map<String, String>? headers,
  }) {
    final title = _metaTitle(html);

    // Strategy 1: Parse structured JSON from script tags.
    for (final scriptId in [
      '__UNIVERSAL_DATA_FOR_REHYDRATION__',
      'SIGI_STATE',
    ]) {
      final jsonStr = _scriptJson(html, scriptId);
      if (jsonStr == null) continue;

      try {
        final data = jsonDecode(jsonStr);
        if (data is! Map<String, dynamic>) continue;

        final images = _findImagePostUrls(data);
        if (images.isNotEmpty) {
          return _buildPhotoResources(
            images: images,
            pageUrl: pageUrl,
            contentId: contentId,
            title: title,
            headers: headers,
          );
        }
      } on FormatException {
        // JSON parse failed — try regex fallback below.
      }
    }

    // Strategy 2: Regex fallback for imageURL.urlList patterns.
    final regexImages = _extractImageUrlsByRegex(html);
    if (regexImages.isNotEmpty) {
      return _buildPhotoResources(
        images: regexImages,
        pageUrl: pageUrl,
        contentId: contentId,
        title: title,
        headers: headers,
      );
    }

    // Strategy 3: og:image fallback (single image only).
    final ogImage = _metaContent(html, 'og:image');
    if (ogImage != null && ogImage.startsWith('http')) {
      return [
        DiscoveredResource(
          directUrl: ogImage,
          fileName: MediaExtractor.buildFileNameForSocial(
            pageUrl: pageUrl,
            platform: SocialPlatform.tiktok,
            mediaUrl: ogImage,
            title: title,
            fallbackSlug: contentId,
            mimeHint: 'image/jpeg',
          ),
          platform: SocialPlatform.tiktok.label,
          pageUrl: pageUrl.toString(),
          title: title,
          mimeType: 'image/jpeg',
          thumbnailUrl: ogImage,
          requestHeaders: headers,
        ),
      ];
    }

    return const [];
  }

  /// Navigates TikTok's JSON structure to find imagePost image URLs.
  /// TikTok uses two known structures:
  ///   __UNIVERSAL_DATA: __DEFAULT_SCOPE__ → webapp.video-detail → itemInfo → itemStruct → imagePost
  ///   SIGI_STATE: ItemModule → {id} → imagePost
  static List<String> _findImagePostUrls(Map<String, dynamic> root) {
    // Path 1: __UNIVERSAL_DATA_FOR_REHYDRATION__
    final scope = root['__DEFAULT_SCOPE__'];
    if (scope is Map<String, dynamic>) {
      final detail = scope['webapp.video-detail'];
      if (detail is Map<String, dynamic>) {
        final itemStruct = _dig(detail, ['itemInfo', 'itemStruct']);
        if (itemStruct is Map<String, dynamic>) {
          final urls = _imagesFromItemStruct(itemStruct);
          if (urls.isNotEmpty) return urls;
        }
      }
    }

    // Path 2: SIGI_STATE ItemModule
    final itemModule = root['ItemModule'];
    if (itemModule is Map<String, dynamic>) {
      for (final value in itemModule.values) {
        if (value is Map<String, dynamic>) {
          final urls = _imagesFromItemStruct(value);
          if (urls.isNotEmpty) return urls;
        }
      }
    }

    // Path 3: Deep search for imagePost anywhere in the tree.
    return _deepFindImagePostUrls(root, depth: 0);
  }

  /// Extracts image URLs from an itemStruct containing imagePost.
  static List<String> _imagesFromItemStruct(Map<String, dynamic> item) {
    final imagePost = item['imagePost'];
    if (imagePost is! Map<String, dynamic>) return const [];

    final imagesList = imagePost['images'];
    if (imagesList is! List) return const [];

    final urls = <String>[];
    for (final image in imagesList) {
      if (image is! Map<String, dynamic>) continue;
      final url = _bestUrlFromImageEntry(image);
      if (url != null) urls.add(url);
    }
    return urls;
  }

  /// Picks the best (highest quality) URL from a single image entry.
  /// TikTok image entries have: imageURL.urlList, imageWidth, imageHeight.
  static String? _bestUrlFromImageEntry(Map<String, dynamic> image) {
    final imageURL = image['imageURL'];
    if (imageURL is Map<String, dynamic>) {
      final urlList = imageURL['urlList'];
      if (urlList is List && urlList.isNotEmpty) {
        for (final url in urlList) {
          if (url is String && url.startsWith('http')) return url;
        }
      }
    }
    // Fallback: direct url field
    final directUrl = image['url'];
    if (directUrl is String && directUrl.startsWith('http')) return directUrl;
    return null;
  }

  /// Recursively searches for imagePost.images in nested JSON (max 8 levels).
  static List<String> _deepFindImagePostUrls(
    dynamic data, {
    required int depth,
  }) {
    if (depth > 8) return const [];
    if (data is Map<String, dynamic>) {
      if (data.containsKey('imagePost')) {
        final urls = _imagesFromItemStruct(data);
        if (urls.isNotEmpty) return urls;
      }
      for (final value in data.values) {
        final urls = _deepFindImagePostUrls(value, depth: depth + 1);
        if (urls.isNotEmpty) return urls;
      }
    }
    if (data is List) {
      for (final item in data) {
        final urls = _deepFindImagePostUrls(item, depth: depth + 1);
        if (urls.isNotEmpty) return urls;
      }
    }
    return const [];
  }

  /// Regex-based fallback: extracts image URLs near "imagePost" context.
  static List<String> _extractImageUrlsByRegex(String html) {
    // Locate the imagePost block in the raw HTML/JSON.
    final imagePostIdx = html.indexOf('"imagePost"');
    if (imagePostIdx < 0) return const [];

    // Extract a window around imagePost (up to 50KB) to limit regex scope.
    final start = imagePostIdx;
    final end = (imagePostIdx + 50000).clamp(0, html.length);
    final window = html.substring(start, end);

    final urlPattern = RegExp(
      r'"urlList"\s*:\s*\[\s*"(https?://[^"]+)"',
      caseSensitive: false,
    );

    final seen = <String>{};
    final images = <String>[];
    for (final match in urlPattern.allMatches(window)) {
      final url = SocialSessionUtils.decodeEmbeddedUrl(match.group(1)!);
      if (_isImageUrl(url) && seen.add(url)) {
        images.add(url);
      }
    }
    return images;
  }

  static bool _isImageUrl(String url) {
    if (!url.startsWith('http')) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final lower = url.toLowerCase();
    if (lower.contains('/obj/tos-') && lower.contains('image')) return true;
    if (lower.contains('.jpeg') ||
        lower.contains('.jpg') ||
        lower.contains('.png') ||
        lower.contains('.webp')) {
      return true;
    }
    return false;
  }

  static List<DiscoveredResource> _buildPhotoResources({
    required List<String> images,
    required Uri pageUrl,
    required String contentId,
    required String? title,
    required Map<String, String>? headers,
  }) {
    return [
      for (var i = 0; i < images.length; i++)
        DiscoveredResource(
          directUrl: images[i],
          fileName: MediaExtractor.buildFileNameForSocial(
            pageUrl: pageUrl,
            platform: SocialPlatform.tiktok,
            mediaUrl: images[i],
            title: title != null ? '${title}_${i + 1}' : null,
            fallbackSlug: '${contentId}_${i + 1}',
            mimeHint: 'image/jpeg',
          ),
          platform: SocialPlatform.tiktok.label,
          pageUrl: pageUrl.toString(),
          title: title,
          mimeType: 'image/jpeg',
          thumbnailUrl: images[i],
          requestHeaders: headers,
          kind: DiscoveredResourceKind.fromMime(
            'image/jpeg',
            carousel: images.length > 1,
          ),
        ),
    ];
  }

  // ─── Shared helpers ─────────────────────────────────────────────────

  static String? _scriptJson(String html, String id) {
    final pattern = RegExp(
      '<script[^>]+id=["\']$id["\'][^>]*>(\\{.*?\\})</script>',
      dotAll: true,
      caseSensitive: false,
    );
    return pattern.firstMatch(html)?.group(1);
  }

  static dynamic _dig(dynamic data, List<String> keys) {
    dynamic current = data;
    for (final key in keys) {
      if (current is! Map<String, dynamic>) return null;
      current = current[key];
    }
    return current;
  }

  static String? _metaContent(String html, String property) {
    for (final pattern in [
      RegExp(
        '<meta[^>]+property=["\']$property["\'][^>]+content=["\']([^"\']+)["\']',
        caseSensitive: false,
      ),
      RegExp(
        '<meta[^>]+content=["\']([^"\']+)["\'][^>]+property=["\']$property["\']',
        caseSensitive: false,
      ),
    ]) {
      final match = pattern.firstMatch(html);
      if (match != null) return match.group(1);
    }
    return null;
  }

  static String? _metaTitle(String html) => _metaContent(html, 'og:title');
}

class _FetchedTikTokPage {
  const _FetchedTikTokPage({required this.html, required this.cookies});

  final String html;
  final Map<String, String> cookies;
}

/// Play vs official-save streams extracted from a TikTok page.
class _TikTokVideoStreams {
  const _TikTokVideoStreams({
    this.withoutWatermark,
    this.withWatermark,
    this.fallback,
  });

  final String? withoutWatermark;
  final String? withWatermark;
  final String? fallback;

  String? get defaultUrl => withoutWatermark ?? withWatermark ?? fallback;

  List<MediaFormat> toFormats() {
    final formats = <MediaFormat>[];
    final seen = <String>{};

    void add(String? url, String label, {required bool recommended}) {
      if (url == null || url.isEmpty || !seen.add(url)) return;
      formats.add(
        MediaFormat(
          url: url,
          label: label,
          mimeType: 'video/mp4',
          isRecommended: recommended,
        ),
      );
    }

    add(
      withoutWatermark,
      TikTokResolver.withoutWatermarkLabel,
      recommended: true,
    );
    add(
      withWatermark,
      TikTokResolver.withWatermarkLabel,
      recommended: withoutWatermark == null,
    );
    if (formats.isEmpty) {
      add(fallback, 'Video', recommended: true);
    }
    return formats;
  }
}
