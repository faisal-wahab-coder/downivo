import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final validator = UrlValidator();

  group('SoundCloud URL scheme security', () {
    test('SC-SEC-001 javascript: is rejected', () {
      expect(validator.validate('javascript:alert(1)').isValid, isFalse);
      expect(
        SocialPlatform.fromUri(Uri.parse('javascript:alert(1)')),
        isNull,
      );
    });

    test('SC-SEC-002 file: is rejected', () {
      expect(validator.validate('file:///test.mp3').isValid, isFalse);
    });

    test('SC-SEC-003 data: is rejected', () {
      expect(
        validator.validate('data:text/html,<h1>hi</h1>').isValid,
        isFalse,
      );
    });

    test('SC-SEC-004 ftp: is rejected', () {
      expect(validator.validate('ftp://soundcloud.com/file').isValid, isFalse);
    });

    test('SC-SEC-005 https SoundCloud is accepted', () {
      expect(
        validator.validate('https://soundcloud.com/artist/track').isValid,
        isTrue,
      );
    });
  });

  group('SoundCloud private / local hosts', () {
    test('SC-SEC-010 localhost is not SoundCloud', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://localhost/artist/track')),
        isNull,
      );
    });

    test('SC-SEC-011 127.0.0.1 is not SoundCloud', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://127.0.0.1/artist/track')),
        isNull,
      );
    });

    test('SC-SEC-012 192.168.1.1 is not SoundCloud', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://192.168.1.1/artist/track')),
        isNull,
      );
    });

    test('SC-SEC-013 10.0.0.1 is not SoundCloud', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://10.0.0.1/artist/track')),
        isNull,
      );
    });
  });

  group('SoundCloud filename sanitization', () {
    test('SC-SEC-020 path traversal is sanitized', () {
      final name = FileNameResolver.sanitize('../../../../test.mp3');
      expect(name.contains('/'), isFalse);
      expect(name.contains('\\'), isFalse);
      expect(name, isNot(equals('../../../../test.mp3')));
      expect(name, isNot(startsWith('/')));
    });

    test('SC-SEC-021 slash and colon are stripped', () {
      final name = FileNameResolver.sanitize('artist/track:name?.mp3');
      expect(name.contains('/'), isFalse);
      expect(name.contains(':'), isFalse);
      expect(name.contains('?'), isFalse);
    });

    test('SC-SEC-022 quotes and pipes are stripped', () {
      final name = FileNameResolver.sanitize('track|"name".mp3');
      expect(name.contains('"'), isFalse);
      expect(name.contains('|'), isFalse);
    });

    test('SC-SEC-023 emoji title does not crash', () {
      final name = FileNameResolver.sanitize('track 🔥 fire.mp3');
      expect(name, isNotEmpty);
    });

    test('SC-SEC-024 Arabic title is kept safely', () {
      final name = FileNameResolver.sanitize('أغنية جميلة.mp3');
      expect(name, contains('أغنية'));
      expect(name.contains('/'), isFalse);
    });

    test('SC-SEC-025 very long title is usable as filename input', () {
      final name = FileNameResolver.sanitize('${'a' * 400}.mp3');
      expect(name, isNotEmpty);
      expect(name.contains('/'), isFalse);
    });

    test('SC-SEC-026 social filename builder blocks traversal title', () {
      final name = MediaExtractor.buildFileNameForSocial(
        pageUrl: Uri.parse('https://soundcloud.com/artist/track'),
        platform: SocialPlatform.soundcloud,
        mediaUrl: 'https://cf-media.sndcdn.com/x.mp3',
        title: '../../../../etc/passwd',
        fallbackSlug: 'track',
        mimeHint: 'audio/mpeg',
      );
      expect(name.contains('..'), isFalse);
      expect(name.contains('/'), isFalse);
    });
  });

  group('SoundCloud content identity vs tracking', () {
    test('SC-SEC-030 tracking params cannot bypass duplicate identity', () {
      final a = SoundCloudUri.normalize(
        Uri.parse('https://soundcloud.com/artist/track'),
      );
      final b = SoundCloudUri.normalize(
        Uri.parse(
          'https://soundcloud.com/artist/track?utm_source=x&si=1&fbclid=2',
        ),
      );
      expect(SoundCloudUri.contentIdentity(a), SoundCloudUri.contentIdentity(b));
    });
  });
}
