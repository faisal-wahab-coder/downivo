import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final validator = UrlValidator();

  group('Reddit URL scheme security', () {
    test('RD-SEC-001 javascript: is rejected', () {
      expect(validator.validate('javascript:alert(1)').isValid, isFalse);
    });

    test('RD-SEC-002 file: is rejected', () {
      expect(validator.validate('file:///test.mp4').isValid, isFalse);
    });

    test('RD-SEC-003 data: is rejected', () {
      expect(validator.validate('data:text/html,<h1>x</h1>').isValid, isFalse);
    });

    test('RD-SEC-004 https Reddit URL is accepted', () {
      expect(
        validator
            .validate('https://www.reddit.com/r/pics/comments/abc/x/')
            .isValid,
        isTrue,
      );
    });
  });

  group('Reddit private IP rejection', () {
    test('RD-SEC-010 localhost is not Reddit', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://localhost/r/pics/comments/a/')),
        isNull,
      );
    });

    test('RD-SEC-011 127.0.0.1 is not Reddit', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://127.0.0.1/r/pics/comments/a/')),
        isNull,
      );
    });

    test('RD-SEC-012 private LAN is not Reddit', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://192.168.1.1/r/pics/comments/a/')),
        isNull,
      );
    });

    test('RD-SEC-013 10.x is not Reddit', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://10.0.0.1/video.mp4')),
        isNull,
      );
    });
  });

  group('Reddit filename sanitization', () {
    test('RD-SEC-020 path traversal is sanitized', () {
      final name = FileNameResolver.sanitize('../../../../test.mp4');
      expect(name, isNot(contains('/')));
      expect(name, isNot(contains('\\')));
      expect(name, isNot(equals('../../../../test.mp4')));
    });

    test('RD-SEC-021 slash and colon are stripped', () {
      final name = FileNameResolver.sanitize('a/b:c?.mp4');
      expect(name, isNot(contains('/')));
      expect(name, isNot(contains(':')));
      expect(name, isNot(contains('?')));
    });

    test('RD-SEC-022 quotes and pipes are stripped', () {
      final name = FileNameResolver.sanitize('title|"file".mp4');
      expect(name, isNot(contains('|')));
      expect(name, isNot(contains('"')));
    });

    test('RD-SEC-023 arabic title is kept safely', () {
      final name = FileNameResolver.sanitize('عنوان عربي.mp4');
      expect(name, isNotEmpty);
      expect(name, isNot(contains('/')));
    });

    test('RD-SEC-024 emoji title is kept safely', () {
      final name = FileNameResolver.sanitize('cats 😂🎉.mp4');
      expect(name, isNotEmpty);
    });

    test('RD-SEC-025 very long title is usable as preferred name', () {
      final long = '${'a' * 300}.jpg';
      final name = FileNameResolver.sanitize(long);
      expect(name, isNotEmpty);
      expect(name, isNot(contains('/')));
    });

    test('RD-SEC-026 resolver title traversal cannot escape', () {
      final result = RedditResolver.parsePostJson(
        pageUrl: Uri.parse('https://www.reddit.com/r/pics/comments/abc/x/'),
        payload: [
          {
            'data': {
              'children': [
                {
                  'data': {
                    'id': 'abc',
                    'title': '../../../../test.mp4',
                    'url': 'https://i.redd.it/x.jpg',
                    'url_overridden_by_dest': 'https://i.redd.it/x.jpg',
                  },
                },
              ],
            },
          },
        ],
      );
      expect(result, isNotNull);
      expect(result!.fileName, isNot(contains('..')));
      expect(result.fileName, isNot(contains('/')));
    });
  });

  group('Reddit malformed URLs', () {
    test('RD-SEC-030 encoded post URL still extracts ID', () {
      final uri = Uri.parse(
        'https://www.reddit.com/r/pics/comments/abc123/hello%20world/',
      );
      expect(RedditUri.postIdFromUri(uri), 'abc123');
    });

    test('RD-SEC-031 example.com is not Reddit', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('https://example.com/video.mp4')),
        isNull,
      );
    });
  });
}
