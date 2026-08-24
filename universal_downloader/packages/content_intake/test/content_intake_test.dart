import 'package:content_intake/content_intake.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContentAnalyzer', () {
    final analyzer = ContentAnalyzer();

    test('extracts http URLs from text', () {
      final result = analyzer.analyzeText(
        'Check https://example.com/video.mp4 for the file',
      );
      expect(result.urls, ['https://example.com/video.mp4']);
    });

    test('accepts bare URL input', () {
      final result = analyzer.analyzeText('https://cdn.test/file.zip');
      expect(result.urls, ['https://cdn.test/file.zip']);
    });

    test('accepts TikTok URLs for provider handling', () {
      final result = analyzer.analyzeText(
        'https://www.tiktok.com/@user/video/1234567890',
      );
      expect(result.urls, hasLength(1));
    });
  });

  group('QrContentResolver', () {
    final resolver = QrContentResolver();

    test('resolves direct download QR codes', () {
      final action = resolver.resolveQr('https://files.test/setup.apk');
      expect(action.type, IntakeActionType.download);
      expect(action.url, contains('setup.apk'));
    });

    test('resolves web URLs to browser action', () {
      final action = resolver.resolveQr('https://example.com/page');
      expect(action.type, IntakeActionType.openInBrowser);
    });

    test('resolves TikTok URLs to download action', () {
      final action = resolver.resolveQr(
        'https://www.tiktok.com/@user/video/1234567890',
      );
      expect(action.type, IntakeActionType.download);
      expect(action.label, 'TikTok');
    });

    test('resolves shared files to import action', () {
      final action = resolver.resolveShare(
        const SharePayload(
          text: null,
          filePaths: ['/tmp/shared.pdf'],
          mimeTypes: ['application/pdf'],
        ),
      );
      expect(action.type, IntakeActionType.importFiles);
      expect(action.filePaths, hasLength(1));
    });
  });
}
