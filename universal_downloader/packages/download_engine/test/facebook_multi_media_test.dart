import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Facebook multi-media post tests: multi-photo extraction, ordering,
/// and mixed-media post handling.
void main() {
  late Dio mockDio;

  setUp(() {
    mockDio = Dio();
    mockDio.httpClientAdapter = _MockAdapter();
    _MockAdapter.htmlResponse = '';
    _MockAdapter.htmlByHost = {};
    _MockAdapter.statusCode = 200;
  });

  group('Facebook multi-photo posts', () {
    test('FB-MULTI-001 discoverAll extracts multiple photos', () async {
      _MockAdapter.htmlResponse = '''
<html><head>
<meta property="og:title" content="Multi Photo" />
<meta property="og:image" content="https://scontent.xx.fbcdn.net/v/p1.jpg?oh=1" />
</head><body>
<script>
{"images":[
  {"uri":"https://scontent.xx.fbcdn.net/v/p1.jpg?oh=1"},
  {"uri":"https://scontent.xx.fbcdn.net/v/p2.jpg?oh=2"},
  {"uri":"https://scontent.xx.fbcdn.net/v/p3.jpg?oh=3"}
]}
</script>
</body></html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final results = await resolver.discoverAll(
        Uri.parse('https://www.facebook.com/photo/?fbid=123456'),
      );

      expect(results.length, 3);
      expect(results.map((r) => r.directUrl), [
        contains('p1.jpg'),
        contains('p2.jpg'),
        contains('p3.jpg'),
      ]);
      for (final r in results) {
        expect(r.platform, 'Facebook');
      }
    });

    test('FB-MULTI-002 single photo post returns single item', () async {
      _MockAdapter.htmlResponse = '''
<html><head>
<meta property="og:image" content="https://scontent.xx.fbcdn.net/v/single.jpg?oh=1" />
<meta property="og:title" content="Single Photo" />
</head><body></body></html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final results = await resolver.discoverAll(
        Uri.parse('https://www.facebook.com/photo/?fbid=123456'),
      );

      expect(results.length, 1);
      expect(results.first.directUrl, contains('single.jpg'));
    });

    test('FB-MULTI-003 multi-photo items have unique filenames', () async {
      _MockAdapter.htmlResponse = '''
<html><head>
<meta property="og:title" content="Multiple" />
<meta property="og:image" content="https://scontent.xx.fbcdn.net/v/a.jpg?oh=1" />
</head><body>
<script>
{"images":[
  {"uri":"https://scontent.xx.fbcdn.net/v/a.jpg?oh=1"},
  {"uri":"https://scontent.xx.fbcdn.net/v/b.jpg?oh=2"}
]}
</script>
</body></html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final results = await resolver.discoverAll(
        Uri.parse('https://www.facebook.com/photo/?fbid=123456'),
      );

      if (results.length > 1) {
        final fileNames = results.map((r) => r.fileName).toSet();
        expect(fileNames.length, results.length);
      }
    });

    test('FB-MULTI-005 nested image.uri objects are extracted in order', () async {
      _MockAdapter.htmlResponse = '''
<html><body>
<script>
{"subattachments":{"nodes":[
  {"media":{"image":{"height":720,"uri":"https://scontent.xx.fbcdn.net/v/album1.jpg?oh=1","width":1080}}},
  {"media":{"image":{"height":720,"uri":"https://scontent.xx.fbcdn.net/v/album2.jpg?oh=2","width":1080}}},
  {"media":{"image":{"height":720,"uri":"https://scontent.xx.fbcdn.net/v/album3.jpg?oh=3","width":1080}}}
]}}
</script>
</body></html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final results = await resolver.discoverAll(
        Uri.parse('https://www.facebook.com/user/posts/pfbid123'),
      );

      expect(results.length, 3);
      expect(results[0].directUrl, contains('album1.jpg'));
      expect(results[1].directUrl, contains('album2.jpg'));
      expect(results[2].directUrl, contains('album3.jpg'));
    });

    test('FB-MULTI-006 single og:image does not hide later album JSON', () async {
      _MockAdapter.htmlByHost = {
        'www.facebook.com': '''
<html><head>
<meta property="og:image" content="https://scontent.xx.fbcdn.net/v/p1.jpg?oh=1" />
</head><body></body></html>''',
        'mbasic.facebook.com': '''
<html><body>
<script>
{"images":[
  {"uri":"https://scontent.xx.fbcdn.net/v/p1.jpg?oh=1"},
  {"uri":"https://scontent.xx.fbcdn.net/v/p2.jpg?oh=2"},
  {"uri":"https://scontent.xx.fbcdn.net/v/p3.jpg?oh=3"}
]}
</script>
</body></html>''',
      };

      final resolver = FacebookResolver(dio: mockDio);
      final results = await resolver.discoverAll(
        Uri.parse('https://www.facebook.com/user/posts/pfbid123'),
      );

      expect(results.length, 3);
    });

    test('FB-MULTI-004 all items have correct platform', () async {
      _MockAdapter.htmlResponse = '''
<html><head>
<meta property="og:image" content="https://scontent.xx.fbcdn.net/v/x.jpg?oh=1" />
</head><body></body></html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final results = await resolver.discoverAll(
        Uri.parse('https://www.facebook.com/photo/?fbid=123456'),
      );

      for (final r in results) {
        expect(r.platform, 'Facebook');
        expect(r.pageUrl, isNotNull);
      }
    });
  });

  group('Facebook mixed media posts', () {
    test('FB-MULTI-010 post with video resolves video', () async {
      _MockAdapter.htmlResponse = '''
<html><head>
<meta property="og:video" content="https://video.xx.fbcdn.net/v/mixed.mp4?oh=abc" />
<meta property="og:image" content="https://scontent.xx.fbcdn.net/v/thumb.jpg" />
<meta property="og:title" content="Mixed Post" />
</head><body></body></html>''';

      final resolver = FacebookResolver(dio: mockDio);
      final results = await resolver.discoverAll(
        Uri.parse('https://www.facebook.com/watch/?v=123456'),
      );

      expect(results.isNotEmpty, isTrue);
      expect(results.first.mimeType, contains('video'));
    });
  });

  group('Facebook ContentProviderRegistry multi-media', () {
    test('FB-MULTI-020 registry discoverAll returns Facebook photos', () async {
      _MockAdapter.htmlResponse = '''
<html><head>
<meta property="og:image" content="https://scontent.xx.fbcdn.net/v/reg_photo.jpg?oh=1" />
<meta property="og:title" content="Registry Photo" />
</head><body></body></html>''';

      final registry = ContentProviderRegistry(dio: mockDio);
      final results = await registry.discoverAll(
        Uri.parse('https://www.facebook.com/photo/?fbid=123456'),
      );

      expect(results.isNotEmpty, isTrue);
      expect(results.first.platform, 'Facebook');
    });
  });
}

class _MockAdapter implements HttpClientAdapter {
  static String htmlResponse = '';
  static Map<String, String> htmlByHost = {};
  static int statusCode = 200;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (statusCode >= 400) {
      throw DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: statusCode,
          data: htmlResponse,
        ),
        type: DioExceptionType.badResponse,
      );
    }
    final html = htmlByHost[options.uri.host] ?? htmlResponse;
    return ResponseBody.fromString(
      html,
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['text/html; charset=utf-8'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
