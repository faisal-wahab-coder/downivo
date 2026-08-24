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

  group('LinkedIn multi-image posts', () {
    test('LI-MULTI-001 media count is 2 unique images', () {
      final results = LinkedInResolver.parseHtmlResources(
        html: linkedinMultiImageHtml(),
        pageUrl: Uri.parse(linkedinPostUrl),
        contentId: linkedinActivityId,
      );
      expect(results.length, 2);
    });

    test('LI-MULTI-002 order is preserved', () {
      final results = LinkedInResolver.parseHtmlResources(
        html: linkedinMultiImageHtml(),
        pageUrl: Uri.parse(linkedinPostUrl),
        contentId: linkedinActivityId,
      );
      expect(results.first.directUrl, contains('D4E22AQFtestfeed'));
      expect(results.last.directUrl, contains('D4E22AQFsecondimg'));
    });

    test('LI-MULTI-003 no duplicate URLs', () {
      final results = LinkedInResolver.parseHtmlResources(
        html: linkedinMultiImageHtml(),
        pageUrl: Uri.parse(linkedinPostUrl),
        contentId: linkedinActivityId,
      );
      expect(results.map((r) => r.directUrl).toSet().length, results.length);
    });

    test('LI-MULTI-004 filenames are unique per index', () {
      final results = LinkedInResolver.parseHtmlResources(
        html: linkedinMultiImageHtml(),
        pageUrl: Uri.parse(linkedinPostUrl),
        contentId: linkedinActivityId,
      );
      expect(results.map((r) => r.fileName).toSet().length, 2);
    });

    test('LI-MULTI-005 registry discoverAll returns both images', () async {
      LinkedInMockAdapter.htmlResponse = linkedinMultiImageHtml();
      final results = await ContentProviderRegistry(dio: mockDio).discoverAll(
        Uri.parse(linkedinPostUrl),
      );
      expect(results.length, 2);
      expect(results.every((r) => r.platform == 'LinkedIn'), isTrue);
    });

    test('LI-MULTI-006 single image post is one resource', () {
      final results = LinkedInResolver.parseHtmlResources(
        html: linkedinImagePostHtml(),
        pageUrl: Uri.parse(linkedinPostUrl),
        contentId: linkedinActivityId,
      );
      expect(results.length, 1);
    });
  });
}
