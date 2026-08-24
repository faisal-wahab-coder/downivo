import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WhatsApp audio and voice notes', () {
    test('WA-AUD-001 MP3 is AUDIO', () {
      expect(
        WhatsAppResolver.classifyImportedFile(fileName: 'song.mp3'),
        WhatsAppMediaType.audio,
      );
    });

    test('WA-AUD-002 M4A is AUDIO', () {
      expect(
        WhatsAppResolver.classifyImportedFile(fileName: 'clip.m4a'),
        WhatsAppMediaType.audio,
      );
    });

    test('WA-AUD-003 AAC is AUDIO', () {
      expect(
        WhatsAppResolver.classifyImportedFile(fileName: 'clip.aac'),
        WhatsAppMediaType.audio,
      );
    });

    test('WA-AUD-004 PTT opus is VOICE_NOTE', () {
      expect(
        WhatsAppResolver.classifyImportedFile(
          fileName: 'PTT-20240101-WA0001.opus',
          mimeType: 'audio/opus',
        ),
        WhatsAppMediaType.voiceNote,
      );
    });

    test('WA-AUD-005 MIME mapping for voice and audio files', () {
      expect(WhatsAppResolver.mimeFromUrl('a.mp3'), 'audio/mpeg');
      expect(WhatsAppResolver.mimeFromUrl('a.m4a'), 'audio/mp4');
      expect(WhatsAppResolver.mimeFromUrl('a.opus'), 'audio/opus');
      expect(WhatsAppResolver.mimeFromUrl('a.ogg'), 'audio/ogg');
      expect(FileNameResolver.extensionFromMime('audio/opus'), '.opus');
      expect(FileNameResolver.extensionFromMime('audio/ogg'), '.ogg');
    });

    test('WA-AUD-006 OGA is VOICE_NOTE', () {
      expect(
        WhatsAppResolver.classifyImportedFile(fileName: 'note.oga'),
        WhatsAppMediaType.voiceNote,
      );
    });
  });
}
