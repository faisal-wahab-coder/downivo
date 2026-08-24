import 'package:dio/dio.dart';

import 'media_extractor.dart';
import 'models/discovered_resource.dart';
import 'social_http_headers.dart';
import 'social_platform.dart';
import 'social_session_utils.dart';
import 'social_url_resolver.dart';
import 'social_url_utils.dart';

/// Resolves public Facebook page URLs to direct media CDN links.
///
/// Supports:
/// - Videos (`/watch/?v=`, `/<page>/videos/<id>/`, `/video.php?v=`)
/// - Reels (`/reel/<id>`)
/// - Photo posts (`/photo/?fbid=`, `/<page>/photos/`)
/// - Share / redirect URLs (`fb.watch`, mobile share links)
/// - Multi-photo posts (extracts all images)
class FacebookResolver {
  FacebookResolver({Dio? dio})
      : _dio = dio ?? Dio(),
        _urlResolver = SocialUrlResolver(dio: dio);

  final Dio _dio;
  final SocialUrlResolver _urlResolver;

  Future<DiscoveredResource?> discover(Uri pageUrl) async {
    final all = await discoverAll(pageUrl);
    return all.isEmpty ? null : all.first;
  }

  /// Returns all downloadable media from a Facebook post.
  /// For single-media posts returns a single-element list.
  /// For multi-photo posts returns each image in order.
  Future<List<DiscoveredResource>> discoverAll(Uri pageUrl) async {
    final contentType = classifyUrl(pageUrl);
    if (contentType == FacebookContentType.home ||
        contentType == FacebookContentType.page) {
      return const [];
    }

    final resolved = await _resolveUrl(pageUrl);
    final contentId = FacebookUri.contentIdFromUri(resolved) ??
        FacebookUri.contentIdFromUri(pageUrl);

    final targets = _buildTargets(resolved, pageUrl);
    final isVideoType = contentType == FacebookContentType.video ||
        contentType == FacebookContentType.reel;

    var best = <DiscoveredResource>[];
    for (final target in targets) {
      final page = await _fetchPage(target);
      if (page == null || page.html.isEmpty) continue;

      final headers = page.cookies.isEmpty
          ? null
          : <String, String>{
              'Cookie': SocialSessionUtils.cookieHeader(page.cookies),
            };

      final resolvedType = _classifyFromHtml(page.html, contentType);

      final resources = _extractFromStructuredData(
        html: page.html,
        pageUrl: pageUrl,
        contentId: contentId,
        contentType: resolvedType,
        headers: headers,
      );
      if (resources.isNotEmpty) {
        if (isVideoType || resources.length > 1) return resources;
        if (resources.length > best.length) best = resources;
      }

      final ogResources = _extractFromOpenGraph(
        html: page.html,
        pageUrl: pageUrl,
        contentId: contentId,
        contentType: resolvedType,
        headers: headers,
      );
      if (ogResources.isNotEmpty) {
        if (isVideoType || ogResources.length > 1) return ogResources;
        if (ogResources.length > best.length) best = ogResources;
      }
    }

    return best;
  }

  /// Classifies a Facebook URL by content type — exposed for tests.
  static FacebookContentType classifyUrl(Uri uri) {
    final path = uri.path.toLowerCase();
    final host = uri.host.toLowerCase();

    if (host == 'fb.watch') return FacebookContentType.video;

    if (path == '/' || path.isEmpty) return FacebookContentType.home;

    if (path.contains('/reel/') || path.contains('/reels/')) {
      final idMatch = RegExp(r'/reels?/(\d+)').firstMatch(path);
      if (idMatch != null) return FacebookContentType.reel;
      return FacebookContentType.unknown;
    }

    if (path.contains('/watch') || path.contains('/video')) {
      return FacebookContentType.video;
    }
    if (path == '/video.php') return FacebookContentType.video;

    if (path.contains('/photo') || path.contains('/photos/')) {
      return FacebookContentType.photo;
    }

    if (path.contains('/posts/')) {
      return FacebookContentType.post;
    }

    if (uri.queryParameters.containsKey('v')) {
      return FacebookContentType.video;
    }

    if (uri.queryParameters.containsKey('fbid')) {
      return FacebookContentType.photo;
    }

    // Bare page path like /facebook/ or /pagename/ (no content segment).
    if (RegExp(r'^/[a-zA-Z0-9._-]+/?$').hasMatch(path)) {
      return FacebookContentType.page;
    }

    return FacebookContentType.unknown;
  }

  // ─── URL resolution ──────────────────────────────────────────────────

  Future<Uri> _resolveUrl(Uri pageUrl) async {
    final host = pageUrl.host.toLowerCase();
    if (host == 'fb.watch' ||
        host == 'l.facebook.com' ||
        host == 'lm.facebook.com') {
      return _urlResolver.resolveRedirects(pageUrl);
    }
    return pageUrl;
  }

  List<Uri> _buildTargets(Uri resolved, Uri original) {
    final targets = <Uri>{};

    final normalized = FacebookUri.normalize(resolved);
    targets.add(normalized);

    if (resolved != original) {
      targets.add(FacebookUri.normalize(original));
    }

    // Try mobile version (often has simpler HTML with og: tags).
    targets.add(
      Uri.parse(_swapHost(normalized, 'm.facebook.com')),
    );

    // Try mbasic (minimal HTML, often accessible without login).
    targets.add(
      Uri.parse(_swapHost(normalized, 'mbasic.facebook.com')),
    );

    return targets.toList();
  }

  static String _swapHost(Uri uri, String host) {
    final path = uri.path.isEmpty ? '/' : uri.path;
    final query = uri.query.isEmpty ? '' : '?${uri.query}';
    return 'https://$host$path$query';
  }

  // ─── Page fetching ────────────────────────────────────────────────────

  Future<_FetchedFacebookPage?> _fetchPage(Uri url) async {
    try {
      final response = await _dio.get<String>(
        url.toString(),
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: true,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 400,
          headers: SocialHttpHeaders.forPageFetch(
            url,
            SocialPlatform.facebook,
          ),
        ),
      );
      return _FetchedFacebookPage(
        html: response.data ?? '',
        cookies: SocialSessionUtils.cookiesFromHeaders(response.headers),
      );
    } on DioException {
      return null;
    }
  }

  // ─── Content classification from HTML ─────────────────────────────────

  FacebookContentType _classifyFromHtml(
    String html,
    FacebookContentType urlType,
  ) {
    if (urlType != FacebookContentType.unknown) return urlType;

    if (_metaContent(html, 'og:video') != null ||
        _metaContent(html, 'og:video:url') != null) {
      return FacebookContentType.video;
    }
    if (_metaContent(html, 'og:image') != null) {
      return FacebookContentType.photo;
    }
    return FacebookContentType.unknown;
  }

  // ─── Structured data extraction ──────────────────────────────────────

  List<DiscoveredResource> _extractFromStructuredData({
    required String html,
    required Uri pageUrl,
    required String? contentId,
    required FacebookContentType contentType,
    required Map<String, String>? headers,
  }) {
    final title = _metaContent(html, 'og:title');
    final thumbnailUrl = _metaContent(html, 'og:image');
    final extractVideo = contentType == FacebookContentType.video ||
        contentType == FacebookContentType.reel;

    if (extractVideo) {
      // Strategy 1: Look for video URLs in embedded JSON (Facebook Relay data).
      final videoUrls = _extractVideoUrlsFromJson(html);
      if (videoUrls.isNotEmpty) {
        final slug = contentId ?? _slugFromPageUrl(pageUrl);
        return [
          DiscoveredResource(
            directUrl: videoUrls.first,
            fileName: MediaExtractor.buildFileNameForSocial(
              pageUrl: pageUrl,
              platform: SocialPlatform.facebook,
              mediaUrl: videoUrls.first,
              title: title,
              fallbackSlug: slug,
              mimeHint: 'video/mp4',
            ),
            platform: SocialPlatform.facebook.label,
            pageUrl: pageUrl.toString(),
            title: title,
            mimeType: 'video/mp4',
            thumbnailUrl: thumbnailUrl,
            requestHeaders: headers,
          ),
        ];
      }

      // Strategy 2: Look for HD/SD video URLs in HTML attributes.
      final hdSdUrls = _extractHdSdVideoUrls(html);
      if (hdSdUrls.isNotEmpty) {
        final bestUrl = hdSdUrls.first;
        final slug = contentId ?? _slugFromPageUrl(pageUrl);
        return [
          DiscoveredResource(
            directUrl: bestUrl,
            fileName: MediaExtractor.buildFileNameForSocial(
              pageUrl: pageUrl,
              platform: SocialPlatform.facebook,
              mediaUrl: bestUrl,
              title: title,
              fallbackSlug: slug,
              mimeHint: 'video/mp4',
            ),
            platform: SocialPlatform.facebook.label,
            pageUrl: pageUrl.toString(),
            title: title,
            mimeType: 'video/mp4',
            thumbnailUrl: thumbnailUrl,
            requestHeaders: headers,
          ),
        ];
      }
    }

    // Strategy 3: Extract photo URLs from structured data.
    // Run for photo, post, and unknown types — posts can contain images.
    if (contentType == FacebookContentType.photo ||
        contentType == FacebookContentType.post ||
        contentType == FacebookContentType.unknown) {
      final imageUrls = _extractImageUrlsFromJson(html);
      if (imageUrls.isNotEmpty) {
        return _buildPhotoResources(
          images: imageUrls,
          pageUrl: pageUrl,
          contentId: contentId,
          title: title,
          headers: headers,
        );
      }
    }

    return const [];
  }

  // ─── OpenGraph fallback ───────────────────────────────────────────────

  List<DiscoveredResource> _extractFromOpenGraph({
    required String html,
    required Uri pageUrl,
    required String? contentId,
    required FacebookContentType contentType,
    required Map<String, String>? headers,
  }) {
    final title = _metaContent(html, 'og:title');
    final thumbnailUrl = _metaContent(html, 'og:image');
    final slug = contentId ?? _slugFromPageUrl(pageUrl);
    final isVideoType = contentType == FacebookContentType.video ||
        contentType == FacebookContentType.reel;

    if (isVideoType) {
      final videoUrl = _metaContent(html, 'og:video') ??
          _metaContent(html, 'og:video:url') ??
          _metaContent(html, 'og:video:secure_url');
      if (videoUrl != null && videoUrl.startsWith('http')) {
        return [
          DiscoveredResource(
            directUrl: videoUrl,
            fileName: MediaExtractor.buildFileNameForSocial(
              pageUrl: pageUrl,
              platform: SocialPlatform.facebook,
              mediaUrl: videoUrl,
              title: title,
              fallbackSlug: slug,
              mimeHint: _metaContent(html, 'og:video:type') ?? 'video/mp4',
            ),
            platform: SocialPlatform.facebook.label,
            pageUrl: pageUrl.toString(),
            title: title,
            mimeType: _metaContent(html, 'og:video:type') ?? 'video/mp4',
            thumbnailUrl: thumbnailUrl,
            requestHeaders: headers,
          ),
        ];
      }
      return const [];
    }
    final imageUrls = _allMetaContent(html, 'og:image')
        .followedBy(_allMetaContent(html, 'og:image:url'))
        .followedBy(_allMetaContent(html, 'og:image:secure_url'))
        .where(
          (url) =>
              url.startsWith('http') &&
              _isFacebookImageUrl(url) &&
              !_isLowValueFacebookImage(url),
        )
        .toList();
    final unique = _dedupeFacebookImageUrls(imageUrls);
    if (unique.isEmpty) return const [];
    return _buildPhotoResources(
      images: unique,
      pageUrl: pageUrl,
      contentId: contentId,
      title: title,
      headers: headers,
    );
  }

  // ─── Video URL extraction ─────────────────────────────────────────────

  /// Extracts direct video CDN URLs from Facebook's embedded JSON/HTML.
  static List<String> _extractVideoUrlsFromJson(String html) {
    final urls = <String>[];

    // Pattern 1: "playable_url_quality_hd":"..." or "playable_url":"..."
    for (final field in [
      'playable_url_quality_hd',
      'playable_url',
      'browser_native_hd_url',
      'browser_native_sd_url',
    ]) {
      final pattern = RegExp(
        '"$field"\\s*:\\s*"((?:\\\\.|[^"\\\\])*)"',
        caseSensitive: false,
      );
      for (final match in pattern.allMatches(html)) {
        final url = SocialSessionUtils.decodeEmbeddedUrl(match.group(1)!);
        if (_isFacebookVideoUrl(url)) urls.add(url);
      }
    }

    // Pattern 2: data-video-url or data-hd attributes.
    for (final attr in ['data-hd', 'data-sd', 'data-video-url']) {
      final pattern = RegExp('$attr=["\']([^"\']+)["\']', caseSensitive: false);
      for (final match in pattern.allMatches(html)) {
        final url = _decodeHtmlEntities(match.group(1)!);
        if (_isFacebookVideoUrl(url)) urls.add(url);
      }
    }

    // Deduplicate, preferring HD first.
    return urls.toSet().toList();
  }

  /// Extracts HD/SD video URLs from Facebook HTML.
  static List<String> _extractHdSdVideoUrls(String html) {
    final urls = <String>[];

    // Facebook CDN video patterns.
    final patterns = [
      RegExp(
        r'https://video[^\s"\\]*\.fbcdn\.net/[^\s"\\]+',
        caseSensitive: false,
      ),
      RegExp(
        r'https://scontent[^\s"\\]*\.fbcdn\.net/[^\s"\\]*\.mp4[^\s"\\]*',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      for (final match in pattern.allMatches(html)) {
        final url = SocialSessionUtils.decodeEmbeddedUrl(match.group(0)!);
        if (_isFacebookVideoUrl(url)) urls.add(url);
      }
    }

    return urls.toSet().toList();
  }

  static bool _isFacebookVideoUrl(String url) {
    if (!url.startsWith('http')) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    return (host.contains('fbcdn.net') ||
            host.contains('facebook.com') ||
            host.contains('fbvideo')) &&
        !host.contains('static') &&
        !url.contains('/static/');
  }

  // ─── Image URL extraction ─────────────────────────────────────────────

  static List<String> _extractImageUrlsFromJson(String html) {
    final urls = <String>[];

    void add(String raw) {
      final url = SocialSessionUtils.decodeEmbeddedUrl(raw);
      if (_isFacebookImageUrl(url) && !_isLowValueFacebookImage(url)) {
        urls.add(url);
      }
    }

    final nestedImageUri = RegExp(
      r'"(?:image|full_image|photo_image)"\s*:\s*\{[^{}]*?"uri"\s*:\s*"((?:\\.|[^"\\])*)"',
      caseSensitive: false,
    );
    for (final match in nestedImageUri.allMatches(html)) {
      add(match.group(1)!);
    }

    for (final field in ['uri', 'url']) {
      final pattern = RegExp(
        '"$field"\\s*:\\s*"(https?://scontent[^"]*fbcdn\\.net[^"]*)"',
        caseSensitive: false,
      );
      for (final match in pattern.allMatches(html)) {
        add(match.group(1)!);
      }
    }

    return _dedupeFacebookImageUrls(urls);
  }

  static bool _isFacebookImageUrl(String url) {
    if (!url.startsWith('http')) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    if (!host.contains('fbcdn.net') && !host.contains('facebook.com')) {
      return false;
    }
    final lower = url.toLowerCase();
    return lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.png') ||
        lower.contains('.webp') ||
        lower.contains('image/') ||
        lower.contains('/p/') ||
        lower.contains('stp=');
  }

  static bool _isLowValueFacebookImage(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('safe_image.php') ||
        lower.contains('rsrc.php') ||
        lower.contains('/static/')) {
      return true;
    }
    if (RegExp(
      r'/s(?:32|50|64|96|100|130|160|200)x(?:32|50|64|96|100|130|160|200)/',
    ).hasMatch(lower)) {
      return true;
    }
    if (RegExp(r'stp=[^&]*s(?:32|50|64|96|100|130|160|200)x').hasMatch(lower)) {
      return true;
    }
    return false;
  }

  static List<String> _dedupeFacebookImageUrls(List<String> urls) {
    final seen = <String>{};
    final unique = <String>[];
    for (final url in urls) {
      final key = Uri.tryParse(url)?.path ?? url;
      if (key.isEmpty || !seen.add(key)) continue;
      unique.add(url);
    }
    return unique;
  }

  static List<DiscoveredResource> _buildPhotoResources({
    required List<String> images,
    required Uri pageUrl,
    required String? contentId,
    required String? title,
    required Map<String, String>? headers,
  }) {
    return [
      for (var i = 0; i < images.length; i++)
        DiscoveredResource(
          directUrl: images[i],
          fileName: MediaExtractor.buildFileNameForSocial(
            pageUrl: pageUrl,
            platform: SocialPlatform.facebook,
            mediaUrl: images[i],
            title: title != null && images.length > 1
                ? '${title}_${i + 1}'
                : title,
            fallbackSlug: contentId != null && images.length > 1
                ? '${contentId}_${i + 1}'
                : contentId,
            mimeHint: 'image/jpeg',
          ),
          platform: SocialPlatform.facebook.label,
          pageUrl: pageUrl.toString(),
          title: title,
          mimeType: 'image/jpeg',
          thumbnailUrl: images[i],
          requestHeaders: headers,
        ),
    ];
  }

  // ─── Shared helpers ──────────────────────────────────────────────────

  static String? _metaContent(String html, String property) {
    final all = _allMetaContent(html, property);
    return all.isEmpty ? null : all.first;
  }

  static List<String> _allMetaContent(String html, String property) {
    final patterns = [
      RegExp(
        '<meta[^>]+property=["\']$property["\'][^>]+content=["\']([^"\']+)["\']',
        caseSensitive: false,
      ),
      RegExp(
        '<meta[^>]+content=["\']([^"\']+)["\'][^>]+property=["\']$property["\']',
        caseSensitive: false,
      ),
      RegExp(
        '<meta[^>]+name=["\']$property["\'][^>]+content=["\']([^"\']+)["\']',
        caseSensitive: false,
      ),
    ];
    final values = <String>[];
    for (final pattern in patterns) {
      for (final match in pattern.allMatches(html)) {
        final value = _decodeHtmlEntities(match.group(1)!);
        if (value.isNotEmpty && !values.contains(value)) {
          values.add(value);
        }
      }
    }
    return values;
  }

  static String _decodeHtmlEntities(String value) {
    return value
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }

  static String? _slugFromPageUrl(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;
    return segments.last;
  }
}

class _FetchedFacebookPage {
  const _FetchedFacebookPage({required this.html, required this.cookies});

  final String html;
  final Map<String, String> cookies;
}

/// Classification of Facebook URL types.
enum FacebookContentType {
  video,
  reel,
  photo,
  post,
  page,
  home,
  unknown,
}
