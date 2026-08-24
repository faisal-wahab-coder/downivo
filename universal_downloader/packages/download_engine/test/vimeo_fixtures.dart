import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

Map<String, dynamic> vimeoProgressive({
  required String quality,
  required int width,
  required int height,
  required String url,
  String mime = 'video/mp4',
  double fps = 30,
}) {
  return {
    'quality': quality,
    'width': width,
    'height': height,
    'url': url,
    'mime': mime,
    'fps': fps,
  };
}

Map<String, dynamic> vimeoPlayerConfig({
  String videoId = '76979871',
  String title = 'The New Vimeo Player',
  String? description,
  String author = 'Vimeo Staff',
  String authorId = '928647',
  String videoUrl = 'https://vimeo.com/76979871',
  int duration = 62,
  int width = 1920,
  int height = 1080,
  bool includeProgressive = true,
  bool includeHls = true,
  bool includeDash = false,
  bool hasAudio = true,
  String privacyView = 'anybody',
  bool privacyDownload = false,
  String? uploadedOn = '2013-09-12 00:00:00',
  List<Map<String, dynamic>>? progressive,
}) {
  final files = <String, dynamic>{};
  if (includeProgressive) {
    files['progressive'] = progressive ??
        [
          vimeoProgressive(
            quality: '1080p',
            width: 1920,
            height: 1080,
            url:
                'https://vod-progressive.akamaized.net/exp=1/vimeo/file_1080.mp4',
            fps: 30,
          ),
          vimeoProgressive(
            quality: '720p',
            width: 1280,
            height: 720,
            url:
                'https://vod-progressive.akamaized.net/exp=1/vimeo/file_720.mp4',
            fps: 30,
          ),
          vimeoProgressive(
            quality: '360p',
            width: 640,
            height: 360,
            url:
                'https://vod-progressive.akamaized.net/exp=1/vimeo/file_360.mp4',
            fps: 24,
          ),
        ];
  }
  if (includeHls) {
    files['hls'] = {
      'separate_av': !includeProgressive,
      'cdns': {
        'akamai_interconnect': {
          'url':
              'https://skyfire.vimeocdn.com/exp=1/video/$videoId/master.m3u8',
        },
      },
    };
  }
  if (includeDash) {
    files['dash'] = {
      'separate_av': true,
      'cdns': {
        'akamai_interconnect': {
          'url':
              'https://skyfire.vimeocdn.com/exp=1/video/$videoId/master.mpd',
        },
      },
    };
  }

  return {
    'video': {
      'id': int.tryParse(videoId) ?? videoId,
      'title': title,
      if (description != null) 'description': description,
      'width': width,
      'height': height,
      'duration': duration,
      'url': videoUrl,
      'share_url': videoUrl,
      if (uploadedOn != null) 'uploaded_on': uploadedOn,
      'has_audio': hasAudio,
      'owner': {
        'id': int.tryParse(authorId) ?? authorId,
        'name': author,
        'url': 'https://vimeo.com/staff',
      },
      'thumbs': {
        '640': 'https://i.vimeocdn.com/video/${videoId}_640.jpg',
        '960': 'https://i.vimeocdn.com/video/${videoId}_960.jpg',
        '1280': 'https://i.vimeocdn.com/video/${videoId}_1280.jpg',
        'base': 'https://i.vimeocdn.com/video/$videoId',
      },
      'privacy': {
        'view': privacyView,
        'download': privacyDownload,
        'embed': 'public',
      },
    },
    'request': {'files': files},
  };
}

Map<String, dynamic> vimeoHlsOnlyConfig({String videoId = '555'}) {
  return vimeoPlayerConfig(
    videoId: videoId,
    title: 'HLS only',
    includeProgressive: false,
    includeHls: true,
    includeDash: true,
  );
}

Map<String, dynamic> vimeoPasswordConfig() {
  return {'message': 'Password required to access this video.'};
}

Map<String, dynamic> vimeoPrivateConfig() {
  return {'message': 'This video is private.'};
}

Map<String, dynamic> vimeoUnavailableConfig() {
  return {'message': "Sorry, we couldn't find that page"};
}

Map<String, dynamic> vimeoDrmConfig() {
  return {
    ...vimeoHlsOnlyConfig(videoId: 'drm1'),
    'drm': true,
  };
}

String vimeoPlayerHtml(Map<String, dynamic> config) {
  return '<!DOCTYPE html><html><head><title>Vimeo</title></head>'
      '<body><script>window.playerConfig = ${jsonEncode(config)};</script>'
      '</body></html>';
}

String vimeoOgHtml({
  required String title,
  String? videoUrl,
  String? imageUrl,
}) {
  final video = videoUrl == null
      ? ''
      : '<meta property="og:video" content="$videoUrl" />';
  final image = imageUrl == null
      ? ''
      : '<meta property="og:image" content="$imageUrl" />';
  return '<!DOCTYPE html><html><head>'
      '<meta property="og:title" content="$title" />'
      '$image$video'
      '</head><body></body></html>';
}

class VimeoMockAdapter implements HttpClientAdapter {
  static String configResponse = '';
  static String htmlResponse = '';
  static int statusCode = 200;
  static bool throwError = false;
  static DioExceptionType exceptionType = DioExceptionType.connectionError;

  static void reset() {
    configResponse = '';
    htmlResponse = '';
    statusCode = 200;
    throwError = false;
    exceptionType = DioExceptionType.connectionError;
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

    final path = options.uri.path;
    if (path.endsWith('/config')) {
      final body = configResponse.isEmpty ? '{}' : configResponse;
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

  @override
  void close({bool force = false}) {}
}
