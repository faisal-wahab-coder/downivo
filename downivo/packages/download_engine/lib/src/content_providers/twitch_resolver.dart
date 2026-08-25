import 'dart:convert';

import 'package:dio/dio.dart';

import '../filename_resolver.dart';
import 'models/discovered_resource.dart';
import 'social_http_headers.dart';
import 'social_platform.dart';
import 'social_url_utils.dart';

/// Resolves public Twitch Clip URLs to progressive MP4 playback files.
///
/// Uses the same public GraphQL endpoint the Twitch website loads. Does not
/// bypass authentication, subscriber-only VODs, private content, or DRM.
///
/// Clips expose muxed MP4 renditions. VODs and live streams are HLS-only
/// (no converter in this engine) — metadata is parsed, files are not
/// downloaded. Live channels are detected but not recorded unless a Clip
/// or VOD MP4 exists.
class TwitchResolver {
  TwitchResolver({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// Public web Client-ID used by twitch.tv itself. Not a user secret.
  static const gqlClientId = 'kimne78kx3nj6tv0uzuvi73ty9katz';

  static const _gqlEndpoint = 'https://gql.twitch.tv/gql';

  static const _clipQuery = r'''
query ClipInfo($slug: ID!) {
  clip(slug: $slug) {
    id
    slug
    title
    durationSeconds
    createdAt
    url
    thumbnailURL(width: 480, height: 272)
    broadcaster { id login displayName }
    curator { login displayName }
    game { id name }
    videoQualities { frameRate quality sourceURL }
    playbackAccessToken { signature value }
  }
}
''';

  static const _videoQuery = r'''
query VideoInfo($id: ID!) {
  video(id: $id) {
    id
    title
    description
    lengthSeconds
    createdAt
    publishedAt
    previewThumbnailURL(width: 1280, height: 720)
    owner { id login displayName }
    creator { login displayName }
    game { id name }
    broadcastType
    status
  }
}
''';

  static const _userQuery = r'''
query UserInfo($login: String!) {
  user(login: $login) {
    id
    login
    displayName
    description
    profileImageURL(width: 300)
    stream {
      id
      title
      type
      createdAt
      viewersCount
      previewImageURL(width: 1920, height: 1080)
      game { id name }
    }
    broadcastSettings {
      title
      game { name }
    }
  }
}
''';

  Future<DiscoveredResource?> discover(Uri pageUrl) async {
    final all = await discoverAll(pageUrl);
    return all.isEmpty ? null : all.first;
  }

  /// Returns a Clip MP4 when one exists. Channel/VOD/live/home return empty.
  Future<List<DiscoveredResource>> discoverAll(Uri pageUrl) async {
    final normalized = TwitchUri.normalize(pageUrl);
    final type = TwitchUri.classifyUrl(normalized);
    if (type == TwitchContentType.home ||
        type == TwitchContentType.directory ||
        type == TwitchContentType.nonContent) {
      return const [];
    }

    if (type == TwitchContentType.clip) {
      final slug =
          TwitchUri.clipIdFromUri(normalized) ?? TwitchUri.clipIdFromUri(pageUrl);
      if (slug == null) return const [];
      final payload = await _gql(_clipQuery, {'slug': slug});
      if (payload != null) {
        final info = parseClipInfo(payload);
        if (info != null) {
          final resource = resourceFromClip(pageUrl: pageUrl, info: info);
          if (resource != null) return [resource];
        }
        if (restrictionFromClipPayload(payload) != TwitchRestriction.none) {
          return const [];
        }
      }
      return const [];
    }

    if (type == TwitchContentType.vod) {
      // Metadata is parsed for tests/UI; HLS is not a downloadable file.
      return const [];
    }

    // Channel live/offline: detect only, never download the channel itself.
    return const [];
  }

  static TwitchContentType classifyUrl(Uri uri) => TwitchUri.classifyUrl(uri);

  static String? videoIdFromUri(Uri uri) => TwitchUri.videoIdFromUri(uri);

  static String? clipIdFromUri(Uri uri) => TwitchUri.clipIdFromUri(uri);

  static String? channelLoginFromUri(Uri uri) =>
      TwitchUri.channelLoginFromUri(uri);

  static TwitchClipInfo? parseClipInfo(Map<dynamic, dynamic> payload) {
    if (restrictionFromClipPayload(payload) != TwitchRestriction.none) {
      return null;
    }
    final clip = _clipMap(payload);
    if (clip == null) return null;

    final slug = clip['slug']?.toString();
    if (slug == null || slug.isEmpty) return null;

    final qualities = parseClipQualities(clip);
    final best = bestQuality(qualities);
    if (best == null) return null;

    final token = _asMap(clip['playbackAccessToken']);
    final signature = _nonEmpty(token?['signature']?.toString());
    final tokenValue = _nonEmpty(token?['value']?.toString());
    final signedUrl = signedMediaUrl(best.url, signature, tokenValue);

    final broadcaster = _asMap(clip['broadcaster']);
    final curator = _asMap(clip['curator']);
    final game = _asMap(clip['game']);

    return TwitchClipInfo(
      clipId: clip['id']?.toString() ?? slug,
      slug: slug,
      title: _nonEmpty(clip['title']?.toString()),
      description: _nonEmpty(clip['description']?.toString()),
      creator: _nonEmpty(
        curator?['displayName']?.toString() ?? curator?['login']?.toString(),
      ),
      channelLogin: _nonEmpty(broadcaster?['login']?.toString()),
      channelId: broadcaster?['id']?.toString(),
      channelName: _nonEmpty(
        broadcaster?['displayName']?.toString() ??
            broadcaster?['login']?.toString(),
      ),
      category: _nonEmpty(game?['name']?.toString()),
      clipUrl: _nonEmpty(clip['url']?.toString()) ??
          'https://clips.twitch.tv/$slug',
      durationSeconds: _asDouble(clip['durationSeconds'] ?? clip['duration']),
      thumbnailUrl: _httpUrl(clip['thumbnailURL'] ?? clip['thumbnailUrl']),
      createdAt: _nonEmpty(clip['createdAt']?.toString()),
      mimeType: best.mimeType,
      qualities: qualities,
      hasAudio: true,
      selectedQuality: best.copyWith(url: signedUrl),
    );
  }

  static TwitchVideoInfo? parseVideoInfo(Map<dynamic, dynamic> payload) {
    final restriction = restrictionFromVideoPayload(payload);
    final video = _videoMap(payload);
    if (video == null) return null;

    final videoId = video['id']?.toString();
    if (videoId == null || videoId.isEmpty) return null;

    final owner = _asMap(video['owner']) ?? _asMap(video['creator']);
    final game = _asMap(video['game']);
    final broadcastType = _nonEmpty(video['broadcastType']?.toString());
    final isHighlight = broadcastType?.toUpperCase() == 'HIGHLIGHT';

    return TwitchVideoInfo(
      videoId: videoId,
      title: _nonEmpty(video['title']?.toString()),
      description: _nonEmpty(video['description']?.toString()),
      channelLogin: _nonEmpty(owner?['login']?.toString()),
      channelId: owner?['id']?.toString(),
      channelName: _nonEmpty(
        owner?['displayName']?.toString() ?? owner?['login']?.toString(),
      ),
      category: _nonEmpty(game?['name']?.toString()),
      videoUrl: _nonEmpty(video['url']?.toString()) ??
          'https://www.twitch.tv/videos/$videoId',
      durationSeconds: _asDouble(
        video['lengthSeconds'] ?? video['duration'] ?? video['length'],
      ),
      thumbnailUrl: _httpUrl(
        video['previewThumbnailURL'] ??
            video['previewThumbnailUrl'] ??
            video['thumbnailURL'],
      ),
      createdAt: _nonEmpty(
        video['publishedAt']?.toString() ?? video['createdAt']?.toString(),
      ),
      broadcastType: broadcastType,
      isHighlight: isHighlight,
      restriction: restriction == TwitchRestriction.none
          ? TwitchRestriction.hlsOnly
          : restriction,
    );
  }

  static TwitchChannelInfo? parseChannelInfo(Map<dynamic, dynamic> payload) {
    final user = _userMap(payload);
    if (user == null) return null;

    final login = user['login']?.toString();
    if (login == null || login.isEmpty) return null;

    final stream = _asMap(user['stream']);
    final settings = _asMap(user['broadcastSettings']);
    final live = stream != null;
    final game = _asMap(stream?['game']) ?? _asMap(settings?['game']);

    return TwitchChannelInfo(
      channelId: user['id']?.toString(),
      login: login,
      displayName: _nonEmpty(user['displayName']?.toString()) ?? login,
      description: _nonEmpty(user['description']?.toString()),
      profileImageUrl: _httpUrl(user['profileImageURL']),
      isLive: live,
      streamTitle: live
          ? _nonEmpty(
              stream?['title']?.toString() ?? settings?['title']?.toString(),
            )
          : null,
      category: _nonEmpty(game?['name']?.toString()),
      thumbnailUrl: live
          ? _httpUrl(stream?['previewImageURL']) ??
              _httpUrl(user['profileImageURL'])
          : _httpUrl(user['profileImageURL']),
      viewerCount: live ? _asInt(stream?['viewersCount']) : null,
      streamId: live ? stream!['id']?.toString() : null,
    );
  }

  /// Progressive MP4 clip renditions only. HLS URLs are omitted.
  static List<TwitchQuality> parseClipQualities(Map<dynamic, dynamic> clip) {
    final raw = clip['videoQualities'];
    if (raw is! List) return const [];

    final qualities = <TwitchQuality>[];
    final seen = <String>{};
    for (final item in raw) {
      final map = _asMap(item);
      if (map == null) continue;
      final url = map['sourceURL']?.toString() ?? map['sourceUrl']?.toString();
      if (url == null || !url.startsWith('http')) continue;
      if (isHlsOrDashUrl(url)) continue;

      final height = heightFromQualityLabel(map['quality']?.toString());
      final quality = _qualityLabel(
        raw: map['quality']?.toString(),
        height: height,
      );
      final mime = normalizeMime(null, fallbackUrl: url);
      final key = '$quality:$url';
      if (!seen.add(key)) continue;

      qualities.add(
        TwitchQuality(
          quality: quality,
          url: url,
          height: height,
          frameRate: _asDouble(map['frameRate'] ?? map['framerate']),
          mimeType: mime,
        ),
      );
    }

    qualities.sort((a, b) => (b.height ?? 0).compareTo(a.height ?? 0));
    return qualities;
  }

  /// Parses an HLS master playlist for quality labels. URLs are not downloadable.
  static List<TwitchQuality> parseHlsMaster(String playlist) {
    final qualities = <TwitchQuality>[];
    final seen = <String>{};
    final lines = playlist.split(RegExp(r'\r?\n'));
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (!line.startsWith('#EXT-X-STREAM-INF:')) continue;
      final resolution = RegExp(r'RESOLUTION=(\d+)x(\d+)').firstMatch(line);
      final width = resolution == null ? null : int.tryParse(resolution.group(1)!);
      final height = resolution == null ? null : int.tryParse(resolution.group(2)!);
      String? url;
      if (i + 1 < lines.length && !lines[i + 1].trim().startsWith('#')) {
        url = lines[i + 1].trim();
      }
      if (url == null || url.isEmpty) continue;
      if (!url.contains('.m3u8') && !url.startsWith('http')) continue;

      final fromPath = _qualityFromHlsPath(url);
      final quality = fromPath ??
          _qualityLabel(raw: null, height: height) ??
          'unknown';
      if (quality.toLowerCase() == 'audio_only') continue;
      if (!seen.add(quality)) continue;

      qualities.add(
        TwitchQuality(
          quality: quality,
          url: url,
          width: width,
          height: height,
          mimeType: 'application/vnd.apple.mpegurl',
        ),
      );
    }
    qualities.sort((a, b) => (b.height ?? 0).compareTo(a.height ?? 0));
    return qualities;
  }

  static TwitchQuality? bestQuality(List<TwitchQuality> qualities) {
    if (qualities.isEmpty) return null;
    TwitchQuality best = qualities.first;
    for (final item in qualities.skip(1)) {
      final itemHeight = item.height ?? 0;
      final bestHeight = best.height ?? 0;
      if (itemHeight > bestHeight) {
        best = item;
      } else if (itemHeight == bestHeight &&
          (item.frameRate ?? 0) > (best.frameRate ?? 0)) {
        best = item;
      }
    }
    return best;
  }

  static TwitchQuality? qualityByLabel(
    List<TwitchQuality> qualities,
    String label,
  ) {
    final wanted = label.toLowerCase();
    for (final item in qualities) {
      if (item.quality.toLowerCase() == wanted) return item;
    }
    return null;
  }

  static DiscoveredResource? resourceFromClip({
    required Uri pageUrl,
    required TwitchClipInfo info,
    TwitchQuality? quality,
  }) {
    final selected =
        quality ?? info.selectedQuality ?? bestQuality(info.qualities);
    if (selected == null) return null;
    if (isHlsOrDashUrl(selected.url)) return null;

    return DiscoveredResource(
      directUrl: selected.url,
      fileName: buildFileName(
        id: info.slug,
        title: info.title,
        quality: selected.quality,
        mimeType: selected.mimeType,
      ),
      platform: SocialPlatform.twitch.label,
      pageUrl: pageUrl.toString(),
      title: info.title,
      mimeType: selected.mimeType,
      thumbnailUrl: info.thumbnailUrl,
      requestHeaders: SocialHttpHeaders.forMediaDownload(
        pageUrl: pageUrl,
        mediaUrl: selected.url,
        platform: SocialPlatform.twitch,
      ),
      author: info.creator ?? info.channelName,
      durationSeconds: info.durationSeconds,
      width: selected.width,
      height: selected.height,
      kind: DiscoveredResourceKind.video,
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
    required String id,
    String? title,
    String? quality,
    String? mimeType,
  }) {
    var base = (title != null && title.trim().isNotEmpty) ? title.trim() : id;
    base = FileNameResolver.sanitize(base).replaceAll('..', '_');
    if (base.length > 80) base = base.substring(0, 80).trim();
    if (base.isEmpty) {
      base = FileNameResolver.sanitize(id).replaceAll('..', '_');
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

  static TwitchRestriction restrictionFromClipPayload(
    Map<dynamic, dynamic> payload,
  ) {
    final errors = payload['errors'];
    if (errors is List && errors.isNotEmpty) {
      final text = errors.toString().toLowerCase();
      if (text.contains('not found') || text.contains('does not exist')) {
        return TwitchRestriction.unavailable;
      }
    }

    final clip = _clipMap(payload);
    if (payload.containsKey('data') && clip == null) {
      return TwitchRestriction.unavailable;
    }
    if (clip == null) return TwitchRestriction.unavailable;

    final token = _asMap(clip['playbackAccessToken']);
    final tokenValue = token?['value']?.toString();
    if (isTokenForbidden(tokenValue)) return TwitchRestriction.restricted;

    final qualities = parseClipQualities(clip);
    if (qualities.isEmpty) {
      final raw = clip['videoQualities'];
      if (raw is List && raw.isNotEmpty) return TwitchRestriction.hlsOnly;
      return TwitchRestriction.unavailable;
    }
    return TwitchRestriction.none;
  }

  static TwitchRestriction restrictionFromVideoPayload(
    Map<dynamic, dynamic> payload,
  ) {
    final video = _videoMap(payload);
    if (payload.containsKey('data') && video == null) {
      return TwitchRestriction.unavailable;
    }
    if (video == null) return TwitchRestriction.unavailable;

    final status = video['status']?.toString().toLowerCase() ?? '';
    if (status.contains('record') || status == 'recorded' || status.isEmpty) {
      return TwitchRestriction.hlsOnly;
    }
    if (status.contains('unavail') || status.contains('deleted')) {
      return TwitchRestriction.unavailable;
    }
    return TwitchRestriction.hlsOnly;
  }

  static bool isTokenForbidden(String? token) {
    if (token == null || token.isEmpty) return false;
    try {
      final decoded = jsonDecode(token);
      if (decoded is Map) {
        final auth = decoded['authorization'];
        if (auth is Map && auth['forbidden'] == true) return true;
      }
    } on Object {
      return false;
    }
    return false;
  }

  static String signedMediaUrl(
    String sourceUrl,
    String? signature,
    String? token,
  ) {
    if (signature == null ||
        token == null ||
        signature.isEmpty ||
        token.isEmpty) {
      return sourceUrl;
    }
    final uri = Uri.parse(sourceUrl);
    final params = Map<String, String>.from(uri.queryParameters);
    params['sig'] = signature;
    params['token'] = token;
    return uri.replace(queryParameters: params).toString();
  }

  static bool isHlsOrDashUrl(String url) {
    final path = (Uri.tryParse(url)?.path ?? url).toLowerCase();
    return path.contains('.m3u8') ||
        path.contains('.mpd') ||
        path.endsWith('m3u8') ||
        path.endsWith('mpd');
  }

  static bool isLive(TwitchChannelInfo? info) => info?.isLive == true;

  static int? heightFromQualityLabel(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final digits = RegExp(r'(\d{3,4})').firstMatch(raw);
    if (digits == null) return null;
    return int.tryParse(digits.group(1)!);
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

  static Map<dynamic, dynamic>? clipPayload(Map<dynamic, dynamic> clip) {
    return {'data': {'clip': clip}};
  }

  static Map<dynamic, dynamic>? videoPayload(Map<dynamic, dynamic> video) {
    return {'data': {'video': video}};
  }

  static Map<dynamic, dynamic>? userPayload(Map<dynamic, dynamic> user) {
    return {'data': {'user': user}};
  }

  Future<Map<dynamic, dynamic>?> _gql(
    String query,
    Map<String, dynamic> variables,
  ) async {
    try {
      final response = await _dio.post<dynamic>(
        _gqlEndpoint,
        data: {
          'query': query,
          'variables': variables,
        },
        options: Options(
          responseType: ResponseType.json,
          followRedirects: true,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 400,
          headers: {
            ...SocialHttpHeaders.forPageFetch(
              Uri.parse('https://www.twitch.tv/'),
              SocialPlatform.twitch,
            ),
            'Client-ID': gqlClientId,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      final data = response.data;
      if (data is Map) return data;
      if (data is List && data.isNotEmpty && data.first is Map) {
        return data.first as Map;
      }
      if (data is String && data.isNotEmpty) {
        final decoded = jsonDecode(data);
        if (decoded is Map) return decoded;
        if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
          return decoded.first as Map;
        }
      }
      return null;
    } on DioException {
      return null;
    } on Object {
      return null;
    }
  }

  static Map<dynamic, dynamic>? _clipMap(Map<dynamic, dynamic> payload) {
    final data = _asMap(payload['data']) ?? payload;
    return _asMap(data['clip']);
  }

  static Map<dynamic, dynamic>? _videoMap(Map<dynamic, dynamic> payload) {
    final data = _asMap(payload['data']) ?? payload;
    return _asMap(data['video']);
  }

  static Map<dynamic, dynamic>? _userMap(Map<dynamic, dynamic> payload) {
    final data = _asMap(payload['data']) ?? payload;
    return _asMap(data['user']);
  }

  static Map<dynamic, dynamic>? _asMap(dynamic value) {
    if (value is Map<dynamic, dynamic>) return value;
    return null;
  }

  static String? _nonEmpty(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _httpUrl(dynamic value) {
    final text = _nonEmpty(value?.toString());
    if (text == null) return null;
    if (text.startsWith('http://') || text.startsWith('https://')) return text;
    return null;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static String _qualityLabel({String? raw, int? height}) {
    if (raw != null && raw.trim().isNotEmpty) {
      final trimmed = raw.trim();
      if (trimmed.toLowerCase() == 'chunked' ||
          trimmed.toLowerCase() == 'source') {
        return 'Source';
      }
      if (RegExp(r'^\d+p$', caseSensitive: false).hasMatch(trimmed)) {
        return trimmed.toLowerCase();
      }
      if (RegExp(r'^\d+$').hasMatch(trimmed)) {
        return '${trimmed}p';
      }
      final digits = RegExp(r'(\d{3,4})').firstMatch(trimmed);
      if (digits != null) return '${digits.group(1)}p';
    }
    if (height != null && height > 0) return '${height}p';
    return 'unknown';
  }

  static String? _qualityFromHlsPath(String url) {
    final path = (Uri.tryParse(url)?.path ?? url).toLowerCase();
    if (path.contains('/chunked/')) return 'Source';
    if (path.contains('audio_only')) return 'audio_only';
    final match = RegExp(r'/(\d{3,4}p\d*)/').firstMatch(path);
    if (match != null) {
      final label = match.group(1)!;
      final height = RegExp(r'^(\d+)').firstMatch(label)?.group(1);
      return height == null ? label : '${height}p';
    }
    return null;
  }

  static String _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return '';
    return name.substring(dot);
  }
}

class TwitchQuality {
  const TwitchQuality({
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

  TwitchQuality copyWith({
    String? quality,
    String? url,
    String? mimeType,
    int? width,
    int? height,
    double? frameRate,
  }) {
    return TwitchQuality(
      quality: quality ?? this.quality,
      url: url ?? this.url,
      mimeType: mimeType ?? this.mimeType,
      width: width ?? this.width,
      height: height ?? this.height,
      frameRate: frameRate ?? this.frameRate,
    );
  }
}

class TwitchClipInfo {
  const TwitchClipInfo({
    required this.clipId,
    required this.slug,
    required this.qualities,
    this.title,
    this.description,
    this.creator,
    this.channelLogin,
    this.channelId,
    this.channelName,
    this.category,
    this.clipUrl,
    this.durationSeconds,
    this.thumbnailUrl,
    this.createdAt,
    this.mimeType,
    this.hasAudio = true,
    this.selectedQuality,
  });

  final String clipId;
  final String slug;
  final String? title;
  final String? description;
  final String? creator;
  final String? channelLogin;
  final String? channelId;
  final String? channelName;
  final String? category;
  final String? clipUrl;
  final double? durationSeconds;
  final String? thumbnailUrl;
  final String? createdAt;
  final String? mimeType;
  final List<TwitchQuality> qualities;
  final bool hasAudio;
  final TwitchQuality? selectedQuality;

  List<String> get availableQualityLabels =>
      qualities.map((q) => q.quality).toList();
}

class TwitchVideoInfo {
  const TwitchVideoInfo({
    required this.videoId,
    this.title,
    this.description,
    this.channelLogin,
    this.channelId,
    this.channelName,
    this.category,
    this.videoUrl,
    this.durationSeconds,
    this.thumbnailUrl,
    this.createdAt,
    this.broadcastType,
    this.isHighlight = false,
    this.restriction = TwitchRestriction.hlsOnly,
  });

  final String videoId;
  final String? title;
  final String? description;
  final String? channelLogin;
  final String? channelId;
  final String? channelName;
  final String? category;
  final String? videoUrl;
  final double? durationSeconds;
  final String? thumbnailUrl;
  final String? createdAt;
  final String? broadcastType;
  final bool isHighlight;
  final TwitchRestriction restriction;
}

class TwitchChannelInfo {
  const TwitchChannelInfo({
    required this.login,
    required this.displayName,
    required this.isLive,
    this.channelId,
    this.description,
    this.profileImageUrl,
    this.streamTitle,
    this.category,
    this.thumbnailUrl,
    this.viewerCount,
    this.streamId,
  });

  final String? channelId;
  final String login;
  final String displayName;
  final String? description;
  final String? profileImageUrl;
  final bool isLive;
  final String? streamTitle;
  final String? category;
  final String? thumbnailUrl;
  final int? viewerCount;
  final String? streamId;
}

enum TwitchRestriction {
  none,
  unavailable,
  restricted,
  hlsOnly,
  offline,
}
