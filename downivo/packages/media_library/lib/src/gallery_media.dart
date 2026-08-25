/// Helpers for copying photos/videos into the device gallery.
///
/// Detection is MIME-first with extension fallback so QR Downloads and
/// unsorted imports still qualify when they are images or videos.
const _imageExtensions = {
  '.jpg',
  '.jpeg',
  '.png',
  '.gif',
  '.webp',
  '.bmp',
  '.heic',
  '.heif',
  '.avif',
};

const _videoExtensions = {
  '.mp4',
  '.mkv',
  '.webm',
  '.mov',
  '.3gp',
  '.avi',
  '.m4v',
};

String galleryExtensionOf(String path) {
  final slash = path.replaceAll('\\', '/').lastIndexOf('/');
  final name = (slash >= 0 ? path.substring(slash + 1) : path).toLowerCase();
  final dot = name.lastIndexOf('.');
  if (dot <= 0) return '';
  return name.substring(dot);
}

bool isGallerySaveable({required String path, String? mimeType}) {
  return isGalleryImageMedia(path: path, mimeType: mimeType) ||
      isGalleryVideoMedia(path: path, mimeType: mimeType);
}

bool isGalleryImageMedia({required String path, String? mimeType}) {
  final mime = (mimeType ?? '').toLowerCase();
  if (mime.startsWith('image/')) return true;
  if (mime.startsWith('video/')) return false;
  return _imageExtensions.contains(galleryExtensionOf(path));
}

bool isGalleryVideoMedia({required String path, String? mimeType}) {
  final mime = (mimeType ?? '').toLowerCase();
  if (mime.startsWith('video/')) return true;
  if (mime.startsWith('image/')) return false;
  return _videoExtensions.contains(galleryExtensionOf(path));
}
