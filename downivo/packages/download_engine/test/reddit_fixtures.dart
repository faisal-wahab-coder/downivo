import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Shared Reddit JSON fixtures and a mock Dio adapter for resolver tests.
List<dynamic> redditListing(Map<String, dynamic> postData) {
  return [
    {
      'kind': 'Listing',
      'data': {
        'children': [
          {'kind': 't3', 'data': postData},
        ],
      },
    },
    {'kind': 'Listing', 'data': {'children': <dynamic>[]}},
  ];
}

Map<String, dynamic> redditVideoPost({
  String id = 'abc123',
  String subreddit = 'videos',
  String author = 'test_user',
  String title = 'A Reddit Video',
  String fallbackUrl = 'https://v.redd.it/vid123/DASH_720.mp4?source=fallback',
  bool hasAudio = true,
  bool isGif = false,
  int duration = 12,
  int width = 1280,
  int height = 720,
  String? thumbnail = 'https://preview.redd.it/thumb.jpg',
}) {
  return {
    'id': id,
    'subreddit': subreddit,
    'author': author,
    'title': title,
    'is_video': true,
    'is_gif': isGif,
    'thumbnail': thumbnail,
    'permalink': '/r/$subreddit/comments/$id/slug/',
    'url': 'https://v.redd.it/vid123',
    'preview': {
      'images': [
        {
          'source': {
            'url': thumbnail ?? 'https://preview.redd.it/thumb.jpg',
            'width': width,
            'height': height,
          },
        },
      ],
    },
    'secure_media': {
      'reddit_video': {
        'fallback_url': fallbackUrl,
        'hls_url': 'https://v.redd.it/vid123/HLSPlaylist.m3u8',
        'dash_url': 'https://v.redd.it/vid123/DASHPlaylist.mpd',
        'has_audio': hasAudio,
        'is_gif': isGif,
        'duration': duration,
        'width': width,
        'height': height,
      },
    },
    'media': {
      'reddit_video': {
        'fallback_url': fallbackUrl,
        'has_audio': hasAudio,
        'is_gif': isGif,
        'duration': duration,
        'width': width,
        'height': height,
      },
    },
  };
}

Map<String, dynamic> redditImagePost({
  String id = 'img123',
  String subreddit = 'pics',
  String author = 'photog',
  String title = 'A Reddit Image',
  String url = 'https://i.redd.it/photo123.jpg',
  String? thumbnail,
}) {
  return {
    'id': id,
    'subreddit': subreddit,
    'author': author,
    'title': title,
    'is_video': false,
    'post_hint': 'image',
    'url': url,
    'url_overridden_by_dest': url,
    'thumbnail': thumbnail ?? url,
    'preview': {
      'images': [
        {
          'source': {'url': url, 'width': 1920, 'height': 1080},
        },
      ],
    },
  };
}

Map<String, dynamic> redditGifPost({
  String id = 'gif123',
  String title = 'An Animated GIF',
  String gifUrl = 'https://i.redd.it/anim123.gif',
  String? mp4Url = 'https://preview.redd.it/anim123.mp4',
}) {
  return {
    'id': id,
    'subreddit': 'gifs',
    'author': 'gif_user',
    'title': title,
    'is_video': false,
    'url': gifUrl,
    'url_overridden_by_dest': gifUrl,
    'preview': {
      'images': [
        {
          'source': {'url': gifUrl, 'width': 480, 'height': 270},
          'variants': {
            'gif': {
              'source': {'url': gifUrl},
            },
            if (mp4Url != null)
              'mp4': {
                'source': {'url': mp4Url},
              },
          },
        },
      ],
    },
  };
}

Map<String, dynamic> redditGalleryPost({
  String id = 'gal123',
  String title = 'A Gallery',
  List<({String id, String url, String mime, String kind})> items = const [],
}) {
  final resolvedItems = items.isEmpty
      ? [
          (
            id: 'm1',
            url: 'https://preview.redd.it/a.jpg?width=100',
            mime: 'image/jpg',
            kind: 'Image',
          ),
          (
            id: 'm2',
            url: 'https://preview.redd.it/b.png?width=100',
            mime: 'image/png',
            kind: 'Image',
          ),
          (
            id: 'm3',
            url: 'https://preview.redd.it/c.webp?width=100',
            mime: 'image/webp',
            kind: 'Image',
          ),
        ]
      : items;

  return {
    'id': id,
    'subreddit': 'pics',
    'author': 'gallery_user',
    'title': title,
    'is_gallery': true,
    'is_video': false,
    'permalink': '/r/pics/comments/$id/gallery/',
    'gallery_data': {
      'items': [
        for (var i = 0; i < resolvedItems.length; i++)
          {'media_id': resolvedItems[i].id, 'id': i},
      ],
    },
    'media_metadata': {
      for (final item in resolvedItems)
        item.id: {
          'status': 'valid',
          'e': item.kind,
          'm': item.mime,
          's': {
            'u': item.url,
            if (item.kind == 'AnimatedImage' && item.mime == 'image/gif')
              'gif': item.url,
            if (item.kind == 'AnimatedImage' && item.mime == 'video/mp4')
              'mp4': item.url,
            'x': 800,
            'y': 600,
          },
          'p': [
            {'u': item.url, 'x': 200, 'y': 150},
          ],
        },
    },
  };
}

Map<String, dynamic> redditYouTubeLinkPost({
  String id = '3wbg49',
  String title = 'Dude has epic meltdown over bad haircut',
  String youtubeUrl = 'https://www.youtube.com/watch?v=TzBDpdhC8Hs',
}) {
  return {
    'id': id,
    'subreddit': 'videos',
    'author': 'op',
    'title': title,
    'is_video': false,
    'post_hint': 'rich:video',
    'domain': 'youtube.com',
    'url': youtubeUrl,
    'url_overridden_by_dest': youtubeUrl,
    'secure_media': {
      'type': 'youtube.com',
      'oembed': {'provider_name': 'YouTube', 'title': title},
    },
  };
}

Map<String, dynamic> redditRemovedPost({String id = 'gone1'}) {
  return {
    'id': id,
    'subreddit': 'pics',
    'author': '[deleted]',
    'title': '[removed]',
    'removed_by_category': 'moderator',
    'is_video': false,
    'selftext': '[removed]',
  };
}

Map<String, dynamic> redditSelfPost({String id = 'text1'}) {
  return {
    'id': id,
    'subreddit': 'askreddit',
    'author': 'op',
    'title': 'Text only',
    'is_self': true,
    'is_video': false,
    'selftext': 'Just a question.',
    'url': 'https://www.reddit.com/r/askreddit/comments/$id/text_only/',
  };
}

/// Mock adapter: JSON for `.json` paths, optional 302 for share URLs, HTML otherwise.
class RedditMockAdapter implements HttpClientAdapter {
  static String jsonResponse = '[]';
  static String htmlResponse = '';
  static int statusCode = 200;
  static bool throwError = false;
  static DioExceptionType exceptionType = DioExceptionType.connectionError;
  static String? redirectLocation;

  static void reset() {
    jsonResponse = '[]';
    htmlResponse = '';
    statusCode = 200;
    throwError = false;
    exceptionType = DioExceptionType.connectionError;
    redirectLocation = null;
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

    final path = options.uri.path;
    final isShare = path.contains('/s/');
    if (redirectLocation != null && isShare) {
      return ResponseBody.fromString(
        '',
        302,
        headers: {
          'location': [redirectLocation!],
        },
      );
    }

    if (statusCode >= 400) {
      throw DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: statusCode,
          data: jsonResponse,
        ),
        type: DioExceptionType.badResponse,
      );
    }

    final wantsJson = path.endsWith('.json') ||
        options.uri.queryParameters.containsKey('raw_json');
    if (wantsJson) {
      return ResponseBody.fromString(
        jsonResponse,
        statusCode,
        headers: {
          Headers.contentTypeHeader: ['application/json; charset=utf-8'],
        },
      );
    }

    return ResponseBody.fromString(
      htmlResponse,
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['text/html; charset=utf-8'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

String encodeListing(Map<String, dynamic> postData) =>
    jsonEncode(redditListing(postData));
