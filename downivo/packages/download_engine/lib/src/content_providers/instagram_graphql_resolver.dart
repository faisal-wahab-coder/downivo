import 'dart:convert';

import 'package:dio/dio.dart';

import 'models/discovered_resource.dart';
import 'social_http_headers.dart';
import 'social_platform.dart';
import 'media_extractor.dart';

/// Resolves public Instagram posts/reels via the same GraphQL endpoint as the web app.
class InstagramGraphqlResolver {
  InstagramGraphqlResolver({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const _appId = '936619743392459';
  static const _docId = '24368985919464652';

  Future<DiscoveredResource?> discover(Uri pageUrl) async {
    final all = await discoverAll(pageUrl);
    return all.isEmpty ? null : all.first;
  }

  /// Returns all downloadable media items in the post (carousel items, etc.).
  /// For single-media posts this returns a list with one element.
  /// For carousel posts this returns each image/video in order.
  Future<List<DiscoveredResource>> discoverAll(Uri pageUrl) async {
    final shortcode = shortcodeFromUri(pageUrl);
    if (shortcode == null) return const [];

    final canonical = canonicalPageUrl(pageUrl, shortcode);
    final session = await _loadSession(canonical);
    if (session == null) return const [];

    final payload = await _queryGraphql(
      pageUrl: canonical,
      shortcode: shortcode,
      session: session,
    );
    if (payload == null) return const [];

    return _parseAllMedia(pageUrl: pageUrl, shortcode: shortcode, payload: payload);
  }

  static Uri canonicalPageUrl(Uri pageUrl, String shortcode) {
    final kind =
        RegExp(r'/(reel|p|tv)/').firstMatch(pageUrl.path)?.group(1) ?? 'reel';
    return Uri.parse('https://www.instagram.com/$kind/$shortcode/');
  }

  static String? shortcodeFromUri(Uri uri) {
    final match = RegExp(r'/(reel|p|tv)/([^/?#]+)').firstMatch(uri.path);
    final code = match?.group(2);
    if (code == null || code.isEmpty) return null;
    return code;
  }

  /// Classifies an Instagram URL by content type.
  static InstagramContentType classifyUrl(Uri uri) {
    final path = uri.path;
    if (RegExp(r'^/stories/[^/]+').hasMatch(path)) {
      return InstagramContentType.story;
    }
    if (RegExp(r'^/(reel|p|tv)/[^/?#]+').hasMatch(path)) {
      return InstagramContentType.post;
    }
    if (RegExp(r'^/[a-zA-Z0-9._]+/?$').hasMatch(path) && path != '/') {
      return InstagramContentType.profile;
    }
    return InstagramContentType.unknown;
  }

  /// Parses a GraphQL JSON payload — exposed for unit tests.
  static DiscoveredResource? parsePayload({
    required Uri pageUrl,
    required String shortcode,
    required Map<String, dynamic> payload,
  }) {
    final all = parseAllMedia(pageUrl: pageUrl, shortcode: shortcode, payload: payload);
    return all.isEmpty ? null : all.first;
  }

  /// Parses all media items from a payload — exposed for unit tests.
  static List<DiscoveredResource> parseAllMedia({
    required Uri pageUrl,
    required String shortcode,
    required Map<String, dynamic> payload,
  }) {
    return InstagramGraphqlResolver()._parseAllMedia(
      pageUrl: pageUrl,
      shortcode: shortcode,
      payload: payload,
    );
  }

  Future<_InstagramSession?> _loadSession(Uri pageUrl) async {
    try {
      final response = await _dio.get<String>(
        pageUrl.toString(),
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: true,
          validateStatus: (status) => status != null && status >= 200 && status < 400,
          headers: SocialHttpHeaders.forPageFetch(
            pageUrl,
            SocialPlatform.instagram,
          ),
        ),
      );

      final html = response.data;
      if (html == null || html.isEmpty) return null;

      final cookies = _cookiesFromHeaders(response.headers.map);
      final csrf = cookies['csrftoken'] ?? _firstMatch(html, [
            RegExp(r'"csrf_token":"([^"]+)"'),
            RegExp(r'"csrf_token"\s*:\s*"([^"]+)"'),
          ]);
      final lsd = _firstMatch(html, [
        RegExp(r'"LSD",\[\],\{"token":"([^"]+)"'),
        RegExp(r'"lsd":"([^"]+)"'),
      ]);

      if (csrf == null && lsd == null && cookies.isEmpty) return null;

      return _InstagramSession(cookies: cookies, csrfToken: csrf, lsdToken: lsd);
    } on DioException {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _queryGraphql({
    required Uri pageUrl,
    required String shortcode,
    required _InstagramSession session,
  }) async {
    try {
      final variables = jsonEncode({'shortcode': shortcode});
      final headers = {
        ...SocialHttpHeaders.forPageFetch(pageUrl, SocialPlatform.instagram),
        'Content-Type': 'application/x-www-form-urlencoded',
        'X-IG-App-ID': _appId,
        'X-Requested-With': 'XMLHttpRequest',
        'Accept': '*/*',
        if (session.csrfToken != null) 'X-CSRFToken': session.csrfToken!,
        if (session.lsdToken != null) 'X-FB-LSD': session.lsdToken!,
        if (session.cookies.isNotEmpty)
          'Cookie': session.cookieHeader,
      };

      final response = await _dio.post<Map<String, dynamic>>(
        'https://www.instagram.com/graphql/query/',
        data: {'variables': variables, 'doc_id': _docId},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.json,
          followRedirects: true,
          validateStatus: (status) => status != null && status >= 200 && status < 400,
          headers: headers,
        ),
      );

      return response.data;
    } on DioException {
      return null;
    }
  }

  List<DiscoveredResource> _parseAllMedia({
    required Uri pageUrl,
    required String shortcode,
    required Map<String, dynamic> payload,
  }) {
    final data = payload['data'];
    if (data is! Map<String, dynamic>) return const [];

    final webInfo = data['xdt_api__v1__media__shortcode__web_info'];
    if (webInfo is! Map<String, dynamic>) {
      final legacy = _parseLegacyShortcodeMedia(pageUrl, data['xdt_shortcode_media']);
      return legacy != null ? [legacy] : const [];
    }

    final items = webInfo['items'];
    if (items is! List || items.isEmpty) return const [];

    final item = items.first;
    if (item is! Map<String, dynamic>) return const [];

    final caption = _captionText(item['caption']);

    // Carousel: extract all media items.
    final carouselMedia = item['carousel_media'];
    if (carouselMedia is List && carouselMedia.isNotEmpty) {
      return _parseAllCarouselMedia(
        pageUrl: pageUrl,
        shortcode: shortcode,
        carousel: carouselMedia,
        caption: caption,
      );
    }

    // Single item: try video then image.
    final single = _extractSingleResource(
      item: item,
      pageUrl: pageUrl,
      shortcode: shortcode,
      caption: caption,
      index: null,
    );
    return single != null ? [single] : const [];
  }

  List<DiscoveredResource> _parseAllCarouselMedia({
    required Uri pageUrl,
    required String shortcode,
    required List<dynamic> carousel,
    required String? caption,
  }) {
    final results = <DiscoveredResource>[];
    for (var i = 0; i < carousel.length; i++) {
      final media = carousel[i];
      if (media is! Map<String, dynamic>) continue;

      final resource = _extractSingleResource(
        item: media,
        pageUrl: pageUrl,
        shortcode: shortcode,
        caption: caption,
        index: i + 1,
      );
      if (resource != null) results.add(resource);
    }
    return results;
  }

  DiscoveredResource? _extractSingleResource({
    required Map<String, dynamic> item,
    required Uri pageUrl,
    required String shortcode,
    required String? caption,
    required int? index,
  }) {
    final indexSuffix = index != null ? '_$index' : '';

    // Always try to get thumbnail (for both video and image items).
    final thumbnailUrl = _bestImageUrl(item);

    final videoUrl = _bestVideoUrl(item);
    if (videoUrl != null) {
      final fileName = MediaExtractor.buildFileNameForSocial(
        pageUrl: pageUrl,
        platform: SocialPlatform.instagram,
        mediaUrl: videoUrl,
        title: caption,
        fallbackSlug: '$shortcode$indexSuffix',
      );
      return DiscoveredResource(
        directUrl: videoUrl,
        fileName: fileName,
        platform: SocialPlatform.instagram.label,
        pageUrl: pageUrl.toString(),
        title: caption,
        mimeType: 'video/mp4',
        thumbnailUrl: thumbnailUrl,
        kind: DiscoveredResourceKind.video,
      );
    }

    final imageUrl = _bestImageUrl(item);
    if (imageUrl != null) {
      final fileName = MediaExtractor.buildFileNameForSocial(
        pageUrl: pageUrl,
        platform: SocialPlatform.instagram,
        mediaUrl: imageUrl,
        title: caption,
        fallbackSlug: '$shortcode$indexSuffix',
        mimeHint: 'image/jpeg',
      );
      return DiscoveredResource(
        directUrl: imageUrl,
        fileName: fileName,
        platform: SocialPlatform.instagram.label,
        pageUrl: pageUrl.toString(),
        title: caption,
        mimeType: 'image/jpeg',
        thumbnailUrl: imageUrl,
        kind: DiscoveredResourceKind.image,
      );
    }

    return null;
  }

  DiscoveredResource? _parsePayload({
    required Uri pageUrl,
    required String shortcode,
    required Map<String, dynamic> payload,
  }) {
    final all = _parseAllMedia(pageUrl: pageUrl, shortcode: shortcode, payload: payload);
    return all.isEmpty ? null : all.first;
  }

  DiscoveredResource? _parseCarouselFirstMedia({
    required Uri pageUrl,
    required String shortcode,
    required List<dynamic> carousel,
    required String? caption,
  }) {
    final all = _parseAllCarouselMedia(
      pageUrl: pageUrl,
      shortcode: shortcode,
      carousel: carousel,
      caption: caption,
    );
    return all.isEmpty ? null : all.first;
  }

  DiscoveredResource? _parseLegacyShortcodeMedia(
    Uri pageUrl,
    Object? media,
  ) {
    if (media is! Map<String, dynamic>) return null;

    final shortcode = media['shortcode']?.toString() ?? shortcodeFromUri(pageUrl);
    final caption = _captionFromLegacyEdges(media['edge_media_to_caption']);

    // Try video first.
    final videoUrl = media['video_url'];
    if (videoUrl is String && videoUrl.startsWith('http')) {
      final fileName = MediaExtractor.buildFileNameForSocial(
        pageUrl: pageUrl,
        platform: SocialPlatform.instagram,
        mediaUrl: videoUrl,
        title: caption,
        fallbackSlug: shortcode,
      );
      return DiscoveredResource(
        directUrl: videoUrl,
        fileName: fileName,
        platform: SocialPlatform.instagram.label,
        pageUrl: pageUrl.toString(),
        title: caption,
        mimeType: 'video/mp4',
      );
    }

    // Fall back to image (display_url or thumbnail_src).
    final imageUrl = media['display_url'] ?? media['thumbnail_src'];
    if (imageUrl is String && imageUrl.startsWith('http')) {
      final fileName = MediaExtractor.buildFileNameForSocial(
        pageUrl: pageUrl,
        platform: SocialPlatform.instagram,
        mediaUrl: imageUrl,
        title: caption,
        fallbackSlug: shortcode,
        mimeHint: 'image/jpeg',
      );
      return DiscoveredResource(
        directUrl: imageUrl,
        fileName: fileName,
        platform: SocialPlatform.instagram.label,
        pageUrl: pageUrl.toString(),
        title: caption,
        mimeType: 'image/jpeg',
      );
    }

    return null;
  }

  static String? _bestVideoUrl(Map<String, dynamic> item) {
    final versions = item['video_versions'];
    if (versions is! List || versions.isEmpty) {
      final direct = item['video_url'];
      return direct is String && direct.startsWith('http') ? direct : null;
    }

    Map<String, dynamic>? best;
    var bestWidth = -1;
    for (final version in versions) {
      if (version is! Map<String, dynamic>) continue;
      final url = version['url'];
      if (url is! String || !url.startsWith('http')) continue;
      final width = version['width'];
      final parsedWidth = width is int ? width : int.tryParse('$width') ?? 0;
      if (parsedWidth >= bestWidth) {
        bestWidth = parsedWidth;
        best = version;
      }
    }

    final url = best?['url'];
    return url is String ? url : null;
  }

  static String? _bestImageUrl(Map<String, dynamic> item) {
    final originalAspect = _aspectRatio(
      _asInt(item['original_width']),
      _asInt(item['original_height']),
    );

    final versions = item['image_versions2'];
    if (versions is Map<String, dynamic>) {
      final candidates = versions['candidates'];
      if (candidates is List && candidates.isNotEmpty) {
        _ImageCandidate? best;
        for (final candidate in candidates) {
          if (candidate is! Map<String, dynamic>) continue;
          final url = candidate['url'];
          if (url is! String || !url.startsWith('http')) continue;
          final scored = _ImageCandidate(
            url: url,
            width: _asInt(candidate['width']) ?? 0,
            height: _asInt(candidate['height']) ?? 0,
            originalAspect: originalAspect,
          );
          if (best == null || scored.isBetterThan(best)) {
            best = scored;
          }
        }
        if (best != null) return best.url;
      }
    }

    final displayUrl = item['display_url'];
    if (displayUrl is String && displayUrl.startsWith('http')) return displayUrl;
    final thumb = item['thumbnail_src'];
    return thumb is String && thumb.startsWith('http') ? thumb : null;
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    return int.tryParse('$value');
  }

  static double? _aspectRatio(int? width, int? height) {
    if (width == null || height == null || width <= 0 || height <= 0) {
      return null;
    }
    return width / height;
  }

  static String? _captionText(Object? caption) {
    if (caption is Map<String, dynamic>) {
      final text = caption['text'];
      if (text is String && text.trim().isNotEmpty) return text.trim();
    }
    return null;
  }

  static String? _captionFromLegacyEdges(Object? edges) {
    if (edges is! Map<String, dynamic>) return null;
    final list = edges['edges'];
    if (list is! List || list.isEmpty) return null;
    final first = list.first;
    if (first is! Map<String, dynamic>) return null;
    final node = first['node'];
    if (node is! Map<String, dynamic>) return null;
    final text = node['text'];
    return text is String && text.trim().isNotEmpty ? text.trim() : null;
  }

  static Map<String, String> _cookiesFromHeaders(Map<String, List<String>> headers) {
    final cookies = <String, String>{};
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() != 'set-cookie') continue;
      for (final line in entry.value) {
        final part = line.split(';').first.trim();
        final separator = part.indexOf('=');
        if (separator <= 0) continue;
        cookies[part.substring(0, separator)] = part.substring(separator + 1);
      }
    }
    return cookies;
  }

  static String? _firstMatch(String html, List<RegExp> patterns) {
    for (final pattern in patterns) {
      final match = pattern.firstMatch(html);
      if (match != null) return match.group(1);
    }
    return null;
  }
}

class _InstagramSession {
  const _InstagramSession({
    required this.cookies,
    required this.csrfToken,
    required this.lsdToken,
  });

  final Map<String, String> cookies;
  final String? csrfToken;
  final String? lsdToken;

  String get cookieHeader =>
      cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
}

class _ImageCandidate {
  _ImageCandidate({
    required this.url,
    required this.width,
    required this.height,
    required double? originalAspect,
  })  : cropped = _isCroppedImageUrl(url),
        aspectMatch = _matchesOriginalAspect(
          width: width,
          height: height,
          originalAspect: originalAspect,
        );

  final String url;
  final int width;
  final int height;
  final bool cropped;
  final bool aspectMatch;

  int get area => width * height;

  bool isBetterThan(_ImageCandidate other) {
    if (cropped != other.cropped) return !cropped;
    if (aspectMatch != other.aspectMatch) return aspectMatch;
    if (area != other.area) return area > other.area;
    return height > other.height;
  }

  static bool _matchesOriginalAspect({
    required int width,
    required int height,
    required double? originalAspect,
  }) {
    if (originalAspect == null || width <= 0 || height <= 0) return true;
    final aspect = width / height;
    return (aspect - originalAspect).abs() / originalAspect <= 0.08;
  }

  static bool _isCroppedImageUrl(String url) {
    final lower = url.toLowerCase();
    if (RegExp(r'stp=[^&\s]*c\d+\.\d+\.\d+\.\d+').hasMatch(lower)) {
      return true;
    }
    if (RegExp(r'/s\d+x\d+/').hasMatch(lower)) return true;
    if (RegExp(r'stp=[^&\s]*s(\d+)x\1(?:[^\d]|$)').hasMatch(lower)) {
      return true;
    }
    return false;
  }
}

/// Classification of Instagram URL types.
enum InstagramContentType {
  post,
  story,
  profile,
  unknown,
}
