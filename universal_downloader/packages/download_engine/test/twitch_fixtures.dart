import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

const twitchClipSlug = 'AwkwardHelplessSalamanderSwiftRage';
const twitchVodId = '123456789';
const twitchChannel = 'shroud';

Map<String, dynamic> twitchClipQuality({
  required String quality,
  required String url,
  double frameRate = 30,
}) {
  return {
    'frameRate': frameRate,
    'quality': quality,
    'sourceURL': url,
  };
}

Map<String, dynamic> twitchClip({
  String slug = twitchClipSlug,
  String id = 'clip-1',
  String title = 'Perfect dodge',
  String? description,
  double durationSeconds = 32.1,
  String createdAt = '2017-11-20T00:00:00Z',
  String channelLogin = 'lirik',
  String channelId = '37402112',
  String channelName = 'LIRIK',
  String creator = 'Viewer1',
  String category = 'Just Chatting',
  bool includeQualities = true,
  bool includeHls = false,
  String? tokenValue,
  String signature = 'sigvalue',
  List<Map<String, dynamic>>? qualities,
}) {
  final videoQualities = <Map<String, dynamic>>[];
  if (includeQualities) {
    videoQualities.addAll(
      qualities ??
          [
            twitchClipQuality(
              quality: '1080',
              url:
                  'https://production.assets.clips.twitchcdn.net/clip_1080.mp4',
              frameRate: 60,
            ),
            twitchClipQuality(
              quality: '720',
              url:
                  'https://production.assets.clips.twitchcdn.net/clip_720.mp4',
            ),
            twitchClipQuality(
              quality: '480',
              url:
                  'https://production.assets.clips.twitchcdn.net/clip_480.mp4',
            ),
            twitchClipQuality(
              quality: '360',
              url:
                  'https://production.assets.clips.twitchcdn.net/clip_360.mp4',
            ),
            twitchClipQuality(
              quality: '160',
              url:
                  'https://production.assets.clips.twitchcdn.net/clip_160.mp4',
            ),
          ],
    );
  }
  if (includeHls) {
    videoQualities.add(
      twitchClipQuality(
        quality: '1080',
        url: 'https://production.assets.clips.twitchcdn.net/clip.m3u8',
      ),
    );
  }

  return {
    'id': id,
    'slug': slug,
    'title': title,
    if (description != null) 'description': description,
    'durationSeconds': durationSeconds,
    'createdAt': createdAt,
    'url': 'https://clips.twitch.tv/$slug',
    'thumbnailURL':
        'https://clips-media-assets2.twitch.tv/$slug-preview.jpg',
    'broadcaster': {
      'id': channelId,
      'login': channelLogin,
      'displayName': channelName,
    },
    'curator': {
      'login': 'viewer1',
      'displayName': creator,
    },
    'game': {
      'id': '1',
      'name': category,
    },
    'videoQualities': videoQualities,
    'playbackAccessToken': {
      'signature': signature,
      'value': tokenValue ??
          jsonEncode({
            'authorization': {'forbidden': false},
          }),
      },
  };
}

Map<String, dynamic> twitchClipPayload({
  Map<String, dynamic>? clip,
}) {
  return {
    'data': {'clip': clip ?? twitchClip()},
  };
}

Map<String, dynamic> twitchMissingClipPayload() {
  return {
    'data': {'clip': null},
  };
}

Map<String, dynamic> twitchRestrictedClipPayload() {
  return twitchClipPayload(
    clip: twitchClip(
      tokenValue: jsonEncode({
        'authorization': {
          'forbidden': true,
          'reason': 'UNAUTHORIZED_ENTITLEMENTS',
        },
      }),
    ),
  );
}

Map<String, dynamic> twitchHlsOnlyClipPayload() {
  return twitchClipPayload(
    clip: twitchClip(includeQualities: false, includeHls: true),
  );
}

Map<String, dynamic> twitchVideo({
  String id = twitchVodId,
  String title = 'Ranked grind',
  String? description = 'Day 12',
  int lengthSeconds = 3600,
  String channelLogin = twitchChannel,
  String channelId = '37402112',
  String channelName = 'shroud',
  String category = 'VALORANT',
  String broadcastType = 'ARCHIVE',
  String status = 'RECORDED',
  String createdAt = '2024-01-01T00:00:00Z',
}) {
  return {
    'id': id,
    'title': title,
    if (description != null) 'description': description,
    'lengthSeconds': lengthSeconds,
    'createdAt': createdAt,
    'publishedAt': createdAt,
    'previewThumbnailURL':
        'https://static-cdn.jtvnw.net/cf_vods/$id-thumb.jpg',
    'url': 'https://www.twitch.tv/videos/$id',
    'owner': {
      'id': channelId,
      'login': channelLogin,
      'displayName': channelName,
    },
    'game': {'id': '2', 'name': category},
    'broadcastType': broadcastType,
    'status': status,
  };
}

Map<String, dynamic> twitchVideoPayload({
  Map<String, dynamic>? video,
}) {
  return {
    'data': {'video': video ?? twitchVideo()},
  };
}

Map<String, dynamic> twitchHighlightPayload() {
  return twitchVideoPayload(
    video: twitchVideo(
      id: '555',
      title: 'Best play',
      broadcastType: 'HIGHLIGHT',
      lengthSeconds: 120,
    ),
  );
}

Map<String, dynamic> twitchMissingVideoPayload() {
  return {
    'data': {'video': null},
  };
}

Map<String, dynamic> twitchUser({
  String login = twitchChannel,
  String id = '37402112',
  String displayName = 'shroud',
  String? description = 'Streamer',
  bool live = false,
  String streamTitle = 'Radiant only',
  String category = 'VALORANT',
  int viewers = 12000,
}) {
  return {
    'id': id,
    'login': login,
    'displayName': displayName,
    if (description != null) 'description': description,
    'profileImageURL':
        'https://static-cdn.jtvnw.net/jtv_user_pictures/$login.png',
    'stream': live
        ? {
            'id': 'live-1',
            'title': streamTitle,
            'type': 'live',
            'createdAt': '2026-08-15T00:00:00Z',
            'viewersCount': viewers,
            'previewImageURL':
                'https://static-cdn.jtvnw.net/previews-ttv/$login.jpg',
            'game': {'id': '2', 'name': category},
          }
        : null,
    'broadcastSettings': {
      'title': streamTitle,
      'game': {'name': category},
    },
  };
}

Map<String, dynamic> twitchUserPayload({
  Map<String, dynamic>? user,
}) {
  return {
    'data': {'user': user ?? twitchUser()},
  };
}

Map<String, dynamic> twitchMissingUserPayload() {
  return {
    'data': {'user': null},
  };
}

String twitchHlsMaster({
  bool includeSource = true,
  List<String> heights = const ['1080', '720', '480', '360', '160'],
}) {
  final buffer = StringBuffer('#EXTM3U\n');
  if (includeSource) {
    buffer.writeln(
      '#EXT-X-STREAM-INF:BANDWIDTH=8000000,RESOLUTION=1920x1080,'
      'CODECS="avc1.64002A,mp4a.40.2"',
    );
    buffer.writeln('https://d2e2.hls.twitch.tv/chunked/index-dvr.m3u8');
  }
  for (final height in heights) {
    final width = switch (height) {
      '1080' => 1920,
      '720' => 1280,
      '480' => 852,
      '360' => 640,
      '160' => 284,
      _ => 640,
    };
    buffer.writeln(
      '#EXT-X-STREAM-INF:BANDWIDTH=${height}000,RESOLUTION=${width}x$height',
    );
    buffer.writeln(
      'https://d2e2.hls.twitch.tv/${height}p30/index-dvr.m3u8',
    );
  }
  buffer.writeln('#EXT-X-STREAM-INF:BANDWIDTH=64000,CODECS="mp4a.40.2"');
  buffer.writeln('https://d2e2.hls.twitch.tv/audio_only/index-dvr.m3u8');
  return buffer.toString();
}

class TwitchMockAdapter implements HttpClientAdapter {
  static String gqlResponse = '';
  static String htmlResponse = '';
  static int statusCode = 200;
  static bool throwError = false;
  static DioExceptionType exceptionType = DioExceptionType.connectionError;
  static Map<String, String> gqlByOperation = {};

  static void reset() {
    gqlResponse = '';
    htmlResponse = '';
    statusCode = 200;
    throwError = false;
    exceptionType = DioExceptionType.connectionError;
    gqlByOperation = {};
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (throwError) {
      throw DioException(
        requestOptions: options,
        type: exceptionType,
      );
    }

    if (statusCode >= 400) {
      throw DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: statusCode,
          data: '',
        ),
        type: DioExceptionType.badResponse,
      );
    }

    final host = options.uri.host.toLowerCase();
    if (host.contains('gql.twitch.tv')) {
      final body = _selectGqlBody(options);
      return ResponseBody.fromString(
        body,
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json; charset=utf-8'],
        },
      );
    }

    return ResponseBody.fromString(
      htmlResponse,
      200,
      headers: {
        Headers.contentTypeHeader: ['text/html; charset=utf-8'],
      },
    );
  }

  static String _selectGqlBody(RequestOptions options) {
    final data = options.data;
    var encoded = '';
    if (data is String) {
      encoded = data;
    } else if (data != null) {
      encoded = jsonEncode(data);
    }
    final lower = encoded.toLowerCase();
    if (gqlByOperation.isNotEmpty) {
      if (lower.contains('clipinfo') || lower.contains('clip(')) {
        return gqlByOperation['clip'] ?? gqlResponse;
      }
      if (lower.contains('videoinfo') || lower.contains('video(')) {
        return gqlByOperation['video'] ?? gqlResponse;
      }
      if (lower.contains('userinfo') || lower.contains('user(')) {
        return gqlByOperation['user'] ?? gqlResponse;
      }
    }
    if (gqlResponse.isNotEmpty) return gqlResponse;
    if (lower.contains('clip')) return jsonEncode(twitchClipPayload());
    if (lower.contains('video')) return jsonEncode(twitchVideoPayload());
    if (lower.contains('user')) return jsonEncode(twitchUserPayload());
    return '{}';
  }

  @override
  void close({bool force = false}) {}
}
