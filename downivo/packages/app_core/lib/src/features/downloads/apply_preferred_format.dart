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
        mime: _audioFormatNeedle(settings.preferredFormat),
      );
  if (format == null) return resource;
  return resource.withFormat(format);
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
  final mime = _audioFormatNeedle(settings.preferredFormat);
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

/// Settings format is Video or Audio. Only Audio selects an audio row.
/// Video, and older saved values (Any, MP4, WebM), keep the video choice
/// so a label of "video" does not match the first `video/mp4` and skip
/// the quality sheet.
String? _audioFormatNeedle(String? format) {
  final value = format?.trim().toLowerCase();
  return value == 'audio' ? 'audio' : null;
}
