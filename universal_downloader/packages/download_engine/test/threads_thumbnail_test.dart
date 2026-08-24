import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'threads_fixtures.dart';

void main() {
  group('Threads thumbnails', () {
    test('TH-THUMB-001 image thumbnail exists', () {
      final results = ThreadsResolver.parseHtmlResources(
        html: threadsImageHtml(),
        pageUrl: Uri.parse(threadsPostUrl),
      );
      expect(results.single.thumbnailUrl, isNotNull);
    });

    test('TH-THUMB-002 video uses og:image thumbnail', () {
      final results = ThreadsResolver.parseHtmlResources(
        html: threadsVideoHtml(),
        pageUrl: Uri.parse(threadsPostUrl),
      );
      expect(results.single.thumbnailUrl, threadsThumbUrl);
    });

    test('TH-THUMB-003 missing thumbnail does not crash', () {
      final html = '''
<!DOCTYPE html>
<html>
<head><meta property="og:title" content="No thumb" /></head>
<body>
<script>{"video_versions":[{"url":"$threadsVideoUrl","width":1080,"height":1920}]}</script>
</body>
</html>''';
      final results = ThreadsResolver.parseHtmlResources(
        html: html,
        pageUrl: Uri.parse(threadsPostUrl),
      );
      expect(results, hasLength(1));
    });

    test('TH-THUMB-004 site icon is not used as thumbnail media', () {
      final html = '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:image" content="https://www.threads.net/favicon.ico" />
<meta property="og:description" content="Text" />
</head>
<body><script>{"text":"Text","text_post_app_info":{}}</script></body>
</html>''';
      expect(
        ThreadsResolver.parseHtmlResources(
          html: html,
          pageUrl: Uri.parse(threadsPostUrl),
        ),
        isEmpty,
      );
    });
  });
}
