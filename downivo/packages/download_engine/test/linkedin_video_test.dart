import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'linkedin_fixtures.dart';

void main() {
  group('LinkedIn video posts', () {
    test('LI-VID-001 discovers progressive MP4 not the player page', () {
      final results = LinkedInResolver.parseHtmlResources(
        html: linkedinVideoPostHtml(),
        pageUrl: Uri.parse(linkedinPostUrl),
        contentId: linkedinActivityId,
      );
      expect(results, isNotEmpty);
      expect(results.single.directUrl, contains('.mp4'));
      expect(results.single.directUrl, isNot(contains('linkedin.com/feed')));
      expect(results.single.mimeType, 'video/mp4');
    });

    test('LI-VID-002 prefers 720p over 360p', () {
      final qualities = LinkedInResolver.parseProgressiveStreams(
        linkedinVideoPostHtml(),
      );
      expect(qualities.any((q) => q.height == 720), isTrue);
      expect(qualities.any((q) => q.height == 360), isTrue);
      final results = LinkedInResolver.parseHtmlResources(
        html: linkedinVideoPostHtml(),
        pageUrl: Uri.parse(linkedinPostUrl),
        contentId: linkedinActivityId,
      );
      expect(results.single.directUrl, linkedinVideoMp4);
    });

    test('LI-VID-003 does not invent 1080p', () {
      final qualities = LinkedInResolver.parseProgressiveStreams(
        linkedinVideoPostHtml(),
      );
      expect(qualities.any((q) => q.height == 1080), isFalse);
    });

    test('LI-VID-004 HLS-only video is not downloaded as a file', () {
      final results = LinkedInResolver.parseHtmlResources(
        html: linkedinHlsOnlyVideoHtml(),
        pageUrl: Uri.parse(linkedinPostUrl),
        contentId: linkedinActivityId,
      );
      expect(results, isEmpty);
    });

    test('LI-VID-005 HLS playlist is not treated as MP4', () {
      expect(LinkedInResolver.isDirectMediaUrl(linkedinHls), isFalse);
      expect(
        LinkedInResolver.mimeFromUrl(linkedinHls),
        'application/vnd.apple.mpegurl',
      );
    });

    test('LI-VID-006 muxed MP4 is a single resource', () {
      final results = LinkedInResolver.parseHtmlResources(
        html: linkedinVideoPostHtml(),
        pageUrl: Uri.parse(linkedinPostUrl),
        contentId: linkedinActivityId,
      );
      expect(results.length, 1);
    });

    test('LI-VID-007 mp4-720p path without .mp4 extension is video', () {
      expect(LinkedInResolver.isDirectMediaUrl(linkedinVideoMp4Path), isTrue);
      expect(LinkedInResolver.mimeFromUrl(linkedinVideoMp4Path), 'video/mp4');
      final results = LinkedInResolver.parseHtmlResources(
        html: linkedinEmbedProgressivePathHtml(),
        pageUrl: Uri.parse(linkedinPostUrl),
        contentId: linkedinActivityId,
      );
      expect(results, isNotEmpty);
      expect(results.single.directUrl, linkedinVideoMp4Path);
      expect(results.single.mimeType, 'video/mp4');
      expect(results.single.directUrl, isNot(contains('comment-image')));
      expect(results.single.directUrl, isNot(contains('article-cover')));
    });

    test('LI-VID-008 play-button thumbnail is not a video file', () {
      expect(LinkedInResolver.isDirectMediaUrl(linkedinVideoThumb), isFalse);
    });

    test('LI-VID-009 comment images are not used when video file is missing', () {
      final results = LinkedInResolver.parseHtmlResources(
        html: linkedinVideoPageWithCommentImagesOnlyHtml(),
        pageUrl: Uri.parse(linkedinPostUrl),
        contentId: linkedinActivityId,
      );
      expect(results, isEmpty);
    });

    test('LI-VID-010 HTML entity-terminated CDN URL is cleaned', () {
      final html = '''
<meta property="og:image" content="$linkedinVideoThumb" />
https://dms.licdn.com/playlist/vid/v2/D4E10AQFvideo/mp4-720p-30fp-crf28/B4DZVIDEO/0/1?e=2147483647&amp;v=beta&amp;t=abc&quot;,&quot;type
''';
      final results = LinkedInResolver.parseHtmlResources(
        html: html,
        pageUrl: Uri.parse(linkedinPostUrl),
        contentId: linkedinActivityId,
      );
      expect(results, isNotEmpty);
      expect(results.single.directUrl, contains('mp4-720p-30fp-crf28'));
      expect(results.single.directUrl, isNot(contains('quot')));
      expect(results.single.directUrl, isNot(contains(',type')));
    });
  });
}
