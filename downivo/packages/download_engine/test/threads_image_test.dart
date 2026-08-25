import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'threads_fixtures.dart';

void main() {
  group('Threads image posts', () {
    test('TH-IMG-001 image post is IMAGE', () {
      expect(
        ThreadsResolver.detectMediaType(threadsImageHtml()),
        ThreadsMediaType.image,
      );
    });

    test('TH-IMG-002 image URL, thumbnail, and dimensions', () {
      final results = ThreadsResolver.parseHtmlResources(
        html: threadsImageHtml(),
        pageUrl: Uri.parse(threadsPostUrl),
      );
      expect(results.single.directUrl, threadsImageUrl);
      expect(results.single.thumbnailUrl, isNotNull);
      expect(results.single.mimeType, 'image/jpeg');
      expect(results.single.fileName.toLowerCase(), endsWith('.jpg'));
    });

    test('TH-IMG-003 author and caption are mapped', () {
      final info = ThreadsResolver.parsePostInfo(
        html: threadsImageHtml(),
        pageUrl: Uri.parse(threadsPostUrl),
      );
      expect(info.author, threadsDisplayName);
      expect(info.username, threadsUsername);
      expect(info.caption, 'A public Threads image');
    });

    test('TH-IMG-004 profile picture is not treated as post media', () {
      final html = '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="Fixture User on Threads" />
<meta property="og:description" content="Text only" />
<meta property="og:image" content="$threadsProfilePicUrl" />
</head>
<body>
<script>{"text":"Text only","text_post_app_info":{}}</script>
</body>
</html>''';
      expect(ThreadsResolver.parseHtmlResources(
        html: html,
        pageUrl: Uri.parse(threadsPostUrl),
      ), isEmpty);
    });

    test('TH-IMG-005 MIME comes from resolved metadata not extension alone', () {
      expect(ThreadsResolver.mimeFromUrl(threadsImageUrl), 'image/jpeg');
      expect(
        ThreadsResolver.detectMediaType(threadsImageHtml()),
        isNot(ThreadsMediaType.video),
      );
    });

    test('TH-IMG-006 unicode-escaped fna CDN image is decoded', () {
      final results = ThreadsResolver.parseHtmlResources(
        html: threadsUnicodeImageHtml(),
        pageUrl: Uri.parse(threadsPostComUrl),
        contentId: threadsPostId,
      );
      expect(results, hasLength(1));
      expect(results.single.directUrl, threadsFnaImageUrl);
      expect(results.single.directUrl, isNot(contains(r'\u002F')));
      expect(results.single.mimeType, 'image/jpeg');
    });

    test('TH-IMG-007 null carousel on an image post stays IMAGE', () {
      final html = threadsImageWithNullCarouselHtml();
      expect(ThreadsResolver.detectMediaType(html), ThreadsMediaType.image);
      final results = ThreadsResolver.parseHtmlResources(
        html: html,
        pageUrl: Uri.parse(threadsPostComUrl),
        contentId: threadsPostId,
      );
      expect(results, hasLength(1));
      expect(results.single.directUrl, threadsImageUrl);
      expect(results.single.mimeType, 'image/jpeg');
    });
  });
}
