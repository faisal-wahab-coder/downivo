import 'dart:convert';

import 'package:path/path.dart' as p;

import '../filename_resolver.dart';
import 'models/discovered_resource.dart';
import 'social_platform.dart';
import 'social_url_utils.dart';

/// Extracts direct media URLs from fetched page HTML.
class MediaExtractor {
  const MediaExtractor._();

  static DiscoveredResource? extract({
    required Uri pageUrl,
    required String html,
    required SocialPlatform platform,
  }) {
    var direct = _extractDirectMediaUrl(html, platform);
    if (platform != SocialPlatform.vimeo &&
        platform != SocialPlatform.twitch &&
        platform != SocialPlatform.linkedin &&
        platform != SocialPlatform.telegram &&
        platform != SocialPlatform.snapchat &&
        platform != SocialPlatform.threads &&
        platform != SocialPlatform.whatsapp &&
        platform != SocialPlatform.soundcloud) {
      direct ??= _extractOpenGraphVideo(html);
      final reelPage = platform == SocialPlatform.instagram &&
          RegExp(r'/(reels?|tv)/').hasMatch(pageUrl.path);
      if (!reelPage) {
        direct ??= _extractOpenGraphImage(html);
      }
    }
    if (direct == null) return null;

    var decodedUrl = _unescapeJsonUrl(direct);
    if (platform == SocialPlatform.pinterest) {
      decodedUrl = PinterestUri.upgradeImageUrl(decodedUrl);
    }
    final title = _metaContent(html, 'og:title') ??
        _metaContent(html, 'twitter:title');
    final mime = _metaContent(html, 'og:video:type') ??
        _metaContent(html, 'og:audio:type');
    final fileName = _buildFileName(
      pageUrl: pageUrl,
      platform: platform,
      mediaUrl: decodedUrl,
      title: title,
      mimeHint: mime,
    );
    final durationRaw = _metaContent(html, 'og:video:duration') ??
        _metaContent(html, 'og:duration');
    final widthRaw = _metaContent(html, 'og:video:width') ??
        _metaContent(html, 'og:image:width');
    final heightRaw = _metaContent(html, 'og:video:height') ??
        _metaContent(html, 'og:image:height');

    return DiscoveredResource(
      directUrl: decodedUrl,
      fileName: fileName,
      platform: platform.label,
      title: title,
      mimeType: mime,
      thumbnailUrl: _metaContent(html, 'og:image'),
      author: _metaContent(html, 'og:video:actor') ??
          _metaContent(html, 'author'),
      durationSeconds: durationRaw == null ? null : double.tryParse(durationRaw),
      width: widthRaw == null ? null : int.tryParse(widthRaw),
      height: heightRaw == null ? null : int.tryParse(heightRaw),
      kind: DiscoveredResourceKind.fromMime(mime),
    );
  }

  /// Builds a sanitized filename for discovered social media.
  static String buildFileNameForSocial({
    required Uri pageUrl,
    required SocialPlatform platform,
    required String mediaUrl,
    String? title,
    String? fallbackSlug,
    String? mimeHint,
  }) {
    return _buildFileName(
      pageUrl: pageUrl,
      platform: platform,
      mediaUrl: mediaUrl,
      title: title,
      mimeHint: mimeHint,
      fallbackSlug: fallbackSlug,
    );
  }

  static String? _extractDirectMediaUrl(
    String html,
    SocialPlatform platform,
  ) {
    return switch (platform) {
      SocialPlatform.youtube => _extractYouTubeStream(html),
      SocialPlatform.tiktok => _extractTikTokVideo(html) ??
          _firstJsonString(html, [
            'playAddr',
            'playApi',
            'downloadAddr',
          ]),
      SocialPlatform.instagram => _extractInstagramVideo(html) ??
          _metaContent(html, 'og:video') ??
          _metaContent(html, 'og:video:url'),
      SocialPlatform.twitter => _firstPatternMatch(html, [
          RegExp(r'https://video\.twimg\.com/[^\s"\\]+'),
          RegExp(r'https://pbs\.twimg\.com/media/[^\s"\\]+'),
        ]),
      SocialPlatform.facebook => _extractFacebookVideo(html) ??
          _metaContent(html, 'og:video') ??
          _metaContent(html, 'og:video:url'),
      SocialPlatform.reddit => _extractRedditMedia(html),
      SocialPlatform.pinterest => _metaContent(html, 'og:video') ??
          _metaContent(html, 'og:video:url') ??
          _firstPatternMatch(html, [
            RegExp(r'https://[^\s"\\]*pinimg\.com[^\s"\\]*\.mp4'),
          ]),
      SocialPlatform.linkedin => _extractLinkedInMedia(html),
      SocialPlatform.threads => _extractThreadsMedia(html),
      SocialPlatform.soundcloud => _metaContent(html, 'og:audio') ??
          _metaContent(html, 'og:audio:url'),
      SocialPlatform.vimeo => _extractVimeoMedia(html),
      SocialPlatform.twitch => _extractTwitchMedia(html),
      SocialPlatform.telegram => _extractTelegramMedia(html),
      SocialPlatform.snapchat => _extractSnapchatMedia(html),
      SocialPlatform.whatsapp => _extractWhatsAppMedia(html),
      SocialPlatform.dailymotion => _metaContent(html, 'og:video') ??
          _metaContent(html, 'og:video:url'),
    };
  }

  static String? _extractTikTokVideo(String html) {
    final universal = _scriptJson(html, '__UNIVERSAL_DATA_FOR_REHYDRATION__');
    if (universal != null) {
      final fromUniversal = _firstJsonString(universal, [
        'playAddr',
        'playApi',
        'downloadAddr',
      ]);
      if (fromUniversal != null) return fromUniversal;
    }

    final sigi = _scriptJson(html, 'SIGI_STATE');
    if (sigi != null) {
      final fromSigi = _firstJsonString(sigi, [
        'playAddr',
        'playApi',
        'downloadAddr',
      ]);
      if (fromSigi != null) return fromSigi;
    }

    return _firstPatternMatch(html, [
      RegExp(r'https://[^\s"\\]*tiktokcdn\.com[^\s"\\]*\.mp4[^\s"\\]*'),
      RegExp(r'https://[^\s"\\]*tiktokv\.com[^\s"\\]*'),
    ]);
  }

  static String? _extractRedditMedia(String html) {
    final fromJson = _firstJsonString(html, [
      'fallback_url',
      'dashUrl',
    ]);
    if (fromJson != null && !_isPlaylistUrl(fromJson)) return fromJson;

    return _firstPatternMatch(html, [
      RegExp(r'https://i\.redd\.it/[^\s"\\]+'),
      RegExp(r'https://preview\.redd\.it/[^\s"\\]+'),
      RegExp(r'https://v\.redd\.it/[a-z0-9]+/DASH_[^\s"\\]+'),
      RegExp(r'https://[^\s"\\]*redd\.it[^\s"\\]*\.(?:mp4|gif|jpg|jpeg|png|webp)'),
    ]);
  }

  /// Direct LinkedIn media only — player pages and HLS are skipped.
  static String? _extractLinkedInMedia(String html) {
    final og = _extractOpenGraphVideo(html);
    if (og != null && _isDirectLinkedInMedia(og)) return og;
    final image = _extractOpenGraphImage(html);
    if (image != null && _isDirectLinkedInMedia(image)) return image;
    return _firstPatternMatch(html, [
      RegExp(r'https://[^\s"\\]*licdn\.com[^\s"\\]*\.mp4[^\s"\\]*'),
      RegExp(r'https://[^\s"\\]*licdn\.com[^\s"\\]*mp4-\d{3,4}p[^\s"\\]*'),
      RegExp(r'https://[^\s"\\]*licdn\.com/dms/image/[^\s"\\]+'),
    ]);
  }

  static bool _isDirectLinkedInMedia(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.m3u8') || lower.contains('.mpd')) return false;
    if (lower.contains('linkedin.com')) return false;
    if (lower.contains('static.licdn.com')) return false;
    return lower.contains('licdn.com') &&
        (lower.contains('.mp4') ||
            RegExp(r'(?:^|/)mp4-\d{3,4}p(?:-|/|\?|$)').hasMatch(lower) ||
            lower.contains('/dms/image/') ||
            lower.contains('/dms/video/') ||
            lower.contains('.pdf') ||
            lower.contains('.jpg') ||
            lower.contains('.jpeg') ||
            lower.contains('.png') ||
            lower.contains('.webp'));
  }

  /// Direct Twitch media only — HLS playlists and page URLs are skipped.
  static String? _extractTwitchMedia(String html) {
    final og = _extractOpenGraphVideo(html);
    if (og != null && _isDirectTwitchMedia(og)) return og;
    return _firstPatternMatch(html, [
      RegExp(r'https://[^\s"\\]*twitchcdn\.net[^\s"\\]*\.mp4[^\s"\\]*'),
      RegExp(r'https://[^\s"\\]*clips-media-assets[^\s"\\]*\.mp4[^\s"\\]*'),
    ]);
  }

  static bool _isDirectTwitchMedia(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.m3u8') || lower.contains('.mpd')) return false;
    if (lower.contains('twitch.tv')) return false;
    return lower.contains('.mp4') ||
        lower.contains('twitchcdn.net') ||
        lower.contains('jtvnw.net') ||
        lower.contains('ttvnw.net');
  }

  /// Direct Threads CDN media only — page URLs and HLS are skipped.
  static String? _extractThreadsMedia(String html) {
    final og = _extractOpenGraphVideo(html);
    if (og != null && _isDirectThreadsMedia(og)) return og;
    final image = _extractOpenGraphImage(html);
    if (image != null && _isDirectThreadsMedia(image)) return image;
    return _firstPatternMatch(html, [
      RegExp(r'https://[^\s"\\]*cdninstagram\.com[^\s"\\]*\.mp4[^\s"\\]*'),
      RegExp(r'https://[^\s"\\]*fbcdn\.net[^\s"\\]*\.mp4[^\s"\\]*'),
      RegExp(
        r'https://[^\s"\\]*cdninstagram\.com[^\s"\\]*\.(?:jpg|jpeg|png|webp)',
      ),
    ]);
  }

  static bool _isDirectThreadsMedia(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.m3u8') || lower.contains('.mpd')) return false;
    if (lower.contains('threads.net') || lower.contains('threads.com')) {
      return false;
    }
    return (lower.contains('cdninstagram.com') || lower.contains('fbcdn.net')) &&
        (lower.contains('.mp4') ||
            lower.contains('.jpg') ||
            lower.contains('.jpeg') ||
            lower.contains('.png') ||
            lower.contains('.webp') ||
            lower.contains('.gif'));
  }

  /// Direct Snapchat CDN media only — page URLs and HLS are skipped.
  static String? _extractSnapchatMedia(String html) {
    final og = _extractOpenGraphVideo(html);
    if (og != null && _isDirectSnapchatMedia(og)) return og;
    final image = _extractOpenGraphImage(html);
    if (image != null && _isDirectSnapchatMedia(image)) return image;
    return _firstPatternMatch(html, [
      RegExp(r'https://[^\s"\\]*sc-cdn\.net[^\s"\\]*\.mp4[^\s"\\]*'),
      RegExp(r'https://[^\s"\\]*sc-cdn\.net[^\s"\\]*\.(?:jpg|jpeg|png|webp)'),
      RegExp(r'https://[^\s"\\]*sc-cdn\.net/[^\s"\\<>]+'),
    ]);
  }

  static bool _isDirectSnapchatMedia(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return false;
    final lower = url.toLowerCase();
    if (lower.contains('.m3u8') || lower.contains('.mpd')) return false;
    return SnapchatUri.isDirectMediaHost(uri.host);
  }

  /// Direct Telegram CDN media only — t.me page URLs are not files.
  static String? _extractTelegramMedia(String html) {
    final og = _extractOpenGraphVideo(html);
    if (og != null && _isDirectTelegramMedia(og)) return og;
    final image = _extractOpenGraphImage(html);
    if (image != null && _isDirectTelegramMedia(image)) return image;
    return _firstPatternMatch(html, [
      RegExp(r'https://[^\s"\\]*telesco\.pe/file/[^\s"\\]+'),
      RegExp(r'https://[^\s"\\]*telegram-cdn\.org/[^\s"\\]+'),
      RegExp(r'https://cdn\.telegram\.org/file/[^\s"\\]+'),
    ]);
  }

  static bool _isDirectTelegramMedia(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.m3u8') || lower.contains('.mpd')) return false;
    if (lower.contains('t.me') || lower.contains('telegram.me')) return false;
    return lower.contains('telesco.pe') ||
        lower.contains('telegram-cdn.org') ||
        lower.contains('cdn.telegram.org');
  }

  /// Direct public WhatsApp Channel CDN media only — pages, wa.me, and
  /// encrypted `mmg.whatsapp.net` gateways are skipped.
  static String? _extractWhatsAppMedia(String html) {
    final og = _extractOpenGraphVideo(html);
    if (og != null && _isDirectWhatsAppMedia(og)) return og;
    final image = _extractOpenGraphImage(html);
    if (image != null && _isDirectWhatsAppMedia(image)) return image;
    return _firstPatternMatch(html, [
      RegExp(r'https://[^\s"\\]*fbcdn\.net[^\s"\\]*\.(?:jpg|jpeg|png|webp|mp4)'),
      RegExp(
        r'https://[^\s"\\]*lookaside\.fbsbx\.com[^\s"\\]*\.(?:jpg|jpeg|png|webp)',
      ),
    ]);
  }

  static bool _isDirectWhatsAppMedia(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.m3u8') || lower.contains('.mpd')) return false;
    if (lower.contains('wa.me') || lower.contains('whatsapp.com')) return false;
    if (lower.contains('mmg.whatsapp.net') ||
        lower.contains('pps.whatsapp.net')) {
      return false;
    }
    return (lower.contains('fbcdn.net') ||
            lower.contains('lookaside.fbsbx.com') ||
            lower.contains('static.whatsapp.net')) &&
        !lower.contains('/rsrc.php') &&
        (lower.contains('.mp4') ||
            lower.contains('.jpg') ||
            lower.contains('.jpeg') ||
            lower.contains('.png') ||
            lower.contains('.webp') ||
            lower.contains('.gif'));
  }

  /// Direct Vimeo media only — player/embed URLs are not downloadable files.
  static String? _extractVimeoMedia(String html) {
    final og = _extractOpenGraphVideo(html);
    if (og != null && _isDirectVimeoMedia(og)) return og;
    return _firstPatternMatch(html, [
      RegExp(r'https://[^\s"\\]*vimeocdn\.com[^\s"\\]*\.mp4[^\s"\\]*'),
      RegExp(r'https://[^\s"\\]*akamaized\.net[^\s"\\]*\.mp4[^\s"\\]*'),
    ]);
  }

  static bool _isDirectVimeoMedia(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.m3u8') || lower.contains('.mpd')) return false;
    if (lower.contains('player.vimeo.com')) return false;
    return lower.contains('.mp4') ||
        lower.contains('vimeocdn.com') ||
        lower.contains('akamaized.net');
  }

  static bool _isPlaylistUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.m3u8') || lower.contains('.mpd');
  }

  static String? _extractFacebookVideo(String html) {
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
      final match = pattern.firstMatch(html);
      if (match != null) {
        final url = _unescapeJsonUrl(match.group(1)!);
        if (url.startsWith('http')) return url;
      }
    }

    return _firstPatternMatch(html, [
      RegExp(r'https://video[^\s"\\]*\.fbcdn\.net/[^\s"\\]+'),
      RegExp(r'https://scontent[^\s"\\]*\.fbcdn\.net/[^\s"\\]*\.mp4[^\s"\\]*'),
    ]);
  }

  static String? _extractInstagramVideo(String html) {
    return _firstJsonString(html, [
          'video_url',
          'contentUrl',
          'playback_url',
        ]) ??
        _firstPatternMatch(html, [
          RegExp(r'https://[^\s"\\]*cdninstagram\.com[^\s"\\]*\.mp4[^\s"\\]*'),
          RegExp(r'https://[^\s"\\]*fbcdn\.net[^\s"\\]*\.mp4[^\s"\\]*'),
        ]);
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

  static String? _extractYouTubeStream(String html) {
    final playerJson = _extractJsonAfterMarker(html, 'ytInitialPlayerResponse');
    if (playerJson == null) return null;

    try {
      final decoded = jsonDecode(playerJson) as Map<String, dynamic>;
      final streaming = decoded['streamingData'] as Map<String, dynamic>?;
      if (streaming == null) return null;

      for (final key in ['formats', 'adaptiveFormats']) {
        final formats = streaming[key];
        if (formats is! List) continue;
        for (final item in formats) {
          if (item is! Map) continue;
          final url = item['url'];
          if (url is String && url.startsWith('http')) {
            return url;
          }
        }
      }
    } on Object {
      return null;
    }
    return null;
  }

  static String? _extractOpenGraphVideo(String html) {
    return _metaContent(html, 'og:video:url') ??
        _metaContent(html, 'og:video:secure_url') ??
        _metaContent(html, 'og:video');
  }

  static String? _extractOpenGraphImage(String html) {
    return _metaContent(html, 'og:image:url') ??
        _metaContent(html, 'og:image:secure_url') ??
        _metaContent(html, 'og:image');
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
      if (match != null) {
        return _decodeHtmlEntities(match.group(1)!);
      }
    }
    return null;
  }

  static String? _firstJsonString(String html, List<String> fields) {
    for (final field in fields) {
      final pattern = RegExp(
        '"$field"\\s*:\\s*"((?:\\\\.|[^"\\\\])*)"',
        caseSensitive: false,
      );
      final match = pattern.firstMatch(html);
      if (match != null) {
        return _unescapeJsonUrl(match.group(1)!);
      }
    }
    return null;
  }

  static String? _firstPatternMatch(String html, List<RegExp> patterns) {
    for (final pattern in patterns) {
      final match = pattern.firstMatch(html);
      if (match != null) return match.group(0);
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

  static String _buildFileName({
    required Uri pageUrl,
    required SocialPlatform platform,
    required String mediaUrl,
    String? title,
    String? mimeHint,
    String? fallbackSlug,
  }) {
    final mediaUri = Uri.tryParse(mediaUrl);
    final pathName = mediaUri != null && mediaUri.pathSegments.isNotEmpty
        ? p.basename(mediaUri.path)
        : null;
    if (pathName != null && p.extension(pathName).isNotEmpty) {
      return FileNameResolver.sanitize(pathName);
    }

    final slug = _slugFromTitle(title) ??
        fallbackSlug ??
        _slugFromPath(pageUrl) ??
        '${platform.name}_${DateTime.now().millisecondsSinceEpoch}';

    var name = FileNameResolver.sanitize(slug);
    if (p.extension(name).isEmpty) {
      final ext = FileNameResolver.extensionFromMime(mimeHint) ??
          _extensionFromUrl(mediaUrl) ??
          '.mp4';
      name = '$name$ext';
    }
    return name;
  }

  static String? _slugFromTitle(String? title) {
    if (title == null || title.trim().isEmpty) return null;
    var slug = title.trim().toLowerCase();
    slug = slug.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    slug = slug.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
    if (slug.length > 64) slug = slug.substring(0, 64);
    return slug.isEmpty ? null : slug;
  }

  static String? _slugFromPath(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;
    final last = segments.last;
    if (last == 'watch' && uri.queryParameters.containsKey('v')) {
      return uri.queryParameters['v'];
    }
    return last;
  }

  static String? _extensionFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final ext = p.extension(uri.path);
    return ext.isEmpty ? null : ext;
  }

  static String _unescapeJsonUrl(String raw) {
    return raw
        .replaceAll(r'\u0026', '&')
        .replaceAll(r'\u002F', '/')
        .replaceAll(r'\\/', '/')
        .replaceAll(r'\"', '"')
        .replaceAll(r'\\', r'\');
  }

  static String _decodeHtmlEntities(String value) {
    return value
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }
}
