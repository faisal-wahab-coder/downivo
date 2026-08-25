import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RangeResponseParser', () {
    test('parses total bytes from content-range', () {
      expect(
        RangeResponseParser.totalBytesFromContentRange('bytes 0-99/1000'),
        1000,
      );
    });

    test('returns null for wildcard total', () {
      expect(
        RangeResponseParser.totalBytesFromContentRange('bytes 0-99/*'),
        isNull,
      );
    });

    test('builds range header', () {
      expect(RangeResponseParser.rangeHeaderFor(512), 'bytes=512-');
    });
  });
}
