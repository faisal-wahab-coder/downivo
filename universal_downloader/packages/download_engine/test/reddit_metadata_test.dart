import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reddit_fixtures.dart';

void main() {
  group('Reddit metadata mapping', () {
    test('RD-META-001 extracts post id, subreddit, author, title', () {
      final info = RedditResolver.parsePostInfo(
        payload: redditListing(
          redditVideoPost(
            id: 'zz99',
            subreddit: 'videos',
            author: 'alice',
            title: 'Hello',
          ),
        ),
      );
      expect(info, isNotNull);
      expect(info!.postId, 'zz99');
      expect(info.subreddit, 'videos');
      expect(info.author, 'alice');
      expect(info.title, 'Hello');
    });

    test('RD-META-002 thumbnail from http thumbnail field', () {
      final info = RedditResolver.parsePostInfo(
        payload: redditListing(
          redditImagePost(thumbnail: 'https://b.thumbs.redditmedia.com/t.jpg'),
        ),
      );
      expect(info!.thumbnailUrl, startsWith('http'));
    });

    test('RD-META-003 default thumbnail is not treated as URL', () {
      final info = RedditResolver.parsePostInfo(
        payload: redditListing(
          redditSelfPost()..['thumbnail'] = 'self',
        ),
      );
      expect(info!.thumbnailUrl, isNull);
    });

    test('RD-META-004 removed post is flagged', () {
      final info = RedditResolver.parsePostInfo(
        payload: redditListing(redditRemovedPost()),
      );
      expect(info!.isRemoved, isTrue);
      expect(info.author, '[deleted]');
    });

    test('RD-META-005 gallery metadata includes count', () {
      final info = RedditResolver.parsePostInfo(
        payload: redditListing(redditGalleryPost()),
      );
      expect(info!.isGallery, isTrue);
      expect(info.galleryCount, 3);
      expect(info.isVideo, isFalse);
    });

    test('RD-META-006 video metadata includes duration', () {
      final info = RedditResolver.parsePostInfo(
        payload: redditListing(redditVideoPost(duration: 15)),
      );
      expect(info!.durationSeconds, 15);
      expect(info.hasAudio, isTrue);
    });

    test('RD-META-007 discovered resource title matches post title', () {
      final result = RedditResolver.parsePostJson(
        pageUrl: Uri.parse('https://www.reddit.com/r/pics/comments/img123/x/'),
        payload: redditListing(redditImagePost(title: 'Exact Title')),
      );
      expect(result!.title, 'Exact Title');
    });

    test('RD-META-008 empty payload returns null info', () {
      expect(RedditResolver.parsePostInfo(payload: []), isNull);
      expect(RedditResolver.postDataFromPayload([]), isNull);
    });

    test('RD-META-009 malformed listing returns null', () {
      expect(
        RedditResolver.parsePostInfo(payload: [
          {'data': 'not-a-map'},
        ]),
        isNull,
      );
    });
  });
}
