import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'snapchat_fixtures.dart';

void main() {
  final validator = UrlValidator();

  group('Snapchat URL scheme security', () {
    test('SC-SEC-001 javascript: is rejected', () {
      expect(validator.validate('javascript:alert(1)').isValid, isFalse);
    });

    test('SC-SEC-002 file: is rejected', () {
      expect(validator.validate('file:///test.mp4').isValid, isFalse);
    });

    test('SC-SEC-003 data: is rejected', () {
      expect(validator.validate('data:text/html,<h1>x</h1>').isValid, isFalse);
    });

    test('SC-SEC-004 https Snapchat URL is accepted', () {
      expect(validator.validate(snapchatSpotlightUrl).isValid, isTrue);
    });

    test('SC-SEC-005 public snapchat://spotlight is normalized to https', () {
      final result = validator.validate(
        'snapchat://spotlight/$snapchatSpotlightId',
      );
      expect(result.isValid, isTrue);
      expect(result.uri.toString(), snapchatSpotlightUrl);
    });

    test('SC-SEC-006 snapchat://chat is rejected safely', () {
      final result = validator.validate('snapchat://chat');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('restricted'));
    });

    test('SC-SEC-006b snap://memories is rejected safely', () {
      final result = validator.validate('snap://memories');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('restricted'));
    });
  });

  group('Snapchat private IP rejection', () {
    test('SC-SEC-010 localhost is not Snapchat', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://localhost/snapchat/1')),
        isNull,
      );
    });

    test('SC-SEC-011 127.0.0.1 is not Snapchat', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://127.0.0.1/video.mp4')),
        isNull,
      );
    });

    test('SC-SEC-012 private LAN is not Snapchat', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://192.168.1.1/snapchat/1')),
        isNull,
      );
    });

    test('SC-SEC-013 10.x is not Snapchat', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://10.0.0.1/photo.jpg')),
        isNull,
      );
    });

    test('SC-SEC-014 example.com video is not Snapchat', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('https://example.com/video.mp4')),
        isNull,
      );
    });
  });

  group('Snapchat filename sanitization', () {
    test('SC-SEC-020 path traversal is sanitized', () {
      final name = FileNameResolver.sanitize('../../../../snapchat.mp4');
      expect(name, isNot(contains('/')));
      expect(name, isNot(contains('\\')));
      expect(name, isNot(equals('../../../../snapchat.mp4')));
    });

    test('SC-SEC-021 slash and colon are stripped', () {
      final name = FileNameResolver.sanitize('a/b:c?.jpg');
      expect(name, isNot(contains('/')));
      expect(name, isNot(contains(':')));
      expect(name, isNot(contains('?')));
    });

    test('SC-SEC-022 quotes and pipes are stripped', () {
      final name = FileNameResolver.sanitize('title|"file".jpg');
      expect(name, isNot(contains('|')));
      expect(name, isNot(contains('"')));
    });

    test('SC-SEC-023 malicious title cannot escape storage', () {
      final results = SnapchatResolver.parseHtmlResources(
        html: snapchatPhotoHtml(title: '../../../../snapchat.mp4'),
        pageUrl: Uri.parse(snapchatSnapUrl),
      );
      expect(results.single.fileName, isNot(contains('..')));
      expect(results.single.fileName, isNot(contains('/')));
    });
  });

  group('Snapchat media URL safety', () {
    test('SC-SEC-030 snapchat.com page is not a direct media URL', () {
      expect(
        SnapchatResolver.isDirectMediaUrl(snapchatSpotlightUrl),
        isFalse,
      );
    });

    test('SC-SEC-031 javascript media is rejected', () {
      expect(SnapchatResolver.isDirectMediaUrl('javascript:alert(1)'), isFalse);
    });

    test('SC-SEC-032 localhost media is rejected', () {
      expect(
        SnapchatResolver.isDirectMediaUrl('http://127.0.0.1/file.mp4'),
        isFalse,
      );
    });

    test('SC-SEC-033 encoded Spotlight URL still classifies', () {
      final uri = Uri.parse(
        'https://www.snapchat.com/spotlight/${Uri.encodeComponent(snapchatSpotlightId)}',
      );
      expect(SocialPlatform.fromUri(uri), SocialPlatform.snapchat);
      expect(SnapchatUri.spotlightIdFromUri(uri), snapchatSpotlightId);
    });

    test('SC-SEC-034 chat is never downloadable', () {
      final uri = Uri.parse(snapchatChatUrl);
      expect(SnapchatUri.isDownloadable(uri), isFalse);
      expect(SnapchatUri.isRestricted(uri), isTrue);
    });
  });
}
