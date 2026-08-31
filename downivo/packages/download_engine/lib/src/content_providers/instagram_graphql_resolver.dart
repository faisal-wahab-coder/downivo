import 'dart:convert';

import 'package:dio/dio.dart';

import 'models/discovered_resource.dart';
import 'social_http_headers.dart';
import 'social_platform.dart';
import 'media_extractor.dart';

/// Resolves public Instagram posts/reels via the logged-out web GraphQL API.
class InstagramGraphqlResolver {
  InstagramGraphqlResolver({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const _appId = '936619743392459';
  static const _asbdId = '359341';
  static const _docId = '27130156389949648';
  static const _friendlyName = 'PolarisLoggedOutDesktopWWWPostRootContentQuery';
  static const _graphqlUrl = 'https://www.instagram.com/api/graphql';
  static const _homeUrl = 'https://www.instagram.com/';
  static const _shortcodeAlphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

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

    final mediaId = mediaIdFromShortcode(shortcode);
    if (mediaId == null) return const [];

    final canonical = canonicalPageUrl(pageUrl, shortcode);
    final session = await _loadSession(
      pageUrl: canonical,
      mediaId: mediaId,
    );

    if (session != null) {
      final payload = await _queryGraphql(
        pageUrl: canonical,
        mediaId: mediaId,
        session: session,
      );
      if (payload != null) {
        final parsed = _parseAllMedia(
          pageUrl: pageUrl,
          shortcode: shortcode,
          payload: payload,
        );
        if (_usableResources(parsed, pageUrl)) return parsed;
      }
    }

    final html = await _fetchHtml(canonical);
    if (html == null || html.isEmpty) return const [];
    final fromHtml = _parsePrefetchedMedia(
      pageUrl: pageUrl,
      shortcode: shortcode,
      html: html,
    );
    if (_usableResources(fromHtml, pageUrl)) return fromHtml;
    return const [];
  }

  static Uri canonicalPageUrl(Uri pageUrl, String shortcode) {
    final raw =
        RegExp(r'/(reels?|p|tv)/').firstMatch(pageUrl.path)?.group(1) ?? 'reel';
    final kind = raw == 'reels' ? 'reel' : raw;
    return Uri.parse('https://www.instagram.com/$kind/$shortcode/');
  }

  static String? shortcodeFromUri(Uri uri) {
    final match = RegExp(r'/(reels?|p|tv)/([^/?#]+)').firstMatch(uri.path);
    final code = match?.group(2);
    if (code == null || code.isEmpty) return null;
    return code;
  }

  /// Converts an Instagram shortcode to the numeric media id GraphQL expects.
  static String? mediaIdFromShortcode(String shortcode) {
    var code = shortcode;
    if (code.length > 28) {
      code = code.substring(0, code.length - 28);
    }
    if (code.isEmpty) return null;
    var value = BigInt.zero;
    final base = BigInt.from(64);
    for (var i = 0; i < code.length; i++) {
      final digit = _shortcodeAlphabet.indexOf(code[i]);
      if (digit < 0) return null;
      value = value * base + BigInt.from(digit);
    }
    return value.toString();
  }

  /// Classifies an Instagram URL by content type.
  static InstagramContentType classifyUrl(Uri uri) {
    final path = uri.path;
    if (RegExp(r'^/stories/[^/]+').hasMatch(path)) {
      return InstagramContentType.story;
    }
    if (RegExp(r'^/(reels?|p|tv)/[^/?#]+').hasMatch(path) ||
        RegExp(r'^/[^/]+/(reels?|p|tv)/[^/?#]+').hasMatch(path)) {
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

  Future<_InstagramSession?> _loadSession({
    required Uri pageUrl,
    required String mediaId,
  }) async {
    try {
      final cookies = <String, String>{};
      String? csrf;
      String? lsd;

      final home = await _dio.get<String>(
        _homeUrl,
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: true,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 400,
          headers: SocialHttpHeaders.forPageFetch(
            Uri.parse(_homeUrl),
            SocialPlatform.instagram,
          ),
        ),
      );
      cookies.addAll(_cookiesFromHeaders(home.headers.map));
      final homeHtml = home.data ?? '';
      csrf = cookies['csrftoken'] ?? _csrfFromHtml(homeHtml);
      lsd = _lsdFromHtml(homeHtml);

      try {
        final ruling = await _dio.get<String>(
          'https://www.instagram.com/api/v1/web/get_ruling_for_content/',
          queryParameters: {
            'content_type': 'MEDIA',
            'target_id': mediaId,
          },
          options: Options(
            responseType: ResponseType.plain,
            followRedirects: true,
            validateStatus: (status) =>
                status != null && status >= 200 && status < 500,
            headers: _apiHeaders(
              pageUrl: pageUrl,
              csrf: csrf,
              lsd: lsd,
              cookie: _cookieHeader(cookies),
            ),
          ),
        );
        cookies.addAll(_cookiesFromHeaders(ruling.headers.map));
        csrf = cookies['csrftoken'] ?? csrf;
      } on DioException {
        // Ruling is best-effort; GraphQL can still succeed with homepage tokens.
      }

      if (lsd == null && csrf == null && cookies.isEmpty) {
        final pageHtml = await _fetchHtml(pageUrl);
        if (pageHtml == null || pageHtml.isEmpty) return null;
        csrf = _csrfFromHtml(pageHtml);
        lsd = _lsdFromHtml(pageHtml);
        if (csrf == null && lsd == null) return null;
      }

      if (csrf == null && lsd == null && cookies.isEmpty) return null;

      return _InstagramSession(
        cookies: cookies,
        csrfToken: csrf,
        lsdToken: lsd,
      );
    } on DioException {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _queryGraphql({
    required Uri pageUrl,
    required String mediaId,
    required _InstagramSession session,
  }) async {
    try {
      final headers = {
        ..._apiHeaders(
          pageUrl: pageUrl,
          csrf: session.csrfToken,
          lsd: session.lsdToken,
          cookie: session.cookieHeader,
        ),
        'Content-Type': 'application/x-www-form-urlencoded',
        'X-FB-Friendly-Name': _friendlyName,
      };

      final body = <String, String>{
        'fb_api_caller_class': 'RelayModern',
        'fb_api_req_friendly_name': _friendlyName,
        'server_timestamps': 'true',
        'variables': jsonEncode({'media_id': mediaId}),
        'doc_id': _docId,
        if (session.lsdToken != null) 'lsd': session.lsdToken!,
      };

      final endpoints = [
        _graphqlUrl,
        'https://www.instagram.com/graphql/query/',
      ];

      for (final endpoint in endpoints) {
        try {
          final response = await _dio.post<dynamic>(
            endpoint,
            data: body,
            options: Options(
              contentType: Headers.formUrlEncodedContentType,
              responseType: ResponseType.plain,
              followRedirects: true,
              validateStatus: (status) =>
                  status != null && status >= 200 && status < 400,
              headers: headers,
            ),
          );
          final parsed = _decodeJsonMap(response.data);
          if (parsed != null) return parsed;
        } on DioException {
          continue;
        }
      }
      return null;
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

    final polaris = _polarisProductMedia(data['xig_polaris_media']);
    if (polaris != null) {
      return _resourcesFromItem(
        pageUrl: pageUrl,
        shortcode: shortcode,
        item: polaris,
      );
    }

    final webInfo = data['xdt_api__v1__media__shortcode__web_info'];
    if (webInfo is! Map<String, dynamic>) {
      final legacy =
          _parseLegacyShortcodeMedia(pageUrl, data['xdt_shortcode_media']);
      return legacy != null ? [legacy] : const [];
    }

    final items = webInfo['items'];
    if (items is! List || items.isEmpty) return const [];

    final item = items.first;
    if (item is! Map<String, dynamic>) return const [];

    return _resourcesFromItem(
      pageUrl: pageUrl,
      shortcode: shortcode,
      item: item,
    );
  }

  List<DiscoveredResource> _resourcesFromItem({
    required Uri pageUrl,
    required String shortcode,
    required Map<String, dynamic> item,
  }) {
    final caption = _captionText(item['caption']);
    final carouselMedia = item['carousel_media'];
    if (carouselMedia is List && carouselMedia.isNotEmpty) {
      return _parseAllCarouselMedia(
        pageUrl: pageUrl,
        shortcode: shortcode,
        carousel: carouselMedia,
        caption: caption,
      );
    }

    final single = _extractSingleResource(
      item: item,
      pageUrl: pageUrl,
      shortcode: shortcode,
      caption: caption,
      index: null,
    );
    return single != null ? [single] : const [];
  }

  List<DiscoveredResource> _parsePrefetchedMedia({
    required Uri pageUrl,
    required String shortcode,
    required String html,
  }) {
    final product = _polarisMediaFromHtml(html);
    if (product == null) return const [];
    return _resourcesFromItem(
      pageUrl: pageUrl,
      shortcode: shortcode,
      item: product,
    );
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

    // Reels / IGTV / media_type=2 are videos. Never download the poster JPEG.
    if (_isVideoItem(item, pageUrl)) return null;

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

    // Fall back to image only for photo posts — never for video items.
    final imageUrl = media['display_url'] ?? media['thumbnail_src'];
    if (imageUrl is String &&
        imageUrl.startsWith('http') &&
        !_isVideoItem(media, pageUrl)) {
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
    final fromVersions = _bestUrlFromVideoVersions(item['video_versions']);
    if (fromVersions != null) return fromVersions;

    for (final key in ['video_url', 'playback_url']) {
      final direct = item[key];
      if (direct is String && direct.startsWith('http')) return direct;
    }

    return _videoUrlFromDashManifest(item['video_dash_manifest']);
  }

  static String? _bestUrlFromVideoVersions(Object? versions) {
    if (versions is! List || versions.isEmpty) return null;

    String? bestUrl;
    var bestWidth = -1;
    for (final version in versions) {
      if (version is! Map) continue;
      final mapped = version is Map<String, dynamic>
          ? version
          : version.map((key, value) => MapEntry(key.toString(), value));
      final url = mapped['url'] ?? mapped['src'];
      if (url is! String || !url.startsWith('http')) continue;
      final parsedWidth = _asInt(mapped['width']) ?? 0;
      if (parsedWidth >= bestWidth) {
        bestWidth = parsedWidth;
        bestUrl = url;
      }
    }
    return bestUrl;
  }

  static String? _videoUrlFromDashManifest(Object? manifest) {
    if (manifest is! String || manifest.isEmpty) return null;
    final decoded = manifest
        .replaceAll('&amp;', '&')
        .replaceAll(r'\u0026', '&')
        .replaceAll(r'\/', '/');
    final mp4 = RegExp(r'https://[^\s"<>\\]+?\.mp4[^\s"<>\\]*')
        .allMatches(decoded)
        .map((m) => m.group(0)!)
        .toList();
    if (mp4.isNotEmpty) return mp4.first;
    final hls = RegExp(r'https://[^\s"<>\\]+?\.m3u8[^\s"<>\\]*')
        .firstMatch(decoded)
        ?.group(0);
    return hls;
  }

  static bool _isVideoPage(Uri pageUrl) =>
      RegExp(r'/(reels?|tv)/').hasMatch(pageUrl.path);

  static bool _isVideoItem(Map<String, dynamic> item, Uri pageUrl) {
    if (_isVideoPage(pageUrl)) return true;
    if (item['is_video'] == true) return true;
    if (_asInt(item['media_type']) == 2) return true;
    final productType = item['product_type']?.toString().toLowerCase();
    if (productType == 'clips' ||
        productType == 'igtv' ||
        productType == 'reel') {
      return true;
    }
    if (item['video_dash_manifest'] is String &&
        (item['video_dash_manifest'] as String).isNotEmpty) {
      return true;
    }
    return false;
  }

  static bool _usableResources(
    List<DiscoveredResource> resources,
    Uri pageUrl,
  ) {
    if (resources.isEmpty) return false;
    if (!_isVideoPage(pageUrl)) return true;
    return resources.any(_isVideoResource);
  }

  static bool _isVideoResource(DiscoveredResource resource) {
    if (resource.kind == DiscoveredResourceKind.video) return true;
    final mime = resource.mimeType?.toLowerCase() ?? '';
    if (mime.startsWith('video/')) return true;
    final url = resource.directUrl.toLowerCase();
    return url.contains('.mp4') || url.contains('.m3u8');
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

  Map<String, String> _apiHeaders({
    required Uri pageUrl,
    String? csrf,
    String? lsd,
    String? cookie,
  }) {
    return {
      'User-Agent': SocialHttpHeaders.instagramDesktopUserAgent,
      'Accept': '*/*',
      'Accept-Language': 'en-US,en;q=0.9',
      'Origin': 'https://www.instagram.com',
      'Referer': pageUrl.toString(),
      'X-IG-App-ID': _appId,
      'X-ASBD-ID': _asbdId,
      'X-IG-WWW-Claim': '0',
      'X-Requested-With': 'XMLHttpRequest',
      if (csrf != null) 'X-CSRFToken': csrf,
      if (lsd != null) 'X-FB-LSD': lsd,
      if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
    };
  }

  Future<String?> _fetchHtml(Uri url) async {
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
            SocialPlatform.instagram,
          ),
        ),
      );
      return response.data;
    } on DioException {
      return null;
    }
  }

  static Map<String, dynamic>? _decodeJsonMap(Object? raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    if (raw is! String) return null;
    final trimmed = raw.trimLeft();
    if (trimmed.isEmpty || trimmed.startsWith('<')) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } on Object {
      return null;
    }
    return null;
  }

  static String? _csrfFromHtml(String html) {
    return _firstMatch(html, [
      RegExp(r'"csrf_token":"([^"]+)"'),
      RegExp(r'"csrf_token"\s*:\s*"([^"]+)"'),
    ]);
  }

  static String? _lsdFromHtml(String html) {
    final direct = _firstMatch(html, [
      RegExp(r'"LSD",\[\],\{"token":"([^"]+)"'),
      RegExp(r'"lsd":"([^"]+)"'),
    ]);
    if (direct != null) return direct;

    final eqmc = RegExp(
      r'<script\b[^>]*\bid=["' "'" r']__eqmc["' "'" r'][^>]*>(.*?)</script>',
      dotAll: true,
      caseSensitive: false,
    ).firstMatch(html)?.group(1);
    if (eqmc == null) return null;
    try {
      final decoded = jsonDecode(eqmc.trim());
      if (decoded is Map && decoded['l'] is String) {
        return decoded['l'] as String;
      }
    } on Object {
      return null;
    }
    return null;
  }

  static Map<String, dynamic>? _polarisProductMedia(Object? polaris) {
    if (polaris is! Map) return null;
    final mapped = polaris is Map<String, dynamic>
        ? polaris
        : polaris.map((key, value) => MapEntry(key.toString(), value));
    final product = mapped['if_not_gated_logged_out'];
    if (product is Map<String, dynamic>) return product;
    if (product is Map) {
      return product.map((key, value) => MapEntry(key.toString(), value));
    }
    if (mapped.containsKey('video_versions') ||
        mapped.containsKey('image_versions2') ||
        mapped.containsKey('carousel_media') ||
        mapped.containsKey('video_url')) {
      return mapped;
    }
    return null;
  }

  static Map<String, dynamic>? _polarisMediaFromHtml(String html) {
    if (!html.contains('xig_polaris_media')) return null;
    final scripts = RegExp(
      r'<script\b[^>]*>([\s\S]*?)</script>',
      caseSensitive: false,
    ).allMatches(html);
    for (final match in scripts) {
      final raw = match.group(1)?.trim();
      if (raw == null || !raw.contains('xig_polaris_media')) continue;
      try {
        final decoded = jsonDecode(raw);
        final found = _findPolarisMedia(decoded);
        if (found != null) return found;
      } on Object {
        continue;
      }
    }
    return null;
  }

  static Map<String, dynamic>? _findPolarisMedia(Object? node) {
    if (node is Map) {
      final mapped = node.map((key, value) => MapEntry(key.toString(), value));
      final polaris = _polarisProductMedia(mapped['xig_polaris_media']);
      if (polaris != null) return polaris;
      for (final value in mapped.values) {
        final found = _findPolarisMedia(value);
        if (found != null) return found;
      }
    } else if (node is List) {
      for (final item in node) {
        final found = _findPolarisMedia(item);
        if (found != null) return found;
      }
    }
    return null;
  }

  static String _cookieHeader(Map<String, String> cookies) =>
      cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');

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
