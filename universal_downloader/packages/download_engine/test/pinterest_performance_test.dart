import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pinterest_fixtures.dart';

void main() {
  group('Pinterest performance / scale', () {
    test('PT-PERF-001 large idea pin does not collapse items', () {
      final pages = [
        for (var i = 0; i < 50; i++)
          {
            'image': {
              'images': {
                'orig': {
                  'url': 'https://i.pinimg.com/originals/aa/bb/cc/img$i.jpg',
                  'width': 800,
                  'height': 1200,
                },
              },
            },
          },
      ];
      final results = PinterestResolver.parsePinObject(
        pageUrl: Uri.parse('https://www.pinterest.com/pin/idea123456789/'),
        pin: pinterestIdeaPin(pages: pages),
      );
      expect(results.length, 50);
      expect(results.map((r) => r.directUrl).toSet().length, 50);
      expect(results.map((r) => r.fileName).toSet().length, 50);
    });

    test('PT-PERF-002 parse is deterministic', () {
      final pin = pinterestIdeaPin();
      final pageUrl = Uri.parse('https://www.pinterest.com/pin/idea123456789/');
      final a = PinterestResolver.parsePinObject(pageUrl: pageUrl, pin: pin);
      final b = PinterestResolver.parsePinObject(pageUrl: pageUrl, pin: pin);
      expect(a.map((r) => r.directUrl), b.map((r) => r.directUrl));
    });

    test('PT-PERF-003 small image parse is a single resource', () {
      final results = PinterestResolver.parsePinObject(
        pageUrl: Uri.parse('https://www.pinterest.com/pin/580547278694592554/'),
        pin: pinterestImagePin(),
      );
      expect(results.length, 1);
    });

    test('PT-PERF-004 identity computation is cheap and stable', () {
      final uri = Uri.parse(
        'https://www.pinterest.com/pin/123456789/slug/?utm_source=x',
      );
      String? last;
      for (var i = 0; i < 50; i++) {
        last = PinterestUri.contentIdentity(PinterestUri.normalize(uri));
      }
      expect(last, 'pinterest:pin:123456789');
    });
  });
}
