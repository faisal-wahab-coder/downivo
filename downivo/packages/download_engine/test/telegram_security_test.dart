import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'telegram_fixtures.dart';

void main() {
  final validator = UrlValidator();

  group('Telegram URL scheme security', () {
    test('TG-SEC-001 javascript: is rejected', () {
      expect(validator.validate('javascript:alert(1)').isValid, isFalse);
    });

    test('TG-SEC-002 file: is rejected', () {
      expect(validator.validate('file:///test.mp4').isValid, isFalse);
    });

    test('TG-SEC-003 data: is rejected', () {
      expect(validator.validate('data:text/html,<h1>x</h1>').isValid, isFalse);
    });

    test('TG-SEC-004 https Telegram URL is accepted', () {
      expect(validator.validate(telegramMessageUrl).isValid, isTrue);
    });

    test('TG-SEC-005 public tg://resolve is normalized to https', () {
      final result = validator.validate(
        'tg://resolve?domain=telegram&post=1001',
      );
      expect(result.isValid, isTrue);
      expect(result.uri.toString(), telegramMessageUrl);
    });

    test('TG-SEC-006 tg://join is rejected safely', () {
      final result = validator.validate('tg://join?invite=AbCdEf');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('restricted'));
    });

    test('TG-SEC-006b telegram://join is rejected safely', () {
      final result = validator.validate('telegram://join?invite=AbCdEf');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('restricted'));
    });
  });

  group('Telegram private IP rejection', () {
    test('TG-SEC-010 localhost is not Telegram', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://localhost/telegram/1')),
        isNull,
      );
    });

    test('TG-SEC-011 127.0.0.1 is not Telegram', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://127.0.0.1/video.mp4')),
        isNull,
      );
    });

    test('TG-SEC-012 private LAN is not Telegram', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://192.168.1.1/telegram/1')),
        isNull,
      );
    });

    test('TG-SEC-013 10.x is not Telegram', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://10.0.0.1/photo.jpg')),
        isNull,
      );
    });

    test('TG-SEC-014 example.com video is not Telegram', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('https://example.com/video.mp4')),
        isNull,
      );
    });
  });

  group('Telegram filename sanitization', () {
    test('TG-SEC-020 path traversal is sanitized', () {
      final name = FileNameResolver.sanitize('../../../../telegram.mp4');
      expect(name, isNot(contains('/')));
      expect(name, isNot(contains('\\')));
      expect(name, isNot(equals('../../../../telegram.mp4')));
    });

    test('TG-SEC-021 slash and colon are stripped', () {
      final name = FileNameResolver.sanitize('a/b:c?.jpg');
      expect(name, isNot(contains('/')));
      expect(name, isNot(contains(':')));
      expect(name, isNot(contains('?')));
    });

    test('TG-SEC-022 quotes and pipes are stripped', () {
      final name = FileNameResolver.sanitize('title|"file".jpg');
      expect(name, isNot(contains('|')));
      expect(name, isNot(contains('"')));
    });

    test('TG-SEC-023 malicious title cannot escape storage', () {
      final results = TelegramResolver.parseHtmlResources(
        html: telegramPhotoHtml(title: '../../../../telegram.mp4'),
        pageUrl: Uri.parse(telegramMessageUrl),
      );
      expect(results.single.fileName, isNot(contains('..')));
      expect(results.single.fileName, isNot(contains('/')));
    });
  });

  group('Telegram media URL safety', () {
    test('TG-SEC-030 t.me page is not a direct media URL', () {
      expect(TelegramResolver.isDirectMediaUrl(telegramMessageUrl), isFalse);
    });

    test('TG-SEC-031 javascript media is rejected', () {
      expect(TelegramResolver.isDirectMediaUrl('javascript:alert(1)'), isFalse);
    });

    test('TG-SEC-032 localhost media is rejected', () {
      expect(
        TelegramResolver.isDirectMediaUrl('http://127.0.0.1/file.mp4'),
        isFalse,
      );
    });

    test('TG-SEC-033 encoded Telegram URL still classifies', () {
      final uri = Uri.parse(
        'https://t.me/$telegramChannel/${Uri.encodeComponent(telegramMessageId)}',
      );
      expect(SocialPlatform.fromUri(uri), SocialPlatform.telegram);
      expect(TelegramUri.messageIdFromUri(uri), telegramMessageId);
    });

    test('TG-SEC-034 private /c/ is never downloadable', () {
      final uri = Uri.parse('https://t.me/c/1234567890/12');
      expect(TelegramUri.isDownloadable(uri), isFalse);
      expect(TelegramUri.isRestricted(uri), isTrue);
    });
  });
}
