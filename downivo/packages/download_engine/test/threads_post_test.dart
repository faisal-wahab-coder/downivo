import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'threads_fixtures.dart';

void main() {
  group('Threads posts', () {
    test('TH-POST-001 text-only is TEXT and not downloadable media', () {
      expect(
        ThreadsResolver.detectMediaType(threadsTextHtml()),
        ThreadsMediaType.text,
      );
      expect(
        ThreadsResolver.parseHtmlResources(
          html: threadsTextHtml(),
          pageUrl: Uri.parse(threadsPostUrl),
        ),
        isEmpty,
      );
      expect(
        ThreadsResolver.detectPostKind(threadsTextHtml()),
        ThreadsPostKind.textOnly,
      );
    });

    test('TH-POST-002 text post still exposes author and caption', () {
      final info = ThreadsResolver.parsePostInfo(
        html: threadsTextHtml(),
        pageUrl: Uri.parse(threadsPostUrl),
        contentId: threadsPostId,
      );
      expect(info.postId, threadsPostId);
      expect(info.username, threadsUsername);
      expect(info.caption, 'Just a public text post');
      expect(info.canonicalUrl, isNotNull);
    });

    test('TH-POST-003 quote post is QUOTE and resolves quoted media', () {
      expect(
        ThreadsResolver.detectPostKind(threadsQuoteHtml()),
        ThreadsPostKind.quote,
      );
      final results = ThreadsResolver.parseHtmlResources(
        html: threadsQuoteHtml(),
        pageUrl: Uri.parse(threadsPostUrl),
      );
      expect(results, hasLength(1));
      expect(results.single.directUrl, threadsImageUrl);
    });

    test('TH-POST-004 quote uses original post id for identity', () {
      final info = ThreadsResolver.parsePostInfo(
        html: threadsQuoteHtml(),
        pageUrl: Uri.parse(threadsPostUrl),
        contentId: threadsPostId,
      );
      expect(info.originalPostId, threadsQuotedPostId);
    });

    test('TH-POST-005 repost is REPOST and resolves original media', () {
      expect(
        ThreadsResolver.detectPostKind(threadsRepostHtml()),
        ThreadsPostKind.repost,
      );
      final results = ThreadsResolver.parseHtmlResources(
        html: threadsRepostHtml(),
        pageUrl: Uri.parse(threadsPostUrl),
      );
      expect(results, hasLength(1));
      expect(results.single.directUrl, threadsImageUrl);
    });

    test('TH-POST-006 share URL classifies as the same post', () {
      expect(
        ThreadsUri.contentIdentity(Uri.parse(threadsShareUrl)),
        ThreadsUri.contentIdentity(Uri.parse(threadsPostUrl)),
      );
    });
  });
}
