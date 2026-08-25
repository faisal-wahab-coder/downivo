import 'package:analytics/analytics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppLogger never prints raw urls', () {
    final lines = <String>[];
    final logger = AppLogger(
      sink: (level, line) => lines.add(line),
    );
    logger.info(
      'Download started https://secret.example/file?token=1',
      fields: {
        'downloadId': '83921',
        'url': 'https://secret.example/file',
        'platform': 'youtube',
      },
    );
    expect(lines, hasLength(1));
    expect(lines.single.contains('https://'), isFalse);
    expect(lines.single.contains('token='), isFalse);
    expect(lines.single.contains('downloadId=83921'), isTrue);
    expect(lines.single.contains('platform=youtube'), isTrue);
  });
}
