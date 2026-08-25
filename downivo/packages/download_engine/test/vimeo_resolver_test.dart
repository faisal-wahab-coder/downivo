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

  group('Vimeo resolver discovery', () {
    test('VM-RES-001 discovers progressive MP4 from player config', () async {
      VimeoMockAdapter.configResponse = jsonEncode(vimeoPlayerConfig());
      final result = await VimeoResolver(dio: mockDio).discover(
        Uri.parse('https://vimeo.com/76979871'),
      );
      expect(result, isNotNull);
      expect(result!.platform, 'Vimeo');
      expect(result.directUrl, contains('file_1080.mp4'));
      expect(result.mimeType, 'video/mp4');
      expect(result.title, 'The New Vimeo Player');
    });

    test('VM-RES-002 home returns empty', () async {
      VimeoMockAdapter.configResponse = jsonEncode(vimeoPlayerConfig());
      final result = await VimeoResolver(dio: mockDio).discover(
        Uri.parse('https://vimeo.com/'),
      );
      expect(result, isNull);
    });

    test('VM-RES-003 user profile returns empty', () async {
      final result = await VimeoResolver(dio: mockDio).discover(
        Uri.parse('https://vimeo.com/staff'),
      );
      expect(result, isNull);
    });

    test('VM-RES-004 INVALID returns empty', () async {
      final result = await VimeoResolver(dio: mockDio).discover(
        Uri.parse('https://vimeo.com/INVALID'),
      );
      expect(result, isNull);
    });

    test('VM-RES-005 player URL resolves the same video', () async {
      VimeoMockAdapter.configResponse = jsonEncode(vimeoPlayerConfig());
      final result = await VimeoResolver(dio: mockDio).discover(
        Uri.parse('https://player.vimeo.com/video/76979871'),
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('file_1080.mp4'));
    });

    test('VM-RES-006 HTML playerConfig fallback', () async {
      VimeoMockAdapter.configResponse = '{}';
      VimeoMockAdapter.htmlResponse = vimeoPlayerHtml(vimeoPlayerConfig());
      final result = await VimeoResolver(dio: mockDio).discover(
        Uri.parse('https://vimeo.com/76979871'),
      );
      expect(result, isNotNull);
      expect(result!.title, 'The New Vimeo Player');
    });

    test('VM-RES-007 empty config returns null', () async {
      VimeoMockAdapter.configResponse = '{}';
      VimeoMockAdapter.htmlResponse = '<html></html>';
      final result = await VimeoResolver(dio: mockDio).discover(
        Uri.parse('https://vimeo.com/76979871'),
      );
      expect(result, isNull);
    });

    test('VM-RES-008 registry discover returns Vimeo resource', () async {
      VimeoMockAdapter.configResponse = jsonEncode(vimeoPlayerConfig());
      final result = await ContentProviderRegistry(dio: mockDio).discover(
        Uri.parse('https://vimeo.com/76979871'),
      );
      expect(result, isNotNull);
      expect(result!.platform, 'Vimeo');
    });

    test('VM-RES-009 registry does not scrape Vimeo home HTML', () async {
      VimeoMockAdapter.htmlResponse = vimeoOgHtml(
        title: 'Vimeo',
        videoUrl: 'https://player.vimeo.com/video/76979871',
        imageUrl: 'https://i.vimeocdn.com/video/home.jpg',
      );
      final result = await ContentProviderRegistry(dio: mockDio).discover(
        Uri.parse('https://vimeo.com/'),
      );
      expect(result, isNull);
    });

    test('VM-RES-010 request headers include Vimeo referer', () {
      final info = VimeoResolver.parseVideoInfo(vimeoPlayerConfig())!;
      final resource = VimeoResolver.resourceFromInfo(
        pageUrl: Uri.parse('https://vimeo.com/76979871'),
        info: info,
      )!;
      expect(resource.requestHeaders, isNotNull);
      expect(resource.requestHeaders!['Referer'], contains('vimeo.com'));
    });

    test('VM-RES-011 discoverAll returns a single video item', () async {
      VimeoMockAdapter.configResponse = jsonEncode(vimeoPlayerConfig());
      final results = await VimeoResolver(dio: mockDio).discoverAll(
        Uri.parse('https://vimeo.com/76979871'),
      );
      expect(results.length, 1);
      expect(results.first.mimeType, 'video/mp4');
    });

    test('VM-RES-012 channel video URL is downloadable and resolved', () async {
      VimeoMockAdapter.configResponse = jsonEncode(vimeoPlayerConfig());
      final result = await VimeoResolver(dio: mockDio).discover(
        Uri.parse('https://vimeo.com/channels/staffpicks/76979871'),
      );
      expect(result, isNotNull);
    });

    test('VM-RES-013 filename uses video id fallback for empty title', () {
      final config = vimeoPlayerConfig(title: '   ');
      (config['video'] as Map)['title'] = '   ';
      final info = VimeoResolver.parseVideoInfo(config)!;
      final resource = VimeoResolver.resourceFromInfo(
        pageUrl: Uri.parse('https://vimeo.com/76979871'),
        info: info,
      )!;
      expect(resource.fileName, contains('76979871'));
      expect(resource.fileName.toLowerCase(), endsWith('.mp4'));
    });
  });
}
