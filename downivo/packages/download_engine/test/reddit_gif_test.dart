import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reddit_fixtures.dart';

void main() {
  final pageUrl =
      Uri.parse('https://www.reddit.com/r/gifs/comments/gif123/anim/');

  group('Reddit GIF / animated media', () {
    test('RD-GIF-001 gif URL is preserved as image/gif', () {
      final result = RedditResolver.parsePostJson(
        pageUrl: pageUrl,
        payload: redditListing(redditGifPost()),
      );
      expect(result, isNotNull);
      expect(result!.mimeType, 'image/gif');
      expect(result.fileName, endsWith('.gif'));
      expect(result.directUrl, contains('.gif'));
    });

    test('RD-GIF-002 does not rename GIF to MP4 when gif source exists', () {
      final result = RedditResolver.parsePostJson(
        pageUrl: pageUrl,
        payload: redditListing(
          redditGifPost(
            gifUrl: 'https://i.redd.it/anim.gif',
            mp4Url: 'https://preview.redd.it/anim.mp4',
          ),
        ),
      );
      expect(result!.mimeType, isNot('video/mp4'));
      expect(result.fileName, isNot(endsWith('.mp4')));
    });

    test('RD-GIF-003 mp4-only animated media stays video/mp4', () {
      final post = redditGifPost(gifUrl: 'https://i.redd.it/anim.mp4', mp4Url: null);
      post['url'] = 'https://i.redd.it/anim.mp4';
      post['url_overridden_by_dest'] = 'https://i.redd.it/anim.mp4';
      post['preview'] = {
        'images': [
          {
            'source': {'url': 'https://i.redd.it/anim.mp4'},
            'variants': {
              'mp4': {
                'source': {'url': 'https://preview.redd.it/anim.mp4'},
              },
            },
          },
        ],
      };
      final result = RedditResolver.parsePostJson(
        pageUrl: pageUrl,
        payload: redditListing(post),
      );
      expect(result!.mimeType, 'video/mp4');
      expect(result.fileName, endsWith('.mp4'));
    });

    test('RD-GIF-004 reddit_video is_gif keeps mp4 extension', () {
      final result = RedditResolver.parsePostJson(
        pageUrl: pageUrl,
        payload: redditListing(
          redditVideoPost(isGif: true, hasAudio: false, title: 'Silent GIF'),
        ),
      );
      expect(result!.mimeType, 'video/mp4');
      expect(result.fileName.endsWith('.gif'), isFalse);
    });

    test('RD-GIF-005 gallery AnimatedImage with image/gif stays gif', () {
      final results = RedditResolver.parseAllMedia(
        pageUrl: pageUrl,
        payload: redditListing(
          redditGalleryPost(
            items: [
              (
                id: 'g1',
                url: 'https://i.redd.it/anim.gif',
                mime: 'image/gif',
                kind: 'AnimatedImage',
              ),
            ],
          ),
        ),
      );
      expect(results.length, 1);
      expect(results.first.mimeType, 'image/gif');
    });
  });
}
