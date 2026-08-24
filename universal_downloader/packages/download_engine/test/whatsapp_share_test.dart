import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WhatsApp share MIME and filename', () {
    test('WA-SHARE-001 shared JPEG is IMAGE', () {
      expect(
        WhatsAppResolver.classifyImportedFile(
          fileName: 'IMG-20240101-WA0001.jpg',
          mimeType: 'image/jpeg',
        ),
        WhatsAppMediaType.image,
      );
    });

    test('WA-SHARE-002 shared MP4 is VIDEO', () {
      expect(
        WhatsAppResolver.classifyImportedFile(
          fileName: 'VID-20240101-WA0001.mp4',
          mimeType: 'video/mp4',
        ),
        WhatsAppMediaType.video,
      );
    });

    test('WA-SHARE-003 shared MP3 is AUDIO', () {
      expect(
        WhatsAppResolver.classifyImportedFile(
          fileName: 'AUD-20240101-WA0001.mp3',
          mimeType: 'audio/mpeg',
        ),
        WhatsAppMediaType.audio,
      );
    });

    test('WA-SHARE-004 shared PTT opus is VOICE_NOTE', () {
      expect(
        WhatsAppResolver.classifyImportedFile(
          fileName: 'PTT-20240101-WA0001.opus',
          mimeType: 'audio/opus',
        ),
        WhatsAppMediaType.voiceNote,
      );
    });

    test('WA-SHARE-005 shared PDF is PDF', () {
      expect(
        WhatsAppResolver.classifyImportedFile(
          fileName: 'DOC-20240101-WA0001.pdf',
          mimeType: 'application/pdf',
        ),
        WhatsAppMediaType.pdf,
      );
    });

    test('WA-SHARE-006 shared ZIP is ARCHIVE', () {
      expect(
        WhatsAppResolver.classifyImportedFile(
          fileName: 'archive.zip',
          mimeType: 'application/zip',
        ),
        WhatsAppMediaType.archive,
      );
    });

    test('WA-SHARE-007 shared vCard is CONTACT', () {
      expect(
        WhatsAppResolver.classifyImportedFile(
          fileName: 'contact.vcf',
          mimeType: 'text/vcard',
        ),
        WhatsAppMediaType.contact,
      );
    });

    test('WA-SHARE-008 filename is sanitized for share import', () {
      final name = FileNameResolver.sanitize('IMG-2024/WA:0001?.jpg');
      expect(name, isNot(contains('/')));
      expect(name, isNot(contains(':')));
      expect(name, isNot(contains('?')));
    });

    test('WA-SHARE-009 multiple files keep independent types', () {
      final types = [
        WhatsAppResolver.classifyImportedFile(fileName: 'a.jpg'),
        WhatsAppResolver.classifyImportedFile(fileName: 'b.mp4'),
        WhatsAppResolver.classifyImportedFile(fileName: 'c.pdf'),
      ];
      expect(types, [
        WhatsAppMediaType.image,
        WhatsAppMediaType.video,
        WhatsAppMediaType.pdf,
      ]);
    });
  });
}
