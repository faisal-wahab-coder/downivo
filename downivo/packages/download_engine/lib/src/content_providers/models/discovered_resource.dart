import '../../filename_resolver.dart';

/// Direct media resource discovered from a social or content page URL.
class DiscoveredResource {
  const DiscoveredResource({
    required this.directUrl,
    required this.fileName,
    required this.platform,
    this.pageUrl,
    this.title,
    this.mimeType,
    this.requestHeaders,
    this.thumbnailUrl,
    this.author,
    this.durationSeconds,
    this.width,
    this.height,
    this.contentLengthBytes,
    this.kind = DiscoveredResourceKind.unknown,
    this.formats = const [],
  });

  final String directUrl;
  final String fileName;
  final String platform;
  final String? pageUrl;
  final String? title;
  final String? mimeType;
  final Map<String, String>? requestHeaders;
  final String? thumbnailUrl;
  final String? author;
  final double? durationSeconds;
  final int? width;
  final int? height;
  final int? contentLengthBytes;
  final DiscoveredResourceKind kind;
  final List<MediaFormat> formats;

  DiscoveredResourceKind get resolvedKind =>
      kind != DiscoveredResourceKind.unknown
          ? kind
          : DiscoveredResourceKind.fromMime(mimeType);

  MediaFormat? get recommendedFormat {
    for (final format in formats) {
      if (format.isRecommended) return format;
    }
    return formats.isEmpty ? null : formats.first;
  }

  MediaFormat? formatMatching({String? quality, String? mime}) {
    if (formats.isEmpty) return null;
    final qualityNeedle = quality?.trim().toLowerCase();
    final mimeNeedle = mime?.trim().toLowerCase();
    if (qualityNeedle != null && qualityNeedle.isNotEmpty) {
      for (final format in formats) {
        if (format.label.toLowerCase().contains(qualityNeedle)) {
          if (mimeNeedle == null ||
              mimeNeedle.isEmpty ||
              (format.mimeType?.toLowerCase().contains(mimeNeedle) ?? false)) {
            return format;
          }
        }
      }
    }
    if (mimeNeedle != null && mimeNeedle.isNotEmpty) {
      for (final format in formats) {
        if (format.mimeType?.toLowerCase().contains(mimeNeedle) ?? false) {
          return format;
        }
      }
    }
    return recommendedFormat;
  }

  String? get resolutionLabel {
    if (width == null || height == null || height == 0) return null;
    return '${width}x$height';
  }

  bool get offersAudio =>
      formats.any((format) => format.track == MediaFormatTrack.audio);

  /// Applies a picker choice: audio saves as an audio file, video stays video.
  DiscoveredResource withFormat(MediaFormat format) {
    final audio = format.track == MediaFormatTrack.audio;
    final mime = format.mimeType ?? mimeType;
    return copyWith(
      directUrl: format.url,
      fileName: FileNameResolver.replaceExtension(fileName, mime),
      mimeType: mime,
      width: format.width,
      height: format.height,
      clearDimensions: audio,
      contentLengthBytes: format.extractAudio
          ? null
          : (format.sizeBytes ?? contentLengthBytes),
      clearContentLength: format.extractAudio,
      kind: audio ? DiscoveredResourceKind.audio : kind,
    );
  }

  DiscoveredResource copyWith({
    String? directUrl,
    String? fileName,
    String? platform,
    String? pageUrl,
    String? title,
    String? mimeType,
    Map<String, String>? requestHeaders,
    String? thumbnailUrl,
    String? author,
    double? durationSeconds,
    int? width,
    int? height,
    bool clearDimensions = false,
    int? contentLengthBytes,
    bool clearContentLength = false,
    DiscoveredResourceKind? kind,
    List<MediaFormat>? formats,
  }) {
    return DiscoveredResource(
      directUrl: directUrl ?? this.directUrl,
      fileName: fileName ?? this.fileName,
      platform: platform ?? this.platform,
      pageUrl: pageUrl ?? this.pageUrl,
      title: title ?? this.title,
      mimeType: mimeType ?? this.mimeType,
      requestHeaders: requestHeaders ?? this.requestHeaders,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      author: author ?? this.author,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      width: clearDimensions ? null : (width ?? this.width),
      height: clearDimensions ? null : (height ?? this.height),
      contentLengthBytes: clearContentLength
          ? null
          : (contentLengthBytes ?? this.contentLengthBytes),
      kind: kind ?? this.kind,
      formats: formats ?? this.formats,
    );
  }
}

enum DiscoveredResourceKind {
  video,
  audio,
  image,
  document,
  carousel,
  unknown;

  static DiscoveredResourceKind fromMime(
    String? mime, {
    bool carousel = false,
  }) {
    if (carousel) return DiscoveredResourceKind.carousel;
    if (mime == null || mime.isEmpty) return DiscoveredResourceKind.unknown;
    if (mime.startsWith('video/')) return DiscoveredResourceKind.video;
    if (mime.startsWith('audio/')) return DiscoveredResourceKind.audio;
    if (mime.startsWith('image/')) return DiscoveredResourceKind.image;
    return DiscoveredResourceKind.document;
  }

  String get label => switch (this) {
        DiscoveredResourceKind.video => 'Video',
        DiscoveredResourceKind.audio => 'Audio',
        DiscoveredResourceKind.image => 'Image',
        DiscoveredResourceKind.document => 'Document',
        DiscoveredResourceKind.carousel => 'Gallery',
        DiscoveredResourceKind.unknown => 'Media',
      };
}

enum MediaFormatTrack { video, audio }

/// A selectable download rendition exposed by a resolver.
class MediaFormat {
  const MediaFormat({
    required this.url,
    required this.label,
    this.mimeType,
    this.height,
    this.width,
    this.bitrate,
    this.sizeBytes,
    this.isRecommended = false,
    this.track = MediaFormatTrack.video,
    this.extractAudio = false,
  });

  final String url;
  final String label;
  final String? mimeType;
  final int? height;
  final int? width;
  final int? bitrate;
  final int? sizeBytes;
  final bool isRecommended;

  /// Video keeps the picture. Audio saves only the soundtrack.
  final MediaFormatTrack track;

  /// Download the video file, then copy its audio track into an M4A.
  final bool extractAudio;

  bool sameChoice(MediaFormat other) {
    return url == other.url &&
        track == other.track &&
        extractAudio == other.extractAudio &&
        label == other.label;
  }
}
