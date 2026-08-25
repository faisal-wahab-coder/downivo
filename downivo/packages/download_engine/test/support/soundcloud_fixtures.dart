import 'dart:convert';

import 'package:dio/dio.dart';

/// Deterministic SoundCloud HTML / API fixtures. No live network.
const soundCloudTestClientId = 'TESTCLIENTID1234567890AB';

const soundCloudCdnTrack = 'https://cf-media.sndcdn.com/test-track.mp3';
const soundCloudCdnTrackOne = 'https://cf-media.sndcdn.com/track-one.mp3';
const soundCloudCdnTrackTwo = 'https://cf-media.sndcdn.com/track-two.mp3';
const soundCloudCdnTrackThree = 'https://cf-media.sndcdn.com/track-three.mp3';
const soundCloudCdnFallback = 'https://cf-media.sndcdn.com/fallback.mp3';
const soundCloudCdnM4a = 'https://cf-media.sndcdn.com/hq-track.m4a';
const soundCloudCdnOfficial = 'https://cf-media.sndcdn.com/official-download.mp3';

String soundCloudTrackHtml({
  String artist = 'test-artist',
  String slug = 'test-track',
  Map<String, dynamic>? trackOverrides,
}) {
  final data = Map<String, dynamic>.from(_baseTrackData(artist, slug))
    ..addAll(trackOverrides ?? const {});
  return '''
<html>
<head>
<meta property="og:title" content="${data['title']} by Test Artist">
<meta property="og:image" content="https://i1.sndcdn.com/artworks-000123-large.jpg">
</head>
<body>
<script>window.SC={client_id:"$soundCloudTestClientId"};</script>
<script>window.__sc_hydration = ${jsonEncode([
        {'hydratable': 'sound', 'data': data},
      ])};</script>
</body>
</html>
''';
}

String soundCloudPlaylistHtml({
  List<Map<String, dynamic>>? tracks,
  bool includeStubs = false,
}) {
  final items = tracks ??
      [
        _playlistTrack(111, 'Track One', 'track-one'),
        _playlistTrack(222, 'Track Two', 'track-two'),
        _playlistTrack(333, 'Track Three', 'track-three'),
      ];
  if (includeStubs) {
    items.add({'id': 444, 'kind': 'track'});
  }
  return '''
<html>
<head>
<meta property="og:title" content="Test Playlist by Test Artist">
</head>
<body>
<script>window.SC={client_id:"$soundCloudTestClientId"};</script>
<script>window.__sc_hydration = ${jsonEncode([
        {
          'hydratable': 'playlist',
          'data': {
            'id': 987654321,
            'title': 'Test Playlist',
            'permalink_url':
                'https://soundcloud.com/test-artist/sets/test-playlist',
            'tracks': items,
          },
        },
      ])};</script>
</body>
</html>
''';
}

const soundCloudMetaOnlyHtml = '''
<html>
<head>
<meta property="og:title" content="Meta Only Track">
<meta property="og:image" content="https://i1.sndcdn.com/artworks-meta-large.jpg">
<meta property="og:audio" content="$soundCloudCdnFallback">
</head>
<body>
<p>No hydration data on this page.</p>
</body>
</html>
''';

final soundCloudNoArtworkHtml = '''
<html>
<head>
<meta property="og:title" content="No Artwork Track">
</head>
<body>
<script>window.SC={client_id:"$soundCloudTestClientId"};</script>
<script>window.__sc_hydration = ${jsonEncode([
      {
        'hydratable': 'sound',
        'data': {
          'id': 555,
          'title': 'No Artwork Track',
          'permalink_url': 'https://soundcloud.com/test-artist/no-artwork',
          'duration': 120000,
          'artwork_url': null,
          'user': {
            'username': 'Test Artist',
            'avatar_url': 'https://i1.sndcdn.com/avatars-000456-large.jpg',
          },
          'media': {
            'transcodings': [
              {
                'url':
                    'https://api-v2.soundcloud.com/media/noart/stream/progressive',
                'format': {
                  'protocol': 'progressive',
                  'mime_type': 'audio/mpeg',
                },
              },
            ],
          },
        },
      },
    ])};</script>
</body>
</html>
''';

Map<String, dynamic> _baseTrackData(String artist, String slug) {
  return {
    'id': 123456789,
    'title': 'Test Track Title',
    'permalink_url': 'https://soundcloud.com/$artist/$slug',
    'duration': 245000,
    'genre': 'Electronic',
    'description': 'A public test track',
    'created_at': '2024-01-15T12:00:00Z',
    'release_date': '2024-01-01',
    'artwork_url': 'https://i1.sndcdn.com/artworks-000123-large.jpg',
    'user': {
      'id': 42,
      'username': 'Test Artist',
      'avatar_url': 'https://i1.sndcdn.com/avatars-000456-large.jpg',
    },
    'media': {
      'transcodings': [
        {
          'url': 'https://api-v2.soundcloud.com/media/abc123/stream/progressive',
          'format': {'protocol': 'progressive', 'mime_type': 'audio/mpeg'},
          'quality': 'sq',
        },
        {
          'url': 'https://api-v2.soundcloud.com/media/abc123/stream/hls',
          'format': {
            'protocol': 'hls',
            'mime_type': 'audio/ogg; codecs="opus"',
          },
          'quality': 'sq',
        },
      ],
    },
  };
}

Map<String, dynamic> _playlistTrack(int id, String title, String slug) {
  return {
    'id': id,
    'title': title,
    'permalink_url': 'https://soundcloud.com/test-artist/$slug',
    'duration': 180000,
    'artwork_url': 'https://i1.sndcdn.com/artworks-$slug-large.jpg',
    'user': {'username': 'Test Artist'},
    'media': {
      'transcodings': [
        {
          'url': 'https://api-v2.soundcloud.com/media/$slug/stream/progressive',
          'format': {'protocol': 'progressive', 'mime_type': 'audio/mpeg'},
        },
      ],
    },
  };
}

/// Maps transcoding API paths to resolved CDN audio URLs.
const soundCloudTranscodingMap = {
  'abc123': soundCloudCdnTrack,
  't1': soundCloudCdnTrackOne,
  'track-one': soundCloudCdnTrackOne,
  't2': soundCloudCdnTrackTwo,
  'track-two': soundCloudCdnTrackTwo,
  't3': soundCloudCdnTrackThree,
  'track-three': soundCloudCdnTrackThree,
  'noart': 'https://cf-media.sndcdn.com/no-artwork.mp3',
  'm4a': soundCloudCdnM4a,
  'official': soundCloudCdnOfficial,
  'restricted': 'https://cf-media.sndcdn.com/should-not-resolve.mp3',
  'hydrated-stub': 'https://cf-media.sndcdn.com/hydrated-stub.mp3',
};

class SoundCloudMockInterceptor extends Interceptor {
  SoundCloudMockInterceptor({
    this.statusOverride,
    this.throwConnectionError = false,
    this.customHtml,
  });

  final int? statusOverride;
  final bool throwConnectionError;
  final String? customHtml;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (throwConnectionError) {
      handler.reject(DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: 'Network unreachable',
      ));
      return;
    }

    if (statusOverride != null && statusOverride! >= 400) {
      handler.reject(DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: statusOverride,
        ),
        type: DioExceptionType.badResponse,
      ));
      return;
    }

    final url = options.uri.toString();

    if (url.contains('api-v2.soundcloud.com/resolve')) {
      final target = options.uri.queryParameters['url'] ?? '';
      if (target.contains('cover-only')) {
        handler.reject(DioException(
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: 404),
          type: DioExceptionType.badResponse,
        ));
        return;
      }
      if (target.contains('api-only-track')) {
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'kind': 'track',
            'id': 963930517,
            'title': 'API Only Track',
            'permalink_url':
                'https://soundcloud.com/test-artist/api-only-track',
            'artwork_url':
                'https://i1.sndcdn.com/artworks-000123-large.jpg',
            'user': {'username': 'Test Artist'},
            'policy': 'ALLOW',
            'sharing': 'public',
            'media': {
              'transcodings': [
                {
                  'url':
                      'https://api-v2.soundcloud.com/media/abc123/stream/progressive',
                  'format': {
                    'protocol': 'progressive',
                    'mime_type': 'audio/mpeg',
                  },
                },
              ],
            },
          },
        ));
        return;
      }
      if (target.contains('/sets/')) {
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'kind': 'playlist',
            'title': 'API Playlist',
            'tracks': [
              _playlistTrack(111, 'Track One', 'track-one'),
              _playlistTrack(222, 'Track Two', 'track-two'),
            ],
          },
        ));
        return;
      }
      handler.reject(DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 404),
        type: DioExceptionType.badResponse,
      ));
      return;
    }

    if (url.contains('api-v2.soundcloud.com/tracks')) {
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: [
          _playlistTrack(444, 'Hydrated Stub', 'hydrated-stub'),
        ],
      ));
      return;
    }

    if (url.contains('api-v2.soundcloud.com/media/')) {
      final key = _transcodingKey(url);
      final cdn = soundCloudTranscodingMap[key];
      if (cdn == null) {
        handler.reject(DioException(
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: 404),
          type: DioExceptionType.badResponse,
        ));
        return;
      }
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {'url': cdn},
      ));
      return;
    }

    if (url.contains('a-v2.sndcdn.com/assets/') ||
        url.contains('widget.sndcdn.com')) {
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: 'var config={client_id:"$soundCloudTestClientId"};',
      ));
      return;
    }

    if (url.contains('api-only-track')) {
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: '''
<html>
<head><meta property="og:title" content="API Only Track"></head>
<body>
<script>window.SC={client_id:"$soundCloudTestClientId"};</script>
<p>Mobile shell with no hydration.</p>
</body>
</html>
''',
      ));
      return;
    }

    if (url.contains('not-found') || url.contains('/INVALID')) {
      handler.reject(DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 404),
        type: DioExceptionType.badResponse,
      ));
      return;
    }

    if (url.contains('empty-page')) {
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: '',
      ));
      return;
    }

    if (url.contains('malformed-hydration')) {
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data:
            '<html><script>window.__sc_hydration = [INVALID JSON;</script></html>',
      ));
      return;
    }

    if (url.contains('meta-only-track')) {
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: soundCloudMetaOnlyHtml,
      ));
      return;
    }

    if (url.contains('no-artwork')) {
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: soundCloudNoArtworkHtml,
      ));
      return;
    }

    if (url.contains('sets/test-playlist') || url.contains('sets/mixed')) {
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: customHtml ??
            soundCloudPlaylistHtml(
              includeStubs: url.contains('sets/mixed'),
            ),
      ));
      return;
    }

    if (customHtml != null) {
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: customHtml,
      ));
      return;
    }

    if (url.contains('soundcloud.com/test-artist') ||
        url.contains('soundcloud.com/artist')) {
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: soundCloudTrackHtml(),
      ));
      return;
    }

    handler.resolve(Response(
      requestOptions: options,
      statusCode: 200,
      data: '<html></html>',
    ));
  }

  String _transcodingKey(String url) {
    final match = RegExp(r'/media/([^/]+)/').firstMatch(url);
    return match?.group(1) ?? '';
  }
}
