import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pinterest_fixtures.dart';

void main() {
  group('Pinterest metadata mapping', () {
    test('PT-META-001 image pin fields', () {
      final info = PinterestPinInfo.fromPin(pinterestImagePin());
      expect(info.pinId, '580547278694592554');
      expect(info.title, 'Sunset photo');
      expect(info.description, 'A public sunset');
      expect(info.author, 'Alex');
      expect(info.authorId, '42');
      expect(info.width, 2000);
      expect(info.height, 3000);
      expect(info.isVideo, isFalse);
      expect(info.isIdeaPin, isFalse);
      expect(info.mimeType, 'image/png');
      expect(info.pinUrl, contains('/pin/580547278694592554/'));
    });

    test('PT-META-002 video pin duration and dimensions', () {
      final info = PinterestPinInfo.fromPin(pinterestVideoPin());
      expect(info.isVideo, isTrue);
      expect(info.durationSeconds, 15.2);
      expect(info.width, 720);
      expect(info.height, 1280);
      expect(info.mimeType, 'video/mp4');
    });

    test('PT-META-003 missing title is not fabricated', () {
      final pin = pinterestImagePin()
        ..remove('grid_title')
        ..remove('title');
      final info = PinterestPinInfo.fromPin(pin);
      expect(info.title, isNull);
    });

    test('PT-META-004 thumbnail from orig image', () {
      final info = PinterestPinInfo.fromPin(pinterestImagePin());
      expect(info.thumbnailUrl, contains('/originals/'));
    });

    test('PT-META-005 parsePinInfo from PWS payload', () {
      final payload = pwsPayload(pinterestImagePin());
      final info = PinterestResolver.parsePinInfo(
        payload: payload,
        pinId: '580547278694592554',
      );
      expect(info, isNotNull);
      expect(info!.author, 'Alex');
    });

    test('PT-META-006 resource title and platform', () {
      final results = PinterestResolver.parsePinObject(
        pageUrl: Uri.parse('https://www.pinterest.com/pin/580547278694592554/'),
        pin: pinterestImagePin(),
      );
      expect(results.single.title, 'Sunset photo');
      expect(results.single.platform, 'Pinterest');
      expect(
        results.single.pageUrl,
        'https://www.pinterest.com/pin/580547278694592554/',
      );
    });

    test('PT-META-007 MIME mapping from URL', () {
      expect(
        PinterestResolver.mimeFromUrl(
          'https://i.pinimg.com/originals/a.png',
        ),
        'image/png',
      );
      expect(
        PinterestResolver.mimeFromUrl(
          'https://i.pinimg.com/originals/a.webp',
        ),
        'image/webp',
      );
      expect(
        PinterestResolver.mimeFromUrl(
          'https://i.pinimg.com/originals/a.gif',
        ),
        'image/gif',
      );
      expect(
        PinterestResolver.mimeFromUrl(
          'https://v1.pinimg.com/videos/mc/720p/a.mp4',
        ),
        'video/mp4',
      );
      expect(PinterestResolver.normalizeMime('image/jpg'), 'image/jpeg');
    });

    test('PT-META-008 findPinObject locates pin in nested PWS JSON', () {
      final found = PinterestResolver.findPinObject(
        pwsPayload(pinterestImagePin()),
        pinId: '580547278694592554',
      );
      expect(found, isNotNull);
      expect(found!['id'], '580547278694592554');
    });
  });
}
