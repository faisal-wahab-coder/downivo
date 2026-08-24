import 'dart:convert';

import 'package:dio/dio.dart';

import 'media_extractor.dart';
import 'models/discovered_resource.dart';
import 'social_http_headers.dart';
import 'social_platform.dart';
import 'social_session_utils.dart';
import 'social_url_resolver.dart';
import 'social_url_utils.dart';

/// Resolves public LinkedIn URLs to direct media CDN links.
///
/// Supports:
/// - Public image posts (highest legitimately exposed DMS image)
/// - Public video posts (progressive MP4 only; HLS is not downloaded)
/// - Multi-image posts (order preserved, duplicates collapsed)
/// - Document/carousel posts when a PDF or page images are exposed
/// - Share / `lnkd.in` / embed / mobile URLs (normalized to activity identity)
/// - Direct `media.licdn.com` / `dms.licdn.com` URLs
///
/// Profiles, company pages, articles, home, and feed are classified and are
/// **not** bulk-downloaded. Login walls, private posts, and DRM/HLS-only
/// video are not bypassed.
class LinkedInResolver {
  LinkedInResolver({Dio? dio})
      : _dio = dio ?? Dio(),
        _urlResolver = SocialUrlResolver(dio: dio);

  final Dio _dio;
  final SocialUrlResolver _urlResolver;

  Future<DiscoveredResource?> discover(Uri pageUrl) async {
    final all = await discoverAll(pageUrl);
    return all.isEmpty ? null : all.first;
  }

  Future<List<DiscoveredResource>> discoverAll(Uri pageUrl) async {
    var resolved = LinkedInUri.normalize(pageUrl);
    final type = LinkedInUri.classifyUrl(pageUrl);

    if (!LinkedInUri.isDownloadable(pageUrl) &&
        type != LinkedInContentType.shortUrl) {
      return const [];
    }

    if (type == LinkedInContentType.directMedia ||
        LinkedInUri.classifyUrl(resolved) == LinkedInContentType.directMedia) {
      final mediaUri = type == LinkedInContentType.directMedia
          ? pageUrl
          : resolved;
      return [_directMediaResource(mediaUri, pageUrl)];
    }

    if (type == LinkedInContentType.shortUrl) {
      resolved = LinkedInUri.normalize(
        await _urlResolver.resolveRedirects(pageUrl),
      );
      if (LinkedInUri.classifyUrl(resolved) == LinkedInContentType.shortUrl) {
        return const [];
      }
      if (!LinkedInUri.isDownloadable(resolved)) return const [];
      if (LinkedInUri.classifyUrl(resolved) ==
          LinkedInContentType.directMedia) {
        return [_directMediaResource(resolved, pageUrl)];
      }
    }

    final contentId = LinkedInUri.contentIdFromUri(resolved) ??
        LinkedInUri.contentIdFromUri(pageUrl);

    for (final target in LinkedInUri.fetchTargets(resolved)) {
      final html = await _fetchHtml(target);
      if (html == null || html.isEmpty) continue;

      final resources = parseHtmlResources(
        html: html,
        pageUrl: pageUrl,
        contentId: contentId,
      );
      if (resources.isNotEmpty) return resources;
    }

    return const [];
  }

  static LinkedInContentType classifyUrl(Uri uri) =>
      LinkedInUri.classifyUrl(uri);

  /// Parses downloadable media from public LinkedIn HTML. Exposed for tests.
  static List<DiscoveredResource> parseHtmlResources({
    required String html,
    required Uri pageUrl,
    String? contentId,
  }) {
    if (html.trim().isEmpty) return const [];

    final info = parsePostInfo(html: html, pageUrl: pageUrl, contentId: contentId);
    final headers = _mediaHeaders(pageUrl);

    final documents = _extractDocumentUrls(html);
    if (documents.isNotEmpty) {
      return _buildResources(
        urls: documents,
        pageUrl: pageUrl,
        info: info,
        headers: headers,
        defaultMime: 'application/pdf',
      );
    }

    final videos = parseProgressiveStreams(html);
    if (videos.isNotEmpty) {
      final best = _bestVideo(videos);
      return [
        _resourceForUrl(
          url: best.url,
          pageUrl: pageUrl,
          info: info.copyWith(
            width: best.width,
            height: best.height,
            mimeType: 'video/mp4',
            isVideo: true,
          ),
          headers: headers,
          mimeHint: 'video/mp4',
          index: 0,
          total: 1,
        ),
      ];
    }

    if (_looksLikeVideoWithoutFile(html)) {
      return const [];
    }

    final images = _extractImageUrls(html);
    if (images.isNotEmpty) {
      return _buildResources(
        urls: images,
        pageUrl: pageUrl,
        info: info,
        headers: headers,
        defaultMime: 'image/jpeg',
      );
    }

    return const [];
  }

  /// Progressive MP4 renditions actually present in HTML. Does not invent
  /// qualities or parse HLS as a downloadable file.
  static List<LinkedInVideoQuality> parseProgressiveStreams(String html) {
    final qualities = <LinkedInVideoQuality>[];

    final marker = '"progressiveStreams"';
    var searchFrom = 0;
    while (true) {
      final start = html.indexOf(marker, searchFrom);
      if (start < 0) break;
      final bracket = html.indexOf('[', start);
      if (bracket < 0) break;
      final array = _balancedJsonArray(html, bracket);
      if (array != null) {
        qualities.addAll(_qualitiesFromJsonArray(array));
      }
      searchFrom = bracket + 1;
    }

    for (final field in [
      'downloadUrl',
      'contentUrl',
      'source',
      'fileUrl',
    ]) {
      final pattern = RegExp(
        '"$field"\\s*:\\s*"((?:\\\\.|[^"\\\\])*)"',
        caseSensitive: false,
      );
      for (final match in pattern.allMatches(html)) {
        final url = SocialSessionUtils.decodeEmbeddedUrl(match.group(1)!);
        if (_isDirectVideoUrl(url)) {
          qualities.add(
            LinkedInVideoQuality(
              url: url,
              height: _inferHeightFromUrl(url),
            ),
          );
        }
      }
    }

    qualities.addAll(
      _cdnVideoUrls(html).map(
        (url) => LinkedInVideoQuality(
          url: url,
          height: _inferHeightFromUrl(url),
        ),
      ),
    );
    qualities.addAll(_jsonLdVideos(html));

    return _dedupeVideos(qualities);
  }

  static LinkedInPostInfo parsePostInfo({
    required String html,
    required Uri pageUrl,
    String? contentId,
  }) {
    final title = _metaContent(html, 'og:title') ??
        _metaContent(html, 'twitter:title');
    final description = _metaContent(html, 'og:description') ??
        _metaContent(html, 'twitter:description');
    final thumbnail = _bestThumbnail(html);
    final author = _jsonString(html, 'authorName') ??
        _jsonString(html, 'author') ??
        _metaContent(html, 'author') ??
        LinkedInUri.authorFromUri(pageUrl);
    final authorUrl = LinkedInUri.authorUrlFromUri(pageUrl);
    final company = LinkedInUri.companyFromUri(pageUrl);
    final duration = _durationFromHtml(html);
    final id = contentId ??
        LinkedInUri.contentIdFromUri(pageUrl) ??
        _jsonString(html, 'activityUrn') ??
        _urnIdFromHtml(html);

    return LinkedInPostInfo(
      contentId: id,
      title: _cleanTitle(title),
      description: description,
      author: author,
      authorUrl: authorUrl,
      company: company,
      thumbnailUrl: thumbnail,
      durationSeconds: duration,
    );
  }

  static String mimeFromUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.m3u8') || lower.contains('.mpd')) {
      return 'application/vnd.apple.mpegurl';
    }
    if (lower.contains('.mp4') ||
        _hasProgressiveMp4Path(lower) ||
        lower.contains('/dms/video/')) {
      return 'video/mp4';
    }
    if (lower.contains('.webm')) return 'video/webm';
    if (lower.contains('.pdf') || lower.contains('/document/')) {
      return 'application/pdf';
    }
    if (lower.contains('.png')) return 'image/png';
    if (lower.contains('.webp')) return 'image/webp';
    if (lower.contains('.gif')) return 'image/gif';
    if (lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('/image/')) {
      return 'image/jpeg';
    }
    return 'application/octet-stream';
  }

  static bool isDirectMediaUrl(String url) {
    if (!url.startsWith('http')) return false;
    if (_isPlaylist(url)) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    if (host.contains('static.licdn.com')) return false;
    return LinkedInUri.isDirectMediaHost(host) &&
        (_isDirectVideoUrl(url) ||
            _isDirectImageUrl(url) ||
            _isDirectDocumentUrl(url));
  }

  // ─── Fetch ────────────────────────────────────────────────────────────

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
            SocialPlatform.linkedin,
          ),
        ),
      );
      return response.data;
    } on DioException {
      return null;
    }
  }

  static DiscoveredResource _directMediaResource(Uri mediaUri, Uri pageUrl) {
    final url = mediaUri.toString();
    final mime = mimeFromUrl(url);
    return DiscoveredResource(
      directUrl: url,
      fileName: MediaExtractor.buildFileNameForSocial(
        pageUrl: pageUrl,
        platform: SocialPlatform.linkedin,
        mediaUrl: url,
        fallbackSlug: LinkedInUri.contentIdFromUri(pageUrl) ?? 'linkedin_media',
        mimeHint: mime,
      ),
      platform: SocialPlatform.linkedin.label,
      pageUrl: pageUrl.toString(),
      mimeType: mime,
      thumbnailUrl: mime.startsWith('image/') ? url : null,
      requestHeaders: _mediaHeaders(pageUrl),
    );
  }

  static Map<String, String> _mediaHeaders(Uri pageUrl) {
    return SocialHttpHeaders.forMediaDownload(
      pageUrl: pageUrl,
      mediaUrl: 'https://media.licdn.com/',
      platform: SocialPlatform.linkedin,
    );
  }

  // ─── Resource builders ────────────────────────────────────────────────

  static List<DiscoveredResource> _buildResources({
    required List<String> urls,
    required Uri pageUrl,
    required LinkedInPostInfo info,
    required Map<String, String> headers,
    required String defaultMime,
  }) {
    final results = <DiscoveredResource>[];
    for (var i = 0; i < urls.length; i++) {
      results.add(
        _resourceForUrl(
          url: urls[i],
          pageUrl: pageUrl,
          info: info,
          headers: headers,
          mimeHint: mimeFromUrl(urls[i]) == 'application/octet-stream'
              ? defaultMime
              : mimeFromUrl(urls[i]),
          index: i,
          total: urls.length,
        ),
      );
    }
    return results;
  }

  static DiscoveredResource _resourceForUrl({
    required String url,
    required Uri pageUrl,
    required LinkedInPostInfo info,
    required Map<String, String> headers,
    required String mimeHint,
    required int index,
    required int total,
  }) {
    final slug = info.contentId ??
        LinkedInUri.contentIdFromUri(pageUrl) ??
        'linkedin';
    final indexedSlug = total > 1 ? '${slug}_${index + 1}' : slug;
    final titleForName = total > 1
        ? '${info.title ?? slug} ${index + 1}'
        : info.title;
    return DiscoveredResource(
      directUrl: url,
      fileName: MediaExtractor.buildFileNameForSocial(
        pageUrl: pageUrl,
        platform: SocialPlatform.linkedin,
        mediaUrl: url,
        title: titleForName,
        fallbackSlug: indexedSlug,
        mimeHint: mimeHint,
      ),
      platform: SocialPlatform.linkedin.label,
      pageUrl: pageUrl.toString(),
      title: info.title,
      mimeType: mimeHint,
      thumbnailUrl: info.thumbnailUrl ??
          (mimeHint.startsWith('image/') ? url : null),
      requestHeaders: headers,
      author: info.author,
      durationSeconds: info.durationSeconds,
      width: info.width,
      height: info.height,
      kind: DiscoveredResourceKind.fromMime(
        mimeHint,
        carousel: total > 1,
      ),
    );
  }

  // ─── Video ────────────────────────────────────────────────────────────

  static List<LinkedInVideoQuality> _qualitiesFromJsonArray(String raw) {
    try {
      final decoded = jsonDecode(_sanitizeJsonArray(raw));
      if (decoded is! List) return const [];
      final out = <LinkedInVideoQuality>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final height = _asInt(item['height']);
        final width = _asInt(item['width']);
        final bitRate = _asInt(item['bitRate'] ?? item['bitrate']);
        final urls = <String>[];
        final locations = item['streamingLocations'];
        if (locations is List) {
          for (final loc in locations) {
            if (loc is Map && loc['url'] is String) {
              urls.add(loc['url'] as String);
            }
          }
        }
        if (item['url'] is String) urls.add(item['url'] as String);
        for (final url in urls) {
          final decodedUrl = SocialSessionUtils.decodeEmbeddedUrl(url);
          if (_isDirectVideoUrl(decodedUrl)) {
            out.add(
              LinkedInVideoQuality(
                url: decodedUrl,
                width: width,
                height: height ?? _inferHeightFromUrl(decodedUrl),
                bitRate: bitRate,
              ),
            );
          }
        }
      }
      return out;
    } on Object {
      return const [];
    }
  }

  static String? _balancedJsonArray(String html, int start) {
    if (start < 0 || start >= html.length || html[start] != '[') return null;
    var depth = 0;
    for (var i = start; i < html.length; i++) {
      final char = html[i];
      if (char == '[') depth++;
      if (char == ']') {
        depth--;
        if (depth == 0) return html.substring(start, i + 1);
      }
    }
    return null;
  }

  static int? _inferHeightFromUrl(String url) {
    final match = RegExp(r'(\d{3,4})p', caseSensitive: false).firstMatch(url);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  static String _sanitizeJsonArray(String raw) {
    var value = raw;
    final end = value.lastIndexOf(']');
    if (end >= 0) value = value.substring(0, end + 1);
    return value.replaceAll(r'\/', '/');
  }

  static LinkedInVideoQuality _bestVideo(List<LinkedInVideoQuality> videos) {
    final ranked = [...videos]..sort((a, b) {
        final ah = a.height ?? 0;
        final bh = b.height ?? 0;
        if (ah != bh) return bh.compareTo(ah);
        return (b.bitRate ?? 0).compareTo(a.bitRate ?? 0);
      });
    return ranked.first;
  }

  static List<LinkedInVideoQuality> _dedupeVideos(
    List<LinkedInVideoQuality> input,
  ) {
    final seen = <String>{};
    final out = <LinkedInVideoQuality>[];
    for (final item in input) {
      if (seen.add(item.url)) out.add(item);
    }
    return out;
  }

  static List<String> _cdnVideoUrls(String html) {
    final urls = <String>[];
    final pattern = RegExp(
      r'https://(?:media(?:-exp\d+)?|dms)\.licdn\.com/[^\s"\\<>]+',
      caseSensitive: false,
    );
    for (final match in pattern.allMatches(html)) {
      final url = _normalizeCdnUrl(match.group(0)!);
      if (url != null && _isDirectVideoUrl(url) && !urls.contains(url)) {
        urls.add(url);
      }
    }
    return urls;
  }

  /// LinkedIn HTML often terminates JSON strings with `&quot;` instead of `"`.
  static String? _normalizeCdnUrl(String raw) {
    var url = raw.replaceAll(r'\/', '/').replaceAll(r'\u002F', '/');
    final quot = url.indexOf('&quot;');
    if (quot >= 0) url = url.substring(0, quot);
    url = url.split('"').first;
    url = SocialSessionUtils.decodeEmbeddedUrl(url.replaceAll('&amp;', '&'));
    url = url.replaceAll(RegExp(r'[,;\\]+$'), '');
    if (!url.startsWith('http')) return null;
    return url;
  }

  static List<LinkedInVideoQuality> _jsonLdVideos(String html) {
    final out = <LinkedInVideoQuality>[];
    for (final block in _jsonLdBlocks(html)) {
      if (!_isType(block, 'VideoObject')) continue;
      final contentUrl = block['contentUrl'] ?? block['url'];
      if (contentUrl is! String || !_isDirectVideoUrl(contentUrl)) continue;
      out.add(
        LinkedInVideoQuality(
          url: SocialSessionUtils.decodeEmbeddedUrl(contentUrl),
          width: _asInt(block['width']),
          height: _asInt(block['height']),
        ),
      );
    }
    return out;
  }

  static bool _looksLikeVideoWithoutFile(String html) {
    if (parseProgressiveStreams(html).isNotEmpty) return false;

    final ogType = _metaContent(html, 'og:video:type');
    if (ogType != null && ogType.toLowerCase().contains('text/html')) {
      return true;
    }
    final ogVideo = _metaContent(html, 'og:video') ??
        _metaContent(html, 'og:video:url') ??
        _metaContent(html, 'og:video:secure_url');
    if (ogVideo != null &&
        ogVideo.contains('linkedin.com') &&
        !_isDirectVideoUrl(ogVideo)) {
      return true;
    }
    if (html.contains('progressiveStreams') && html.contains('.m3u8')) {
      return true;
    }

    final ogImage = (_metaContent(html, 'og:image') ?? '').toLowerCase();
    final lower = html.toLowerCase();
    if (ogImage.contains('playlist/vid') ||
        ogImage.contains('thumbnail-with-play-button') ||
        lower.contains('thumbnail-with-play-button-overlay') ||
        lower.contains('/videocover')) {
      return true;
    }
    return false;
  }

  // ─── Images ───────────────────────────────────────────────────────────

  static List<String> _extractImageUrls(String html) {
    final candidates = <_ScoredImage>[];

    for (final block in _jsonLdBlocks(html)) {
      if (_isType(block, 'ImageObject') || _isType(block, 'SocialMediaPosting')) {
        final url = block['contentUrl'] ?? block['url'] ?? block['image'];
        if (url is String) {
          _offerImage(candidates, url);
        } else if (url is List) {
          for (final item in url) {
            if (item is String) _offerImage(candidates, item);
            if (item is Map && item['url'] is String) {
              _offerImage(candidates, item['url'] as String);
            }
          }
        }
      }
    }

    for (final field in [
      'rootUrl',
      'originalUrl',
      'downloadUrl',
      'contentUrl',
    ]) {
      final pattern = RegExp(
        '"$field"\\s*:\\s*"((?:\\\\.|[^"\\\\])*)"',
        caseSensitive: false,
      );
      for (final match in pattern.allMatches(html)) {
        _offerImage(
          candidates,
          SocialSessionUtils.decodeEmbeddedUrl(match.group(1)!),
        );
      }
    }

    final cdn = RegExp(
      r'https://(?:media(?:-exp\d+)?|dms)\.licdn\.com/dms/image/[^\s"\\<>]+',
      caseSensitive: false,
    );
    for (final match in cdn.allMatches(html)) {
      final url = _normalizeCdnUrl(match.group(0)!);
      if (url != null) _offerImage(candidates, url);
    }

    for (final property in ['og:image', 'og:image:url', 'og:image:secure_url']) {
      final og = _metaContent(html, property);
      if (og != null) _offerImage(candidates, og);
    }

    return _collapseImages(candidates);
  }

  static void _offerImage(List<_ScoredImage> out, String raw) {
    final url = SocialSessionUtils.decodeEmbeddedUrl(raw);
    if (!_isDirectImageUrl(url)) return;
    out.add(
      _ScoredImage(
        url: url,
        group: _imageGroupKey(url),
        score: _imageScore(url),
      ),
    );
  }

  static List<String> _collapseImages(List<_ScoredImage> input) {
    final best = <String, _ScoredImage>{};
    final order = <String>[];
    for (final item in input) {
      final existing = best[item.group];
      if (existing == null) {
        best[item.group] = item;
        order.add(item.group);
      } else if (item.score > existing.score) {
        best[item.group] = item;
      }
    }
    return [
      for (final key in order) best[key]!.url,
    ];
  }

  static String _imageGroupKey(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return uri.path.replaceAll(RegExp(r'shrink_\d+_\d+'), 'shrink');
  }

  static int _imageScore(String url) {
    final shrink = RegExp(r'shrink_(\d+)_(\d+)').firstMatch(url);
    if (shrink != null) {
      return int.parse(shrink.group(1)!) * int.parse(shrink.group(2)!);
    }
    if (url.contains('original') || url.contains('/sync/')) return 1 << 30;
    return 1;
  }

  static String? _bestThumbnail(String html) {
    final images = _extractImageUrls(html);
    if (images.isNotEmpty) return images.first;
    final og = _metaContent(html, 'og:image');
    if (og != null && _isDirectImageUrl(og)) return og;
    return null;
  }

  // ─── Documents ────────────────────────────────────────────────────────

  static List<String> _extractDocumentUrls(String html) {
    final urls = <String>[];
    for (final field in [
      'transcribedDocumentUrl',
      'documentUrl',
      'downloadUrl',
    ]) {
      final pattern = RegExp(
        '"$field"\\s*:\\s*"((?:\\\\.|[^"\\\\])*)"',
        caseSensitive: false,
      );
      for (final match in pattern.allMatches(html)) {
        final url = SocialSessionUtils.decodeEmbeddedUrl(match.group(1)!);
        if (_isDirectDocumentUrl(url) && !urls.contains(url)) urls.add(url);
      }
    }

    final pdf = RegExp(
      r'https://(?:media(?:-exp\d+)?|dms)\.licdn\.com/[^\s"\\<>]+\.pdf[^\s"\\<>]*',
      caseSensitive: false,
    );
    for (final match in pdf.allMatches(html)) {
      final url = SocialSessionUtils.decodeEmbeddedUrl(
        match.group(0)!.replaceAll(r'\/', '/').replaceAll('&amp;', '&'),
      );
      if (_isDirectDocumentUrl(url) && !urls.contains(url)) urls.add(url);
    }
    return urls;
  }

  // ─── URL predicates ───────────────────────────────────────────────────

  static bool _isPlaylist(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.m3u8') || lower.contains('.mpd');
  }

  static bool _isDirectVideoUrl(String url) {
    if (!url.startsWith('http')) return false;
    if (_isPlaylist(url)) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    if (!LinkedInUri.isDirectMediaHost(host)) return false;
    final lower = url.toLowerCase();
    if (host.contains('linkedin.com')) return false;
    if (lower.contains('thumbnail')) return false;
    if (lower.contains('videocover')) return false;
    // LinkedIn progressive files use a path segment like `mp4-720p-30fp-crf28`
    // with no `.mp4` extension.
    if (_hasProgressiveMp4Path(lower)) return true;
    if (lower.contains('.mp4')) return true;
    if (lower.contains('/dms/video/') && !lower.contains('playlist')) {
      return true;
    }
    return false;
  }

  static bool _hasProgressiveMp4Path(String lowerUrl) {
    return RegExp(r'(?:^|/)mp4-\d{3,4}p(?:-|/|\?|$)').hasMatch(lowerUrl);
  }

  static bool _isDirectImageUrl(String url) {
    if (!url.startsWith('http')) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    if (host.contains('static.licdn.com')) return false;
    if (!LinkedInUri.isDirectMediaHost(host)) return false;
    final path = uri.path.toLowerCase();
    if (path.contains('profile-displayphoto')) return false;
    if (path.contains('profile-displaybackground')) return false;
    if (path.contains('company-logo')) return false;
    if (path.contains('comment-image')) return false;
    if (path.contains('article-cover')) return false;
    if (path.contains('article_cover')) return false;
    if (path.contains('thumbnail-with-play-button')) return false;
    if (path.contains('videocover')) return false;
    if (path.contains('/sc/h/')) return false;
    return path.contains('/dms/image/') ||
        path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.webp') ||
        path.endsWith('.gif');
  }

  static bool _isDirectDocumentUrl(String url) {
    if (!url.startsWith('http')) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (!LinkedInUri.isDirectMediaHost(uri.host)) return false;
    final lower = url.toLowerCase();
    return lower.contains('.pdf') || lower.contains('/dms/document/');
  }

  // ─── HTML helpers ─────────────────────────────────────────────────────

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
      if (match != null) {
        return _decodeHtml(match.group(1)!);
      }
    }
    return null;
  }

  static String? _jsonString(String html, String field) {
    final pattern = RegExp(
      '"$field"\\s*:\\s*"((?:\\\\.|[^"\\\\])*)"',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(html);
    if (match == null) return null;
    final value = SocialSessionUtils.decodeEmbeddedUrl(match.group(1)!).trim();
    return value.isEmpty ? null : value;
  }

  static String? _urnIdFromHtml(String html) {
    final match = RegExp(
      r'urn:li:(activity|ugcPost|share):(\d{10,})',
    ).firstMatch(html);
    return match?.group(2);
  }

  static double? _durationFromHtml(String html) {
    final seconds = _jsonNumber(html, 'duration');
    if (seconds != null) {
      return seconds > 1000 ? seconds / 1000.0 : seconds;
    }
    final millis = _jsonNumber(html, 'durationInMilliseconds');
    if (millis != null) return millis / 1000.0;
    final iso = _jsonString(html, 'duration') ??
        _metaContent(html, 'og:video:duration');
    if (iso != null) {
      final parsed = _parseIsoDuration(iso) ?? double.tryParse(iso);
      if (parsed != null) return parsed;
    }
    for (final block in _jsonLdBlocks(html)) {
      if (_isType(block, 'VideoObject') && block['duration'] is String) {
        final parsed = _parseIsoDuration(block['duration'] as String);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static double? _jsonNumber(String html, String field) {
    final pattern = RegExp('"$field"\\s*:\\s*([0-9]+(?:\\.[0-9]+)?)');
    final match = pattern.firstMatch(html);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }

  static double? _parseIsoDuration(String raw) {
    final match = RegExp(
      r'^PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+(?:\.\d+)?)S)?$',
      caseSensitive: false,
    ).firstMatch(raw.trim());
    if (match == null) return null;
    final hours = int.tryParse(match.group(1) ?? '') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '') ?? 0;
    final seconds = double.tryParse(match.group(3) ?? '') ?? 0;
    return hours * 3600 + minutes * 60 + seconds;
  }

  static List<Map<String, dynamic>> _jsonLdBlocks(String html) {
    final blocks = <Map<String, dynamic>>[];
    final pattern = RegExp(
      r'<script[^>]+type=["'']application/ld\+json["''][^>]*>(.*?)</script>',
      dotAll: true,
      caseSensitive: false,
    );
    for (final match in pattern.allMatches(html)) {
      final raw = match.group(1)?.trim();
      if (raw == null || raw.isEmpty) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          blocks.add(decoded);
        } else if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) blocks.add(item);
          }
        }
      } on Object {
        continue;
      }
    }
    return blocks;
  }

  static bool _isType(Map<String, dynamic> json, String type) {
    final value = json['@type'];
    if (value is String) return value.toLowerCase() == type.toLowerCase();
    if (value is List) {
      return value.any(
        (item) =>
            item is String && item.toLowerCase() == type.toLowerCase(),
      );
    }
    return false;
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String? _cleanTitle(String? title) {
    if (title == null) return null;
    var cleaned = title.trim();
    if (cleaned.isEmpty) return null;
    cleaned = cleaned.replaceAll(RegExp(r'\s+\|\s+LinkedIn$'), '');
    return cleaned.isEmpty ? null : cleaned;
  }

  static String _decodeHtml(String value) {
    return value
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }
}

class LinkedInVideoQuality {
  const LinkedInVideoQuality({
    required this.url,
    this.width,
    this.height,
    this.bitRate,
  });

  final String url;
  final int? width;
  final int? height;
  final int? bitRate;
}

class LinkedInPostInfo {
  const LinkedInPostInfo({
    this.contentId,
    this.title,
    this.description,
    this.author,
    this.authorUrl,
    this.company,
    this.thumbnailUrl,
    this.durationSeconds,
    this.width,
    this.height,
    this.mimeType,
    this.isVideo = false,
  });

  final String? contentId;
  final String? title;
  final String? description;
  final String? author;
  final String? authorUrl;
  final String? company;
  final String? thumbnailUrl;
  final double? durationSeconds;
  final int? width;
  final int? height;
  final String? mimeType;
  final bool isVideo;

  LinkedInPostInfo copyWith({
    String? contentId,
    String? title,
    String? description,
    String? author,
    String? authorUrl,
    String? company,
    String? thumbnailUrl,
    double? durationSeconds,
    int? width,
    int? height,
    String? mimeType,
    bool? isVideo,
  }) {
    return LinkedInPostInfo(
      contentId: contentId ?? this.contentId,
      title: title ?? this.title,
      description: description ?? this.description,
      author: author ?? this.author,
      authorUrl: authorUrl ?? this.authorUrl,
      company: company ?? this.company,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      width: width ?? this.width,
      height: height ?? this.height,
      mimeType: mimeType ?? this.mimeType,
      isVideo: isVideo ?? this.isVideo,
    );
  }
}

class _ScoredImage {
  const _ScoredImage({
    required this.url,
    required this.group,
    required this.score,
  });

  final String url;
  final String group;
  final int score;
}
