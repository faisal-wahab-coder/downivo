import 'dart:convert';

import 'package:dio/dio.dart';

import 'media_extractor.dart';
import 'models/discovered_resource.dart';
import 'social_http_headers.dart';
import 'social_platform.dart';
import 'social_url_utils.dart';

/// Resolves SoundCloud track and playlist/set URLs to direct audio stream URLs.
///
/// Public content only. Does not bypass authentication, privacy controls, or DRM.
///
/// SoundCloud progressive transcodings are API endpoints that return JSON
/// `{ "url": "https://cf-media.sndcdn.com/....mp3" }`. This resolver follows
/// that hop so the Download Engine receives a real audio file URL.
class SoundCloudResolver {
  SoundCloudResolver({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<DiscoveredResource?> discover(Uri pageUrl) async {
    final contentType = SoundCloudUri.classifyUrl(pageUrl);
    if (contentType != SoundCloudContentType.track &&
        contentType != SoundCloudContentType.shortUrl) {
      return null;
    }

    final html = await _fetchHtml(pageUrl);
    if (html == null || html.isEmpty) return null;

    final clientId = await _resolveClientId(html, pageUrl);
    final hydration = _extractHydration(html);

    if (hydration != null) {
      final resource = await _resolveFromHydration(hydration, pageUrl, clientId);
      if (resource != null) return resource;
    }

    if (contentType != SoundCloudContentType.shortUrl) {
      final fromMeta = _resolveFromMeta(html, pageUrl);
      if (fromMeta != null) return fromMeta;
    }

    final fromApi = await _resourceFromResolveApi(pageUrl, clientId);
    if (fromApi != null) return fromApi;

    if (contentType == SoundCloudContentType.shortUrl) return null;
    return null;
  }

  /// Resolves all tracks from a playlist/set URL, or a single track.
  ///
  /// Unavailable / stub tracks are skipped. One failure does not fail the rest.
  Future<List<DiscoveredResource>> discoverAll(Uri pageUrl) async {
    final contentType = SoundCloudUri.classifyUrl(pageUrl);

    if (contentType == SoundCloudContentType.track) {
      final single = await discover(pageUrl);
      return single != null ? [single] : const [];
    }

    if (contentType != SoundCloudContentType.playlist &&
        contentType != SoundCloudContentType.shortUrl) {
      return const [];
    }

    final html = await _fetchHtml(pageUrl);
    if (html == null || html.isEmpty) return const [];

    final clientId = await _resolveClientId(html, pageUrl);
    final hydration = _extractHydration(html);
    if (hydration != null) {
      final playlist = await _resolvePlaylistFromHydration(
        hydration,
        pageUrl,
        clientId,
      );
      if (playlist.isNotEmpty) return playlist;

      if (contentType == SoundCloudContentType.shortUrl) {
        final single = await _resolveFromHydration(hydration, pageUrl, clientId);
        if (single != null) return [single];
      }
    }

    final fromApi = await _resourcesFromResolveApi(pageUrl, clientId);
    if (fromApi.isNotEmpty) return fromApi;

    if (contentType == SoundCloudContentType.shortUrl) {
      final single = _resolveFromMeta(html, pageUrl);
      return single != null ? [single] : const [];
    }
    return const [];
  }

  Future<DiscoveredResource?> _resourceFromResolveApi(
    Uri pageUrl,
    String? clientId,
  ) async {
    final data = await _resolvePermalink(pageUrl, clientId);
    if (data == null) return null;
    final kind = data['kind']?.toString();
    if (kind != 'track' && kind != 'sound') return null;
    return _resourceFromTrack(data, pageUrl, clientId);
  }

  Future<List<DiscoveredResource>> _resourcesFromResolveApi(
    Uri pageUrl,
    String? clientId,
  ) async {
    final data = await _resolvePermalink(pageUrl, clientId);
    if (data == null) return const [];
    final kind = data['kind']?.toString();
    if (kind == 'playlist' || kind == 'system-playlist') {
      return _resolvePlaylistFromData(data, pageUrl, clientId);
    }
    if (kind == 'track' || kind == 'sound') {
      final single = await _resourceFromTrack(data, pageUrl, clientId);
      return single != null ? [single] : const [];
    }
    return const [];
  }

  Future<Map<String, dynamic>?> _resolvePermalink(
    Uri pageUrl,
    String? clientId,
  ) async {
    if (clientId == null || clientId.isEmpty) return null;
    try {
      final response = await _dio.get<dynamic>(
        'https://api-v2.soundcloud.com/resolve',
        queryParameters: {
          'url': pageUrl.toString(),
          'client_id': clientId,
        },
        options: Options(
          responseType: ResponseType.json,
          followRedirects: true,
          validateStatus: (s) => s != null && s >= 200 && s < 400,
          headers: _apiHeaders(),
        ),
      );
      final data = response.data;
      if (data is String) {
        try {
          return _asStringKeyMap(jsonDecode(data));
        } on Object {
          return null;
        }
      }
      return _asStringKeyMap(data);
    } on Object {
      return null;
    }
  }

  Future<DiscoveredResource?> _resolveFromHydration(
    List<dynamic> hydration,
    Uri pageUrl,
    String? clientId,
  ) async {
    final trackData = _findTrackData(hydration);
    if (trackData == null) return null;
    return _resourceFromTrack(trackData, pageUrl, clientId);
  }

  Future<List<DiscoveredResource>> _resolvePlaylistFromHydration(
    List<dynamic> hydration,
    Uri pageUrl,
    String? clientId,
  ) async {
    final playlistData = _findPlaylistData(hydration);
    if (playlistData == null) return const [];
    return _resolvePlaylistFromData(playlistData, pageUrl, clientId);
  }

  Future<List<DiscoveredResource>> _resolvePlaylistFromData(
    Map<String, dynamic> playlistData,
    Uri pageUrl,
    String? clientId,
  ) async {
    final tracks = playlistData['tracks'];
    if (tracks is! List) return const [];

    final stubs = <Map<String, dynamic>>[];
    for (final track in tracks) {
      final map = _asStringKeyMap(track);
      if (map == null) continue;
      if (!_hasMedia(map) && map['id'] != null) {
        stubs.add(map);
      }
    }

    final hydratedById = <String, Map<String, dynamic>>{};
    if (stubs.isNotEmpty && clientId != null) {
      for (final hydrated in await _hydrateStubTracks(stubs, clientId)) {
        final id = hydrated['id']?.toString();
        if (id != null) hydratedById[id] = hydrated;
      }
    }

    final resources = <DiscoveredResource>[];
    for (final track in tracks) {
      final map = _asStringKeyMap(track);
      if (map == null) continue;
      final id = map['id']?.toString();
      final data = _hasMedia(map)
          ? map
          : (id != null ? hydratedById[id] : null);
      if (data == null) continue;

      final permalink = data['permalink_url']?.toString();
      final trackUri = permalink != null ? Uri.tryParse(permalink) : null;
      final resource = await _resourceFromTrack(
        data,
        trackUri ?? pageUrl,
        clientId,
      );
      if (resource != null) resources.add(resource);
    }
    return resources;
  }

  Future<DiscoveredResource?> _resourceFromTrack(
    Map<String, dynamic> trackData,
    Uri pageUrl,
    String? clientId,
  ) async {
    if (_isRestricted(trackData)) return null;

    final title = trackData['title']?.toString();
    final artist = _extractArtistName(trackData);
    final artworkUrl = _extractArtworkUrl(trackData);
    final mediaUrl = await _resolveStreamUrl(trackData, clientId);
    if (mediaUrl == null) return null;

    final mimeType = detectMimeType(mediaUrl, trackData);
    final displayTitle =
        title != null && artist != null ? '$artist - $title' : title;

    return DiscoveredResource(
      directUrl: mediaUrl,
      fileName: MediaExtractor.buildFileNameForSocial(
        pageUrl: pageUrl,
        platform: SocialPlatform.soundcloud,
        mediaUrl: mediaUrl,
        title: displayTitle,
        fallbackSlug: SoundCloudUri.trackSlugFromUri(pageUrl) ?? title,
        mimeHint: mimeType,
      ),
      platform: SocialPlatform.soundcloud.label,
      pageUrl: pageUrl.toString(),
      title: title,
      mimeType: mimeType,
      thumbnailUrl: artworkUrl,
      requestHeaders: SocialHttpHeaders.forMediaDownload(
        pageUrl: pageUrl,
        mediaUrl: mediaUrl,
        platform: SocialPlatform.soundcloud,
      ),
      author: artist,
      kind: DiscoveredResourceKind.fromMime(mimeType),
    );
  }

  DiscoveredResource? _resolveFromMeta(String html, Uri pageUrl) {
    final title = _metaContent(html, 'og:title') ??
        _metaContent(html, 'twitter:title');
    final thumbnailUrl = SoundCloudUri.upgradeArtworkUrl(
      _metaContent(html, 'og:image'),
    );

    final audioUrl = _metaContent(html, 'og:audio') ??
        _metaContent(html, 'og:audio:url');
    if (audioUrl == null || !audioUrl.startsWith('http')) return null;
    if (_isHlsUrl(audioUrl)) return null;

    return DiscoveredResource(
      directUrl: audioUrl,
      fileName: MediaExtractor.buildFileNameForSocial(
        pageUrl: pageUrl,
        platform: SocialPlatform.soundcloud,
        mediaUrl: audioUrl,
        title: title,
        fallbackSlug: SoundCloudUri.trackSlugFromUri(pageUrl),
        mimeHint: 'audio/mpeg',
      ),
      platform: SocialPlatform.soundcloud.label,
      pageUrl: pageUrl.toString(),
      title: title,
      mimeType: detectMimeType(audioUrl, const {}),
      thumbnailUrl: thumbnailUrl,
      requestHeaders: SocialHttpHeaders.forMediaDownload(
        pageUrl: pageUrl,
        mediaUrl: audioUrl,
        platform: SocialPlatform.soundcloud,
      ),
    );
  }

  Map<String, dynamic>? _findTrackData(List<dynamic> hydration) {
    for (final item in hydration) {
      final map = _asStringKeyMap(item);
      if (map == null) continue;
      final hydratable = map['hydratable']?.toString();
      if (hydratable == 'sound' || hydratable == 'track') {
        return _asStringKeyMap(map['data']);
      }
    }
    return null;
  }

  Map<String, dynamic>? _findPlaylistData(List<dynamic> hydration) {
    for (final item in hydration) {
      final map = _asStringKeyMap(item);
      if (map == null) continue;
      final hydratable = map['hydratable']?.toString();
      if (hydratable == 'playlist' || hydratable == 'system-playlist') {
        return _asStringKeyMap(map['data']);
      }
    }
    return null;
  }

  String? _extractArtistName(Map<String, dynamic> trackData) {
    final user = _asStringKeyMap(trackData['user']);
    if (user == null) return null;
    return user['username']?.toString() ?? user['full_name']?.toString();
  }

  String? _extractArtworkUrl(Map<String, dynamic> trackData) {
    final artwork = SoundCloudUri.upgradeArtworkUrl(
      trackData['artwork_url']?.toString(),
    );
    if (artwork != null) return artwork;

    final user = _asStringKeyMap(trackData['user']);
    if (user == null) return null;
    return SoundCloudUri.upgradeArtworkUrl(user['avatar_url']?.toString());
  }

  Future<String?> _resolveStreamUrl(
    Map<String, dynamic> trackData,
    String? clientId,
  ) async {
    // Artist-enabled official download is the preferred public source.
    if (trackData['downloadable'] == true) {
      final downloadUrl = trackData['download_url']?.toString();
      if (downloadUrl != null && downloadUrl.startsWith('http')) {
        final resolved = await _resolveMaybeApiUrl(
          _appendClientId(downloadUrl, clientId),
        );
        if (resolved != null) return resolved;
      }
    }

    final transcoding = _pickBestProgressiveTranscoding(trackData, clientId);
    if (transcoding != null) {
      final resolved = await _resolveMaybeApiUrl(transcoding);
      if (resolved != null) return resolved;
    }

    final streamUrl = trackData['stream_url']?.toString();
    if (streamUrl != null && streamUrl.startsWith('http')) {
      return _resolveMaybeApiUrl(_appendClientId(streamUrl, clientId));
    }
    return null;
  }

  Future<String?> _resolveMaybeApiUrl(String url) async {
    if (_isHlsUrl(url)) return null;
    if (_isDirectAudioUrl(url)) return url;
    return _resolveTranscodingUrl(url);
  }

  String? _pickBestProgressiveTranscoding(
    Map<String, dynamic> trackData,
    String? clientId,
  ) {
    final media = _asStringKeyMap(trackData['media']);
    final transcodings = media?['transcodings'];
    if (transcodings is! List) return null;

    String? progressiveMp3;
    String? progressiveAac;
    String? progressiveOther;

    for (final t in transcodings) {
      final map = _asStringKeyMap(t);
      if (map == null) continue;
      final url = map['url']?.toString();
      if (url == null || !url.startsWith('http')) continue;

      final format = _asStringKeyMap(map['format']);
      final protocol = format?['protocol']?.toString() ?? '';
      if (protocol != 'progressive') continue;

      final mimeType = format?['mime_type']?.toString() ?? '';
      final resolvedUrl = _appendClientId(url, clientId);

      if (mimeType.contains('mpeg') || mimeType.contains('mp3')) {
        progressiveMp3 = resolvedUrl;
      } else if (mimeType.contains('mp4') || mimeType.contains('aac')) {
        progressiveAac ??= resolvedUrl;
      } else {
        progressiveOther ??= resolvedUrl;
      }
    }

    return progressiveMp3 ?? progressiveAac ?? progressiveOther;
  }

  Future<String?> _resolveTranscodingUrl(String url) async {
    try {
      final response = await _dio.get<dynamic>(
        url,
        options: Options(
          responseType: ResponseType.json,
          followRedirects: true,
          validateStatus: (s) => s != null && s >= 200 && s < 400,
          headers: _apiHeaders(),
        ),
      );
      return _urlFromTranscodingPayload(response.data);
    } on DioException {
      return null;
    } on Object {
      return null;
    }
  }

  String? _urlFromTranscodingPayload(dynamic data) {
    if (data is String) {
      try {
        data = jsonDecode(data);
      } on Object {
        return null;
      }
    }
    if (data is! Map) return null;
    final resolved = data['url']?.toString();
    if (resolved == null || !resolved.startsWith('http')) return null;
    if (_isHlsUrl(resolved)) return null;
    return resolved;
  }

  Future<List<Map<String, dynamic>>> _hydrateStubTracks(
    List<Map<String, dynamic>> stubs,
    String clientId,
  ) async {
    final ids = stubs
        .map((t) => t['id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();
    if (ids.isEmpty) return const [];

    const chunkSize = 50;
    final hydrated = <Map<String, dynamic>>[];
    for (var i = 0; i < ids.length; i += chunkSize) {
      final end = i + chunkSize > ids.length ? ids.length : i + chunkSize;
      final chunk = ids.sublist(i, end);
      try {
        final response = await _dio.get<dynamic>(
          'https://api-v2.soundcloud.com/tracks',
          queryParameters: {
            'ids': chunk.join(','),
            'client_id': clientId,
          },
          options: Options(
            responseType: ResponseType.json,
            validateStatus: (s) => s != null && s >= 200 && s < 400,
            headers: _apiHeaders(),
          ),
        );
        final data = response.data;
        final list = data is List
            ? data
            : (data is String ? jsonDecode(data) : null);
        if (list is! List) continue;
        hydrated.addAll(
          list.map(_asStringKeyMap).whereType<Map<String, dynamic>>(),
        );
      } on Object {
        continue;
      }
    }
    return hydrated;
  }

  Future<String?> _resolveClientId(String html, Uri pageUrl) async {
    final fromHtml = extractClientIdFromText(html);
    if (fromHtml != null) return fromHtml;

    final srcPattern = RegExp(
      r'''src=["'](https://(?:a-v2\.sndcdn\.com|widget\.sndcdn\.com)/[^"']+\.js)["']''',
    );
    var fetched = 0;
    for (final match in srcPattern.allMatches(html)) {
      if (fetched >= 16) break;
      final src = match.group(1);
      if (src == null) continue;
      fetched++;
      final js = await _fetchHtml(Uri.parse(src));
      if (js == null) continue;
      final id = extractClientIdFromText(js);
      if (id != null) return id;
    }

    // Desktop pages often omit client_id; the mobile shell still embeds it.
    if (!pageUrl.host.toLowerCase().startsWith('m.')) {
      final mobile = pageUrl.replace(host: 'm.soundcloud.com');
      final mobileHtml = await _fetchHtml(mobile, desktop: false);
      if (mobileHtml != null) {
        final fromMobile = extractClientIdFromText(mobileHtml);
        if (fromMobile != null) return fromMobile;
      }
    }
    return null;
  }

  Map<String, String> _apiHeaders() => {
        'User-Agent': SocialHttpHeaders.soundcloudDesktopUserAgent,
        'Accept': 'application/json, */*',
        'Referer': 'https://soundcloud.com',
        'Origin': 'https://soundcloud.com',
      };

  /// Detects MIME type from transcoding metadata or the resolved media URL.
  static String detectMimeType(String mediaUrl, Map<String, dynamic> trackData) {
    final media = trackData['media'];
    if (media is Map) {
      final transcodings = media['transcodings'];
      if (transcodings is List) {
        for (final t in transcodings) {
          if (t is! Map) continue;
          final url = t['url']?.toString();
          if (url == null) continue;
          if (mediaUrl.contains(url) || url.contains(mediaUrl)) {
            final format = t['format'];
            if (format is Map) {
              final mime = format['mime_type']?.toString();
              if (mime != null) return mime.split(';').first.trim();
            }
          }
        }
      }
    }
    final lower = mediaUrl.toLowerCase();
    if (lower.contains('.m4a') || lower.contains('audio/mp4')) {
      return 'audio/mp4';
    }
    if (lower.contains('.aac') || lower.contains('audio/aac')) {
      return 'audio/aac';
    }
    if (lower.contains('.wav') || lower.contains('audio/wav')) {
      return 'audio/wav';
    }
    if (lower.contains('.flac') || lower.contains('audio/flac')) {
      return 'audio/flac';
    }
    if (lower.contains('.ogg') ||
        lower.contains('.opus') ||
        lower.contains('audio/ogg')) {
      return 'audio/ogg';
    }
    return 'audio/mpeg';
  }

  static String? extractClientIdFromText(String text) {
    final match = RegExp(
      r'''client_id["']?\s*[:=]\s*["']([0-9A-Za-z]{16,40})["']''',
    ).firstMatch(text);
    if (match != null) return match.group(1);
    final loose = RegExp(
      r'client_id[=:][\s"\x27]*([a-zA-Z0-9]{16,40})',
    ).firstMatch(text);
    return loose?.group(1);
  }

  static String _appendClientId(String url, String? clientId) {
    if (clientId == null || clientId.isEmpty) return url;
    if (url.contains('client_id=')) return url;
    return url.contains('?') ? '$url&client_id=$clientId' : '$url?client_id=$clientId';
  }

  static bool _hasMedia(Map<String, dynamic> track) {
    final media = track['media'];
    if (media is Map) {
      final transcodings = media['transcodings'];
      if (transcodings is List && transcodings.isNotEmpty) return true;
    }
    final streamUrl = track['stream_url']?.toString();
    if (streamUrl != null && streamUrl.startsWith('http')) return true;
    return track['downloadable'] == true &&
        (track['download_url']?.toString().startsWith('http') ?? false);
  }

  static bool _isRestricted(Map<String, dynamic> trackData) {
    final policy = trackData['policy']?.toString().toUpperCase();
    if (policy == 'BLOCK' || policy == 'SNIP') return true;
    if (trackData['sharing']?.toString() == 'private') return true;
    return false;
  }

  static bool _isHlsUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.m3u8') || lower.contains('/hls');
  }

  static bool _isDirectAudioUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('api-v2.soundcloud.com')) return false;
    if (_isHlsUrl(url)) return false;
    if (lower.contains('cf-hls-media.sndcdn.com')) return false;
    return lower.contains('.mp3') ||
        lower.contains('.m4a') ||
        lower.contains('.aac') ||
        lower.contains('.ogg') ||
        lower.contains('.opus') ||
        lower.contains('.wav') ||
        lower.contains('.flac') ||
        lower.contains('cf-media.sndcdn.com');
  }

  static Map<String, dynamic>? _asStringKeyMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, v) => MapEntry(key.toString(), v));
    }
    return null;
  }

  List<dynamic>? _extractHydration(String html) {
    final marker = '__sc_hydration';
    final start = html.indexOf(marker);
    if (start < 0) return null;

    final bracketStart = html.indexOf('[', start);
    if (bracketStart < 0) return null;

    var depth = 0;
    for (var i = bracketStart; i < html.length; i++) {
      final char = html[i];
      if (char == '[') depth++;
      if (char == ']') {
        depth--;
        if (depth == 0) {
          try {
            final decoded = jsonDecode(html.substring(bracketStart, i + 1));
            if (decoded is List) return decoded;
          } on Object {
            return null;
          }
        }
      }
    }
    return null;
  }

  Future<String?> _fetchHtml(Uri url, {bool desktop = true}) async {
    try {
      final headers = Map<String, String>.from(
        SocialHttpHeaders.forPageFetch(url, SocialPlatform.soundcloud),
      );
      if (!desktop) {
        headers['User-Agent'] = SocialHttpHeaders.userAgent;
      }
      final response = await _dio.get<String>(
        url.toString(),
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: true,
          validateStatus: (s) => s != null && s >= 200 && s < 400,
          headers: headers,
        ),
      );
      return response.data;
    } on DioException {
      return null;
    }
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
      if (match != null) return match.group(1);
    }
    return null;
  }
}
