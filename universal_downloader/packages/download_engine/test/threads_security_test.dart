import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'threads_fixtures.dart';

void main() {
  final validator = UrlValidator();

  group('Threads URL scheme security', () {
    test('TH-SEC-001 javascript: is rejected', () {
      expect(validator.validate('javascript:alert(1)').isValid, isFalse);
    });

    test('TH-SEC-002 file: is rejected', () {
      expect(validator.validate('file:///test.mp4').isValid, isFalse);
    });

    test('TH-SEC-003 data: is rejected', () {
      expect(validator.validate('data:text/html,<h1>x</h1>').isValid, isFalse);
    });

    test('TH-SEC-004 https Threads URL is accepted', () {
      expect(validator.validate(threadsPostUrl).isValid, isTrue);
    });

    test('TH-SEC-005 threads.com URL is accepted', () {
      expect(validator.validate(threadsPostComUrl).isValid, isTrue);
    });
  });

  group('Threads private IP rejection', () {
    test('TH-SEC-010 localhost is not Threads', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://localhost/threads/1')),
        isNull,
      );
    });

    test('TH-SEC-011 127.0.0.1 is not Threads', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://127.0.0.1/video.mp4')),
        isNull,
      );
    });

    test('TH-SEC-012 private LAN is not Threads', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://192.168.1.1/threads/1')),
        isNull,
      );
    });

    test('TH-SEC-013 10.x is not Threads', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://10.0.0.1/photo.jpg')),
        isNull,
      );
    });

    test('TH-SEC-014 example.com video is not Threads', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('https://example.com/video.mp4')),
        isNull,
      );
    });
  });

  group('Threads filename sanitization', () {
    test('TH-SEC-020 path traversal is sanitized', () {
      final name = FileNameResolver.sanitize('../../../../threads.mp4');
      expect(name, isNot(contains('/')));
      expect(name, isNot(contains('\\')));
      expect(name, isNot(equals('../../../../threads.mp4')));
    });

    test('TH-SEC-021 slash and colon are stripped', () {
      final name = FileNameResolver.sanitize('a/b:c?.jpg');
      expect(name, isNot(contains('/')));
      expect(name, isNot(contains(':')));
      expect(name, isNot(contains('?')));
    });

    test('TH-SEC-022 quotes and pipes are stripped', () {
      final name = FileNameResolver.sanitize('title|"file".jpg');
      expect(name, isNot(contains('|')));
      expect(name, isNot(contains('"')));
    });

    test('TH-SEC-023 malicious title cannot escape storage', () {
      final results = ThreadsResolver.parseHtmlResources(
        html: threadsImageHtml(title: '../../../../threads.mp4'),
        pageUrl: Uri.parse(threadsPostUrl),
      );
      expect(results.single.fileName, isNot(contains('..')));
      expect(results.single.fileName, isNot(contains('/')));
    });

    test('TH-SEC-024 unicode caption is sanitized for filename', () {
      final results = ThreadsResolver.parseHtmlResources(
        html: threadsImageHtml(title: 'مرحبا / العالم'),
        pageUrl: Uri.parse(threadsPostUrl),
      );
      expect(results.single.fileName, isNot(contains('/')));
    });
  });

  group('Threads media URL safety', () {
    test('TH-SEC-030 threads.net page is not a direct media URL', () {
      expect(ThreadsResolver.isDirectMediaUrl(threadsPostUrl), isFalse);
    });

    test('TH-SEC-031 javascript media is rejected', () {
      expect(ThreadsResolver.isDirectMediaUrl('javascript:alert(1)'), isFalse);
    });

    test('TH-SEC-032 localhost media is rejected', () {
      expect(
        ThreadsResolver.isDirectMediaUrl('http://127.0.0.1/file.mp4'),
        isFalse,
      );
    });

    test('TH-SEC-033 encoded post URL still classifies', () {
      final uri = Uri.parse(
        'https://www.threads.net/@$threadsUsername/post/${Uri.encodeComponent(threadsPostId)}',
      );
      expect(SocialPlatform.fromUri(uri), SocialPlatform.threads);
      expect(ThreadsUri.postIdFromUri(uri), threadsPostId);
    });

    test('TH-SEC-034 login is never downloadable', () {
      final uri = Uri.parse(threadsLoginUrl);
      expect(ThreadsUri.isDownloadable(uri), isFalse);
      expect(ThreadsUri.requiresAuthentication(uri), isTrue);
    });

    test('TH-SEC-035 private IP media is rejected', () {
      expect(
        ThreadsResolver.isDirectMediaUrl('http://192.168.0.5/img.jpg'),
        isFalse,
      );
    });

    test('TH-SEC-036 Instagram fna CDN is accepted', () {
      expect(ThreadsResolver.isDirectMediaUrl(threadsFnaImageUrl), isTrue);
      expect(ThreadsResolver.isDirectMediaUrl(threadsFnaVideoUrl), isTrue);
    });

    test('TH-SEC-037 static Instagram assets are rejected', () {
      expect(ThreadsResolver.isDirectMediaUrl(threadsStaticCdnUrl), isFalse);
    });
  });
}
