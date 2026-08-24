import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'snapchat_fixtures.dart';

void main() {
  group('Snapchat metadata mapping', () {
    test('SC-META-001 spotlight identity and creator', () {
      final info = SnapchatResolver.parseContentInfo(
        html: snapchatVideoHtml(),
        pageUrl: Uri.parse(snapchatSpotlightUrl),
        contentId: snapchatSpotlightId,
      );
      expect(info.contentId, snapchatSpotlightId);
      expect(info.creator, 'Fixture User');
      expect(info.canonicalUrl, snapchatSpotlightUrl);
    });

    test('SC-META-002 Arabic caption is preserved', () {
      const caption = 'مرحبا بالعالم';
      final info = SnapchatResolver.parseContentInfo(
        html: snapchatPhotoHtml(caption: caption),
        pageUrl: Uri.parse(snapchatSnapUrl),
      );
      expect(info.caption, caption);
    });

    test('SC-META-003 MIME mapping', () {
      expect(SnapchatResolver.mimeFromUrl(snapchatVideoUrl), 'video/mp4');
      expect(SnapchatResolver.mimeFromUrl(snapchatPhotoUrl), 'image/jpeg');
      expect(
        SnapchatResolver.mimeFromUrl(snapchatHlsUrl),
        'application/vnd.apple.mpegurl',
      );
    });

    test('SC-META-004 pageUrl is preserved on resources', () {
      final results = SnapchatResolver.parseHtmlResources(
        html: snapchatPhotoHtml(title: 'Sunset'),
        pageUrl: Uri.parse(snapchatSnapUrl),
      );
      expect(results.single.pageUrl, snapchatSnapUrl);
      expect(results.single.platform, 'Snapchat');
    });

    test('SC-META-005 missing metadata is null not fabricated', () {
      final info = SnapchatResolver.parseContentInfo(
        html: '<html><body></body></html>',
        pageUrl: Uri.parse(snapchatSnapUrl),
      );
      expect(info.caption, isNull);
      expect(info.durationSeconds, isNull);
    });
  });
}
