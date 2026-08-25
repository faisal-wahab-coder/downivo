import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WhatsApp file import classification', () {
    test('WA-IMP-001 image import by extension', () {
      expect(
        WhatsAppResolver.classifyImportedFile(fileName: 'photo.png'),
        WhatsAppMediaType.image,
      );
    });

    test('WA-IMP-002 video import by MIME', () {
      expect(
        WhatsAppResolver.classifyImportedFile(
          fileName: 'clip',
          mimeType: 'video/mp4',
        ),
        WhatsAppMediaType.video,
      );
    });

    test('WA-IMP-003 M4A is AUDIO', () {
      expect(
        WhatsAppResolver.classifyImportedFile(
          fileName: 'track.m4a',
          mimeType: 'audio/mp4',
        ),
        WhatsAppMediaType.audio,
      );
    });

    test('WA-IMP-004 AAC is AUDIO', () {
      expect(
        WhatsAppResolver.classifyImportedFile(fileName: 'clip.aac'),
        WhatsAppMediaType.audio,
      );
    });

    test('WA-IMP-005 OGG is VOICE_NOTE for WhatsApp-originated audio', () {
      expect(
        WhatsAppResolver.classifyImportedFile(
          fileName: 'note.ogg',
          mimeType: 'audio/ogg',
        ),
        WhatsAppMediaType.voiceNote,
      );
    });

    test('WA-IMP-006 DOCX is DOCUMENT', () {
      expect(
        WhatsAppResolver.classifyImportedFile(fileName: 'report.docx'),
        WhatsAppMediaType.document,
      );
    });

    test('WA-IMP-007 XLSX is DOCUMENT', () {
      expect(
        WhatsAppResolver.classifyImportedFile(fileName: 'sheet.xlsx'),
        WhatsAppMediaType.document,
      );
    });

    test('WA-IMP-008 PPTX is DOCUMENT', () {
      expect(
        WhatsAppResolver.classifyImportedFile(fileName: 'deck.pptx'),
        WhatsAppMediaType.document,
      );
    });

    test('WA-IMP-009 TXT is TEXT', () {
      expect(
        WhatsAppResolver.classifyImportedFile(fileName: 'notes.txt'),
        WhatsAppMediaType.text,
      );
    });

    test('WA-IMP-010 CSV is DOCUMENT', () {
      expect(
        WhatsAppResolver.classifyImportedFile(fileName: 'data.csv'),
        WhatsAppMediaType.document,
      );
    });

    test('WA-IMP-011 unknown extension is UNKNOWN', () {
      expect(
        WhatsAppResolver.classifyImportedFile(fileName: 'file.bin'),
        WhatsAppMediaType.unknown,
      );
    });
  });
}
