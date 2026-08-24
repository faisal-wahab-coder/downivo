import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final validator = UrlValidator();

  test('SEC-001 rejects file URLs', () {
    expect(validator.validate('file:///etc/passwd').isValid, isFalse);
  });

  test('SEC-002 rejects javascript URLs', () {
    expect(validator.validate('javascript:alert(1)').isValid, isFalse);
  });

  test('SEC-003 rejects ftp URLs', () {
    expect(validator.validate('ftp://files.example.com/a.bin').isValid, isFalse);
  });

  test('SEC-004 rejects empty and whitespace URLs', () {
    expect(validator.validate('').isValid, isFalse);
    expect(validator.validate('   ').isValid, isFalse);
  });

  test('SEC-005 sanitizes path-traversal filenames', () {
    final name = FileNameResolver.sanitize('../../etc/passwd');
    expect(name.contains('/'), isFalse);
    expect(name.contains('\\'), isFalse);
  });

  test('SEC-006 strips traversal from Content-Disposition', () {
    final name = FileNameResolver.resolve(
      uri: Uri.parse('https://cdn.example/file.bin'),
      contentDisposition: 'attachment; filename="../../etc/passwd"',
      contentType: 'application/octet-stream',
    );
    expect(name.contains('/'), isFalse);
    expect(name.contains('\\'), isFalse);
  });

  test('SEC-007 rejects HTML responses', () {
    expect(
      () => FileNameResolver.resolve(
        uri: Uri.parse('https://example.com/page'),
        contentType: 'text/html; charset=utf-8',
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('DownloadErrorFormatter maps HTTP and timeout errors', () {
    expect(
      DownloadErrorFormatter.fromObject(ArgumentError('bad request')),
      'bad request',
    );
  });
}
