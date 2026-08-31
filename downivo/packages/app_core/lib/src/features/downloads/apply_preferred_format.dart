import 'package:download_engine/download_engine.dart';

import '../../providers/settings_provider.dart';

DiscoveredResource applyPreferredFormat(
  DiscoveredResource resource,
  AppSettings settings, {
  MediaFormat? override,
}) {
  final format =
      override ??
      resource.formatMatching(
        quality: settings.preferredQuality,
        mime: settings.preferredFormat,
      );
  if (format == null) return resource;
  return resource.copyWith(
    directUrl: format.url,
    mimeType: format.mimeType ?? resource.mimeType,
    width: format.width ?? resource.width,
    height: format.height ?? resource.height,
    contentLengthBytes: format.sizeBytes ?? resource.contentLengthBytes,
  );
}

List<DiscoveredResource> applyPreferredFormats(
  List<DiscoveredResource> resources,
  AppSettings settings, {
  MediaFormat? override,
}) {
  return [
    for (final resource in resources)
      applyPreferredFormat(resource, settings, override: override),
  ];
}

/// A format whose label/mime actually matches Settings prefs.
/// Does not fall back to the recommended stream.
MediaFormat? explicitPreferredFormat(
  DiscoveredResource resource,
  AppSettings settings,
) {
  final quality = settings.preferredQuality?.trim().toLowerCase();
  final mime = settings.preferredFormat?.trim().toLowerCase();
  if ((quality == null || quality.isEmpty) &&
      (mime == null || mime.isEmpty)) {
    return null;
  }
  if (quality != null && quality.isNotEmpty) {
    for (final format in resource.formats) {
      if (!format.label.toLowerCase().contains(quality)) continue;
      if (mime == null ||
          mime.isEmpty ||
          (format.mimeType?.toLowerCase().contains(mime) ?? false)) {
        return format;
      }
    }
  }
  if (mime != null && mime.isNotEmpty) {
    for (final format in resource.formats) {
      if (format.mimeType?.toLowerCase().contains(mime) ?? false) {
        return format;
      }
    }
  }
  return null;
}
