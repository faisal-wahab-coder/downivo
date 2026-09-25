import 'dart:convert';

import 'package:dio/dio.dart';

import 'media_extractor.dart';
import 'models/discovered_resource.dart';
import 'social_http_headers.dart';
import 'social_platform.dart';
import 'social_url_utils.dart';
import 'social_session_utils.dart';

/// Resolves YouTube watch URLs to direct googlevideo.com streams.
class YouTubeResolver {
  YouTubeResolver({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const _preferredItags = [22, 18, 37, 136, 135, 134, 399, 401, 313];
  static const _androidClientVersion = '20.10.38';

  Future<DiscoveredResource?> discover(Uri pageUrl) async {
    final videoId = YouTubeUri.videoIdFromUri(pageUrl);
    if (videoId == null) return null;

    final fromApi = await _discoverFromInnertube(videoId, pageUrl);
    if (fromApi != null) return fromApi;

    final targets = [
      Uri.parse('https://www.youtube.com/watch?v=$videoId'),
      Uri.parse('https://m.youtube.com/watch?v=$videoId'),
    ];

    for (final target in targets) {
      final html = await _fetchHtml(target);
      if (html == null || html.isEmpty) continue;

      final player = _playerResponseMap(html);
      final streaming = player == null
          ? null
          : _streamingFromPlayerData(player);
      final mediaUrl = streaming?.url ??
          _extractFromHtml(html) ??
          _extractFromPlayerResponse(html);
      if (mediaUrl == null) continue;

      final details = player?['videoDetails'];
      return _resource(
        pageUrl: pageUrl,
        videoId: videoId,
        mediaUrl: mediaUrl,
        title: _titleFromDetails(details) ?? _metaTitle(html) ?? videoId,
        author: _authorFromDetails(details),
        durationSeconds: _durationFromDetails(details),
        thumbnailUrl: _thumbnailFromDetails(details) ??
            _metaContent(html, 'og:image'),
        formats: streaming?.formats ?? const [],
      );
    }
    return null;
  }

  Future<DiscoveredResource?> _discoverFromInnertube(
    String videoId,
    Uri pageUrl,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://www.youtube.com/youtubei/v1/player?prettyPrint=false',
        data: {
          'context': {
            'client': {
              'clientName': 'ANDROID',
              'clientVersion': _androidClientVersion,
              'androidSdkVersion': 34,
              'osName': 'Android',
              'osVersion': '14',
              'platform': 'MOBILE',
              'hl': 'en',
              'gl': 'US',
            },
          },
          'videoId': videoId,
          'contentCheckOk': true,
          'racyCheckOk': true,
        },
        options: Options(
          headers: {
            'User-Agent': SocialHttpHeaders.youtubeAndroidUserAgent,
            'Content-Type': 'application/json',
            'X-YouTube-Client-Name': '3',
            'X-YouTube-Client-Version': _androidClientVersion,
          },
        ),
      );

      final data = response.data;
      if (data == null) return null;
      final status = data['playabilityStatus'];
      if (status is Map && status['status'] != 'OK') return null;

      final streaming = _streamingFromPlayerData(data);
      if (streaming == null) return null;

      final details = data['videoDetails'];
      return _resource(
        pageUrl: pageUrl,
        videoId: videoId,
        mediaUrl: streaming.url,
        title: _titleFromDetails(details) ?? videoId,
        author: _authorFromDetails(details),
        durationSeconds: _durationFromDetails(details),
        thumbnailUrl: _thumbnailFromDetails(details),
        formats: streaming.formats,
      );
    } on DioException {
      return null;
    }
  }

  DiscoveredResource _resource({
    required Uri pageUrl,
    required String videoId,
    required String mediaUrl,
    required String title,
    String? author,
    double? durationSeconds,
    String? thumbnailUrl,
    List<MediaFormat> formats = const [],
  }) {
    final labeled = formats
        .map(
          (f) => MediaFormat(
            url: f.url,
            label: f.label,
            mimeType: f.mimeType,
            height: f.height,
            width: f.width,
            bitrate: f.bitrate,
            sizeBytes: f.sizeBytes,
            isRecommended:
                f.track != MediaFormatTrack.audio && f.url == mediaUrl,
            track: f.track,
            extractAudio: f.extractAudio,
          ),
        )
        .toList();
    final selected = labeled.where((f) => f.isRecommended).toList();
    final picked = selected.isNotEmpty ? selected.first : null;
    return DiscoveredResource(
      directUrl: mediaUrl,
      fileName: MediaExtractor.buildFileNameForSocial(
        pageUrl: pageUrl,
        platform: SocialPlatform.youtube,
        mediaUrl: mediaUrl,
        title: title,
        fallbackSlug: videoId,
        mimeHint: picked?.mimeType ?? 'video/mp4',
      ),
      platform: SocialPlatform.youtube.label,
      pageUrl: pageUrl.toString(),
      title: title,
      mimeType: picked?.mimeType ?? 'video/mp4',
      thumbnailUrl: thumbnailUrl,
      author: author,
      durationSeconds: durationSeconds,
      width: picked?.width,
      height: picked?.height,
      contentLengthBytes: picked?.sizeBytes,
      kind: DiscoveredResourceKind.video,
      formats: labeled,
    );
  }

  static String? videoIdFromUri(Uri uri) => YouTubeUri.videoIdFromUri(uri);

  /// Extracts a googlevideo URL from HTML — exposed for unit tests.
  static String? extractFromHtmlForTest(String html) => _extractFromHtml(html);

  Future<String?> _fetchHtml(Uri url) async {
    try {
      final response = await _dio.get<String>(
        url.toString(),
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: true,
          validateStatus: (status) => status != null && status >= 200 && status < 400,
          headers: SocialHttpHeaders.forPageFetch(url, SocialPlatform.youtube),
        ),
      );
      return response.data;
    } on DioException {
      return null;
    }
  }

  static String? _extractFromHtml(String html) {
    final matches = <String>[];
    final starts = RegExp(
      r'https://rr[0-9]+---[^\s"]+?googlevideo\.com/videoplayback',
      caseSensitive: false,
    );
    for (final match in starts.allMatches(html)) {
      final raw = _consumeEmbeddedUrl(html, match.start);
      if (raw == null) continue;
      final url = SocialSessionUtils.decodeEmbeddedUrl(raw);
      if (_isDownloadablePlayback(url)) {
        matches.add(url);
      }
    }

    final streamingUrl = RegExp(
      r'"streamingUrl"\s*:\s*"((?:\\.|[^"\\])*)"',
    );
    for (final match in streamingUrl.allMatches(html)) {
      final url = SocialSessionUtils.decodeEmbeddedUrl(match.group(1)!);
      if (_isDownloadablePlayback(url)) {
        matches.add(url);
      }
    }

    if (matches.isEmpty) return null;
    return _pickBestGoogleVideoUrl(matches);
  }

  /// Reads past JSON `\u0026` escapes so query params are not truncated.
  static String? _consumeEmbeddedUrl(String html, int start) {
    final buffer = StringBuffer();
    for (var i = start; i < html.length; i++) {
      final char = html[i];
      if (char == '"' ||
          char == "'" ||
          char == '<' ||
          char == '>' ||
          char == ' ' ||
          char == '\n' ||
          char == '\r' ||
          char == '\t') {
        break;
      }
      if (char == '\\' && i + 5 < html.length && html[i + 1] == 'u') {
        buffer.write(html.substring(i, i + 6));
        i += 5;
        continue;
      }
      if (char == '\\') break;
      buffer.write(char);
    }
    final url = buffer.toString();
    return url.contains('videoplayback') ? url : null;
  }

  static String? _extractFromPlayerResponse(String html) {
    final decoded = _playerResponseMap(html);
    if (decoded == null) return null;
    return _pickFromStreamingData(decoded['streamingData']);
  }

  static Map<String, dynamic>? _playerResponseMap(String html) {
    final marker = 'ytInitialPlayerResponse';
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
          try {
            return jsonDecode(html.substring(braceStart, i + 1))
                as Map<String, dynamic>;
          } on Object {
            return null;
          }
        }
      }
    }
    return null;
  }

  /// Progressive video plus an M4A extracted from that same file, for tests.
  static List<MediaFormat> formatsFromStreamingDataForTest(
    Object? streamingData,
  ) {
    return _parseStreaming(streamingData).formats;
  }

  static _StreamingPick? _streamingFromPlayerData(Map<String, dynamic> data) {
    final parsed = _parseStreaming(data['streamingData']);
    if (parsed.urlsByItag.isEmpty) {
      final url = _pickFromStreamingData(data['streamingData']);
      if (url == null) return null;
      return _StreamingPick(url: url, formats: const []);
    }
    final best = _pickBestByItag(parsed.urlsByItag) ??
        parsed.formats.firstOrNull?.url ??
        parsed.urlsByItag.keys.firstOrNull;
    if (best == null) return null;
    return _StreamingPick(url: best, formats: parsed.formats);
  }

  static _ParsedStreaming _parseStreaming(Object? streamingData) {
    if (streamingData is! Map) {
      return const _ParsedStreaming(urlsByItag: {}, formats: []);
    }
    final seen = <String>{};
    final muxed = <MediaFormat>[];
    final videoOnly = <MediaFormat>[];
    final urlsByItag = <String, int>{};

    for (final key in ['formats', 'adaptiveFormats']) {
      final items = streamingData[key];
      if (items is! List) continue;
      for (final item in items) {
        if (item is! Map) continue;
        final url = item['url'];
        if (url is! String || !url.startsWith('http')) continue;
        if (url.contains('sabr=')) continue;
        if (!seen.add(url)) continue;
        final rawMime = item['mimeType']?.toString();
        final mime = rawMime?.split(';').first.toLowerCase();
        final itag = int.tryParse('${item['itag']}') ??
            int.tryParse(Uri.tryParse(url)?.queryParameters['itag'] ?? '') ??
            0;
        urlsByItag[url] = itag;
        final height =
            item['height'] is num ? (item['height'] as num).toInt() : null;
        final width =
            item['width'] is num ? (item['width'] as num).toInt() : null;
        final bitrate =
            item['bitrate'] is num ? (item['bitrate'] as num).toInt() : null;
        final size = item['contentLength'] == null
            ? null
            : int.tryParse('${item['contentLength']}');
        final qualityLabel = item['qualityLabel']?.toString();
        final kind = _trackKind(itag, rawMime, mime);

        if (kind == _YtTrack.audio) continue;

        final format = MediaFormat(
          url: url,
          label: _labelForItag(
            itag,
            qualityLabel: qualityLabel,
            height: height,
            mime: mime,
          ),
          mimeType: mime,
          height: height,
          width: width,
          bitrate: bitrate,
          sizeBytes: size,
        );
        if (kind == _YtTrack.muxed) {
          muxed.add(format);
        } else if (kind == _YtTrack.videoOnly) {
          videoOnly.add(format);
        }
      }
    }

    final videos = muxed.isNotEmpty ? muxed : videoOnly;
    final source = _bestMuxed(muxed);
    final audio = source == null
        ? const <MediaFormat>[]
        : [
            MediaFormat(
              url: source.url,
              label: 'M4A',
              mimeType: 'audio/mp4',
              track: MediaFormatTrack.audio,
              extractAudio: true,
            ),
          ];
    return _ParsedStreaming(
      urlsByItag: urlsByItag,
      formats: [...videos, ...audio],
    );
  }

  /// Separate googlevideo audio URLs are often rejected with 403.
  /// Save audio by copying the track out of the muxed file that already downloads.
  static MediaFormat? _bestMuxed(List<MediaFormat> muxed) {
    if (muxed.isEmpty) return null;
    for (final itag in _preferredItags) {
      for (final format in muxed) {
        final value = int.tryParse(
              Uri.tryParse(format.url)?.queryParameters['itag'] ?? '',
            ) ??
            0;
        if (value == itag) return format;
      }
    }
    return muxed.first;
  }

  static _YtTrack _trackKind(int itag, String? rawMime, String? mime) {
    final lower = rawMime?.toLowerCase() ?? '';
    if (mime != null && mime.startsWith('audio/')) return _YtTrack.audio;
    if (_audioItags.contains(itag)) return _YtTrack.audio;
    if (mime != null && mime.startsWith('video/')) {
      if (_muxedItags.contains(itag)) return _YtTrack.muxed;
      if (lower.contains('mp4a') ||
          lower.contains('opus') ||
          lower.contains('vorbis')) {
        return _YtTrack.muxed;
      }
      return _YtTrack.videoOnly;
    }
    return _YtTrack.other;
  }

  static const _muxedItags = {18, 22, 37, 38, 59, 78};
  static const _audioItags = {139, 140, 141, 171, 172, 249, 250, 251, 256, 258};

  static String _labelForItag(
    int itag, {
    String? qualityLabel,
    int? height,
    String? mime,
  }) {
    if (qualityLabel != null && qualityLabel.isNotEmpty) {
      return qualityLabel;
    }
    if (height != null && height > 0) {
      final audio = mime?.startsWith('audio/') == true ? ' audio' : '';
      return '${height}p$audio';
    }
    return switch (itag) {
      22 => '720p',
      18 => '360p',
      37 => '1080p',
      136 => '720p',
      135 => '480p',
      134 => '360p',
      140 => 'Audio m4a',
      251 => 'Audio opus',
      _ => 'Stream $itag',
    };
  }

  static String? _titleFromDetails(Object? details) {
    if (details is! Map) return null;
    final title = details['title']?.toString();
    return title == null || title.isEmpty ? null : title;
  }

  static String? _authorFromDetails(Object? details) {
    if (details is! Map) return null;
    final author = details['author']?.toString();
    return author == null || author.isEmpty ? null : author;
  }

  static double? _durationFromDetails(Object? details) {
    if (details is! Map) return null;
    return double.tryParse('${details['lengthSeconds'] ?? ''}');
  }

  static String? _thumbnailFromDetails(Object? details) {
    if (details is! Map) return null;
    final thumb = details['thumbnail'];
    if (thumb is! Map) return null;
    final thumbs = thumb['thumbnails'];
    if (thumbs is! List || thumbs.isEmpty) return null;
    final last = thumbs.last;
    if (last is Map && last['url'] is String) return last['url'] as String;
    return null;
  }

  static String? _metaContent(String html, String property) {
    final pattern = RegExp(
      '<meta[^>]+property=["\']$property["\'][^>]+content=["\']([^"\']+)["\']',
      caseSensitive: false,
    );
    return pattern.firstMatch(html)?.group(1);
  }

  static String? _pickFromStreamingData(Object? streamingData) {
    if (streamingData is! Map) return null;
    final urls = <String, int>{};
    final data = streamingData;

    for (final key in ['formats', 'adaptiveFormats']) {
      final formats = data[key];
      if (formats is! List) continue;
      for (final item in formats) {
        if (item is! Map) continue;
        final url = item['url'];
        if (url is! String || !url.startsWith('http')) continue;
        if (url.contains('sabr=')) continue;
        final itag = int.tryParse('${item['itag']}') ??
            int.tryParse(Uri.tryParse(url)?.queryParameters['itag'] ?? '') ??
            0;
        urls[url] = itag;
      }
    }

    if (urls.isEmpty) return null;
    return _pickBestByItag(urls);
  }

  static bool _isDownloadablePlayback(String url) {
    if (!url.startsWith('http') || !url.contains('videoplayback')) {
      return false;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final params = uri.queryParameters;
    if (params.containsKey('sabr') || params['mime'] == 'application/vnd.yt-ump') {
      return false;
    }
    return params.containsKey('itag') || params.containsKey('sig');
  }

  static String? _pickBestGoogleVideoUrl(List<String> urls) {
    final byItag = <String, int>{};
    for (final url in urls) {
      final uri = Uri.tryParse(url);
      final itag = int.tryParse(uri?.queryParameters['itag'] ?? '') ?? 0;
      byItag[url] = itag;
    }
    return _pickBestByItag(byItag);
  }

  static String? _pickBestByItag(Map<String, int> urlsByItag) {
    for (final itag in _preferredItags) {
      for (final entry in urlsByItag.entries) {
        if (entry.value == itag) return entry.key;
      }
    }
    return urlsByItag.keys.firstOrNull;
  }

  static String? _metaTitle(String html) {
    final pattern = RegExp(
      '<meta[^>]+property=["\']og:title["\'][^>]+content=["\']([^"\']+)["\']',
      caseSensitive: false,
    );
    return pattern.firstMatch(html)?.group(1);
  }
}

enum _YtTrack { muxed, videoOnly, audio, other }

class _ParsedStreaming {
  const _ParsedStreaming({required this.urlsByItag, required this.formats});

  final Map<String, int> urlsByItag;
  final List<MediaFormat> formats;
}

class _StreamingPick {
  const _StreamingPick({required this.url, required this.formats});

  final String url;
  final List<MediaFormat> formats;
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
