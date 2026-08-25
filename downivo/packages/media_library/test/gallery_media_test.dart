import 'package:flutter_test/flutter_test.dart';
import 'package:media_library/media_library.dart';
import 'package:storage/storage.dart';

LibraryFile _file({
  required String path,
  required StorageCategory category,
  String? mimeType,
}) {
  return LibraryFile(
    path: path,
    name: path.split('/').last,
    category: category,
    sizeBytes: 12,
    modifiedAt: DateTime(2026, 8, 24),
    mimeType: mimeType,
  );
}

void main() {
  test('jpeg and png are gallery photos', () {
    expect(
      isGallerySaveable(path: '/Images/shot.jpg', mimeType: 'image/jpeg'),
      isTrue,
    );
    expect(
      isGalleryImageMedia(path: '/Images/shot.jpg', mimeType: 'image/jpeg'),
      isTrue,
    );
    expect(
      isGalleryVideoMedia(path: '/Images/shot.jpg', mimeType: 'image/jpeg'),
      isFalse,
    );
    expect(
      _file(
        path: '/Images/shot.png',
        category: StorageCategory.images,
      ).canSaveToGallery,
      isTrue,
    );
  });

  test('jpeg in QR Downloads is still a gallery photo', () {
    expect(
      isGalleryImageMedia(path: '/QR Downloads/shot.jpg', mimeType: null),
      isTrue,
    );
    expect(
      _file(
        path: '/QR Downloads/shot.jpg',
        category: StorageCategory.qrDownloads,
      ).isGalleryImage,
      isTrue,
    );
    expect(
      isGalleryImageMedia(path: '/Videos/clip.mp4', mimeType: 'video/mp4'),
      isFalse,
    );
  });

  test('mp4 is a gallery video even without MIME', () {
    expect(isGallerySaveable(path: '/Videos/clip.mp4'), isTrue);
    expect(isGalleryVideoMedia(path: '/Videos/clip.mp4'), isTrue);
    expect(
      _file(
        path: '/QR Downloads/clip.MP4',
        category: StorageCategory.qrDownloads,
      ).isGalleryVideo,
      isTrue,
    );
  });

  test('documents and audio are not gallery media', () {
    expect(
      isGallerySaveable(
        path: '/Documents/note.pdf',
        mimeType: 'application/pdf',
      ),
      isFalse,
    );
    expect(
      isGallerySaveable(path: '/Audio/track.mp3', mimeType: 'audio/mpeg'),
      isFalse,
    );
    expect(
      _file(
        path: '/Documents/note.pdf',
        category: StorageCategory.documents,
        mimeType: 'application/pdf',
      ).canSaveToGallery,
      isFalse,
    );
  });
}
