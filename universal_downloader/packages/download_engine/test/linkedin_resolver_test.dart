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

  group('LinkedIn resolver discovery', () {
    test('LI-RES-001 discovers image post from HTML', () async {
      LinkedInMockAdapter.htmlResponse = linkedinImagePostHtml();
      final result = await LinkedInResolver(dio: mockDio).discover(
        Uri.parse(linkedinPostUrl),
      );
      expect(result, isNotNull);
      expect(result!.platform, 'LinkedIn');
      expect(result.directUrl, contains('licdn.com'));
      expect(result.mimeType, startsWith('image/'));
    });

    test('LI-RES-002 home returns empty', () async {
      LinkedInMockAdapter.htmlResponse = '<html>LinkedIn</html>';
      final result = await LinkedInResolver(dio: mockDio).discover(
        Uri.parse('https://www.linkedin.com/'),
      );
      expect(result, isNull);
    });

    test('LI-RES-003 profile returns empty', () async {
      final result = await LinkedInResolver(dio: mockDio).discover(
        Uri.parse('https://www.linkedin.com/in/someone/'),
      );
      expect(result, isNull);
    });

    test('LI-RES-004 company returns empty', () async {
      final result = await LinkedInResolver(dio: mockDio).discover(
        Uri.parse('https://www.linkedin.com/company/linkedin/'),
      );
      expect(result, isNull);
    });

    test('LI-RES-005 article returns empty', () async {
      LinkedInMockAdapter.htmlResponse = linkedinArticleHtml();
      final result = await LinkedInResolver(dio: mockDio).discover(
        Uri.parse('https://www.linkedin.com/pulse/how-we-build-software'),
      );
      expect(result, isNull);
    });

    test('LI-RES-006 lnkd.in follows redirect then parses post', () async {
      LinkedInMockAdapter.redirectLocation = linkedinPostUrl;
      LinkedInMockAdapter.htmlResponse = linkedinImagePostHtml();
      final result = await LinkedInResolver(dio: mockDio).discover(
        Uri.parse('https://lnkd.in/abc123XY'),
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('licdn.com'));
    });

    test('LI-RES-007 empty HTML returns null', () async {
      LinkedInMockAdapter.htmlResponse = '';
      final result = await LinkedInResolver(dio: mockDio).discover(
        Uri.parse(linkedinPostUrl),
      );
      expect(result, isNull);
    });

    test('LI-RES-008 parseHtmlResources from image fixture', () {
      final results = LinkedInResolver.parseHtmlResources(
        html: linkedinImagePostHtml(),
        pageUrl: Uri.parse(linkedinPostUrl),
        contentId: linkedinActivityId,
      );
      expect(results, isNotEmpty);
      expect(results.first.platform, 'LinkedIn');
    });

    test('LI-RES-009 registry discover returns LinkedIn resource', () async {
      LinkedInMockAdapter.htmlResponse = linkedinImagePostHtml();
      final result = await ContentProviderRegistry(dio: mockDio).discover(
        Uri.parse(linkedinPostUrl),
      );
      expect(result, isNotNull);
      expect(result!.platform, 'LinkedIn');
    });

    test('LI-RES-010 registry does not scrape LinkedIn home HTML', () async {
      LinkedInMockAdapter.htmlResponse = linkedinDirectOgImageHtml();
      final result = await ContentProviderRegistry(dio: mockDio).discover(
        Uri.parse('https://www.linkedin.com/'),
      );
      expect(result, isNull);
    });

    test('LI-RES-011 filename uses content id fallback for unicode title', () {
      final results = LinkedInResolver.parseHtmlResources(
        html: linkedinImagePostHtml(title: 'مرحبا بالعالم'),
        pageUrl: Uri.parse(linkedinPostUrl),
        contentId: linkedinActivityId,
      );
      expect(results, isNotEmpty);
      expect(results.single.fileName, isNot(contains('..')));
      expect(results.single.fileName, isNot(contains('/')));
    });

    test('LI-RES-012 request headers include LinkedIn referer', () {
      final results = LinkedInResolver.parseHtmlResources(
        html: linkedinImagePostHtml(),
        pageUrl: Uri.parse(linkedinPostUrl),
        contentId: linkedinActivityId,
      );
      expect(results.single.requestHeaders, isNotNull);
      expect(
        results.single.requestHeaders!['Referer'],
        contains('linkedin.com'),
      );
    });

    test('LI-RES-013 direct media URL is returned without HTML', () async {
      final result = await LinkedInResolver(dio: mockDio).discover(
        Uri.parse(linkedinImageUrl),
      );
      expect(result, isNotNull);
      expect(result!.directUrl, linkedinImageUrl);
      expect(result.mimeType, startsWith('image/'));
    });
  });
}
