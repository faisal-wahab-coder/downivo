enum ViewerMediaKind { video, audio, unsupported }

ViewerMediaKind viewerKindForMime(String? mime, String path) {
  final lowerMime = (mime ?? '').toLowerCase();
  final lowerPath = path.toLowerCase();
  if (lowerMime.startsWith('video/') ||
      lowerPath.endsWith('.mp4') ||
      lowerPath.endsWith('.webm') ||
      lowerPath.endsWith('.mkv') ||
      lowerPath.endsWith('.mov')) {
    return ViewerMediaKind.video;
  }
  if (lowerMime.startsWith('audio/') ||
      lowerPath.endsWith('.mp3') ||
      lowerPath.endsWith('.m4a') ||
      lowerPath.endsWith('.aac') ||
      lowerPath.endsWith('.wav') ||
      lowerPath.endsWith('.ogg')) {
    return ViewerMediaKind.audio;
  }
  return ViewerMediaKind.unsupported;
}
