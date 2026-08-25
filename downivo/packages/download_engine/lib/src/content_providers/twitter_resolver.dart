import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';

import 'media_extractor.dart';
import 'models/discovered_resource.dart';
import 'social_http_headers.dart';
import 'social_platform.dart';
import 'social_url_utils.dart';

/// Resolves X/Twitter status URLs via the public syndication endpoint.
class TwitterResolver {
  TwitterResolver({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<DiscoveredResource?> discover(Uri pageUrl) async {
    final tweetId = TwitterUri.tweetIdFromUri(pageUrl);
    if (tweetId == null) return null;

    final syndication = await _fetchSyndication(tweetId);
    if (syndication != null) return syndication.copyWith(pageUrl: pageUrl.toString());

    final embedHtml = await _fetchEmbedHtml(tweetId);
    if (embedHtml == null) return null;

    final mediaUrl = _extractVideoUrlFromHtml(embedHtml);
    if (mediaUrl == null) return null;

    return DiscoveredResource(
      directUrl: mediaUrl,
      fileName: MediaExtractor.buildFileNameForSocial(
        pageUrl: pageUrl,
        platform: SocialPlatform.twitter,
        mediaUrl: mediaUrl,
        fallbackSlug: tweetId,
        mimeHint: 'video/mp4',
      ),
      platform: SocialPlatform.twitter.label,
      pageUrl: pageUrl.toString(),
      mimeType: 'video/mp4',
    );
  }

  static String syndicationToken(String tweetId) {
    final value = (double.parse(tweetId) / 1e15) * math.pi;
    return value.toString().replaceAll(RegExp(r'0+|\.'), '');
  }

  static String? tweetIdFromUri(Uri uri) => TwitterUri.tweetIdFromUri(uri);

  Future<DiscoveredResource?> _fetchSyndication(String tweetId) async {
    try {
      final token = syndicationToken(tweetId);
      final url =
          'https://cdn.syndication.twimg.com/tweet-result?id=$tweetId&token=$token';
      final response = await _dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (status) => status != null && status >= 200 && status < 400,
          headers: {
            'User-Agent': SocialHttpHeaders.userAgent,
            'Accept': 'application/json',
          },
        ),
      );

      final body = response.data;
      if (body == null || body.isEmpty) return null;
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;
      return _parseSyndicationPayload(
        tweetId: tweetId,
        payload: decoded,
      );
    } on Object {
      return null;
    }
  }

  static DiscoveredResource? _parseSyndicationPayload({
    required String tweetId,
    required Map<String, dynamic> payload,
  }) {
    final mediaUrl = _videoFromSyndication(payload);
    if (mediaUrl == null) return null;

    final text = payload['text']?.toString();
    return DiscoveredResource(
      directUrl: mediaUrl,
      fileName: MediaExtractor.buildFileNameForSocial(
        pageUrl: Uri.parse('https://x.com/i/status/$tweetId'),
        platform: SocialPlatform.twitter,
        mediaUrl: mediaUrl,
        title: text,
        fallbackSlug: tweetId,
        mimeHint: 'video/mp4',
      ),
      platform: SocialPlatform.twitter.label,
      title: text,
      mimeType: 'video/mp4',
    );
  }

  static String? _videoFromSyndication(Map<String, dynamic> payload) {
    final video = payload['video'];
    if (video is Map<String, dynamic>) {
      final variants = video['variants'];
      if (variants is List) {
        String? best;
        var bestBitrate = -1;
        for (final variant in variants) {
          if (variant is! Map) continue;
          final url = variant['url'];
          final contentType = variant['content_type']?.toString() ?? '';
          if (url is! String || !url.startsWith('http')) continue;
          if (!contentType.contains('mp4')) continue;
          final bitrate = variant['bitrate'];
          final parsed = bitrate is int ? bitrate : int.tryParse('$bitrate') ?? 0;
          if (parsed >= bestBitrate) {
            bestBitrate = parsed;
            best = url;
          }
        }
        if (best != null) return best;
      }
    }

    final entities = payload['entities'];
    if (entities is Map<String, dynamic>) {
      final media = entities['media'];
      if (media is List) {
        for (final item in media) {
          if (item is! Map) continue;
          final videoInfo = item['video_info'];
          if (videoInfo is Map) {
            final variants = videoInfo['variants'];
            if (variants is List && variants.isNotEmpty) {
              for (final variant in variants) {
                if (variant is Map &&
                    variant['url'] is String &&
                    (variant['content_type']?.toString().contains('mp4') ??
                        false)) {
                  return variant['url'] as String;
                }
              }
            }
          }
        }
      }
    }

    return null;
  }

  Future<String?> _fetchEmbedHtml(String tweetId) async {
    try {
      final response = await _dio.get<String>(
        'https://platform.twitter.com/embed/Tweet.html?id=$tweetId',
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (status) => status != null && status >= 200 && status < 400,
          headers: SocialHttpHeaders.forPageFetch(
            Uri.parse('https://x.com/'),
            SocialPlatform.twitter,
          ),
        ),
      );
      return response.data;
    } on DioException {
      return null;
    }
  }

  static String? _extractVideoUrlFromHtml(String html) {
    final pattern = RegExp(r'https://video\.twimg\.com/[^\s"\\]+');
    final match = pattern.firstMatch(html);
    return match?.group(0);
  }

  /// Parses syndication JSON — exposed for unit tests.
  static DiscoveredResource? parseSyndicationPayload({
    required String tweetId,
    required Map<String, dynamic> payload,
  }) {
    return _parseSyndicationPayload(tweetId: tweetId, payload: payload);
  }
}
