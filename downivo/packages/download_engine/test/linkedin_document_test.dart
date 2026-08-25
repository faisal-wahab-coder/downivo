import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'linkedin_fixtures.dart';

void main() {
  group('LinkedIn document / carousel posts', () {
    test('LI-DOC-001 discovers PDF when exposed', () {
      final results = LinkedInResolver.parseHtmlResources(
        html: linkedinDocumentHtml(),
        pageUrl: Uri.parse(linkedinPostUrl),
        contentId: linkedinActivityId,
      );
      expect(results, isNotEmpty);
      expect(results.single.directUrl, linkedinPdfUrl);
      expect(results.single.mimeType, 'application/pdf');
      expect(results.single.fileName.toLowerCase(), contains('.pdf'));
    });

    test('LI-DOC-002 MIME mapping for document path', () {
      expect(LinkedInResolver.mimeFromUrl(linkedinPdfUrl), 'application/pdf');
    });

    test('LI-DOC-003 document takes priority over og:image', () {
      final html = '${linkedinDocumentHtml()}${linkedinDirectOgImageHtml()}';
      final results = LinkedInResolver.parseHtmlResources(
        html: html,
        pageUrl: Uri.parse(linkedinPostUrl),
        contentId: linkedinActivityId,
      );
      expect(results.single.mimeType, 'application/pdf');
    });
  });
}
