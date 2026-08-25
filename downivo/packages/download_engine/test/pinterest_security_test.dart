import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pinterest_fixtures.dart';

void main() {
  final validator = UrlValidator();

  group('Pinterest URL scheme security', () {
    test('PT-SEC-001 javascript: is rejected', () {
      expect(validator.validate('javascript:alert(1)').isValid, isFalse);
    });

    test('PT-SEC-002 file: is rejected', () {
      expect(validator.validate('file:///test.jpg').isValid, isFalse);
    });

    test('PT-SEC-003 data: is rejected', () {
      expect(validator.validate('data:text/html,<h1>x</h1>').isValid, isFalse);
    });

    test('PT-SEC-004 https Pinterest URL is accepted', () {
      expect(
        validator.validate('https://www.pinterest.com/pin/123/').isValid,
        isTrue,
      );
    });
  });

  group('Pinterest private IP rejection', () {
    test('PT-SEC-010 localhost is not Pinterest', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://localhost/pin/123/')),
        isNull,
      );
    });

    test('PT-SEC-011 127.0.0.1 is not Pinterest', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://127.0.0.1/pin/123/')),
        isNull,
      );
    });

    test('PT-SEC-012 private LAN is not Pinterest', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://192.168.1.1/pin/123/')),
        isNull,
      );
    });

    test('PT-SEC-013 10.x is not Pinterest', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://10.0.0.1/photo.jpg')),
        isNull,
      );
    });

    test('PT-SEC-014 example.com image is not Pinterest', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('https://example.com/image.jpg')),
        isNull,
      );
    });
  });

  group('Pinterest filename sanitization', () {
    test('PT-SEC-020 path traversal is sanitized', () {
      final name = FileNameResolver.sanitize('../../../../test.jpg');
      expect(name, isNot(contains('/')));
      expect(name, isNot(contains('\\')));
      expect(name, isNot(equals('../../../../test.jpg')));
    });

    test('PT-SEC-021 slash and colon are stripped', () {
      final name = FileNameResolver.sanitize('a/b:c?.jpg');
      expect(name, isNot(contains('/')));
      expect(name, isNot(contains(':')));
      expect(name, isNot(contains('?')));
    });

    test('PT-SEC-022 quotes and pipes are stripped', () {
      final name = FileNameResolver.sanitize('title|"file".jpg');
      expect(name, isNot(contains('|')));
      expect(name, isNot(contains('"')));
    });

    test('PT-SEC-023 resolver filename cannot escape directory', () {
      final pin = pinterestImagePin(title: '../../../../test.jpg');
      final results = PinterestResolver.parsePinObject(
        pageUrl: Uri.parse('https://www.pinterest.com/pin/580547278694592554/'),
        pin: pin,
      );
      expect(results.single.fileName, isNot(contains('..')));
      expect(results.single.fileName, isNot(contains('/')));
    });

    test('PT-SEC-024 emoji title is sanitized', () {
      final pin = pinterestImagePin(title: 'Sunset 🔥 photo');
      final results = PinterestResolver.parsePinObject(
        pageUrl: Uri.parse('https://www.pinterest.com/pin/580547278694592554/'),
        pin: pin,
      );
      expect(results.single.fileName, isNot(contains('/')));
      expect(results.single.fileName, isNotEmpty);
    });

    test('PT-SEC-025 very long title is truncated by sanitizer path', () {
      final pin = pinterestImagePin(title: 'A' * 400);
      final results = PinterestResolver.parsePinObject(
        pageUrl: Uri.parse('https://www.pinterest.com/pin/580547278694592554/'),
        pin: pin,
      );
      expect(results.single.fileName.length, lessThan(200));
    });
  });

  group('Pinterest malformed URLs', () {
    test('PT-SEC-030 encoded .. in pin URL is collapsed by Uri', () {
      final uri = Uri.parse(
        'https://www.pinterest.com/pin/123456789/%2e%2e/',
      );
      expect(SocialPlatform.fromUri(uri), SocialPlatform.pinterest);
      expect(PinterestUri.pinIdFromUri(uri), isNull);
      expect(PinterestUri.classifyUrl(uri), PinterestContentType.nonContent);
    });

    test('PT-SEC-031 very long URL still classifies', () {
      final slug = 'x' * 4000;
      final uri = Uri.parse('https://www.pinterest.com/pin/123/$slug/');
      expect(PinterestUri.classifyUrl(uri), PinterestContentType.pin);
      expect(PinterestUri.pinIdFromUri(uri), '123');
    });

    test('PT-SEC-032 tracking params cannot bypass duplicate identity', () {
      final a = PinterestUri.contentIdentity(
        PinterestUri.normalize(
          Uri.parse('https://www.pinterest.com/pin/123/?utm_source=share'),
        ),
      );
      final b = PinterestUri.contentIdentity(
        PinterestUri.normalize(
          Uri.parse('https://www.pinterest.com/pin/123/sent/?invite_code=zz'),
        ),
      );
      expect(a, b);
    });
  });
}
