import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:download_engine/src/content_providers/social_http_headers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'threads_fixtures.dart';

void main() {
  late Dio mockDio;

  setUp(() {
    mockDio = Dio();
    mockDio.httpClientAdapter = ThreadsMockAdapter();
    ThreadsMockAdapter.reset();
  });

  group('Threads resolver', () {
    test('TH-RES-001 image HTML yields an image resource', () {
      final results = ThreadsResolver.parseHtmlResources(
        html: threadsImageHtml(),
        pageUrl: Uri.parse(threadsPostUrl),
        contentId: threadsPostId,
      );
      expect(results, hasLength(1));
      expect(results.single.directUrl, threadsImageUrl);
      expect(results.single.platform, 'Threads');
      expect(results.single.mimeType, 'image/jpeg');
    });

    test('TH-RES-002 discover uses public post HTML', () async {
      ThreadsMockAdapter.htmlResponse = threadsVideoHtml();
      final result = await ThreadsResolver(dio: mockDio).discover(
        Uri.parse(threadsPostUrl),
      );
      expect(result, isNotNull);
      expect(result!.directUrl, threadsVideoUrl);
    });

    test('TH-RES-003 profile URL is not discovered', () async {
      ThreadsMockAdapter.htmlResponse = threadsImageHtml();
      final results = await ThreadsResolver(dio: mockDio).discoverAll(
        Uri.parse(threadsProfileUrl),
      );
      expect(results, isEmpty);
    });

    test('TH-RES-004 home URL is not discovered', () async {
      ThreadsMockAdapter.htmlResponse = threadsImageHtml();
      final results = await ThreadsResolver(dio: mockDio).discoverAll(
        Uri.parse(threadsHomeUrl),
      );
      expect(results, isEmpty);
    });

    test('TH-RES-005 registry skips non-downloadable Threads pages', () async {
      final registry = ContentProviderRegistry(dio: mockDio);
      ThreadsMockAdapter.htmlResponse = threadsImageHtml();
      expect(await registry.discover(Uri.parse(threadsHomeUrl)), isNull);
      expect(await registry.discover(Uri.parse(threadsProfileUrl)), isNull);
    });

    test('TH-RES-006 registry discovers a public post', () async {
      final registry = ContentProviderRegistry(dio: mockDio);
      ThreadsMockAdapter.htmlResponse = threadsVideoHtml();
      final result = await registry.discover(Uri.parse(threadsPostUrl));
      expect(result, isNotNull);
      expect(result!.platform, 'Threads');
    });

    test('TH-RES-007 filename is sanitized', () {
      final results = ThreadsResolver.parseHtmlResources(
        html: threadsImageHtml(title: 'Hello World'),
        pageUrl: Uri.parse(threadsPostUrl),
      );
      expect(results.single.fileName, isNot(contains('/')));
      expect(results.single.fileName.toLowerCase(), contains('.jpg'));
    });

    test('TH-RES-008 HLS-only HTML yields no media file', () {
      final results = ThreadsResolver.parseHtmlResources(
        html: threadsHlsHtml(),
        pageUrl: Uri.parse(threadsPostUrl),
      );
      expect(results, isEmpty);
      expect(
        ThreadsResolver.detectMediaType(threadsHlsHtml()),
        ThreadsMediaType.hlsOnly,
      );
    });

    test('TH-RES-009 private HTML is not parsed as media', () {
      final results = ThreadsResolver.parseHtmlResources(
        html: threadsPrivateHtml(),
        pageUrl: Uri.parse(threadsPostUrl),
      );
      expect(results, isEmpty);
    });

    test('TH-RES-010 text-only post throws no-downloadable-media', () async {
      ThreadsMockAdapter.htmlResponse = threadsTextHtml();
      expect(
        () => ThreadsResolver(dio: mockDio).discoverAll(Uri.parse(threadsPostUrl)),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message.toString().toLowerCase(),
            'message',
            contains('no downloadable media'),
          ),
        ),
      );
    });

    test('TH-RES-011 page fetch uses mobile Safari on threads.com', () {
      final headers = SocialHttpHeaders.forPageFetch(
        Uri.parse(threadsPostComUrl),
        SocialPlatform.threads,
      );
      expect(headers['User-Agent'], SocialHttpHeaders.threadsMobileUserAgent);
      expect(headers['User-Agent'], contains('iPhone'));
      expect(headers['Origin'], 'https://www.threads.com');
    });

    test('TH-RES-012 post-scoped parse ignores other posts in the feed HTML', () {
      final results = ThreadsResolver.parseHtmlResources(
        html: threadsFeedWithOtherPostHtml(),
        pageUrl: Uri.parse(threadsPostUrl),
        contentId: threadsPostId,
      );
      expect(results, hasLength(1));
      expect(results.single.directUrl, threadsImageUrl);
    });

    test('TH-RES-013 media-less shell does not hide a later target', () async {
      ThreadsMockAdapter.htmlResponse = threadsMediaLessShellHtml();
      ThreadsMockAdapter.htmlByPathContains = {
        '/t/$threadsPostId': threadsImageHtml(),
      };
      final results = await ThreadsResolver(dio: mockDio).discoverAll(
        Uri.parse(threadsPostUrl),
      );
      expect(results, hasLength(1));
      expect(results.single.directUrl, threadsImageUrl);
    });
  });
}
