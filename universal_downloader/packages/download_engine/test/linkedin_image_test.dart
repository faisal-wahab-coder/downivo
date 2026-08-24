import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'linkedin_fixtures.dart';

void main() {
  late Dio mockDio;

  setUp(() {
    mockDio = Dio();
    mockDio.httpClientAdapter = LinkedInMockAdapter();
    LinkedInMockAdapter.reset();
  });

  group('LinkedIn image posts', () {
    test('LI-IMG-001 discovers DMS image not the LinkedIn logo', () async {
      LinkedInMockAdapter.htmlResponse = linkedinImagePostHtml();
      final result = await LinkedInResolver(dio: mockDio).discover(
        Uri.parse(linkedinPostUrl),
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('/dms/image/'));
      expect(result.directUrl, isNot(contains('static.licdn.com')));
      expect(result.mimeType, startsWith('image/'));
    });

    test('LI-IMG-002 prefers larger shrink over 800x800', () {
      final results = LinkedInResolver.parseHtmlResources(
        html: linkedinMultiImageHtml(),
        pageUrl: Uri.parse(linkedinPostUrl),
        contentId: linkedinActivityId,
      );
      expect(
        results.any((r) => r.directUrl.contains('shrink_2048_1536')),
        isTrue,
      );
      expect(
        results.any((r) => r.directUrl.contains('shrink_800_800')),
        isFalse,
      );
    });

    test('LI-IMG-003 JPEG MIME from image path', () {
      expect(LinkedInResolver.mimeFromUrl(linkedinImageUrl), 'image/jpeg');
    });

    test('LI-IMG-004 PNG MIME from extension', () {
      expect(
        LinkedInResolver.mimeFromUrl(
          'https://media.licdn.com/dms/image/v2/x/photo.png',
        ),
        'image/png',
      );
    });

    test('LI-IMG-005 logo and profile photos are skipped', () {
      final html = '''
<meta property="og:image" content="$linkedinLogo" />
<img src="https://media.licdn.com/dms/image/v2/D4E03AQFface/profile-displayphoto-shrink_800_800/0/1" />
''';
      final results = LinkedInResolver.parseHtmlResources(
        html: html,
        pageUrl: Uri.parse(linkedinPostUrl),
        contentId: linkedinActivityId,
      );
      expect(results, isEmpty);
    });

    test('LI-IMG-006 comment and article-cover images are skipped', () {
      final html = '''
<img src="$linkedinCommentImage" />
<img src="$linkedinArticleCover" />
''';
      final results = LinkedInResolver.parseHtmlResources(
        html: html,
        pageUrl: Uri.parse(linkedinPostUrl),
        contentId: linkedinActivityId,
      );
      expect(results, isEmpty);
    });
  });
}
