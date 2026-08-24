import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'whatsapp_fixtures.dart';

void main() {
  final validator = UrlValidator();

  group('WhatsApp URL scheme security', () {
    test('WA-SEC-001 javascript: is rejected', () {
      expect(validator.validate('javascript:alert(1)').isValid, isFalse);
    });

    test('WA-SEC-002 file: is rejected', () {
      expect(validator.validate('file:///etc/passwd').isValid, isFalse);
    });

    test('WA-SEC-003 data: is rejected', () {
      expect(validator.validate('data:text/html,<h1>x</h1>').isValid, isFalse);
    });

    test('WA-SEC-004 https WhatsApp URL is accepted', () {
      expect(validator.validate(whatsappChatUrl).isValid, isTrue);
    });

    test('WA-SEC-005 public whatsapp://send is normalized to https', () {
      final result = validator.validate(
        'whatsapp://send?phone=$whatsappPhone&text=Hi',
      );
      expect(result.isValid, isTrue);
      expect(result.uri.toString(), 'https://wa.me/$whatsappPhone?text=Hi');
    });

    test('WA-SEC-006 whatsapp://chat is rejected safely', () {
      final result = validator.validate(
        'whatsapp://chat?code=$whatsappInviteCode',
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage!.toLowerCase(), contains('invitation'));
    });
  });

  group('WhatsApp private IP rejection', () {
    test('WA-SEC-010 localhost is not WhatsApp', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://localhost/whatsapp/1')),
        isNull,
      );
    });

    test('WA-SEC-011 127.0.0.1 is not WhatsApp', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://127.0.0.1/video.mp4')),
        isNull,
      );
    });

    test('WA-SEC-012 private LAN is not WhatsApp', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://192.168.1.1/whatsapp/1')),
        isNull,
      );
    });

    test('WA-SEC-013 10.x is not WhatsApp', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://10.0.0.1/photo.jpg')),
        isNull,
      );
    });

    test('WA-SEC-014 example.com video is not WhatsApp', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('https://example.com/video.mp4')),
        isNull,
      );
    });
  });

  group('WhatsApp filename sanitization', () {
    test('WA-SEC-020 path traversal is sanitized', () {
      final name = FileNameResolver.sanitize('../../../../whatsapp.mp4');
      expect(name, isNot(contains('/')));
      expect(name, isNot(contains('\\')));
      expect(name, isNot(equals('../../../../whatsapp.mp4')));
    });

    test('WA-SEC-021 slash and colon are stripped', () {
      final name = FileNameResolver.sanitize('a/b:c?.jpg');
      expect(name, isNot(contains('/')));
      expect(name, isNot(contains(':')));
      expect(name, isNot(contains('?')));
    });

    test('WA-SEC-022 quotes and pipes are stripped', () {
      final name = FileNameResolver.sanitize('title|"file".jpg');
      expect(name, isNot(contains('|')));
      expect(name, isNot(contains('"')));
    });

    test('WA-SEC-023 malicious title cannot escape storage', () {
      final results = WhatsAppResolver.parseHtmlResources(
        html: whatsappChannelHtml(title: '../../../../whatsapp.mp4'),
        pageUrl: Uri.parse(whatsappChannelUrl),
      );
      expect(results.single.fileName, isNot(contains('..')));
      expect(results.single.fileName, isNot(contains('/')));
    });

    test('WA-SEC-024 unicode and emoji filenames are sanitized', () {
      final arabic = FileNameResolver.sanitize('مرحبا.jpg');
      final emoji = FileNameResolver.sanitize('hello😀.jpg');
      expect(arabic, isNot(contains('/')));
      expect(emoji, isNot(contains('/')));
    });
  });

  group('WhatsApp media URL safety', () {
    test('WA-SEC-030 wa.me page is not a direct media URL', () {
      expect(WhatsAppResolver.isDirectMediaUrl(whatsappChatUrl), isFalse);
    });

    test('WA-SEC-031 javascript media is rejected', () {
      expect(WhatsAppResolver.isDirectMediaUrl('javascript:alert(1)'), isFalse);
    });

    test('WA-SEC-032 localhost media is rejected', () {
      expect(
        WhatsAppResolver.isDirectMediaUrl('http://127.0.0.1/file.mp4'),
        isFalse,
      );
    });

    test('WA-SEC-033 encoded wa.me URL still classifies', () {
      final uri = Uri.parse(
        'https://wa.me/${Uri.encodeComponent(whatsappPhone)}',
      );
      expect(SocialPlatform.fromUri(uri), SocialPlatform.whatsapp);
      expect(WhatsAppUri.phoneFromUri(uri), whatsappPhone);
    });

    test('WA-SEC-034 encrypted mmg URL is never downloadable', () {
      final uri = Uri.parse(whatsappPrivateMediaUrl);
      expect(WhatsAppUri.isDownloadable(uri), isFalse);
      expect(WhatsAppUri.requiresAuthentication(uri), isTrue);
      expect(WhatsAppResolver.isDirectMediaUrl(whatsappPrivateMediaUrl), isFalse);
    });

    test('WA-SEC-035 invite is never downloadable', () {
      final uri = Uri.parse(whatsappInviteUrl);
      expect(WhatsAppUri.isDownloadable(uri), isFalse);
      expect(WhatsAppUri.isRestricted(uri), isTrue);
    });
  });
}
