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

  group('Pinterest multi-media', () {
    test('PT-MULTI-001 media count matches idea pin pages', () {
      final results = PinterestResolver.parsePinObject(
        pageUrl: Uri.parse('https://www.pinterest.com/pin/idea123456789/'),
        pin: pinterestIdeaPin(),
      );
      expect(results.length, 3);
    });

    test('PT-MULTI-002 no duplicate media URLs', () {
      final results = PinterestResolver.parsePinObject(
        pageUrl: Uri.parse('https://www.pinterest.com/pin/idea123456789/'),
        pin: pinterestIdeaPin(),
      );
      expect(results.map((r) => r.directUrl).toSet().length, results.length);
    });

    test('PT-MULTI-003 filenames are unique per index', () {
      final results = PinterestResolver.parsePinObject(
        pageUrl: Uri.parse('https://www.pinterest.com/pin/idea123456789/'),
        pin: pinterestIdeaPin(),
      );
      expect(results.map((r) => r.fileName).toSet().length, 3);
    });

    test('PT-MULTI-004 image pin is a single resource', () {
      final results = PinterestResolver.parsePinObject(
        pageUrl: Uri.parse('https://www.pinterest.com/pin/580547278694592554/'),
        pin: pinterestImagePin(),
      );
      expect(results.length, 1);
    });

    test('PT-MULTI-005 registry discoverAll returns idea pin pages', () async {
      PinterestMockAdapter.htmlResponse = pwsHtml(pinterestIdeaPin());
      final results = await ContentProviderRegistry(dio: mockDio).discoverAll(
        Uri.parse('https://www.pinterest.com/pin/idea123456789/'),
      );
      expect(results.length, 3);
      expect(results.every((r) => r.platform == 'Pinterest'), isTrue);
    });

    test('PT-MULTI-006 duplicate page URLs are collapsed', () {
      final pin = pinterestIdeaPin(
        pages: [
          {
            'image': {
              'images': {
                'orig': {
                  'url': 'https://i.pinimg.com/originals/aa/bb/cc/same.jpg',
                  'width': 100,
                  'height': 100,
                },
              },
            },
          },
          {
            'image': {
              'images': {
                'orig': {
                  'url': 'https://i.pinimg.com/originals/aa/bb/cc/same.jpg',
                  'width': 100,
                  'height': 100,
                },
              },
            },
          },
        ],
      );
      final results = PinterestResolver.parsePinObject(
        pageUrl: Uri.parse('https://www.pinterest.com/pin/idea123456789/'),
        pin: pin,
      );
      expect(results.length, 1);
    });
  });
}
