import 'models/discovered_resource.dart';
import 'tiktok_resolver.dart';

/// Adds an M4A choice when a video has no separate audio URL.
class AudioDownloadOption {
  const AudioDownloadOption._();

  static const audioLabel = 'M4A';

  static DiscoveredResource decorate(DiscoveredResource resource) {
    if (resource.offersAudio) return resource;
    if (resource.resolvedKind != DiscoveredResourceKind.video) return resource;

    final source = resource.recommendedFormat?.url ?? resource.directUrl;
    if (_isPlaylist(source) || _isPlaylist(resource.directUrl)) return resource;

    final videos = resource.formats.isNotEmpty
        ? resource.formats
        : [
            MediaFormat(
              url: resource.directUrl,
              label: resource.height != null && resource.height! > 0
                  ? '${resource.height}p'
                  : 'Video',
              mimeType: resource.mimeType ?? 'video/mp4',
              height: resource.height,
              width: resource.width,
              sizeBytes: resource.contentLengthBytes,
              isRecommended: true,
            ),
          ];

    return resource.copyWith(
      formats: [
        ...videos,
        MediaFormat(
          url: source,
          label: audioLabel,
          mimeType: 'audio/mp4',
          track: MediaFormatTrack.audio,
          extractAudio: true,
        ),
      ],
    );
  }

  static List<DiscoveredResource> decorateAll(List<DiscoveredResource> resources) {
    return [for (final resource in resources) decorate(resource)];
  }

  /// Opens the format sheet for real quality or watermark choices.
  ///
  /// A single video plus an M4A row stays one tap; Audio is under More options.
  static bool shouldAutoPrompt(List<MediaFormat> formats) {
    if (formats.length <= 1) return false;
    if (TikTokResolver.isWatermarkChoice(formats)) return true;
    final videos = formats
        .where((format) => format.track != MediaFormatTrack.audio)
        .length;
    return videos > 1;
  }

  static bool _isPlaylist(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
    return path.endsWith('.m3u8') ||
        path.endsWith('.mpd') ||
        path.contains('.m3u8');
  }
}
