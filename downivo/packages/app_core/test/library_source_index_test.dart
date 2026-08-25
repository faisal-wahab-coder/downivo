import 'package:app_core/src/features/files/library_source_index.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_library/media_library.dart';

void main() {
  test('maps social URLs to file manager sources', () {
    expect(
      librarySourceFromUrl('https://www.youtube.com/watch?v=abc'),
      LibrarySourceFilter.youtube,
    );
    expect(
      librarySourceFromUrl('https://www.instagram.com/reel/xyz/'),
      LibrarySourceFilter.instagram,
    );
    expect(
      librarySourceFromUrl('https://tiktok.com/@user/video/1'),
      LibrarySourceFilter.tiktok,
    );
    expect(
      librarySourceFromUrl('https://cdn.example.com/file.mp4'),
      LibrarySourceFilter.direct,
    );
  });
}
