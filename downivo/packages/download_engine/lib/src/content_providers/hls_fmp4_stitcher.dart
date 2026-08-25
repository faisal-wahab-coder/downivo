import 'package:dio/dio.dart';

import 'dailymotion_cdn_http.dart';

/// Muxed fMP4 HLS (init + `.m4s`) concatenated into a playable MP4.
///
/// Dailymotion VOD no longer exposes progressive MP4 URLs — only this layout.
class HlsFmp4Stitcher {
  HlsFmp4Stitcher({required Dio dio}) : _dio = dio;

  final Dio _dio;

  static bool isPlaylistUrl(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
    return path.contains('.m3u8');
  }

  /// Master playlist variants, highest resolution first.
  static List<HlsVariant> parseMaster(
    String playlist, {
    required String playlistUrl,
  }) {
    final base = Uri.parse(playlistUrl);
    final lines = playlist.split(RegExp(r'\r?\n'));
    final variants = <HlsVariant>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (!line.startsWith('#EXT-X-STREAM-INF:')) continue;
      String? url;
      if (i + 1 < lines.length && !lines[i + 1].trim().startsWith('#')) {
        url = _stripFragment(lines[i + 1].trim());
      }
      if (url == null || url.isEmpty) continue;
      final resolved = base.resolve(url).toString();
      final resolution = RegExp(r'RESOLUTION=(\d+)x(\d+)').firstMatch(line);
      final width = resolution == null
          ? null
          : int.tryParse(resolution.group(1)!);
      final height = resolution == null
          ? null
          : int.tryParse(resolution.group(2)!);
      final name = RegExp(r'NAME="([^"]+)"').firstMatch(line)?.group(1);
      final namedHeight = name == null ? null : int.tryParse(name);
      final label = namedHeight != null
          ? '${namedHeight}p'
          : height != null
          ? '${height}p'
          : (name != null && name.isNotEmpty ? name : 'auto');
      variants.add(
        HlsVariant(url: resolved, label: label, width: width, height: height),
      );
    }
    variants.sort((a, b) => (b.height ?? 0).compareTo(a.height ?? 0));
    return variants;
  }

  /// Init map URI followed by media segment URIs, already resolved.
  static List<String> parseMediaSegmentUrls(
    String playlist, {
    required String playlistUrl,
  }) {
    final base = Uri.parse(playlistUrl);
    final urls = <String>[];
    for (final raw in playlist.split(RegExp(r'\r?\n'))) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('#EXT-X-MAP:')) {
        final uri = _attributeUri(line);
        if (uri != null && uri.isNotEmpty) {
          urls.add(base.resolve(_stripFragment(uri)).toString());
        }
        continue;
      }
      if (line.startsWith('#')) continue;
      urls.add(base.resolve(_stripFragment(line)).toString());
    }
    return urls;
  }

  Future<int> stitch({
    required String playlistUrl,
    required void Function(List<int> chunk) add,
    required Map<String, String> headers,
    required CancelToken cancelToken,
    required Future<void> Function(int received, int done, int total)
    onProgress,
  }) async {
    final playlist = await _getText(playlistUrl, headers, cancelToken);
    if (playlist == null || playlist.trim().isEmpty) {
      throw StateError('Dailymotion playlist was empty.');
    }

    var mediaUrl = playlistUrl;
    var mediaPlaylist = playlist;
    final variants = parseMaster(playlist, playlistUrl: playlistUrl);
    if (variants.isNotEmpty) {
      mediaUrl = variants.first.url;
      mediaPlaylist = await _getText(mediaUrl, headers, cancelToken) ?? '';
      if (mediaPlaylist.trim().isEmpty) {
        throw StateError('Dailymotion media playlist was empty.');
      }
    }

    final segments = parseMediaSegmentUrls(
      mediaPlaylist,
      playlistUrl: mediaUrl,
    );
    if (segments.isEmpty) {
      throw StateError('Dailymotion playlist had no media segments.');
    }

    var received = 0;
    for (var i = 0; i < segments.length; i++) {
      final bytes = await _getBytes(segments[i], headers, cancelToken);
      if (bytes.isEmpty) {
        throw StateError('Dailymotion segment ${i + 1} was empty.');
      }
      add(bytes);
      received += bytes.length;
      await onProgress(received, i + 1, segments.length);
    }
    return received;
  }

  Future<String?> _getText(
    String url,
    Map<String, String> headers,
    CancelToken cancelToken,
  ) async {
    final clean = DailymotionCdnHttp.withoutCookie(headers);
    final host = Uri.tryParse(url)?.host;
    final raw = await DailymotionCdnHttp.get(
      url,
      headers: clean,
      cancelToken: cancelToken,
    );
    // ignore: avoid_print
    print('DM-STITCH-GET ${raw.statusCode} $host len=${raw.bytes.length}');
    if (raw.statusCode == 200 && raw.bytes.isNotEmpty) {
      return raw.text;
    }
    try {
      final response = await _dio.getUri<dynamic>(
        Uri.parse(url),
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: true,
          headers: clean,
          validateStatus: (code) => code != null && code < 500,
        ),
        cancelToken: cancelToken,
      );
      final data = response.data?.toString() ?? '';
      if (response.statusCode == 200 && data.contains('#EXTM3U')) {
        return data;
      }
    } on Object catch (_) {}
    throw StateError('Dailymotion playlist HTTP ${raw.statusCode}.');
  }

  Future<List<int>> _getBytes(
    String url,
    Map<String, String> headers,
    CancelToken cancelToken,
  ) async {
    final clean = DailymotionCdnHttp.withoutCookie(headers);
    final raw = await DailymotionCdnHttp.get(
      url,
      headers: clean,
      cancelToken: cancelToken,
    );
    if (raw.statusCode < 200 || raw.statusCode >= 400 || raw.bytes.isEmpty) {
      throw StateError('Dailymotion segment HTTP ${raw.statusCode}.');
    }
    return raw.bytes;
  }

  static String _stripFragment(String value) {
    final hash = value.indexOf('#');
    return hash == -1 ? value : value.substring(0, hash);
  }

  static String? _attributeUri(String line) {
    final quoted = RegExp(r'URI="([^"]+)"').firstMatch(line);
    if (quoted != null) return quoted.group(1);
    final bare = RegExp(r'URI=([^,]+)').firstMatch(line);
    return bare?.group(1);
  }
}

class HlsVariant {
  const HlsVariant({
    required this.url,
    required this.label,
    this.width,
    this.height,
  });

  final String url;
  final String label;
  final int? width;
  final int? height;
}
