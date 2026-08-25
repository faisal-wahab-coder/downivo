import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'snapchat_fixtures.dart';

void main() {
  group('Snapchat videos', () {
    test('SC-VID-001 detects VIDEO', () {
      expect(
        SnapchatResolver.detectMediaType(snapchatVideoHtml()),
        SnapchatMediaType.video,
      );
    });

    test('SC-VID-002 resolves the exposed MP4', () {
      final results = SnapchatResolver.parseHtmlResources(
        html: snapchatVideoHtml(),
        pageUrl: Uri.parse(snapchatSpotlightUrl),
      );
      expect(results.single.directUrl, snapchatVideoUrl);
      expect(results.single.mimeType, 'video/mp4');
    });

    test('SC-VID-003 duration and thumbnail are mapped', () {
      final info = SnapchatResolver.parseContentInfo(
        html: snapchatVideoHtml(),
        pageUrl: Uri.parse(snapchatSpotlightUrl),
      );
      expect(info.durationSeconds, 12.5);
      expect(info.thumbnailUrl, snapchatThumbUrl);
      expect(info.width, 1080);
      expect(info.height, 1920);
    });

    test('SC-VID-004 HLS is not treated as a file', () {
      expect(SnapchatResolver.isDirectMediaUrl(snapchatHlsUrl), isFalse);
    });

    test('SC-VID-005 snapchat.com page URL is not a video file', () {
      expect(
        SnapchatResolver.isDirectMediaUrl(snapchatSpotlightUrl),
        isFalse,
      );
    });

    test('SC-VID-006 source src tag resolves the MP4', () {
      final results = SnapchatResolver.parseHtmlResources(
        html: snapchatVideoSourceHtml(),
        pageUrl: Uri.parse(snapchatSpotlightUrl),
      );
      expect(results.single.directUrl, snapchatVideoUrl);
      expect(results.single.mimeType, 'video/mp4');
    });
  });
}
