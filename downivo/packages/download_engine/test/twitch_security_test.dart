import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'twitch_fixtures.dart';

void main() {
  final validator = UrlValidator();

  group('Twitch URL scheme security', () {
    test('TW-SEC-001 javascript: is rejected', () {
      expect(validator.validate('javascript:alert(1)').isValid, isFalse);
    });

    test('TW-SEC-002 file: is rejected', () {
      expect(validator.validate('file:///test.mp4').isValid, isFalse);
    });

    test('TW-SEC-003 data: is rejected', () {
      expect(validator.validate('data:text/html,<h1>x</h1>').isValid, isFalse);
    });

    test('TW-SEC-004 https Twitch URL is accepted', () {
      expect(
        validator.validate('https://www.twitch.tv/videos/123456789').isValid,
        isTrue,
      );
    });
  });

  group('Twitch private IP rejection', () {
    test('TW-SEC-010 localhost is not Twitch', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://localhost/shroud')),
        isNull,
      );
    });

    test('TW-SEC-011 127.0.0.1 is not Twitch', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://127.0.0.1/videos/1')),
        isNull,
      );
    });

    test('TW-SEC-012 private LAN is not Twitch', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://192.168.1.1/video.mp4')),
        isNull,
      );
    });

    test('TW-SEC-013 10.x is not Twitch', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://10.0.0.1/video.mp4')),
        isNull,
      );
    });

    test('TW-SEC-014 example.com video is not Twitch', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('https://example.com/video.mp4')),
        isNull,
      );
    });
  });

  group('Twitch filename sanitization', () {
    test('TW-SEC-020 path traversal is sanitized', () {
      final name = TwitchResolver.buildFileName(
        id: twitchClipSlug,
        title: '../../../../twitch.mp4',
        quality: '720p',
        mimeType: 'video/mp4',
      );
      expect(name, isNot(contains('/')));
      expect(name, isNot(contains('\\')));
      expect(name, isNot(contains('..')));
    });

    test('TW-SEC-021 slash and colon are stripped', () {
      final name = TwitchResolver.buildFileName(
        id: '1',
        title: 'a/b:c?.mp4',
        mimeType: 'video/mp4',
      );
      expect(name, isNot(contains('/')));
      expect(name, isNot(contains(':')));
      expect(name, isNot(contains('?')));
    });

    test('TW-SEC-022 quotes and pipes are stripped', () {
      final name = FileNameResolver.sanitize('title|"file".mp4');
      expect(name, isNot(contains('|')));
      expect(name, isNot(contains('"')));
    });

    test('TW-SEC-023 resolver filename cannot escape directory', () {
      final info = TwitchResolver.parseClipInfo(
        twitchClipPayload(clip: twitchClip(title: '../../../../twitch.mp4')),
      )!;
      final resource = TwitchResolver.resourceFromClip(
        pageUrl: Uri.parse('https://clips.twitch.tv/$twitchClipSlug'),
        info: info,
      )!;
      expect(resource.fileName, isNot(contains('..')));
      expect(resource.fileName, isNot(contains('/')));
    });

    test('TW-SEC-024 emoji title is sanitized', () {
      final info = TwitchResolver.parseClipInfo(
        twitchClipPayload(clip: twitchClip(title: 'Play 🔥 clip')),
      )!;
      final resource = TwitchResolver.resourceFromClip(
        pageUrl: Uri.parse('https://clips.twitch.tv/$twitchClipSlug'),
        info: info,
      )!;
      expect(resource.fileName, isNot(contains('/')));
      expect(resource.fileName, isNotEmpty);
    });

    test('TW-SEC-025 very long title is truncated', () {
      final info = TwitchResolver.parseClipInfo(
        twitchClipPayload(clip: twitchClip(title: 'A' * 400)),
      )!;
      final resource = TwitchResolver.resourceFromClip(
        pageUrl: Uri.parse('https://clips.twitch.tv/$twitchClipSlug'),
        info: info,
      )!;
      expect(resource.fileName.length, lessThan(120));
    });

    test('TW-SEC-026 Arabic title is kept as a safe filename', () {
      final name = TwitchResolver.buildFileName(
        id: twitchClipSlug,
        title: 'مرحبا بالعالم',
        quality: '720p',
        mimeType: 'video/mp4',
      );
      expect(name, contains('مرحبا'));
      expect(name, isNot(contains('/')));
      expect(name.toLowerCase(), endsWith('.mp4'));
    });
  });

  group('Twitch malformed URLs', () {
    test('TW-SEC-030 encoded .. is not a channel login', () {
      final uri = Uri.parse('https://www.twitch.tv/%2e%2e/test.mp4');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.twitch);
      expect(TwitchUri.channelLoginFromUri(uri), isNull);
    });

    test('TW-SEC-031 very long URL still classifies a clip', () {
      final extra = 'x' * 4000;
      final uri = Uri.parse(
        'https://clips.twitch.tv/$twitchClipSlug?ref=$extra',
      );
      expect(TwitchUri.classifyUrl(uri), TwitchContentType.clip);
      expect(TwitchUri.clipIdFromUri(uri), twitchClipSlug);
    });

    test('TW-SEC-032 tracking params cannot bypass duplicate identity', () {
      final a = TwitchUri.contentIdentity(
        TwitchUri.normalize(
          Uri.parse(
            'https://clips.twitch.tv/$twitchClipSlug?utm_source=share',
          ),
        ),
      );
      final b = TwitchUri.contentIdentity(
        TwitchUri.normalize(
          Uri.parse(
            'https://www.twitch.tv/lirik/clip/$twitchClipSlug?fbclid=zz',
          ),
        ),
      );
      expect(a, b);
    });
  });
}
