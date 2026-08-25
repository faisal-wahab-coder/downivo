import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WhatsApp documents', () {
    test('WA-DOC-001 PDF is PDF', () {
      expect(
        WhatsAppResolver.classifyImportedFile(fileName: 'report.pdf'),
        WhatsAppMediaType.pdf,
      );
      expect(WhatsAppResolver.mimeFromUrl('a.pdf'), 'application/pdf');
    });

    test('WA-DOC-002 DOCX is DOCUMENT', () {
      expect(
        WhatsAppResolver.classifyImportedFile(fileName: 'letter.docx'),
        WhatsAppMediaType.document,
      );
    });

    test('WA-DOC-003 XLSX is DOCUMENT', () {
      expect(
        WhatsAppResolver.classifyImportedFile(fileName: 'sheet.xlsx'),
        WhatsAppMediaType.document,
      );
    });

    test('WA-DOC-004 PPTX is DOCUMENT', () {
      expect(
        WhatsAppResolver.classifyImportedFile(fileName: 'slides.pptx'),
        WhatsAppMediaType.document,
      );
    });

    test('WA-DOC-005 TXT is TEXT', () {
      expect(
        WhatsAppResolver.classifyImportedFile(fileName: 'notes.txt'),
        WhatsAppMediaType.text,
      );
      expect(WhatsAppResolver.mimeFromUrl('notes.txt'), 'text/plain');
    });

    test('WA-DOC-006 vCard is CONTACT and is not auto-saved', () {
      expect(
        WhatsAppResolver.classifyImportedFile(
          fileName: 'Alice.vcf',
          mimeType: 'text/vcard',
        ),
        WhatsAppMediaType.contact,
      );
      expect(FileNameResolver.extensionFromMime('text/vcard'), '.vcf');
    });

    test('WA-DOC-007 office MIME mapping', () {
      expect(
        WhatsAppResolver.mimeFromUrl('a.docx'),
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
      expect(
        WhatsAppResolver.mimeFromUrl('a.xlsx'),
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    });
  });
}
