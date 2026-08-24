import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reddit_fixtures.dart';

void main() {
  final pageUrl =
      Uri.parse('https://www.reddit.com/r/videos/comments/abc123/clip/');

  group('Reddit video extraction', () {
    test('RD-VID-001 extracts DASH fallback MP4', () {
      final result = RedditResolver.parsePostJson(
        pageUrl: pageUrl,
        payload: redditListing(redditVideoPost()),
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('DASH_720.mp4'));
      expect(result.mimeType, 'video/mp4');
    });

    test('RD-VID-002 thumbnail is extracted from preview', () {
      final result = RedditResolver.parsePostJson(
        pageUrl: pageUrl,
        payload: redditListing(
          redditVideoPost(thumbnail: 'https://preview.redd.it/thumb.jpg'),
        ),
      );
      expect(result!.thumbnailUrl, contains('preview.redd.it'));
    });

    test('RD-VID-003 duration and dimensions are in post info', () {
      final info = RedditResolver.parsePostInfo(
        payload: redditListing(
          redditVideoPost(duration: 42, width: 1920, height: 1080),
        ),
      );
      expect(info!.durationSeconds, 42);
      expect(info.width, 1920);
      expect(info.height, 1080);
      expect(info.isVideo, isTrue);
    });

    test('RD-VID-004 video with audio exposes separate audio stream URL', () {
      final video = redditVideoPost(hasAudio: true)['secure_media']
          ['reddit_video'] as Map<dynamic, dynamic>;
      expect(RedditResolver.hasSeparateAudio(video), isTrue);
      expect(
        RedditResolver.audioStreamUrlFromVideo(video),
        'https://v.redd.it/vid123/DASH_audio.mp4',
      );
    });

    test('RD-VID-005 video without audio has no audio stream', () {
      final video = redditVideoPost(hasAudio: false, isGif: true)['secure_media']
          ['reddit_video'] as Map<dynamic, dynamic>;
      expect(RedditResolver.hasSeparateAudio(video), isFalse);
      expect(RedditResolver.audioStreamUrlFromVideo(video), isNull);
    });

    test('RD-VID-006 HLS-only video without fallback is not downloaded', () {
      final post = redditVideoPost();
      (post['secure_media'] as Map)['reddit_video'] = {
        'hls_url': 'https://v.redd.it/vid123/HLSPlaylist.m3u8',
        'has_audio': true,
      };
      post['media'] = post['secure_media'];
      final result = RedditResolver.parsePostJson(
        pageUrl: pageUrl,
        payload: redditListing(post),
      );
      expect(result, isNull);
    });

    test('RD-VID-007 discoverAll returns a single video item', () {
      final results = RedditResolver.parseAllMedia(
        pageUrl: pageUrl,
        payload: redditListing(redditVideoPost()),
      );
      expect(results.length, 1);
      expect(results.first.mimeType, 'video/mp4');
    });

    test('RD-VID-008 gif-like reddit_video keeps video/mp4', () {
      final result = RedditResolver.parsePostJson(
        pageUrl: pageUrl,
        payload: redditListing(redditVideoPost(isGif: true, hasAudio: false)),
      );
      expect(result!.mimeType, 'video/mp4');
      expect(result.fileName, isNot(endsWith('.gif')));
    });
  });
}
