import 'package:analytics/analytics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps twitter to x and shorts path', () {
    expect(AnalyticsPlatform.fromSocialName('twitter'), AnalyticsPlatform.x);
    expect(
      AnalyticsPlatform.fromSocialName(
        'youtube',
        uri: 'https://www.youtube.com/shorts/abc',
      ),
      AnalyticsPlatform.youtubeShorts,
    );
    expect(
      AnalyticsPlatform.fromSocialName(
        'youtube',
        uri: 'https://www.youtube.com/watch?v=1',
      ),
      AnalyticsPlatform.youtube,
    );
    expect(AnalyticsPlatform.fromSocialName(null), AnalyticsPlatform.unknown);
    expect(
      AnalyticsPlatform.fromSocialName(null, uri: 'https://cdn.example/a.mp4'),
      AnalyticsPlatform.directUrl,
    );
  });

  test('file size buckets', () {
    expect(fileSizeBucket(1024), '< 10 MB');
    expect(fileSizeBucket(20 * 1024 * 1024), '10–50 MB');
    expect(fileSizeBucket(2 * 1024 * 1024 * 1024), '> 1 GB');
  });

  test('error categories from messages', () {
    expect(ErrorCategory.fromMessage('Invalid URL').wireValue, 'invalid_url');
    expect(ErrorCategory.fromMessage('403 forbidden').wireValue, 'private_content');
    expect(ErrorCategory.fromMessage('404 not found').wireValue, 'content_not_found');
    expect(ErrorCategory.fromMessage('429 Too many').wireValue, 'rate_limited');
    expect(ErrorCategory.fromMessage('Connection timed out').wireValue, 'timeout');
  });
}
