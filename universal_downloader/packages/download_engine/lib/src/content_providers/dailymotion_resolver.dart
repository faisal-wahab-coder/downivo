import 'dart:convert';

import 'package:dio/dio.dart';

import 'dailymotion_cdn_http.dart';
import 'dailymotion_uri.dart';
import 'hls_fmp4_stitcher.dart';
import 'media_extractor.dart';
import 'models/discovered_resource.dart';
import 'social_http_headers.dart';
import 'social_platform.dart';

/// Resolves public Dailymotion videos via player metadata.
///
/// Modern VOD is HLS-only (muxed fMP4). Progressive MP4 `qualities` are used
/// when the player still exposes them.
class DailymotionResolver {
  DailymotionResolver({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<DiscoveredResource?> discover(Uri pageUrl) async {
    final all = await discoverAll(pageUrl);
    return all.isEmpty ? null : all.first;
  }

  Future<List<DiscoveredResource>> discoverAll(Uri pageUrl) async {
    final id =
        DailymotionUri.videoIdFromUri(pageUrl) ??
        DailymotionUri.videoIdFromUri(DailymotionUri.normalize(pageUrl));
    if (id == null) return const [];

    // ignore: avoid_print
    print('DM-RESOLVE $pageUrl id=$id');
    try {
      final data = await _fetchMetadata(id, pageUrl);
      if (data == null) {
        // ignore: avoid_print
        print('DM-META empty id=$id');
        return const [];
      }
      if (data['error'] != null) {
        // ignore: avoid_print
        print('DM-META-ERROR ${data['error']}');
      }
      var formats = _formatsFromQualities(data['qualities']);
      final masterUrl = hlsMasterUrlFromQualities(data['qualities']);
      if (formats.isEmpty && masterUrl != null) {
        formats = await _formatsFromHls(masterUrl, pageUrl: pageUrl);
        if (formats.isEmpty) {
          formats = [
            MediaFormat(
              url: masterUrl,
              label: 'auto',
              mimeType: 'video/mp4',
              isRecommended: true,
            ),
          ];
        }
      }
      // ignore: avoid_print
      print(
        'DM-FORMATS count=${formats.length} '
        'cookie=none '
        'first=${formats.isEmpty ? "-" : formats.first.url}',
      );
      final resource = _fromFormats(
        data,
        pageUrl,
        id,
        formats,
      );
      return resource == null ? const [] : [resource];
    } on Object catch (error) {
      // ignore: avoid_print
      print('DM-ERROR $error');
      return const [];
    }
  }

  /// Headers for Dailymotion HLS / fMP4 segments.
  ///
  /// Do not send `Cookie`. A visitor `v1st` from `www.dailymotion.com` that
  /// does not match `dmV1st` on the signed URL makes `cdndirector` return 403.
  /// HTTP/1.1 without cookies is accepted.
  static Map<String, String> streamHeaders(String streamUrl) {
    return {
      'User-Agent': SocialHttpHeaders.userAgent,
      'Accept': '*/*',
      'Accept-Language': 'en-US,en;q=0.9',
      'Referer': 'https://www.dailymotion.com/',
      'Origin': 'https://www.dailymotion.com',
    };
  }

  /// Kept for call sites that previously minted CDN cookies. Always null.
  Future<String?> refreshSessionCookie(String mediaOrPageUrl) async {
    return null;
  }

  static DiscoveredResource? resourceFromMetadata(
    Map<String, dynamic> data, {
    required Uri pageUrl,
    required String id,
  }) {
    return _fromMetadata(data, pageUrl, id);
  }

  static DiscoveredResource? _fromMetadata(
    Map<String, dynamic> data,
    Uri pageUrl,
    String id,
  ) {
    final formats = _formatsFromQualities(data['qualities']);
    return _fromFormats(data, pageUrl, id, formats);
  }

  static DiscoveredResource? _fromFormats(
    Map<String, dynamic> data,
    Uri pageUrl,
    String id,
    List<MediaFormat> usable,
  ) {
    if (usable.isEmpty) return null;

    final recommended = usable.first;
    final labeled = [
      for (final format in usable)
        MediaFormat(
          url: format.url,
          label: format.label,
          mimeType: format.mimeType,
          height: format.height,
          width: format.width,
          isRecommended: format.url == recommended.url,
        ),
    ];
    final owner = data['owner'];
    final author = owner is Map ? owner['screenname']?.toString() : null;
    final thumb = thumbnailFromMetadata(data);
    final title = data['title']?.toString() ?? id;
    final duration = data['duration'] is num
        ? (data['duration'] as num).toDouble()
        : double.tryParse('${data['duration'] ?? ''}');
    final headers = streamHeaders(recommended.url);

    return DiscoveredResource(
      directUrl: recommended.url,
      fileName: MediaExtractor.buildFileNameForSocial(
        pageUrl: pageUrl,
        platform: SocialPlatform.dailymotion,
        mediaUrl: DailymotionUri.normalize(pageUrl).toString(),
        title: title,
        fallbackSlug: id,
        mimeHint: 'video/mp4',
      ),
      platform: SocialPlatform.dailymotion.label,
      pageUrl: pageUrl.toString(),
      title: title,
      mimeType: 'video/mp4',
      thumbnailUrl: thumb,
      author: author,
      durationSeconds: duration,
      height: recommended.height,
      width: recommended.width,
      kind: DiscoveredResourceKind.video,
      formats: labeled,
      requestHeaders: headers,
    );
  }

  static String? thumbnailFromMetadata(Map<String, dynamic> data) {
    final posters = data['posters'];
    if (posters is List && posters.isNotEmpty && posters.last is Map) {
      final url = (posters.last as Map)['url']?.toString();
      if (url != null && url.startsWith('http')) return url;
    }
    final thumbs = data['thumbnails'];
    if (thumbs is Map && thumbs.isNotEmpty) {
      final ranked = thumbs.keys.toList()
        ..sort((a, b) {
          final aa = int.tryParse(a.toString()) ?? 0;
          final bb = int.tryParse(b.toString()) ?? 0;
          return aa.compareTo(bb);
        });
      final url = thumbs[ranked.last]?.toString();
      if (url != null && url.startsWith('http')) return url;
    }
    return data['thumbnail_url']?.toString();
  }

  static Map<String, dynamic>? mapFromResponse(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return {
        for (final entry in data.entries) entry.key.toString(): entry.value,
      };
    }
    if (data is String && data.trim().startsWith('{')) {
      final decoded = jsonDecode(data);
      if (decoded is Map) {
        return {
          for (final entry in decoded.entries)
            entry.key.toString(): entry.value,
        };
      }
    }
    return null;
  }

  static List<MediaFormat> _formatsFromQualities(Object? raw) {
    if (raw is! Map) return const [];
    final formats = <MediaFormat>[];
    for (final entry in raw.entries) {
      final label = entry.key.toString();
      final items = entry.value;
      if (items is! List) continue;
      for (final item in items) {
        if (item is! Map) continue;
        final url = item['url']?.toString();
        if (url == null || !url.startsWith('http')) continue;
        final type = item['type']?.toString();
        if (type != null && type.toLowerCase().contains('mpegurl')) continue;
        if (HlsFmp4Stitcher.isPlaylistUrl(url)) continue;
        final height = int.tryParse(label);
        formats.add(
          MediaFormat(
            url: url,
            label: height != null ? '${height}p' : label,
            mimeType: type ?? 'video/mp4',
            height: height,
          ),
        );
      }
    }
    formats.sort((a, b) => (b.height ?? 0).compareTo(a.height ?? 0));
    return formats;
  }

  static String? hlsMasterUrlFromQualities(Object? raw) {
    if (raw is! Map) return null;
    for (final entry in raw.entries) {
      final items = entry.value;
      if (items is! List) continue;
      for (final item in items) {
        if (item is! Map) continue;
        final url = item['url']?.toString();
        if (url == null || !url.startsWith('http')) continue;
        final type = item['type']?.toString() ?? '';
        if (type.toLowerCase().contains('mpegurl') ||
            HlsFmp4Stitcher.isPlaylistUrl(url)) {
          return url;
        }
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchMetadata(String id, Uri pageUrl) async {
    final page = DailymotionUri.normalize(pageUrl);
    final headers = {
      'User-Agent': SocialHttpHeaders.userAgent,
      'Accept': 'application/json,text/plain,*/*',
      'Accept-Language': 'en-US,en;q=0.9',
      'Referer': page.toString(),
      'Origin': 'https://www.dailymotion.com',
    };
    final response = await _dio.get<dynamic>(
      'https://www.dailymotion.com/player/metadata/video/$id',
      options: Options(
        followRedirects: true,
        headers: headers,
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    // ignore: avoid_print
    print(
      'DM-META status=${response.statusCode} '
      'type=${response.data.runtimeType}',
    );
    return mapFromResponse(response.data);
  }

  Future<List<MediaFormat>> _formatsFromHls(
    String masterUrl, {
    required Uri pageUrl,
  }) async {
    final headers = DailymotionCdnHttp.withoutCookie(streamHeaders(masterUrl));
    try {
      var status = 0;
      var playlist = '';
      String? contentType;
      try {
        final response = await _dio.getUri<dynamic>(
          Uri.parse(masterUrl),
          options: Options(
            responseType: ResponseType.plain,
            followRedirects: true,
            headers: headers,
            validateStatus: (code) => code != null && code < 500,
          ),
        );
        status = response.statusCode ?? 0;
        playlist = response.data?.toString() ?? '';
        contentType = response.headers.value('content-type');
      } on Object catch (error) {
        // ignore: avoid_print
        print('DM-HLS-DIO $error');
      }
      if (status != 200 ||
          playlist.trim().isEmpty ||
          !playlist.contains('#EXTM3U')) {
        final raw = await DailymotionCdnHttp.get(
          masterUrl,
          headers: headers,
        );
        status = raw.statusCode;
        playlist = raw.text;
        contentType = raw.contentType;
        // ignore: avoid_print
        print(
          'DM-HLS-RAW status=$status len=${raw.bytes.length} ctype=$contentType',
        );
      }
      // ignore: avoid_print
      print(
        'DM-HLS status=$status '
        'len=${playlist.length} '
        'ctype=$contentType '
        'cookie=none',
      );
      if (status != 200 ||
          playlist.trim().isEmpty ||
          !playlist.contains('#EXTM3U')) {
        return const [];
      }
      final variants = HlsFmp4Stitcher.parseMaster(
        playlist,
        playlistUrl: masterUrl,
      );
      if (variants.isEmpty) {
        return [
          MediaFormat(
            url: masterUrl,
            label: 'auto',
            mimeType: 'video/mp4',
            isRecommended: true,
          ),
        ];
      }
      return [
        for (var i = 0; i < variants.length; i++)
          MediaFormat(
            url: variants[i].url,
            label: variants[i].label,
            mimeType: 'video/mp4',
            height: variants[i].height,
            width: variants[i].width,
            isRecommended: i == 0,
          ),
      ];
    } on Object catch (error) {
      // ignore: avoid_print
      print('DM-HLS-ERROR $error');
      return const [];
    }
  }
}
