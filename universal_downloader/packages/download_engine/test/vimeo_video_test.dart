import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'vimeo_fixtures.dart';

void main() {
  late Dio mockDio;

  setUp(() {
    mockDio = Dio();
    mockDio.httpClientAdapter = VimeoMockAdapter();
    VimeoMockAdapter.reset();
  });

  group('Vimeo video discovery', () {
    test('VM-VID-001 prefers highest progressive MP4 over HLS', () async {
      VimeoMockAdapter.configResponse = jsonEncode(vimeoPlayerConfig());
      final result = await VimeoResolver(dio: mockDio).discover(
        Uri.parse('https://vimeo.com/76979871'),
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('1080.mp4'));
      expect(result.directUrl, isNot(contains('.m3u8')));
      expect(result.mimeType, 'video/mp4');
    });

    test('VM-VID-002 HLS-only video is not downloadable', () {
      expect(VimeoResolver.parseVideoInfo(vimeoHlsOnlyConfig()), isNull);
      expect(
        VimeoResolver.restrictionFromConfig(vimeoHlsOnlyConfig()),
        VimeoRestriction.hlsOnly,
      );
    });

    test('VM-VID-003 player URL is the same video', () async {
      VimeoMockAdapter.configResponse = jsonEncode(vimeoPlayerConfig());
      final a = await VimeoResolver(dio: mockDio).discover(
        Uri.parse('https://vimeo.com/76979871'),
      );
      final b = await VimeoResolver(dio: mockDio).discover(
        Uri.parse('https://player.vimeo.com/video/76979871'),
      );
      expect(a!.directUrl, b!.directUrl);
    });

    test('VM-VID-004 dimensions match selected progressive file', () {
      final info = VimeoResolver.parseVideoInfo(vimeoPlayerConfig())!;
      expect(info.selectedQuality!.width, 1920);
      expect(info.selectedQuality!.height, 1080);
    });

    test('VM-VID-005 og:video player URL is not treated as media', () {
      expect(
        MediaExtractor.extract(
          pageUrl: Uri.parse('https://vimeo.com/76979871'),
          html: vimeoOgHtml(
            title: 'Demo',
            videoUrl: 'https://player.vimeo.com/video/76979871',
          ),
          platform: SocialPlatform.vimeo,
        ),
        isNull,
      );
    });

    test('VM-VID-006 og:video direct mp4 is accepted as HTML fallback', () {
      final result = MediaExtractor.extract(
        pageUrl: Uri.parse('https://vimeo.com/76979871'),
        html: vimeoOgHtml(
          title: 'Demo',
          videoUrl:
              'https://vod-progressive.akamaized.net/exp=1/vimeo/clip.mp4',
        ),
        platform: SocialPlatform.vimeo,
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('.mp4'));
    });
  });
}
