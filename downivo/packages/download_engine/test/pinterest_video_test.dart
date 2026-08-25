import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pinterest_fixtures.dart';

void main() {
  late Dio mockDio;

  setUp(() {
    mockDio = Dio();
    mockDio.httpClientAdapter = PinterestMockAdapter();
    PinterestMockAdapter.reset();
  });

  group('Pinterest video pin discovery', () {
    test('PT-VID-001 prefers 720p MP4 over HLS and 480p', () async {
      PinterestMockAdapter.htmlResponse = pwsHtml(pinterestVideoPin());
      final result = await PinterestResolver(dio: mockDio).discover(
        Uri.parse('https://www.pinterest.com/pin/vid123456789/'),
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('720p'));
      expect(result.directUrl, endsWith('.mp4'));
      expect(result.mimeType, 'video/mp4');
      expect(result.directUrl, isNot(contains('.m3u8')));
    });

    test('PT-VID-002 HLS-only pin returns no downloadable resource', () {
      final pin = pinterestVideoPin(includeMp4: false, includeHls: true);
      final results = PinterestResolver.parsePinObject(
        pageUrl: Uri.parse('https://www.pinterest.com/pin/hls1/'),
        pin: pin,
      );
      expect(results, isEmpty);
    });

    test('PT-VID-003 video includes thumbnail from images.orig', () {
      final results = PinterestResolver.parsePinObject(
        pageUrl: Uri.parse('https://www.pinterest.com/pin/vid123456789/'),
        pin: pinterestVideoPin(),
      );
      expect(results.single.thumbnailUrl, contains('thumb.jpg'));
    });

    test('PT-VID-004 duration is extracted on pin info', () {
      final info = PinterestPinInfo.fromPin(pinterestVideoPin());
      expect(info.durationSeconds, 15.2);
      expect(info.width, 720);
      expect(info.height, 1280);
      expect(info.isVideo, isTrue);
    });

    test('PT-VID-005 muxed MP4 has no separate audio stream', () {
      final pin = pinterestVideoPin();
      final list = (pin['videos'] as Map)['video_list'] as Map;
      expect(PinterestResolver.hasSeparateAudio(list), isFalse);
      expect(PinterestResolver.bestVideoUrl(list), isNot(contains('.m3u8')));
    });

    test('PT-VID-006 HLS-only reports separate audio limitation', () {
      final pin = pinterestVideoPin(includeMp4: false);
      final list = (pin['videos'] as Map)['video_list'] as Map;
      expect(PinterestResolver.bestVideoUrl(list), isNull);
      expect(PinterestResolver.hasSeparateAudio(list), isTrue);
    });

    test('PT-VID-007 discoverAll returns a single video item', () async {
      PinterestMockAdapter.htmlResponse = pwsHtml(pinterestVideoPin());
      final results = await PinterestResolver(dio: mockDio).discoverAll(
        Uri.parse('https://www.pinterest.com/pin/vid123456789/'),
      );
      expect(results.length, 1);
      expect(results.first.mimeType, 'video/mp4');
    });

    test('PT-VID-008 OG video fallback', () async {
      PinterestMockAdapter.htmlResponse = pinterestOgHtml(
        imageUrl: 'https://i.pinimg.com/736x/aa/bb/cc/thumb.jpg',
        videoUrl: 'https://v1.pinimg.com/videos/mc/720p/og.mp4',
        title: 'OG video',
      );
      final result = await PinterestResolver(dio: mockDio).discover(
        Uri.parse('https://www.pinterest.com/pin/ogvid/'),
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('og.mp4'));
      expect(result.mimeType, 'video/mp4');
    });
  });
}
