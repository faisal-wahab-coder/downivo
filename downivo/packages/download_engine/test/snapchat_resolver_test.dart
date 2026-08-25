import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'snapchat_fixtures.dart';

void main() {
  late Dio mockDio;

  setUp(() {
    mockDio = Dio();
    mockDio.httpClientAdapter = SnapchatMockAdapter();
    SnapchatMockAdapter.reset();
  });

  group('Snapchat resolver', () {
    test('SC-RES-001 photo HTML yields a photo resource', () {
      final results = SnapchatResolver.parseHtmlResources(
        html: snapchatPhotoHtml(),
        pageUrl: Uri.parse(snapchatSnapUrl),
        contentId: snapchatSnapId,
      );
      expect(results, hasLength(1));
      expect(results.single.directUrl, snapchatPhotoUrl);
      expect(results.single.platform, 'Snapchat');
      expect(results.single.mimeType, 'image/jpeg');
    });

    test('SC-RES-002 discover uses public Spotlight HTML', () async {
      SnapchatMockAdapter.htmlResponse = snapchatVideoHtml();
      final result = await SnapchatResolver(dio: mockDio).discover(
        Uri.parse(snapchatSpotlightUrl),
      );
      expect(result, isNotNull);
      expect(result!.directUrl, snapchatVideoUrl);
    });

    test('SC-RES-003 profile URL is not discovered', () async {
      SnapchatMockAdapter.htmlResponse = snapchatPhotoHtml();
      final results = await SnapchatResolver(dio: mockDio).discoverAll(
        Uri.parse(snapchatProfileUrl),
      );
      expect(results, isEmpty);
    });

    test('SC-RES-004 private chat URL is not fetched', () async {
      SnapchatMockAdapter.htmlResponse = snapchatPhotoHtml();
      final results = await SnapchatResolver(dio: mockDio).discoverAll(
        Uri.parse(snapchatChatUrl),
      );
      expect(results, isEmpty);
    });

    test('SC-RES-005 registry skips non-downloadable Snapchat pages', () async {
      final registry = ContentProviderRegistry(dio: mockDio);
      SnapchatMockAdapter.htmlResponse = snapchatPhotoHtml();
      expect(await registry.discover(Uri.parse(snapchatHomeUrl)), isNull);
      expect(await registry.discover(Uri.parse(snapchatProfileUrl)), isNull);
    });

    test('SC-RES-006 registry discovers a public Spotlight', () async {
      final registry = ContentProviderRegistry(dio: mockDio);
      SnapchatMockAdapter.htmlResponse = snapchatVideoHtml();
      final result = await registry.discover(Uri.parse(snapchatSpotlightUrl));
      expect(result, isNotNull);
      expect(result!.platform, 'Snapchat');
    });

    test('SC-RES-006b registry discovers /@user/spotlight/{id}', () async {
      final registry = ContentProviderRegistry(dio: mockDio);
      SnapchatMockAdapter.htmlResponse = snapchatBoltVideoHtml();
      final result = await registry.discover(
        Uri.parse(snapchatProfileSpotlightUrl),
      );
      expect(result, isNotNull);
      expect(result!.directUrl, snapchatBoltVideoUrl);
      expect(result.mimeType, 'video/mp4');
      expect(result.fileName.toLowerCase(), endsWith('.mp4'));
    });

    test('SC-RES-007 filename is sanitized', () {
      final results = SnapchatResolver.parseHtmlResources(
        html: snapchatPhotoHtml(title: 'Hello World'),
        pageUrl: Uri.parse(snapchatSnapUrl),
      );
      expect(results.single.fileName, isNot(contains('/')));
      expect(results.single.fileName.toLowerCase(), contains('.jpg'));
    });

    test('SC-RES-008 direct CDN URL is downloadable', () async {
      final results = await SnapchatResolver(dio: mockDio).discoverAll(
        Uri.parse(snapchatPhotoUrl),
      );
      expect(results, hasLength(1));
      expect(results.single.directUrl, snapchatPhotoUrl);
    });

    test('SC-RES-008b extensionless CDN media uses an mp4 name', () async {
      final results = await SnapchatResolver(dio: mockDio).discoverAll(
        Uri.parse(snapchatBoltVideoUrl),
      );
      expect(results, hasLength(1));
      expect(results.single.directUrl, snapchatBoltVideoUrl);
      expect(results.single.mimeType, 'video/mp4');
      expect(results.single.fileName.toLowerCase(), endsWith('.mp4'));
    });

    test('SC-RES-009 HLS-only HTML yields no media file', () {
      final results = SnapchatResolver.parseHtmlResources(
        html: snapchatHlsHtml(),
        pageUrl: Uri.parse(snapchatSpotlightUrl),
      );
      expect(results, isEmpty);
      expect(
        SnapchatResolver.detectMediaType(snapchatHlsHtml()),
        SnapchatMediaType.hlsOnly,
      );
    });

    test('SC-RES-010 private HTML is not parsed as media', () {
      final results = SnapchatResolver.parseHtmlResources(
        html: snapchatPrivateHtml(),
        pageUrl: Uri.parse(snapchatSpotlightUrl),
      );
      expect(results, isEmpty);
      expect(
        SnapchatResolver.classifyHtml(snapchatPrivateHtml()),
        SnapchatHtmlStatus.restricted,
      );
    });
  });
}
