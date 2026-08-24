import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'vimeo_fixtures.dart';

void main() {
  final validator = UrlValidator();

  group('Vimeo URL scheme security', () {
    test('VM-SEC-001 javascript: is rejected', () {
      expect(validator.validate('javascript:alert(1)').isValid, isFalse);
    });

    test('VM-SEC-002 file: is rejected', () {
      expect(validator.validate('file:///test.mp4').isValid, isFalse);
    });

    test('VM-SEC-003 data: is rejected', () {
      expect(validator.validate('data:text/html,<h1>x</h1>').isValid, isFalse);
    });

    test('VM-SEC-004 https Vimeo URL is accepted', () {
      expect(
        validator.validate('https://vimeo.com/76979871').isValid,
        isTrue,
      );
    });
  });

  group('Vimeo private IP rejection', () {
    test('VM-SEC-010 localhost is not Vimeo', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://localhost/76979871')),
        isNull,
      );
    });

    test('VM-SEC-011 127.0.0.1 is not Vimeo', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://127.0.0.1/76979871')),
        isNull,
      );
    });

    test('VM-SEC-012 private LAN is not Vimeo', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://192.168.1.1/video.mp4')),
        isNull,
      );
    });

    test('VM-SEC-013 10.x is not Vimeo', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://10.0.0.1/video.mp4')),
        isNull,
      );
    });

    test('VM-SEC-014 example.com video is not Vimeo', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('https://example.com/video.mp4')),
        isNull,
      );
    });
  });

  group('Vimeo filename sanitization', () {
    test('VM-SEC-020 path traversal is sanitized', () {
      final name = VimeoResolver.buildFileName(
        videoId: '76979871',
        title: '../../../../test.mp4',
        quality: '720p',
        mimeType: 'video/mp4',
      );
      expect(name, isNot(contains('/')));
      expect(name, isNot(contains('\\')));
      expect(name, isNot(contains('..')));
    });

    test('VM-SEC-021 slash and colon are stripped', () {
      final name = VimeoResolver.buildFileName(
        videoId: '1',
        title: 'a/b:c?.mp4',
        mimeType: 'video/mp4',
      );
      expect(name, isNot(contains('/')));
      expect(name, isNot(contains(':')));
      expect(name, isNot(contains('?')));
    });

    test('VM-SEC-022 quotes and pipes are stripped', () {
      final name = FileNameResolver.sanitize('title|"file".mp4');
      expect(name, isNot(contains('|')));
      expect(name, isNot(contains('"')));
    });

    test('VM-SEC-023 resolver filename cannot escape directory', () {
      final info = VimeoResolver.parseVideoInfo(
        vimeoPlayerConfig(title: '../../../../test.mp4'),
      )!;
      final resource = VimeoResolver.resourceFromInfo(
        pageUrl: Uri.parse('https://vimeo.com/76979871'),
        info: info,
      )!;
      expect(resource.fileName, isNot(contains('..')));
      expect(resource.fileName, isNot(contains('/')));
    });

    test('VM-SEC-024 emoji title is sanitized', () {
      final info = VimeoResolver.parseVideoInfo(
        vimeoPlayerConfig(title: 'Sunset 🔥 video'),
      )!;
      final resource = VimeoResolver.resourceFromInfo(
        pageUrl: Uri.parse('https://vimeo.com/76979871'),
        info: info,
      )!;
      expect(resource.fileName, isNot(contains('/')));
      expect(resource.fileName, isNotEmpty);
    });

    test('VM-SEC-025 very long title is truncated', () {
      final info = VimeoResolver.parseVideoInfo(
        vimeoPlayerConfig(title: 'A' * 400),
      )!;
      final resource = VimeoResolver.resourceFromInfo(
        pageUrl: Uri.parse('https://vimeo.com/76979871'),
        info: info,
      )!;
      expect(resource.fileName.length, lessThan(120));
    });

    test('VM-SEC-026 Arabic title is kept as a safe filename', () {
      final name = VimeoResolver.buildFileName(
        videoId: '76979871',
        title: 'مرحبا بالعالم',
        quality: '720p',
        mimeType: 'video/mp4',
      );
      expect(name, contains('مرحبا'));
      expect(name, isNot(contains('/')));
      expect(name.toLowerCase(), endsWith('.mp4'));
    });
  });

  group('Vimeo malformed URLs', () {
    test('VM-SEC-030 encoded .. does not become a video id', () {
      final uri = Uri.parse('https://vimeo.com/%2e%2e/test.mp4');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.vimeo);
      expect(VimeoUri.videoIdFromUri(uri), isNull);
    });

    test('VM-SEC-031 very long URL still classifies', () {
      final slug = 'x' * 4000;
      final uri = Uri.parse('https://vimeo.com/76979871/$slug');
      expect(VimeoUri.classifyUrl(uri), VimeoContentType.video);
      expect(VimeoUri.videoIdFromUri(uri), '76979871');
    });

    test('VM-SEC-032 tracking params cannot bypass duplicate identity', () {
      final a = VimeoUri.contentIdentity(
        VimeoUri.normalize(
          Uri.parse('https://vimeo.com/76979871?utm_source=share'),
        ),
      );
      final b = VimeoUri.contentIdentity(
        VimeoUri.normalize(
          Uri.parse('https://player.vimeo.com/video/76979871?fbclid=zz'),
        ),
      );
      expect(a, b);
    });
  });
}
