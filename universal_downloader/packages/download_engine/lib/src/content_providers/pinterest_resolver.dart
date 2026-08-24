import 'dart:convert';

import 'package:dio/dio.dart';

import 'media_extractor.dart';
import 'models/discovered_resource.dart';
import 'social_http_headers.dart';
import 'social_platform.dart';
import 'social_url_resolver.dart';
import 'social_url_utils.dart';

/// Resolves public Pinterest pin URLs to direct media CDN links.
///
/// Supports:
/// - Image pins (JPG/PNG/WebP — prefers `images.orig`)
/// - Video pins (highest MP4; HLS is not downloaded)
/// - Idea Pins / multi-page story pins (`story_pin_data.pages`)
/// - Direct `i.pinimg.com` / `v1.pinimg.com` URLs
/// - Share / short URLs (`pin.it`)
///
/// Boards and profiles are collections, not a single downloadable item.
class PinterestResolver {
  PinterestResolver({Dio? dio})
      : _dio = dio ?? Dio(),
        _urlResolver = SocialUrlResolver(dio: dio);

  final Dio _dio;
  final SocialUrlResolver _urlResolver;

  Future<DiscoveredResource?> discover(Uri pageUrl) async {
    final all = await discoverAll(pageUrl);
    return all.isEmpty ? null : all.first;
  }

  /// Returns every downloadable media item for a Pinterest URL.
  /// Idea Pins preserve `story_pin_data.pages` order.
  Future<List<DiscoveredResource>> discoverAll(Uri pageUrl) async {
    var resolved = PinterestUri.normalize(pageUrl);
    final type = PinterestUri.classifyUrl(resolved);

    if (!PinterestUri.isDownloadable(resolved) &&
        type != PinterestContentType.shortUrl) {
      return const [];
    }

    if (type == PinterestContentType.directMedia) {
      return [_directMediaResource(resolved, pageUrl)];
    }

    if (type == PinterestContentType.shortUrl) {
      resolved = PinterestUri.normalize(
        await _urlResolver.resolveRedirects(pageUrl),
      );
      if (PinterestUri.classifyUrl(resolved) ==
          PinterestContentType.shortUrl) {
        final fromHtml = await _canonicalFromShortHtml(pageUrl);
        if (fromHtml != null) {
          resolved = PinterestUri.normalize(fromHtml);
        }
      }
      if (!PinterestUri.isDownloadable(resolved)) return const [];
      if (PinterestUri.classifyUrl(resolved) ==
          PinterestContentType.directMedia) {
        return [_directMediaResource(resolved, pageUrl)];
      }
    }

    final pinId = PinterestUri.pinIdFromUri(resolved) ??
        PinterestUri.pinIdFromUri(pageUrl);

    final html = await _fetchHtml(_pinPageUri(resolved, pinId));
    if (html != null && html.isNotEmpty) {
      final fromHtml = parseHtmlResources(
        html: html,
        pageUrl: pageUrl,
        pinId: pinId,
      );
      if (fromHtml.isNotEmpty) return fromHtml;
    }

    if (pinId != null) {
      final fromPidgets = await _fetchPidgets(pinId, pageUrl);
      if (fromPidgets.isNotEmpty) return fromPidgets;
    }

    if (html != null && html.isNotEmpty) {
      final fromOg = _extractFromOpenGraph(
        html: html,
        pageUrl: pageUrl,
        pinId: pinId,
      );
      if (fromOg.isNotEmpty) return fromOg;
    }

    if (pinId != null) {
      final fromOembed = await _fetchOembed(pinId, pageUrl);
      if (fromOembed.isNotEmpty) return fromOembed;
    }

    return const [];
  }

  static PinterestContentType classifyUrl(Uri uri) =>
      PinterestUri.classifyUrl(uri);

  /// Parses media from a pin JSON object — exposed for unit tests.
  static List<DiscoveredResource> parsePinObject({
    required Uri pageUrl,
    required Map<dynamic, dynamic> pin,
    String? pinId,
  }) {
    return _resourcesFromPin(pin: pin, pageUrl: pageUrl, pinId: pinId);
  }

  /// Parses media from embedded Pinterest page JSON — exposed for unit tests.
  static List<DiscoveredResource> parseEmbeddedJson({
    required Uri pageUrl,
    required Object payload,
    String? pinId,
  }) {
    final pin = findPinObject(payload, pinId: pinId);
    if (pin == null) return const [];
    return _resourcesFromPin(pin: pin, pageUrl: pageUrl, pinId: pinId);
  }

  /// Parses HTML (`__PWS_DATA__`, JSON-LD, OpenGraph) — exposed for tests.
  static List<DiscoveredResource> parseHtmlResources({
    required String html,
    required Uri pageUrl,
    String? pinId,
  }) {
    final embedded = _decodeEmbeddedJson(html);
    if (embedded != null) {
      final fromJson = parseEmbeddedJson(
        pageUrl: pageUrl,
        payload: embedded,
        pinId: pinId,
      );
      if (fromJson.isNotEmpty) return fromJson;
    }

    final ld = _decodeJsonLd(html);
    if (ld != null) {
      final fromLd = _resourcesFromJsonLd(
        node: ld,
        pageUrl: pageUrl,
        pinId: pinId,
      );
      if (fromLd.isNotEmpty) return fromLd;
    }

    return _extractFromOpenGraph(html: html, pageUrl: pageUrl, pinId: pinId);
  }

  /// Structured pin metadata — exposed for unit tests.
  static PinterestPinInfo? parsePinInfo({
    required Object payload,
    String? pinId,
  }) {
    final pin = findPinObject(payload, pinId: pinId);
    if (pin == null) return null;
    return PinterestPinInfo.fromPin(pin);
  }

  static Map<dynamic, dynamic>? findPinObject(
    Object? node, {
    String? pinId,
  }) {
    if (node is Map) {
      if (_looksLikePin(node, pinId: pinId)) {
        return Map<dynamic, dynamic>.from(node);
      }

      final pins = node['pins'];
      if (pins is Map) {
        if (pinId != null && pins[pinId] is Map) {
          final candidate = pins[pinId] as Map;
          if (_looksLikePin(candidate, pinId: pinId)) {
            return Map<dynamic, dynamic>.from(candidate);
          }
        }
        for (final value in pins.values) {
          if (value is Map && _looksLikePin(value, pinId: pinId)) {
            return Map<dynamic, dynamic>.from(value);
          }
        }
      }

      for (final key in ['data', 'closeupPin', 'closeup_unified_json', 'pin']) {
        final nested = node[key];
        if (nested is Map && _looksLikePin(nested, pinId: pinId)) {
          return Map<dynamic, dynamic>.from(nested);
        }
      }

      for (final value in node.values) {
        final found = findPinObject(value, pinId: pinId);
        if (found != null) return found;
      }
    } else if (node is List) {
      for (final item in node) {
        final found = findPinObject(item, pinId: pinId);
        if (found != null) return found;
      }
    }
    return null;
  }

  static String mimeFromUrl(String url) {
    final path = (Uri.tryParse(url)?.path ?? url).toLowerCase();
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.webp')) return 'image/webp';
    if (path.endsWith('.gif')) return 'image/gif';
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'image/jpeg';
    if (path.endsWith('.webm')) return 'video/webm';
    if (path.endsWith('.mp4') || path.endsWith('.m4v')) return 'video/mp4';
    if (path.contains('/videos/')) return 'video/mp4';
    if (path.contains('/originals/') ||
        path.contains('/736x/') ||
        path.contains('/564x/') ||
        path.contains('/474x/') ||
        path.contains('/236x/')) {
      return 'image/jpeg';
    }
    return 'application/octet-stream';
  }

  static String normalizeMime(String? raw, {String? fallbackUrl}) {
    if (raw != null && raw.isNotEmpty) {
      final base = raw.split(';').first.trim().toLowerCase();
      if (base == 'image/jpg') return 'image/jpeg';
      return base;
    }
    if (fallbackUrl != null) return mimeFromUrl(fallbackUrl);
    return 'application/octet-stream';
  }

  /// Best MP4 from `videos.video_list`. Skips HLS (`.m3u8`).
  static String? bestVideoUrl(Map<dynamic, dynamic>? videoList) {
    if (videoList == null || videoList.isEmpty) return null;
    String? bestUrl;
    var bestScore = -1;
    for (final entry in videoList.entries) {
      final value = entry.value;
      if (value is! Map) continue;
      final url = value['url']?.toString();
      if (url == null || !url.startsWith('http')) continue;
      if (_isPlaylistUrl(url)) continue;
      final key = entry.key.toString().toUpperCase();
      if (key.contains('HLS')) continue;
      final width = value['width'] is num ? (value['width'] as num).toInt() : 0;
      final height =
          value['height'] is num ? (value['height'] as num).toInt() : 0;
      final score = width * height;
      if (score > bestScore || (score == bestScore && bestUrl == null)) {
        bestScore = score;
        bestUrl = url;
      }
    }
    return bestUrl;
  }

  /// Highest-resolution still from `images`. Prefers `orig`.
  static String? bestImageUrl(Map<dynamic, dynamic>? images) {
    if (images == null || images.isEmpty) return null;
    final orig = images['orig'];
    if (orig is Map) {
      final url = orig['url']?.toString();
      if (url != null && url.startsWith('http')) {
        return PinterestUri.upgradeImageUrl(url);
      }
    }
    String? bestUrl;
    var bestWidth = -1;
    for (final value in images.values) {
      if (value is! Map) continue;
      final url = value['url']?.toString();
      if (url == null || !url.startsWith('http')) continue;
      if (_isPlaylistUrl(url) || url.contains('/videos/')) continue;
      final width = value['width'] is num ? (value['width'] as num).toInt() : 0;
      if (width > bestWidth) {
        bestWidth = width;
        bestUrl = url;
      }
    }
    return bestUrl == null ? null : PinterestUri.upgradeImageUrl(bestUrl);
  }

  /// Pinterest MP4s are muxed. Separate audio only exists on skipped HLS.
  static bool hasSeparateAudio(Map<dynamic, dynamic>? videoList) {
    if (videoList == null) return false;
    final mp4 = bestVideoUrl(videoList);
    if (mp4 != null) return false;
    for (final value in videoList.values) {
      if (value is Map) {
        final url = value['url']?.toString() ?? '';
        if (_isPlaylistUrl(url)) return true;
      }
    }
    return false;
  }

  // ─── Fetch ───────────────────────────────────────────────────────────

  Future<String?> _fetchHtml(Uri pageUrl) async {
    try {
      final response = await _dio.get<String>(
        pageUrl.toString(),
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: true,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 400,
          headers: SocialHttpHeaders.forPageFetch(
            pageUrl,
            SocialPlatform.pinterest,
          ),
        ),
      );
      return response.data;
    } on DioException {
      return null;
    }
  }

  Future<Uri?> _canonicalFromShortHtml(Uri shortUrl) async {
    final html = await _fetchHtml(shortUrl);
    if (html == null || html.isEmpty) return null;
    final canonical = _metaContent(html, 'og:url') ??
        _linkRel(html, 'canonical');
    if (canonical == null || !canonical.startsWith('http')) return null;
    final uri = Uri.tryParse(canonical);
    if (uri == null) return null;
    if (SocialPlatform.fromUri(uri) != SocialPlatform.pinterest) return null;
    return uri;
  }

  Future<List<DiscoveredResource>> _fetchPidgets(
    String pinId,
    Uri pageUrl,
  ) async {
    try {
      final endpoint = Uri.parse(
        'https://widgets.pinterest.com/v3/pidgets/pins/info/?pin_ids=$pinId',
      );
      final response = await _dio.get<dynamic>(
        endpoint.toString(),
        options: Options(
          responseType: ResponseType.json,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 400,
          headers: {
            ...SocialHttpHeaders.forPageFetch(
              pageUrl,
              SocialPlatform.pinterest,
            ),
            'Accept': 'application/json',
          },
        ),
      );
      final data = response.data;
      if (data is! Map) return const [];
      final list = data['data'];
      if (list is! List || list.isEmpty || list.first is! Map) {
        return const [];
      }
      final pin = Map<dynamic, dynamic>.from(list.first as Map);
      if (pin['is_video'] == true && pin['videos'] == null) {
        return const [];
      }
      return _resourcesFromPin(pin: pin, pageUrl: pageUrl, pinId: pinId);
    } on DioException {
      return const [];
    }
  }

  Future<List<DiscoveredResource>> _fetchOembed(
    String pinId,
    Uri pageUrl,
  ) async {
    try {
      final pinUrl = 'https://www.pinterest.com/pin/$pinId/';
      final endpoint = Uri.parse(
        'https://www.pinterest.com/oembed.json?url=${Uri.encodeQueryComponent(pinUrl)}',
      );
      final response = await _dio.get<dynamic>(
        endpoint.toString(),
        options: Options(
          responseType: ResponseType.json,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 400,
          headers: {
            ...SocialHttpHeaders.forPageFetch(
              pageUrl,
              SocialPlatform.pinterest,
            ),
            'Accept': 'application/json',
          },
        ),
      );
      final data = response.data;
      if (data is! Map) return const [];
      final thumb = data['thumbnail_url']?.toString();
      if (thumb == null || !thumb.startsWith('http')) return const [];
      final upgraded = PinterestUri.upgradeImageUrl(thumb);
      final title = data['title']?.toString();
      return [
        _buildResource(
          pageUrl: pageUrl,
          mediaUrl: upgraded,
          title: title,
          fallbackSlug: pinId,
          mimeType: mimeFromUrl(upgraded),
          thumbnailUrl: thumb,
        ),
      ];
    } on DioException {
      return const [];
    }
  }

  static Uri _pinPageUri(Uri resolved, String? pinId) {
    if (pinId != null) {
      return Uri.parse('https://www.pinterest.com/pin/$pinId/');
    }
    return resolved;
  }

  // ─── Pin parsing ─────────────────────────────────────────────────────

  static List<DiscoveredResource> _resourcesFromPin({
    required Map<dynamic, dynamic> pin,
    required Uri pageUrl,
    String? pinId,
  }) {
    final info = PinterestPinInfo.fromPin(pin);
    final id = info.pinId.isNotEmpty ? info.pinId : pinId;
    final title = info.title;
    final thumbnail = info.thumbnailUrl;

    final story = _parseStoryPages(
      pin: pin,
      pageUrl: pageUrl,
      title: title,
      pinId: id,
      thumbnailUrl: thumbnail,
    );
    if (story.isNotEmpty) return story;

    final videoList = _videoListFromPin(pin);
    final videoUrl = bestVideoUrl(videoList);
    if (videoUrl != null) {
      return [
        _buildResource(
          pageUrl: pageUrl,
          mediaUrl: videoUrl,
          title: title,
          fallbackSlug: id,
          mimeType: 'video/mp4',
          thumbnailUrl: thumbnail ?? bestImageUrl(_imagesFromPin(pin)),
        ),
      ];
    }

    // Video metadata without a progressive MP4 (HLS-only) is not downloadable.
    if (videoList != null && videoList.isNotEmpty) {
      return const [];
    }
    if (pin['is_video'] == true) {
      return const [];
    }

    final imageUrl = bestImageUrl(_imagesFromPin(pin));
    if (imageUrl != null) {
      return [
        _buildResource(
          pageUrl: pageUrl,
          mediaUrl: imageUrl,
          title: title,
          fallbackSlug: id,
          mimeType: mimeFromUrl(imageUrl),
          thumbnailUrl: thumbnail ?? imageUrl,
        ),
      ];
    }

    return const [];
  }

  static List<DiscoveredResource> _parseStoryPages({
    required Map<dynamic, dynamic> pin,
    required Uri pageUrl,
    required String? title,
    required String? pinId,
    required String? thumbnailUrl,
  }) {
    final story = pin['story_pin_data'];
    if (story is! Map) return const [];
    final pages = story['pages'];
    if (pages is! List || pages.isEmpty) return const [];

    final resources = <DiscoveredResource>[];
    final seen = <String>{};
    for (var i = 0; i < pages.length; i++) {
      final page = pages[i];
      if (page is! Map) continue;
      final parsed = _mediaFromStoryPage(page);
      if (parsed == null) continue;
      if (!seen.add(parsed.url)) continue;
      final indexLabel = '${i + 1}';
      resources.add(
        _buildResource(
          pageUrl: pageUrl,
          mediaUrl: parsed.url,
          title: title == null ? null : '${title}_$indexLabel',
          fallbackSlug: pinId == null ? indexLabel : '${pinId}_$indexLabel',
          mimeType: parsed.mimeType,
          thumbnailUrl: parsed.previewUrl ?? thumbnailUrl,
        ),
      );
    }
    return resources;
  }

  static _ParsedMedia? _mediaFromStoryPage(Map<dynamic, dynamic> page) {
    final fromPage = _mediaFromImageAndVideo(
      image: page['image'],
      video: page['video'] ?? page['videos'],
    );
    if (fromPage != null) return fromPage;

    final blocks = page['blocks'];
    if (blocks is List) {
      for (final block in blocks) {
        if (block is! Map) continue;
        final parsed = _mediaFromImageAndVideo(
          image: block['image'],
          video: block['video'] ?? block['videos'],
        );
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static _ParsedMedia? _mediaFromImageAndVideo({
    required Object? image,
    required Object? video,
  }) {
    if (video is Map) {
      final list = video['video_list'];
      if (list is Map) {
        final url = bestVideoUrl(list);
        if (url != null) {
          return _ParsedMedia(
            url: url,
            mimeType: 'video/mp4',
            previewUrl: bestImageUrl(
              image is Map && image['images'] is Map
                  ? image['images'] as Map
                  : null,
            ),
          );
        }
      }
    }
    Map<dynamic, dynamic>? images;
    if (image is Map) {
      final nested = image['images'];
      images = nested is Map ? nested : image;
    }
    final imageUrl = bestImageUrl(images);
    if (imageUrl != null) {
      return _ParsedMedia(
        url: imageUrl,
        mimeType: mimeFromUrl(imageUrl),
        previewUrl: imageUrl,
      );
    }
    return null;
  }

  static Map<dynamic, dynamic>? _imagesFromPin(Map<dynamic, dynamic> pin) {
    final images = pin['images'];
    if (images is Map) return images;
    return null;
  }

  static Map<dynamic, dynamic>? _videoListFromPin(Map<dynamic, dynamic> pin) {
    final videos = pin['videos'];
    if (videos is Map) {
      final list = videos['video_list'];
      if (list is Map) return list;
    }
    return null;
  }

  static bool _looksLikePin(Map node, {String? pinId}) {
    final hasImages = node['images'] is Map;
    final hasVideos = node['videos'] is Map;
    final hasStory = node['story_pin_data'] != null;
    if (!hasImages && !hasVideos && !hasStory) return false;

    if (pinId != null) {
      final id = node['id']?.toString();
      if (id != null && id.isNotEmpty && id != pinId) {
        if (!hasStory && node['pinner'] == null && node['grid_title'] == null) {
          return false;
        }
      }
    }

    return node.containsKey('id') ||
        node.containsKey('pinner') ||
        node.containsKey('grid_title') ||
        node.containsKey('closeup_description') ||
        hasStory;
  }

  static List<DiscoveredResource> _resourcesFromJsonLd({
    required Object node,
    required Uri pageUrl,
    String? pinId,
  }) {
    Map<dynamic, dynamic>? object;
    if (node is Map) {
      object = node;
    } else if (node is List) {
      for (final item in node) {
        if (item is Map) {
          object = item;
          break;
        }
      }
    }
    if (object == null) return const [];

    final type = object['@type']?.toString().toLowerCase() ?? '';
    final contentUrl = object['contentUrl']?.toString() ??
        object['contentURL']?.toString();
    final image = object['image'];
    String? imageUrl;
    if (image is String) {
      imageUrl = image;
    } else if (image is Map) {
      imageUrl = image['url']?.toString() ?? image['contentUrl']?.toString();
    } else if (image is List && image.isNotEmpty) {
      final first = image.first;
      if (first is String) imageUrl = first;
      if (first is Map) imageUrl = first['url']?.toString();
    }

    final title = object['headline']?.toString() ??
        object['name']?.toString() ??
        object['caption']?.toString();

    if (type.contains('video') &&
        contentUrl != null &&
        contentUrl.startsWith('http') &&
        !_isPlaylistUrl(contentUrl)) {
      return [
        _buildResource(
          pageUrl: pageUrl,
          mediaUrl: contentUrl,
          title: title,
          fallbackSlug: pinId,
          mimeType: 'video/mp4',
          thumbnailUrl: imageUrl,
        ),
      ];
    }

    final still = contentUrl ?? imageUrl;
    if (still != null && still.startsWith('http') && !_isPlaylistUrl(still)) {
      final upgraded = PinterestUri.upgradeImageUrl(still);
      return [
        _buildResource(
          pageUrl: pageUrl,
          mediaUrl: upgraded,
          title: title,
          fallbackSlug: pinId,
          mimeType: mimeFromUrl(upgraded),
          thumbnailUrl: imageUrl ?? upgraded,
        ),
      ];
    }
    return const [];
  }

  static List<DiscoveredResource> _extractFromOpenGraph({
    required String html,
    required Uri pageUrl,
    String? pinId,
  }) {
    final title = _metaContent(html, 'og:title');
    final thumbnail = _metaContent(html, 'og:image');

    final videoUrl = _metaContent(html, 'og:video') ??
        _metaContent(html, 'og:video:url') ??
        _metaContent(html, 'og:video:secure_url');
    if (videoUrl != null &&
        videoUrl.startsWith('http') &&
        !_isPlaylistUrl(videoUrl)) {
      return [
        _buildResource(
          pageUrl: pageUrl,
          mediaUrl: videoUrl,
          title: title,
          fallbackSlug: pinId,
          mimeType: _metaContent(html, 'og:video:type') ?? 'video/mp4',
          thumbnailUrl: thumbnail,
        ),
      ];
    }

    final imageUrl = _metaContent(html, 'og:image') ??
        _metaContent(html, 'og:image:url') ??
        _metaContent(html, 'og:image:secure_url');
    if (imageUrl != null && imageUrl.startsWith('http')) {
      final upgraded = PinterestUri.upgradeImageUrl(imageUrl);
      return [
        _buildResource(
          pageUrl: pageUrl,
          mediaUrl: upgraded,
          title: title,
          fallbackSlug: pinId,
          mimeType: mimeFromUrl(upgraded),
          thumbnailUrl: thumbnail ?? upgraded,
        ),
      ];
    }

    return const [];
  }

  static DiscoveredResource _directMediaResource(Uri mediaUrl, Uri pageUrl) {
    final upgraded = PinterestUri.isDirectMediaHost(mediaUrl.host) &&
            !mediaUrl.path.contains('/videos/')
        ? Uri.parse(PinterestUri.upgradeImageUrl(mediaUrl.toString()))
        : mediaUrl;
    final mime = mimeFromUrl(upgraded.toString());
    return _buildResource(
      pageUrl: pageUrl,
      mediaUrl: upgraded.toString(),
      title: null,
      fallbackSlug: PinterestUri.pinIdFromUri(pageUrl) ??
          (upgraded.pathSegments.isEmpty ? 'pin' : upgraded.pathSegments.last),
      mimeType: mime,
      thumbnailUrl: mime.startsWith('image/') ? upgraded.toString() : null,
    );
  }

  static DiscoveredResource _buildResource({
    required Uri pageUrl,
    required String mediaUrl,
    required String? title,
    required String? fallbackSlug,
    required String mimeType,
    required String? thumbnailUrl,
  }) {
    return DiscoveredResource(
      directUrl: mediaUrl,
      fileName: MediaExtractor.buildFileNameForSocial(
        pageUrl: pageUrl,
        platform: SocialPlatform.pinterest,
        mediaUrl: mediaUrl,
        title: title,
        fallbackSlug: fallbackSlug ?? _slugFromPath(pageUrl),
        mimeHint: mimeType,
      ),
      platform: SocialPlatform.pinterest.label,
      pageUrl: pageUrl.toString(),
      title: title,
      mimeType: mimeType,
      thumbnailUrl: thumbnailUrl,
      requestHeaders: SocialHttpHeaders.forMediaDownload(
        pageUrl: pageUrl,
        mediaUrl: mediaUrl,
        platform: SocialPlatform.pinterest,
      ),
      kind: DiscoveredResourceKind.fromMime(mimeType),
    );
  }

  static Object? _decodeEmbeddedJson(String html) {
    for (final id in [
      '__PWS_DATA__',
      '__PWS_INITIAL_PROPS__',
      '__INITIAL_STATE__',
    ]) {
      final raw = _scriptJson(html, id);
      if (raw == null) continue;
      try {
        return jsonDecode(raw);
      } on Object {
        continue;
      }
    }
    return null;
  }

  static Object? _decodeJsonLd(String html) {
    final pattern = RegExp(
      r'<script[^>]*type=["' "'" r']application/ld\+json["' "'" r'][^>]*>(.*?)</script>',
      dotAll: true,
      caseSensitive: false,
    );
    final match = pattern.firstMatch(html);
    if (match == null) return null;
    try {
      return jsonDecode(match.group(1)!);
    } on Object {
      return null;
    }
  }

  static String? _scriptJson(String html, String id) {
    final pattern = RegExp(
      '<script[^>]+id=["\']$id["\'][^>]*>(\\{.*?\\})</script>',
      dotAll: true,
      caseSensitive: false,
    );
    final match = pattern.firstMatch(html);
    return match?.group(1);
  }

  static String? _metaContent(String html, String property) {
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
    for (final pattern in patterns) {
      final match = pattern.firstMatch(html);
      if (match != null) return _decodeHtmlEntities(match.group(1)!);
    }
    return null;
  }

  static String? _linkRel(String html, String rel) {
    final pattern = RegExp(
      '<link[^>]+rel=["\']$rel["\'][^>]+href=["\']([^"\']+)["\']',
      caseSensitive: false,
    );
    return pattern.firstMatch(html)?.group(1);
  }

  static String _decodeHtmlEntities(String value) {
    return value
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }

  static bool _isPlaylistUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.m3u8') || lower.contains('.mpd');
  }

  static String? _slugFromPath(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty);
    return segments.isEmpty ? null : segments.last;
  }
}

class _ParsedMedia {
  const _ParsedMedia({
    required this.url,
    required this.mimeType,
    this.previewUrl,
  });

  final String url;
  final String mimeType;
  final String? previewUrl;
}

/// Structured Pinterest pin metadata extracted from public page JSON.
class PinterestPinInfo {
  const PinterestPinInfo({
    required this.pinId,
    this.title,
    this.description,
    this.author,
    this.authorId,
    this.pinUrl,
    this.thumbnailUrl,
    this.mediaType,
    this.width,
    this.height,
    this.durationSeconds,
    this.mimeType,
    this.isVideo = false,
    this.isIdeaPin = false,
    this.pageCount = 0,
  });

  final String pinId;
  final String? title;
  final String? description;
  final String? author;
  final String? authorId;
  final String? pinUrl;
  final String? thumbnailUrl;
  final String? mediaType;
  final int? width;
  final int? height;
  final double? durationSeconds;
  final String? mimeType;
  final bool isVideo;
  final bool isIdeaPin;
  final int pageCount;

  factory PinterestPinInfo.fromPin(Map<dynamic, dynamic> pin) {
    final images = pin['images'];
    final orig = images is Map ? images['orig'] : null;
    final origMap = orig is Map ? orig : null;
    final videos = pin['videos'];
    final videoList = videos is Map ? videos['video_list'] : null;
    final bestVideo = videoList is Map
        ? PinterestResolver.bestVideoUrl(videoList)
        : null;
    Map<dynamic, dynamic>? bestVideoMeta;
    if (videoList is Map && bestVideo != null) {
      for (final value in videoList.values) {
        if (value is Map && value['url'] == bestVideo) {
          bestVideoMeta = value;
          break;
        }
      }
    }

    final pinner = pin['pinner'] ?? pin['native_creator'];
    String? author;
    String? authorId;
    if (pinner is Map) {
      author = pinner['full_name']?.toString() ??
          pinner['username']?.toString();
      authorId = pinner['id']?.toString();
    }

    final story = pin['story_pin_data'];
    final pages = story is Map ? story['pages'] : null;
    final pageCount = pages is List ? pages.length : 0;
    final isIdea = story != null;

    final thumb = origMap?['url']?.toString() ??
        (images is Map
            ? PinterestResolver.bestImageUrl(images)
            : null);

    final title = pin['grid_title']?.toString() ??
        pin['title']?.toString() ??
        pin['closeup_unified_title']?.toString();
    final description = pin['description']?.toString() ??
        pin['closeup_unified_description']?.toString();

    final isVideo = bestVideo != null || pin['is_video'] == true;
    final imageUrl = thumb;
    final mediaUrl = bestVideo ?? imageUrl;

    return PinterestPinInfo(
      pinId: pin['id']?.toString() ?? '',
      title: (title != null && title.isNotEmpty) ? title : null,
      description:
          (description != null && description.isNotEmpty) ? description : null,
      author: author,
      authorId: authorId,
      pinUrl: pin['link']?.toString() ??
          (pin['id'] != null
              ? 'https://www.pinterest.com/pin/${pin['id']}/'
              : null),
      thumbnailUrl: thumb,
      mediaType: isIdea
          ? 'idea_pin'
          : (isVideo ? 'video' : 'image'),
      width: bestVideoMeta?['width'] is num
          ? (bestVideoMeta!['width'] as num).toInt()
          : origMap?['width'] is num
              ? (origMap!['width'] as num).toInt()
              : null,
      height: bestVideoMeta?['height'] is num
          ? (bestVideoMeta!['height'] as num).toInt()
          : origMap?['height'] is num
              ? (origMap!['height'] as num).toInt()
              : null,
      durationSeconds: bestVideoMeta?['duration'] is num
          ? (bestVideoMeta!['duration'] as num).toDouble()
          : null,
      mimeType: mediaUrl == null
          ? null
          : PinterestResolver.mimeFromUrl(mediaUrl),
      isVideo: isVideo,
      isIdeaPin: isIdea,
      pageCount: pageCount,
    );
  }
}
