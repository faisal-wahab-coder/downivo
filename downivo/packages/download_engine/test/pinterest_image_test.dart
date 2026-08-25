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

  group('Pinterest image pin discovery', () {
    test('PT-IMG-001 discovers original PNG not 736x JPEG', () async {
      PinterestMockAdapter.htmlResponse = pwsHtml(pinterestImagePin());
      final result = await PinterestResolver(dio: mockDio).discover(
        Uri.parse('https://www.pinterest.com/pin/580547278694592554/'),
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('/originals/'));
      expect(result.directUrl, endsWith('.png'));
      expect(result.mimeType, 'image/png');
      expect(result.directUrl, isNot(contains('/736x/')));
      expect(result.directUrl, isNot(contains('/236x/')));
    });

    test('PT-IMG-002 WebP orig keeps image/webp MIME', () async {
      PinterestMockAdapter.htmlResponse = pwsHtml(pinterestWebpPin());
      final result = await PinterestResolver(dio: mockDio).discover(
        Uri.parse('https://www.pinterest.com/pin/webp123/'),
      );
      expect(result, isNotNull);
      expect(result!.mimeType, 'image/webp');
      expect(result.fileName, endsWith('.webp'));
      expect(result.fileName, isNot(endsWith('.jpg')));
    });

    test('PT-IMG-003 JPEG orig uses image/jpeg', () {
      final pin = pinterestImagePin(
        origUrl: 'https://i.pinimg.com/originals/ab/cd/ef/photo.jpg',
      );
      final results = PinterestResolver.parsePinObject(
        pageUrl: Uri.parse('https://www.pinterest.com/pin/580547278694592554/'),
        pin: pin,
      );
      expect(results.single.mimeType, 'image/jpeg');
      expect(results.single.fileName, endsWith('.jpg'));
    });

    test('PT-IMG-004 prefers orig over larger-looking 736x map order', () {
      final pin = {
        'id': '1',
        'grid_title': 'Order test',
        'images': {
          '236x': {
            'url': 'https://i.pinimg.com/236x/a/b/c/x.jpg',
            'width': 236,
            'height': 400,
          },
          'orig': {
            'url': 'https://i.pinimg.com/originals/a/b/c/x.jpg',
            'width': 1600,
            'height': 2400,
          },
          '736x': {
            'url': 'https://i.pinimg.com/736x/a/b/c/x.jpg',
            'width': 736,
            'height': 1100,
          },
        },
        'pinner': {'full_name': 'A', 'id': '1'},
      };
      final url = PinterestResolver.bestImageUrl(pin['images'] as Map);
      expect(url, contains('/originals/'));
    });

    test('PT-IMG-005 OG 736x fallback upgrades to originals', () async {
      PinterestMockAdapter.htmlResponse = pinterestOgHtml(
        imageUrl: 'https://i.pinimg.com/736x/ab/cd/ef/photo.jpg',
        title: 'OG only',
      );
      final result = await PinterestResolver(dio: mockDio).discover(
        Uri.parse('https://www.pinterest.com/pin/999/'),
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('/originals/'));
    });

    test('PT-IMG-006 thumbnail is present', () {
      final results = PinterestResolver.parsePinObject(
        pageUrl: Uri.parse('https://www.pinterest.com/pin/580547278694592554/'),
        pin: pinterestImagePin(),
      );
      expect(results.single.thumbnailUrl, isNotNull);
      expect(results.single.thumbnailUrl, startsWith('http'));
    });

    test('PT-IMG-007 direct pinimg URL upgrades and downloads as image', () async {
      final result = await PinterestResolver(dio: mockDio).discover(
        Uri.parse('https://i.pinimg.com/236x/ab/cd/ef/photo.jpg'),
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('/originals/'));
      expect(result.mimeType, 'image/jpeg');
    });
  });
}
