import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

Map<String, dynamic> pinterestImagePin({
  String id = '580547278694592554',
  String title = 'Sunset photo',
  String description = 'A public sunset',
  String origUrl =
      'https://i.pinimg.com/originals/ab/cd/ef/sunset.png',
  int width = 2000,
  int height = 3000,
  String author = 'Alex',
  String username = 'alex',
  String authorId = '42',
}) {
  return {
    'id': id,
    'grid_title': title,
    'title': title,
    'description': description,
    'is_video': false,
    'images': {
      'orig': {'url': origUrl, 'width': width, 'height': height},
      '736x': {
        'url': 'https://i.pinimg.com/736x/ab/cd/ef/sunset.jpg',
        'width': 736,
        'height': 1104,
      },
      '236x': {
        'url': 'https://i.pinimg.com/236x/ab/cd/ef/sunset.jpg',
        'width': 236,
        'height': 354,
      },
    },
    'pinner': {
      'full_name': author,
      'username': username,
      'id': authorId,
    },
  };
}

Map<String, dynamic> pinterestVideoPin({
  String id = 'vid123456789',
  String title = 'A Pinterest video',
  String mp4Url = 'https://v1.pinimg.com/videos/mc/720p/clip.mp4',
  String hlsUrl = 'https://v1.pinimg.com/videos/mc/hls/clip.m3u8',
  bool includeHls = true,
  bool includeMp4 = true,
  int width = 720,
  int height = 1280,
  double duration = 15.2,
  String thumbUrl =
      'https://i.pinimg.com/originals/aa/bb/cc/thumb.jpg',
}) {
  final videoList = <String, dynamic>{};
  if (includeHls) {
    videoList['V_HLSV4'] = {
      'url': hlsUrl,
      'width': width,
      'height': height,
      'duration': duration,
    };
  }
  if (includeMp4) {
    videoList['V_720P'] = {
      'url': mp4Url,
      'width': width,
      'height': height,
      'duration': duration,
    };
    videoList['V_480P'] = {
      'url': 'https://v1.pinimg.com/videos/mc/480p/clip.mp4',
      'width': 480,
      'height': 854,
      'duration': duration,
    };
  }
  return {
    'id': id,
    'grid_title': title,
    'is_video': true,
    'videos': {'video_list': videoList},
    'images': {
      'orig': {'url': thumbUrl, 'width': width, 'height': height},
    },
    'pinner': {
      'full_name': 'VidUser',
      'username': 'viduser',
      'id': '7',
    },
  };
}

Map<String, dynamic> pinterestIdeaPin({
  String id = 'idea123456789',
  String title = 'Idea Pin recipe',
  List<Map<String, dynamic>>? pages,
}) {
  return {
    'id': id,
    'grid_title': title,
    'description': 'A multi-page idea pin',
    'story_pin_data': {
      'pages': pages ??
          [
            {
              'image': {
                'images': {
                  'orig': {
                    'url':
                        'https://i.pinimg.com/originals/aa/bb/cc/one.jpg',
                    'width': 1080,
                    'height': 1920,
                  },
                },
              },
            },
            {
              'image': {
                'images': {
                  'orig': {
                    'url':
                        'https://i.pinimg.com/originals/aa/bb/cc/two.png',
                    'width': 1080,
                    'height': 1920,
                  },
                },
              },
            },
            {
              'video': {
                'video_list': {
                  'V_720P': {
                    'url':
                        'https://v1.pinimg.com/videos/mc/720p/three.mp4',
                    'width': 720,
                    'height': 1280,
                    'duration': 8.0,
                  },
                  'V_HLSV4': {
                    'url':
                        'https://v1.pinimg.com/videos/mc/hls/three.m3u8',
                  },
                },
              },
            },
          ],
    },
    'images': {
      'orig': {
        'url': 'https://i.pinimg.com/originals/aa/bb/cc/cover.jpg',
        'width': 1080,
        'height': 1920,
      },
    },
    'pinner': {
      'full_name': 'Chef',
      'username': 'chef',
      'id': '99',
    },
  };
}

Map<String, dynamic> pinterestWebpPin({
  String id = 'webp123',
  String title = 'WebP pin',
}) {
  return pinterestImagePin(
    id: id,
    title: title,
    origUrl: 'https://i.pinimg.com/originals/ab/cd/ef/photo.webp',
    width: 1200,
    height: 800,
  );
}

Map<String, dynamic> pwsPayload(Map<String, dynamic> pin) {
  final id = pin['id']?.toString() ?? '0';
  return {
    'props': {
      'initialReduxState': {
        'pins': {id: pin},
      },
    },
  };
}

String pwsHtml(Map<String, dynamic> pin, {String? ogTitle}) {
  final payload = jsonEncode(pwsPayload(pin));
  final title = ogTitle ?? pin['grid_title'] ?? 'Pinterest';
  final orig = pin['images'] is Map
      ? (pin['images'] as Map)['orig']
      : null;
  final thumb = orig is Map ? orig['url'] : null;
  return '<!DOCTYPE html><html><head>'
      '<meta property="og:title" content="$title" />'
      '${thumb == null ? '' : '<meta property="og:image" content="$thumb" />'}'
      '</head><body>'
      '<script id="__PWS_DATA__" type="application/json">$payload</script>'
      '</body></html>';
}

String pinterestOgHtml({
  required String imageUrl,
  String? videoUrl,
  String title = 'OG Pin',
}) {
  final video = videoUrl == null
      ? ''
      : '<meta property="og:video" content="$videoUrl" />';
  return '<!DOCTYPE html><html><head>'
      '<meta property="og:title" content="$title" />'
      '<meta property="og:image" content="$imageUrl" />'
      '$video'
      '</head><body></body></html>';
}

String pidgetsJson(Map<String, dynamic> pin) {
  return jsonEncode({
    'status': 'success',
    'data': [pin],
  });
}

String oembedJson({
  required String title,
  required String thumbnailUrl,
  String author = 'Alex',
}) {
  return jsonEncode({
    'type': 'rich',
    'title': title,
    'author_name': author,
    'thumbnail_url': thumbnailUrl,
  });
}

class PinterestMockAdapter implements HttpClientAdapter {
  static String htmlResponse = '';
  static String pidgetsResponse = '';
  static String oembedResponse = '';
  static int htmlStatus = 200;
  static int jsonStatus = 200;
  static bool throwError = false;
  static DioExceptionType exceptionType = DioExceptionType.connectionError;
  static String? redirectLocation;

  static void reset() {
    htmlResponse = '';
    pidgetsResponse = '';
    oembedResponse = '';
    htmlStatus = 200;
    jsonStatus = 200;
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

    final host = options.uri.host.toLowerCase();
    final path = options.uri.path;

    if (redirectLocation != null &&
        (host == 'pin.it' || host.endsWith('.pin.it'))) {
      return ResponseBody.fromString(
        '',
        302,
        headers: {
          'location': [redirectLocation!],
        },
      );
    }

    final isPidgets = host.contains('widgets.pinterest.com') ||
        path.contains('/pidgets/');
    final isOembed = path.contains('oembed.json');

    if (isPidgets || isOembed) {
      if (jsonStatus >= 400) {
        throw DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: jsonStatus,
            data: '',
          ),
          type: DioExceptionType.badResponse,
        );
      }
      final body = isOembed ? oembedResponse : pidgetsResponse;
      if (body.isEmpty) {
        return ResponseBody.fromString(
          '{"status":"success","data":[]}',
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json; charset=utf-8'],
          },
        );
      }
      return ResponseBody.fromString(
        body,
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json; charset=utf-8'],
        },
      );
    }

    if (htmlStatus >= 400) {
      throw DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: htmlStatus,
          data: htmlResponse,
        ),
        type: DioExceptionType.badResponse,
      );
    }

    return ResponseBody.fromString(
      htmlResponse,
      htmlStatus,
      headers: {
        Headers.contentTypeHeader: ['text/html; charset=utf-8'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
