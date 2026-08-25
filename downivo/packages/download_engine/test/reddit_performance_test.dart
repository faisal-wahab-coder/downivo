import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reddit_fixtures.dart';

void main() {
  group('Reddit performance / scale', () {
    test('RD-PERF-001 large gallery does not collapse items', () {
      final items = [
        for (var i = 0; i < 50; i++)
          (
            id: 'm$i',
            url: 'https://preview.redd.it/img$i.jpg',
            mime: 'image/jpg',
            kind: 'Image',
          ),
      ];
      final results = RedditResolver.parseAllMedia(
        pageUrl: Uri.parse('https://www.reddit.com/r/pics/comments/big/x/'),
        payload: redditListing(redditGalleryPost(items: items)),
      );
      expect(results.length, 50);
      expect(results.map((r) => r.directUrl).toSet().length, 50);
      expect(results.map((r) => r.fileName).toSet().length, 50);
    });

    test('RD-PERF-002 parse is deterministic', () {
      final payload = redditListing(redditGalleryPost());
      final a = RedditResolver.parseAllMedia(
        pageUrl: Uri.parse('https://www.reddit.com/r/pics/comments/gal123/x/'),
        payload: payload,
      );
      final b = RedditResolver.parseAllMedia(
        pageUrl: Uri.parse('https://www.reddit.com/r/pics/comments/gal123/x/'),
        payload: payload,
      );
      expect(a.map((r) => r.directUrl), b.map((r) => r.directUrl));
    });

    test('RD-PERF-003 small image parse is a single resource', () {
      final results = RedditResolver.parseAllMedia(
        pageUrl: Uri.parse('https://www.reddit.com/r/pics/comments/img123/x/'),
        payload: redditListing(redditImagePost()),
      );
      expect(results.length, 1);
    });
  });
}
