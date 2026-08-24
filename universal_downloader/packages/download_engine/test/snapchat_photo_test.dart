import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'snapchat_fixtures.dart';

void main() {
  group('Snapchat photos', () {
    test('SC-PH-001 detects PHOTO', () {
      expect(
        SnapchatResolver.detectMediaType(snapchatPhotoHtml()),
        SnapchatMediaType.photo,
      );
    });

    test('SC-PH-002 resolves photo URL and JPEG MIME', () {
      final results = SnapchatResolver.parseHtmlResources(
        html: snapchatPhotoHtml(),
        pageUrl: Uri.parse(snapchatSnapUrl),
      );
      expect(results.single.directUrl, snapchatPhotoUrl);
      expect(results.single.mimeType, 'image/jpeg');
    });

    test('SC-PH-003 maps dimensions from Open Graph', () {
      final info = SnapchatResolver.parseContentInfo(
        html: snapchatPhotoHtml(),
        pageUrl: Uri.parse(snapchatSnapUrl),
      );
      expect(info.width, 1080);
      expect(info.height, 1920);
    });

    test('SC-PH-004 thumbnail is the exposed image', () {
      final results = SnapchatResolver.parseHtmlResources(
        html: snapchatPhotoHtml(),
        pageUrl: Uri.parse(snapchatSnapUrl),
      );
      expect(results.single.thumbnailUrl, snapchatPhotoUrl);
    });

    test('SC-PH-005 site icons are not treated as photos', () {
      final html = '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="Snapchat" />
<meta property="og:image" content="https://www.snapchat.com/favicon.ico" />
</head>
<body></body>
</html>''';
      final results = SnapchatResolver.parseHtmlResources(
        html: html,
        pageUrl: Uri.parse(snapchatSnapUrl),
      );
      expect(results, isEmpty);
    });
  });
}
