import 'dart:convert';

import 'package:dio/dio.dart';

import '../filename_resolver.dart';
import 'models/discovered_resource.dart';
import 'social_http_headers.dart';
import 'social_platform.dart';
import 'social_url_utils.dart';

/// Resolves public Vimeo video URLs to progressive MP4 playback files.
///
/// Uses the same player config the official embed player loads. Does not
/// bypass passwords, private videos, DRM, or paywalled On Demand content.
/// HLS/DASH-only sources are not downloaded (no converter in this engine).
class VimeoResolver {
  VimeoResolver({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<DiscoveredResource?> discover(Uri pageUrl) async {
    final all = await discoverAll(pageUrl);
    return all.isEmpty ? null : all.first;
  }

  /// Returns the best progressive MP4 for a Vimeo video URL.
  /// Quality variants are not treated as a carousel — see [parseQualities].
  Future<List<DiscoveredResource>> discoverAll(Uri pageUrl) async {
    final normalized = VimeoUri.normalize(pageUrl);
    if (!VimeoUri.isDownloadable(normalized) &&
        !VimeoUri.isDownloadable(pageUrl)) {
      return const [];
    }

    final videoId =
        VimeoUri.videoIdFromUri(normalized) ?? VimeoUri.videoIdFromUri(pageUrl);
    if (videoId == null) return const [];

    final hash = VimeoUri.privacyHashFromUri(pageUrl) ??
        VimeoUri.privacyHashFromUri(normalized);

    final config = await _fetchPlayerConfig(videoId, hash);
    if (config != null) {
      final info = parseVideoInfo(config);
      if (info != null) {
        final resource = resourceFromInfo(pageUrl: pageUrl, info: info);
        if (resource != null) return [resource];
      }
      if (restrictionFromConfig(config) != VimeoRestriction.none) {
        return const [];
      }
    }

    final html = await _fetchHtml(_playerPageUri(videoId, hash));
    if (html != null && html.isNotEmpty) {
      final fromHtml = parseConfigFromHtml(html);
      if (fromHtml != null) {
        final info = parseVideoInfo(fromHtml);
        if (info != null) {
          final resource = resourceFromInfo(pageUrl: pageUrl, info: info);
          if (resource != null) return [resource];
        }
      }
    }

    return const [];
  }

  static VimeoContentType classifyUrl(Uri uri) => VimeoUri.classifyUrl(uri);

  static String? videoIdFromUri(Uri uri) => VimeoUri.videoIdFromUri(uri);

  /// Parses player-config JSON into structured metadata. Null when restricted
  /// or when no progressive MP4 is present.
  static VimeoVideoInfo? parseVideoInfo(Map<dynamic, dynamic> config) {
    if (restrictionFromConfig(config) != VimeoRestriction.none) return null;

    final video = _asMap(config['video']);
    if (video == null) return null;

    final videoId = video['id']?.toString() ?? video['clip_id']?.toString();
    if (videoId == null || videoId.isEmpty) return null;

    final qualities = parseQualities(config);
    final best = bestQuality(qualities);
    if (best == null) return null;

    final owner = _asMap(video['owner']);
    final title = _nonEmpty(video['title']?.toString());
    final description = _nonEmpty(
      video['description']?.toString() ?? config['description']?.toString(),
    );

    return VimeoVideoInfo(
      videoId: videoId,
      title: title,
      description: description,
      author: _nonEmpty(
        owner?['name']?.toString() ?? owner?['display_name']?.toString(),
      ),
      authorId: owner?['id']?.toString(),
      videoUrl: _nonEmpty(video['url']?.toString()) ??
          _nonEmpty(video['share_url']?.toString()) ??
          'https://vimeo.com/$videoId',
      durationSeconds: _asDouble(video['duration']),
      width: best.width ?? _asInt(video['width']),
      height: best.height ?? _asInt(video['height']),
      frameRate: best.frameRate,
      thumbnailUrl: bestThumbnailUrl(video),
      createdAt: _nonEmpty(
        video['uploaded_on']?.toString() ??
            video['created_time']?.toString() ??
            video['release_time']?.toString(),
      ),
      mimeType: best.mimeType,
      qualities: qualities,
      hasAudio: hasMuxedAudio(config, video),
      selectedQuality: best,
    );
  }

  /// Progressive MP4 renditions only. HLS/DASH URLs are omitted.
  static List<VimeoQuality> parseQualities(Map<dynamic, dynamic> config) {
    final files = _asMap(_asMap(config['request'])?['files']);
    final progressive = files?['progressive'];
    if (progressive is! List) return const [];

    final qualities = <VimeoQuality>[];
    final seen = <String>{};
    for (final item in progressive) {
      final map = _asMap(item);
      if (map == null) continue;
      final url = map['url']?.toString();
      if (url == null || !url.startsWith('http')) continue;
      if (isHlsOrDashUrl(url)) continue;

      final height = _asInt(map['height']);
      final width = _asInt(map['width']);
      final quality = _qualityLabel(
        raw: map['quality']?.toString(),
        height: height,
      );
      final mime = normalizeMime(
        map['mime']?.toString() ?? map['type']?.toString(),
        fallbackUrl: url,
      );
      final key = '$quality:${width}x$height:$url';
      if (!seen.add(key)) continue;

      qualities.add(
        VimeoQuality(
          quality: quality,
          url: url,
          width: width,
          height: height,
          frameRate: _asDouble(map['fps'] ?? map['framerate']),
          mimeType: mime,
        ),
      );
    }

    qualities.sort((a, b) => (b.height ?? 0).compareTo(a.height ?? 0));
    return qualities;
  }

  static VimeoQuality? bestQuality(List<VimeoQuality> qualities) {
    if (qualities.isEmpty) return null;
    VimeoQuality best = qualities.first;
    for (final item in qualities.skip(1)) {
      final itemHeight = item.height ?? 0;
      final bestHeight = best.height ?? 0;
      if (itemHeight > bestHeight) {
        best = item;
      } else if (itemHeight == bestHeight &&
          (item.width ?? 0) > (best.width ?? 0)) {
        best = item;
      }
    }
    return best;
  }

  static VimeoQuality? qualityByLabel(
    List<VimeoQuality> qualities,
    String label,
  ) {
    final wanted = label.toLowerCase();
    for (final item in qualities) {
      if (item.quality.toLowerCase() == wanted) return item;
    }
    return null;
  }

  static DiscoveredResource? resourceFromInfo({
    required Uri pageUrl,
    required VimeoVideoInfo info,
    VimeoQuality? quality,
  }) {
    final selected = quality ?? info.selectedQuality ?? bestQuality(info.qualities);
    if (selected == null) return null;

    return DiscoveredResource(
      directUrl: selected.url,
      fileName: buildFileName(
        videoId: info.videoId,
        title: info.title,
        quality: selected.quality,
        mimeType: selected.mimeType,
      ),
      platform: SocialPlatform.vimeo.label,
      pageUrl: pageUrl.toString(),
      title: info.title,
      mimeType: selected.mimeType,
      thumbnailUrl: info.thumbnailUrl,
      requestHeaders: SocialHttpHeaders.forMediaDownload(
        pageUrl: pageUrl,
        mediaUrl: selected.url,
        platform: SocialPlatform.vimeo,
      ),
      author: info.author,
      durationSeconds: info.durationSeconds,
      width: selected.width ?? info.width,
      height: selected.height ?? info.height,
      kind: DiscoveredResourceKind.fromMime(selected.mimeType),
      formats: [
        for (final quality in info.qualities)
          MediaFormat(
            url: quality.url,
            label: quality.quality,
            mimeType: quality.mimeType,
            height: quality.height,
            width: quality.width,
            isRecommended: quality.url == selected.url,
          ),
      ],
    );
  }

  static String buildFileName({
    required String videoId,
    String? title,
    String? quality,
    String? mimeType,
  }) {
    var base = (title != null && title.trim().isNotEmpty)
        ? title.trim()
        : videoId;
    base = FileNameResolver.sanitize(base).replaceAll('..', '_');
    if (base.length > 80) base = base.substring(0, 80).trim();
    if (base.isEmpty) {
      base = FileNameResolver.sanitize(videoId).replaceAll('..', '_');
    }

    final currentExt = _extensionOf(base);
    if (currentExt.isNotEmpty) {
      base = base.substring(0, base.length - currentExt.length);
    }

    final qualitySuffix =
        (quality != null && quality.isNotEmpty) ? '_$quality' : '';
    final ext = FileNameResolver.extensionFromMime(mimeType) ?? '.mp4';
    return FileNameResolver.sanitize('$base$qualitySuffix$ext');
  }

  static VimeoRestriction restrictionFromConfig(Map<dynamic, dynamic> config) {
    final message =
        '${config['message'] ?? ''} ${config['error'] ?? ''}'.toLowerCase();
    if (message.contains('password')) return VimeoRestriction.password;
    if (message.contains('private') || message.contains('not allowed')) {
      return VimeoRestriction.private;
    }
    if (message.contains('not found') || message.contains("couldn't find")) {
      return VimeoRestriction.unavailable;
    }

    final video = _asMap(config['video']);
    final privacy = _asMap(video?['privacy']);
    final view = privacy?['view']?.toString().toLowerCase();
    if (view == 'password') return VimeoRestriction.password;
    if (view == 'nobody' || view == 'disable' || view == 'n') {
      return VimeoRestriction.private;
    }

    if (config['drm'] == true || _asMap(config['request'])?['drm'] == true) {
      return VimeoRestriction.drm;
    }

    final qualities = parseQualities(config);
    if (qualities.isEmpty && _hasHlsOrDash(config)) {
      return VimeoRestriction.hlsOnly;
    }
    if (qualities.isEmpty && video != null) {
      return VimeoRestriction.unavailable;
    }
    return VimeoRestriction.none;
  }

  static String? bestThumbnailUrl(Map<dynamic, dynamic> video) {
    final thumbs = video['thumbs'] ?? video['thumbnail'];
    if (thumbs is String && thumbs.startsWith('http')) return thumbs;
    if (thumbs is! Map) {
      final pictures = _asMap(video['pictures']);
      final sizes = pictures?['sizes'];
      if (sizes is List) {
        String? best;
        var bestWidth = -1;
        for (final size in sizes) {
          final map = _asMap(size);
          if (map == null) continue;
          final url = map['link']?.toString() ?? map['url']?.toString();
          final width = _asInt(map['width']) ?? 0;
          if (url != null && url.startsWith('http') && width >= bestWidth) {
            best = url;
            bestWidth = width;
          }
        }
        return best;
      }
      return null;
    }

    String? best;
    var bestKey = -1;
    String? base;
    thumbs.forEach((key, value) {
      final url = value?.toString();
      if (url == null || !url.startsWith('http')) return;
      if (key.toString() == 'base') {
        base = url;
        return;
      }
      final numeric = int.tryParse(key.toString()) ?? _asInt(key) ?? -1;
      if (numeric >= bestKey) {
        bestKey = numeric;
        best = url;
      }
    });
    return best ?? base;
  }

  /// Progressive files are muxed. Separate A/V exists only on skipped HLS/DASH.
  static bool hasMuxedAudio(
    Map<dynamic, dynamic> config,
    Map<dynamic, dynamic> video,
  ) {
    if (video['has_audio'] == false) return false;
    if (video['is_silent'] == true) return false;
    return parseQualities(config).isNotEmpty;
  }

  static bool hasSeparateAudio(Map<dynamic, dynamic> config) {
    final files = _asMap(_asMap(config['request'])?['files']);
    final hls = _asMap(files?['hls']);
    return hls?['separate_av'] == true && parseQualities(config).isEmpty;
  }

  static bool isHlsOrDashUrl(String url) {
    final path = (Uri.tryParse(url)?.path ?? url).toLowerCase();
    return path.contains('.m3u8') ||
        path.contains('.mpd') ||
        path.endsWith('m3u8') ||
        path.endsWith('mpd');
  }

  static String normalizeMime(String? raw, {String? fallbackUrl}) {
    if (raw != null && raw.isNotEmpty) {
      final base = raw.split(';').first.trim().toLowerCase();
      if (base == 'video/x-m4v') return 'video/mp4';
      return base;
    }
    return mimeFromUrl(fallbackUrl ?? '');
  }

  static String mimeFromUrl(String url) {
    final path = (Uri.tryParse(url)?.path ?? url).toLowerCase();
    if (path.endsWith('.webm')) return 'video/webm';
    if (path.endsWith('.mov')) return 'video/quicktime';
    if (path.endsWith('.m3u8')) return 'application/vnd.apple.mpegurl';
    if (path.endsWith('.mpd')) return 'application/dash+xml';
    if (path.endsWith('.mp4') || path.endsWith('.m4v')) return 'video/mp4';
    return 'video/mp4';
  }

  static Map<dynamic, dynamic>? parseConfigFromHtml(String html) {
    final markers = [
      'window.playerConfig =',
      'window.playerConfig=',
      'var config =',
      'playerConfig:',
    ];
    for (final marker in markers) {
      final json = _extractJsonAfterMarker(html, marker);
      if (json == null) continue;
      try {
        final decoded = jsonDecode(json);
        if (decoded is Map) return decoded;
      } on Object {
        continue;
      }
    }
    return null;
  }

  static String? _extractJsonAfterMarker(String html, String marker) {
    final start = html.indexOf(marker);
    if (start < 0) return null;
    final braceStart = html.indexOf('{', start);
    if (braceStart < 0) return null;
    var depth = 0;
    for (var i = braceStart; i < html.length; i++) {
      final char = html[i];
      if (char == '{') depth++;
      if (char == '}') {
        depth--;
        if (depth == 0) {
          return html.substring(braceStart, i + 1);
        }
      }
    }
    return null;
  }

  Future<Map<dynamic, dynamic>?> _fetchPlayerConfig(
    String videoId,
    String? hash,
  ) async {
    final uri = hash == null
        ? Uri.parse('https://player.vimeo.com/video/$videoId/config')
        : Uri.parse('https://player.vimeo.com/video/$videoId/config?h=$hash');
    try {
      final response = await _dio.get<dynamic>(
        uri.toString(),
        options: Options(
          responseType: ResponseType.json,
          followRedirects: true,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 400,
          headers: {
            ...SocialHttpHeaders.forPageFetch(
              Uri.parse('https://vimeo.com/$videoId'),
              SocialPlatform.vimeo,
            ),
            'Accept': 'application/json',
            'Referer': 'https://player.vimeo.com/video/$videoId',
          },
        ),
      );
      final data = response.data;
      if (data is Map) return data;
      if (data is String && data.isNotEmpty) {
        final decoded = jsonDecode(data);
        if (decoded is Map) return decoded;
      }
      return null;
    } on DioException {
      return null;
    } on Object {
      return null;
    }
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
          headers: SocialHttpHeaders.forPageFetch(url, SocialPlatform.vimeo),
        ),
      );
      return response.data;
    } on DioException {
      return null;
    }
  }

  static Uri _playerPageUri(String videoId, String? hash) {
    return hash == null
        ? Uri.parse('https://player.vimeo.com/video/$videoId')
        : Uri.parse('https://player.vimeo.com/video/$videoId?h=$hash');
  }

  static bool _hasHlsOrDash(Map<dynamic, dynamic> config) {
    final files = _asMap(_asMap(config['request'])?['files']);
    if (files == null) return false;
    return files['hls'] != null || files['dash'] != null;
  }

  static String _qualityLabel({String? raw, int? height}) {
    final cleaned = raw?.trim();
    if (cleaned != null && cleaned.isNotEmpty && cleaned.toLowerCase() != 'auto') {
      return cleaned;
    }
    if (height != null && height > 0) return '${height}p';
    return 'unknown';
  }

  static String? _nonEmpty(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return null;
    return trimmed;
  }

  static Map<dynamic, dynamic>? _asMap(dynamic value) {
    if (value is Map<dynamic, dynamic>) return value;
    if (value is Map) return Map<dynamic, dynamic>.from(value);
    return null;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static String _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return '';
    return name.substring(dot);
  }
}

class VimeoQuality {
  const VimeoQuality({
    required this.quality,
    required this.url,
    required this.mimeType,
    this.width,
    this.height,
    this.frameRate,
  });

  final String quality;
  final String url;
  final String mimeType;
  final int? width;
  final int? height;
  final double? frameRate;

  double? get aspectRatio {
    if (width == null || height == null || height == 0) return null;
    return width! / height!;
  }
}

class VimeoVideoInfo {
  const VimeoVideoInfo({
    required this.videoId,
    required this.qualities,
    this.title,
    this.description,
    this.author,
    this.authorId,
    this.videoUrl,
    this.durationSeconds,
    this.width,
    this.height,
    this.frameRate,
    this.thumbnailUrl,
    this.createdAt,
    this.mimeType,
    this.hasAudio = true,
    this.selectedQuality,
  });

  final String videoId;
  final String? title;
  final String? description;
  final String? author;
  final String? authorId;
  final String? videoUrl;
  final double? durationSeconds;
  final int? width;
  final int? height;
  final double? frameRate;
  final String? thumbnailUrl;
  final String? createdAt;
  final String? mimeType;
  final List<VimeoQuality> qualities;
  final bool hasAudio;
  final VimeoQuality? selectedQuality;

  double? get aspectRatio {
    if (width == null || height == null || height == 0) return null;
    return width! / height!;
  }

  List<String> get availableQualityLabels =>
      qualities.map((q) => q.quality).toList();
}

enum VimeoRestriction {
  none,
  password,
  private,
  unavailable,
  drm,
  hlsOnly,
}
