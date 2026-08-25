import 'package:browser/browser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BrowserUrlUtils', () {
    test('normalizes bare domains to https', () {
      expect(
        BrowserUrlUtils.normalizeInput('example.com'),
        'https://example.com',
      );
    });

    test('turns spaced input into search', () {
      final result = BrowserUrlUtils.normalizeInput('flutter webview');
      expect(result, contains('google.com/search'));
      expect(result, contains('flutter'));
    });

    test('empty input opens home', () {
      expect(BrowserUrlUtils.normalizeInput(''), BrowserTab.homeUrl);
    });
  });

  group('DownloadDetector', () {
    test('detects direct file URLs', () {
      expect(
        DownloadDetector.isDirectDownloadUrl(
          'https://cdn.example.com/files/report.pdf',
        ),
        isTrue,
      );
    });

    test('ignores regular pages', () {
      expect(
        DownloadDetector.isDirectDownloadUrl('https://example.com/about'),
        isFalse,
      );
    });

    test('extracts filename label', () {
      final detected = DownloadDetector.fromNavigationUrl(
        'https://files.example.com/archive.zip',
      );
      expect(detected?.label, 'archive.zip');
    });

    test('deduplicates page links', () {
      final links = DownloadDetector.fromLinkUrls([
        'https://a.example/video.mp4',
        'https://a.example/video.mp4',
        'https://a.example/page',
      ]);
      expect(links, hasLength(1));
      expect(links.first.url, contains('video.mp4'));
    });
  });
}
