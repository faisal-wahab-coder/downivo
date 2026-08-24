import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Facebook security tests: malformed URLs, unsafe schemes, injection,
/// path traversal, private IPs, and filename sanitization.
void main() {
  final validator = UrlValidator();

  group('Facebook URL scheme security', () {
    test('FB-SEC-001 javascript: scheme is rejected', () {
      expect(validator.validate('javascript:alert(1)').isValid, isFalse);
    });

    test('FB-SEC-002 file:///test is rejected', () {
      expect(validator.validate('file:///test').isValid, isFalse);
    });

    test('FB-SEC-003 data: scheme is rejected', () {
      expect(validator.validate('data:text/html,<h1>hi</h1>').isValid, isFalse);
    });

    test('FB-SEC-004 ftp: scheme is rejected', () {
      expect(validator.validate('ftp://facebook.com/file').isValid, isFalse);
    });

    test('FB-SEC-005 http is accepted', () {
      expect(
        validator.validate('http://www.facebook.com/watch/?v=123').isValid,
        isTrue,
      );
    });

    test('FB-SEC-006 https is accepted', () {
      expect(
        validator.validate('https://www.facebook.com/watch/?v=123').isValid,
        isTrue,
      );
    });
  });

  group('Facebook private IP rejection', () {
    test('FB-SEC-010 localhost is not Facebook', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://localhost/watch/?v=123')),
        isNull,
      );
    });

    test('FB-SEC-011 127.0.0.1 is not Facebook', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://127.0.0.1/watch/?v=123')),
        isNull,
      );
    });

    test('FB-SEC-012 192.168.1.1 is not Facebook', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://192.168.1.1/watch/?v=123')),
        isNull,
      );
    });

    test('FB-SEC-013 10.0.0.1 is not Facebook', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://10.0.0.1/watch/?v=123')),
        isNull,
      );
    });

    test('FB-SEC-014 0.0.0.0 is not Facebook', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://0.0.0.0/watch/?v=123')),
        isNull,
      );
    });
  });

  group('Facebook filename sanitization', () {
    test('FB-SEC-020 path traversal ../../../../etc/passwd is sanitized', () {
      final name = FileNameResolver.sanitize('../../../../etc/passwd');
      // sanitize uses basename and replaces separators — no directory escape
      expect(name, isNot(contains('/')));
      expect(name, isNot(equals('../../../../etc/passwd')));
    });

    test('FB-SEC-021 path traversal ..\\..\\Windows\\System32 is sanitized', () {
      final name = FileNameResolver.sanitize('..\\..\\Windows\\System32');
      // sanitize uses basename and replaces separators — no directory escape
      expect(name, isNot(contains('\\')));
      expect(name, isNot(equals('..\\..\\Windows\\System32')));
    });

    test('FB-SEC-022 null bytes in filename are removed', () {
      final name = FileNameResolver.sanitize('test\x00file.mp4');
      expect(name, isNot(contains('\x00')));
      expect(name, endsWith('.mp4'));
    });

    test('FB-SEC-023 control characters are removed', () {
      final name = FileNameResolver.sanitize('test\x01\x02\x03file.mp4');
      expect(name, isNot(contains('\x01')));
      expect(name, endsWith('.mp4'));
    });

    test('FB-SEC-024 empty filename gets default', () {
      final name = FileNameResolver.sanitize('');
      expect(name, isNotEmpty);
    });

    test('FB-SEC-025 dots-only filename is handled', () {
      final name = FileNameResolver.sanitize('...');
      expect(name, isNotEmpty);
      expect(name, isNot(equals('...')));
    });

    test('FB-SEC-026 very long filename is handled', () {
      final longName = 'a' * 500;
      final name = FileNameResolver.sanitize(longName);
      expect(name, isNotEmpty);
    });

    test('FB-SEC-027 special characters are sanitized', () {
      final name = FileNameResolver.sanitize('file<>:"/\\|?*.mp4');
      expect(name, isNot(contains('<')));
      expect(name, isNot(contains('>')));
      expect(name, isNot(contains(':')));
      expect(name, isNot(contains('"')));
      expect(name, isNot(contains('|')));
      expect(name, isNot(contains('?')));
      expect(name, isNot(contains('*')));
    });
  });

  group('Facebook URL encoding security', () {
    test('FB-SEC-030 encoded URL is parseable', () {
      final uri = Uri.parse(
        'https://www.facebook.com/watch/?v=123%20456',
      );
      expect(SocialPlatform.fromUri(uri), SocialPlatform.facebook);
    });

    test('FB-SEC-031 double-encoded URL is parseable', () {
      final uri = Uri.parse(
        'https://www.facebook.com/watch/?v=123%2520456',
      );
      expect(SocialPlatform.fromUri(uri), SocialPlatform.facebook);
    });

    test('FB-SEC-032 unicode URL is parseable', () {
      final uri = Uri.parse(
        'https://www.facebook.com/watch/?v=12345',
      );
      expect(SocialPlatform.fromUri(uri), SocialPlatform.facebook);
    });
  });

  group('Facebook invalid URL edge cases', () {
    test('FB-SEC-040 empty string is rejected', () {
      expect(validator.validate('').isValid, isFalse);
    });

    test('FB-SEC-041 whitespace-only is rejected', () {
      expect(validator.validate('   ').isValid, isFalse);
    });

    test('FB-SEC-042 no scheme is rejected', () {
      expect(validator.validate('www.facebook.com/watch/?v=123').isValid, isFalse);
    });

    test('FB-SEC-043 www.facebook.com without scheme parsed but not valid', () {
      // Uri.parse handles this differently - it's treated as a path
      final result = validator.validate('www.facebook.com');
      // No scheme means it won't match http/https
      expect(result.isValid, isFalse);
    });
  });
}
