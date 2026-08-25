import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'linkedin_fixtures.dart';

void main() {
  final validator = UrlValidator();

  group('LinkedIn URL scheme security', () {
    test('LI-SEC-001 javascript: is rejected', () {
      expect(validator.validate('javascript:alert(1)').isValid, isFalse);
    });

    test('LI-SEC-002 file: is rejected', () {
      expect(validator.validate('file:///test.mp4').isValid, isFalse);
    });

    test('LI-SEC-003 data: is rejected', () {
      expect(validator.validate('data:text/html,<h1>x</h1>').isValid, isFalse);
    });

    test('LI-SEC-004 https LinkedIn URL is accepted', () {
      expect(validator.validate(linkedinPostUrl).isValid, isTrue);
    });
  });

  group('LinkedIn private IP rejection', () {
    test('LI-SEC-010 localhost is not LinkedIn', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://localhost/posts/x')),
        isNull,
      );
    });

    test('LI-SEC-011 127.0.0.1 is not LinkedIn', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://127.0.0.1/video.mp4')),
        isNull,
      );
    });

    test('LI-SEC-012 private LAN is not LinkedIn', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://192.168.1.1/posts/x')),
        isNull,
      );
    });

    test('LI-SEC-013 10.x is not LinkedIn', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://10.0.0.1/photo.jpg')),
        isNull,
      );
    });

    test('LI-SEC-014 example.com video is not LinkedIn', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('https://example.com/video.mp4')),
        isNull,
      );
    });
  });

  group('LinkedIn filename sanitization', () {
    test('LI-SEC-020 path traversal is sanitized', () {
      final name = FileNameResolver.sanitize('../../../../linkedin.mp4');
      expect(name, isNot(contains('/')));
      expect(name, isNot(contains('\\')));
      expect(name, isNot(equals('../../../../linkedin.mp4')));
    });

    test('LI-SEC-021 slash and colon are stripped', () {
      final name = FileNameResolver.sanitize('a/b:c?.jpg');
      expect(name, isNot(contains('/')));
      expect(name, isNot(contains(':')));
      expect(name, isNot(contains('?')));
    });

    test('LI-SEC-022 quotes and pipes are stripped', () {
      final name = FileNameResolver.sanitize('title|"file".jpg');
      expect(name, isNot(contains('"')));
      expect(name, isNot(contains('|')));
    });

    test('LI-SEC-023 unicode title does not escape directory', () {
      final results = LinkedInResolver.parseHtmlResources(
        html: linkedinImagePostHtml(title: '../../../../linkedin.mp4'),
        pageUrl: Uri.parse(linkedinPostUrl),
        contentId: linkedinActivityId,
      );
      expect(results, isNotEmpty);
      expect(results.single.fileName, isNot(contains('..')));
      expect(results.single.fileName, isNot(contains('/')));
    });

    test('LI-SEC-024 emoji and arabic are sanitized or kept safely', () {
      final name = FileNameResolver.sanitize('مرحبا 🎉 photo.jpg');
      expect(name, isNot(contains('/')));
      expect(name, isNotEmpty);
    });

    test('LI-SEC-025 very long title is usable as filename input', () {
      final long = 'a' * 400;
      final name = FileNameResolver.sanitize('$long.jpg');
      expect(name, isNot(contains('/')));
      expect(name.endsWith('.jpg'), isTrue);
    });
  });

  group('LinkedIn media URL safety', () {
    test('LI-SEC-030 player page is not direct media', () {
      expect(
        LinkedInResolver.isDirectMediaUrl(linkedinFeedUrl),
        isFalse,
      );
    });

    test('LI-SEC-031 HLS is not direct media', () {
      expect(LinkedInResolver.isDirectMediaUrl(linkedinHls), isFalse);
    });

    test('LI-SEC-032 javascript URL is not direct media', () {
      expect(
        LinkedInResolver.isDirectMediaUrl('javascript:alert(1)'),
        isFalse,
      );
    });

    test('LI-SEC-033 encoded LinkedIn URL still classifies as LinkedIn', () {
      final uri = Uri.parse(
        'https://www.linkedin.com/feed/update/urn%3Ali%3Aactivity%3A$linkedinActivityId/',
      );
      expect(SocialPlatform.fromUri(uri), SocialPlatform.linkedin);
      expect(LinkedInUri.activityIdFromUri(uri), linkedinActivityId);
    });
  });
}
