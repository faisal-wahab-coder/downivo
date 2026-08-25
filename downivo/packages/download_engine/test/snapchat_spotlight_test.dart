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

  group('Snapchat Spotlight', () {
    test('SC-SPOT-001 URL is SPOTLIGHT', () {
      expect(
        SnapchatUri.classifyUrl(Uri.parse(snapchatSpotlightUrl)),
        SnapchatContentType.spotlight,
      );
    });

    test('SC-SPOT-002 video HTML is VIDEO', () {
      expect(
        SnapchatResolver.detectMediaType(snapchatVideoHtml()),
        SnapchatMediaType.video,
      );
    });

    test('SC-SPOT-003 resolves the exposed MP4', () {
      final results = SnapchatResolver.parseHtmlResources(
        html: snapchatVideoHtml(),
        pageUrl: Uri.parse(snapchatSpotlightUrl),
      );
      expect(results.single.directUrl, snapchatVideoUrl);
      expect(results.single.mimeType, 'video/mp4');
    });

    test('SC-SPOT-004 duration thumbnail and dimensions', () {
      final info = SnapchatResolver.parseContentInfo(
        html: snapchatVideoHtml(),
        pageUrl: Uri.parse(snapchatSpotlightUrl),
      );
      expect(info.durationSeconds, 12.5);
      expect(info.thumbnailUrl, snapchatThumbUrl);
      expect(info.width, 1080);
      expect(info.height, 1920);
      expect(info.creator, 'Fixture User');
    });

    test('SC-SPOT-005 discoverAll returns the Spotlight video', () async {
      SnapchatMockAdapter.htmlResponse = snapchatVideoHtml();
      final results = await SnapchatResolver(dio: mockDio).discoverAll(
        Uri.parse(snapchatSpotlightUrl),
      );
      expect(results, hasLength(1));
      expect(results.single.platform, 'Snapchat');
    });

    test('SC-SPOT-005b /@user/spotlight/{id} discovers the video', () async {
      SnapchatMockAdapter.htmlResponse = snapchatVideoHtml();
      final results = await SnapchatResolver(dio: mockDio).discoverAll(
        Uri.parse(snapchatProfileSpotlightUrl),
      );
      expect(results, hasLength(1));
      expect(results.single.directUrl, snapchatVideoUrl);
      expect(results.single.mimeType, 'video/mp4');
    });

    test('SC-SPOT-005c extensionless bolt-gcdn og:video is an MP4', () {
      final results = SnapchatResolver.parseHtmlResources(
        html: snapchatBoltVideoHtml(),
        pageUrl: Uri.parse(snapchatProfileSpotlightUrl),
      );
      expect(results, hasLength(1));
      expect(results.single.directUrl, snapchatBoltVideoUrl);
      expect(results.single.mimeType, 'video/mp4');
      expect(results.single.fileName.toLowerCase(), endsWith('.mp4'));
    });

    test('SC-SPOT-007 related Spotlight JSON is not extra videos', () {
      final results = SnapchatResolver.parseHtmlResources(
        html: snapchatSpotlightRelatedHtml(),
        pageUrl: Uri.parse(snapchatProfileSpotlightUrl),
      );
      expect(results, hasLength(1));
      expect(results.single.directUrl, snapchatBoltVideoUrl);
      expect(
        SnapchatResolver.detectMediaType(snapchatSpotlightRelatedHtml()),
        SnapchatMediaType.video,
      );
    });

    test('SC-SPOT-006 feed is not downloadable', () {
      expect(
        SnapchatUri.isDownloadable(Uri.parse(snapchatSpotlightFeedUrl)),
        isFalse,
      );
    });
  });
}
