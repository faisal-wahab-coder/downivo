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

  group('Pinterest resolver discovery', () {
    test('PT-RES-001 discovers image pin from __PWS_DATA__', () async {
      PinterestMockAdapter.htmlResponse = pwsHtml(pinterestImagePin());
      final result = await PinterestResolver(dio: mockDio).discover(
        Uri.parse('https://www.pinterest.com/pin/580547278694592554/'),
      );
      expect(result, isNotNull);
      expect(result!.platform, 'Pinterest');
      expect(result.directUrl, contains('/originals/'));
    });

    test('PT-RES-002 home returns empty', () async {
      PinterestMockAdapter.htmlResponse = '<html>Pinterest</html>';
      final result = await PinterestResolver(dio: mockDio).discover(
        Uri.parse('https://www.pinterest.com/'),
      );
      expect(result, isNull);
    });

    test('PT-RES-003 board returns empty (no bulk download)', () async {
      PinterestMockAdapter.htmlResponse = '<html>Board</html>';
      final result = await PinterestResolver(dio: mockDio).discover(
        Uri.parse('https://www.pinterest.com/user/my-board/'),
      );
      expect(result, isNull);
    });

    test('PT-RES-004 profile returns empty', () async {
      final result = await PinterestResolver(dio: mockDio).discover(
        Uri.parse('https://www.pinterest.com/designuser/'),
      );
      expect(result, isNull);
    });

    test('PT-RES-005 pin.it follows redirect then parses pin', () async {
      PinterestMockAdapter.redirectLocation =
          'https://www.pinterest.com/pin/580547278694592554/';
      PinterestMockAdapter.htmlResponse = pwsHtml(pinterestImagePin());
      final result = await PinterestResolver(dio: mockDio).discover(
        Uri.parse('https://pin.it/AbCdEfG'),
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('/originals/'));
    });

    test('PT-RES-006 pidgets fallback when HTML has no JSON', () async {
      PinterestMockAdapter.htmlResponse = '<html><body>empty</body></html>';
      PinterestMockAdapter.pidgetsResponse = pidgetsJson(pinterestImagePin());
      final result = await PinterestResolver(dio: mockDio).discover(
        Uri.parse('https://www.pinterest.com/pin/580547278694592554/'),
      );
      expect(result, isNotNull);
      expect(result!.mimeType, 'image/png');
    });

    test('PT-RES-007 oembed fallback upgrades thumbnail', () async {
      PinterestMockAdapter.htmlResponse = '<html></html>';
      PinterestMockAdapter.pidgetsResponse = '{"data":[]}';
      PinterestMockAdapter.oembedResponse = oembedJson(
        title: 'Embed title',
        thumbnailUrl: 'https://i.pinimg.com/236x/ab/cd/ef/photo.jpg',
      );
      final result = await PinterestResolver(dio: mockDio).discover(
        Uri.parse('https://www.pinterest.com/pin/580547278694592554/'),
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('/originals/'));
      expect(result.title, 'Embed title');
    });

    test('PT-RES-008 empty HTML returns null', () async {
      PinterestMockAdapter.htmlResponse = '';
      final result = await PinterestResolver(dio: mockDio).discover(
        Uri.parse('https://www.pinterest.com/pin/123/'),
      );
      expect(result, isNull);
    });

    test('PT-RES-009 parseHtmlResources from PWS script', () {
      final html = pwsHtml(pinterestImagePin());
      final results = PinterestResolver.parseHtmlResources(
        html: html,
        pageUrl: Uri.parse('https://www.pinterest.com/pin/580547278694592554/'),
        pinId: '580547278694592554',
      );
      expect(results, isNotEmpty);
    });

    test('PT-RES-010 registry discover returns Pinterest resource', () async {
      PinterestMockAdapter.htmlResponse = pwsHtml(pinterestImagePin());
      final result = await ContentProviderRegistry(dio: mockDio).discover(
        Uri.parse('https://www.pinterest.com/pin/580547278694592554/'),
      );
      expect(result, isNotNull);
      expect(result!.platform, 'Pinterest');
    });

    test('PT-RES-011 registry does not scrape Pinterest home HTML', () async {
      PinterestMockAdapter.htmlResponse = pinterestOgHtml(
        imageUrl: 'https://i.pinimg.com/736x/home.jpg',
        title: 'Pinterest',
      );
      final result = await ContentProviderRegistry(dio: mockDio).discover(
        Uri.parse('https://www.pinterest.com/'),
      );
      expect(result, isNull);
    });

    test('PT-RES-012 filename uses pin id fallback for unicode title', () {
      final pin = pinterestImagePin(title: 'مرحبا بالعالم');
      final results = PinterestResolver.parsePinObject(
        pageUrl: Uri.parse('https://www.pinterest.com/pin/580547278694592554/'),
        pin: pin,
      );
      expect(results.single.fileName, isNot(contains('..')));
      expect(results.single.fileName, isNot(contains('/')));
      expect(results.single.fileName.toLowerCase(), contains('.png'));
    });

    test('PT-RES-013 request headers include Pinterest referer', () {
      final results = PinterestResolver.parsePinObject(
        pageUrl: Uri.parse('https://www.pinterest.com/pin/580547278694592554/'),
        pin: pinterestImagePin(),
      );
      expect(results.single.requestHeaders, isNotNull);
      expect(
        results.single.requestHeaders!['Referer'],
        contains('pinterest.com'),
      );
    });
  });
}
