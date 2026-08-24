import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats CORS-style connection errors on web', () {
    final error = DioException(
      requestOptions: RequestOptions(path: 'https://example.com/file.mp4'),
      type: DioExceptionType.connectionError,
      message: 'The XMLHttpRequest onError callback was called.',
    );

    final message = DownloadErrorFormatter.fromDio(error);
    if (kIsWeb) {
      expect(message, contains('CORS'));
      expect(DownloadErrorFormatter.isPermanent(error), isTrue);
    } else {
      expect(message, contains('Network error'));
      expect(DownloadErrorFormatter.isPermanent(error), isFalse);
    }
  });
}
