import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WhatsApp archives', () {
    test('WA-ARC-001 ZIP is ARCHIVE', () {
      expect(
        WhatsAppResolver.classifyImportedFile(fileName: 'bundle.zip'),
        WhatsAppMediaType.archive,
      );
      expect(WhatsAppResolver.mimeFromUrl('a.zip'), 'application/zip');
    });

    test('WA-ARC-002 RAR is ARCHIVE', () {
      expect(
        WhatsAppResolver.classifyImportedFile(fileName: 'bundle.rar'),
        WhatsAppMediaType.archive,
      );
    });

    test('WA-ARC-003 7z is ARCHIVE', () {
      expect(
        WhatsAppResolver.classifyImportedFile(fileName: 'bundle.7z'),
        WhatsAppMediaType.archive,
      );
    });

    test('WA-ARC-004 archives are not auto-extracted by the classifier', () {
      expect(
        WhatsAppResolver.classifyImportedFile(
          fileName: 'bundle.zip',
          mimeType: 'application/zip',
        ),
        WhatsAppMediaType.archive,
      );
    });

    test('WA-ARC-005 path-traversal zip name is sanitized', () {
      final name = FileNameResolver.sanitize('../../../../whatsapp.zip');
      expect(name, isNot(contains('/')));
      expect(name, isNot(contains('\\')));
      expect(name, isNot(equals('../../../../whatsapp.zip')));
    });
  });
}
