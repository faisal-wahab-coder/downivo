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

  group('Pinterest Idea Pin', () {
    test('PT-IDEA-001 parsePinInfo marks idea pin and page count', () {
      final info = PinterestPinInfo.fromPin(pinterestIdeaPin());
      expect(info.isIdeaPin, isTrue);
      expect(info.pageCount, 3);
      expect(info.mediaType, 'idea_pin');
    });

    test('PT-IDEA-002 discoverAll returns pages in order', () {
      final results = PinterestResolver.parsePinObject(
        pageUrl: Uri.parse('https://www.pinterest.com/pin/idea123456789/'),
        pin: pinterestIdeaPin(),
      );
      expect(results.length, 3);
      expect(results[0].directUrl, contains('one.jpg'));
      expect(results[1].directUrl, contains('two.png'));
      expect(results[2].directUrl, contains('three.mp4'));
    });

    test('PT-IDEA-003 mixed MIME is preserved per page', () {
      final results = PinterestResolver.parsePinObject(
        pageUrl: Uri.parse('https://www.pinterest.com/pin/idea123456789/'),
        pin: pinterestIdeaPin(),
      );
      expect(results[0].mimeType, 'image/jpeg');
      expect(results[1].mimeType, 'image/png');
      expect(results[2].mimeType, 'video/mp4');
    });

    test('PT-IDEA-004 HLS on a story page is skipped in favor of MP4', () {
      final results = PinterestResolver.parsePinObject(
        pageUrl: Uri.parse('https://www.pinterest.com/pin/idea123456789/'),
        pin: pinterestIdeaPin(),
      );
      expect(results[2].directUrl, isNot(contains('.m3u8')));
    });

    test('PT-IDEA-005 cover image is not duplicated as an extra item', () {
      final results = PinterestResolver.parsePinObject(
        pageUrl: Uri.parse('https://www.pinterest.com/pin/idea123456789/'),
        pin: pinterestIdeaPin(),
      );
      expect(
        results.any((r) => r.directUrl.contains('cover.jpg')),
        isFalse,
      );
    });

    test('PT-IDEA-006 HTTP discoverAll returns ordered idea pin pages', () async {
      PinterestMockAdapter.htmlResponse = pwsHtml(pinterestIdeaPin());
      final results = await PinterestResolver(dio: mockDio).discoverAll(
        Uri.parse('https://www.pinterest.com/pin/idea123456789/'),
      );
      expect(results.length, 3);
      expect(results[0].directUrl, contains('one.jpg'));
      expect(results[2].mimeType, 'video/mp4');
    });

    test('PT-IDEA-007 single-page idea pin returns one resource', () {
      final pin = pinterestIdeaPin(
        pages: [
          {
            'image': {
              'images': {
                'orig': {
                  'url': 'https://i.pinimg.com/originals/aa/bb/cc/only.jpg',
                  'width': 1080,
                  'height': 1920,
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
      expect(results.single.directUrl, contains('only.jpg'));
    });
  });
}
