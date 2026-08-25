import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reddit_fixtures.dart';

void main() {
  final pageUrl =
      Uri.parse('https://www.reddit.com/r/pics/comments/img123/photo/');

  group('Reddit image extraction', () {
    test('RD-IMG-001 jpg post uses image/jpeg', () {
      final result = RedditResolver.parsePostJson(
        pageUrl: pageUrl,
        payload: redditListing(
          redditImagePost(url: 'https://i.redd.it/a.jpg'),
        ),
      );
      expect(result!.mimeType, 'image/jpeg');
      expect(result.fileName, endsWith('.jpg'));
    });

    test('RD-IMG-002 png post uses image/png', () {
      final result = RedditResolver.parsePostJson(
        pageUrl: pageUrl,
        payload: redditListing(
          redditImagePost(url: 'https://i.redd.it/a.png'),
        ),
      );
      expect(result!.mimeType, 'image/png');
      expect(result.fileName, endsWith('.png'));
    });

    test('RD-IMG-003 webp post uses image/webp', () {
      final result = RedditResolver.parsePostJson(
        pageUrl: pageUrl,
        payload: redditListing(
          redditImagePost(url: 'https://i.redd.it/a.webp'),
        ),
      );
      expect(result!.mimeType, 'image/webp');
      expect(result.fileName, endsWith('.webp'));
    });

    test('RD-IMG-004 thumbnail is the image URL', () {
      final result = RedditResolver.parsePostJson(
        pageUrl: pageUrl,
        payload: redditListing(
          redditImagePost(url: 'https://i.redd.it/a.jpg'),
        ),
      );
      expect(result!.thumbnailUrl, contains('i.redd.it'));
    });

    test('RD-IMG-005 preview URL with amp entities is unescaped', () {
      final result = RedditResolver.parsePostJson(
        pageUrl: pageUrl,
        payload: redditListing(
          redditImagePost(
            url: 'https://preview.redd.it/a.jpg?width=100&amp;format=pjpg',
          ),
        ),
      );
      expect(result!.directUrl, isNot(contains('&amp;')));
      expect(result.directUrl, contains('format=pjpg'));
    });

    test('RD-IMG-006 imgur direct image is accepted', () {
      final result = RedditResolver.parsePostJson(
        pageUrl: pageUrl,
        payload: redditListing(
          redditImagePost(url: 'https://i.imgur.com/abc.jpg'),
        ),
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('i.imgur.com'));
    });

    test('RD-IMG-007 youtube URL is not Reddit-hosted media', () {
      final result = RedditResolver.parsePostJson(
        pageUrl: pageUrl,
        payload: redditListing(
          redditImagePost(url: 'https://www.youtube.com/watch?v=dQw4w9wg'),
        ),
      );
      expect(result, isNull);
      expect(
        RedditResolver.linkedUrlFromPayload(
          redditListing(
            redditImagePost(url: 'https://www.youtube.com/watch?v=dQw4w9wg'),
          ),
        )?.host,
        'www.youtube.com',
      );
    });
  });
}
