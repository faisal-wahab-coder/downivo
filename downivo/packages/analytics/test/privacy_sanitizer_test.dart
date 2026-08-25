import 'package:analytics/analytics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sanitizer = PrivacySanitizer();

  test('drops url and token keys', () {
    final out = sanitizer.sanitize({
      'url': 'https://youtube.com/watch?v=1',
      'token': 'secret',
      'platform': 'youtube',
      'media_type': 'video',
    });
    expect(out.containsKey('url'), isFalse);
    expect(out.containsKey('token'), isFalse);
    expect(out['platform'], 'youtube');
    expect(out['media_type'], 'video');
  });

  test('redacts url-like values', () {
    final out = sanitizer.sanitize({
      'note': 'see https://private.example/file?access_token=abc',
    });
    expect(out.containsKey('note'), isFalse);
  });

  test('sanitizes log lines', () {
    final line = sanitizer.sanitizeMessage(
      'Downloading https://t.me/c/123 and Bearer abc.def',
    );
    expect(line.contains('https://'), isFalse);
    expect(line.contains('Bearer'), isFalse);
  });
}
