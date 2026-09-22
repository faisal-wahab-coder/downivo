import 'package:download_engine/download_engine.dart';
import 'package:flutter/material.dart';
import 'package:shared_utils/shared_utils.dart';

class FormatPickerSheet extends StatelessWidget {
  const FormatPickerSheet({
    super.key,
    required this.formats,
    this.selectedUrl,
    this.selected,
    this.title,
  });

  final List<MediaFormat> formats;
  final String? selectedUrl;
  final MediaFormat? selected;
  final String? title;

  static Future<MediaFormat?> show(
    BuildContext context, {
    required List<MediaFormat> formats,
    String? selectedUrl,
    MediaFormat? selected,
    String? title,
  }) {
    return showModalBottomSheet<MediaFormat>(
      context: context,
      showDragHandle: true,
      builder: (context) => FormatPickerSheet(
        formats: formats,
        selectedUrl: selectedUrl,
        selected: selected,
        title: title,
      ),
    );
  }

  MediaFormat? get _current {
    if (selected != null) return selected;
    final recommended = formats.where((format) => format.isRecommended);
    if (selectedUrl != null) {
      for (final format in formats) {
        if (format.url == selectedUrl && !format.extractAudio) return format;
      }
    }
    if (recommended.isNotEmpty) return recommended.first;
    return formats.isEmpty ? null : formats.first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final videos = [
      for (final format in formats)
        if (format.track != MediaFormatTrack.audio) format,
    ];
    final audios = [
      for (final format in formats)
        if (format.track == MediaFormatTrack.audio) format,
    ];
    final grouped = audios.isNotEmpty && videos.isNotEmpty;
    final heading = title ??
        (TikTokResolver.isWatermarkChoice(formats) ? 'Watermark' : 'Quality');
    final current = _current;

    List<Widget> tiles(List<MediaFormat> items) {
      return [
        for (final format in items)
          ListTile(
            title: Text(
              format.isRecommended
                  ? '${format.label} · Recommended'
                  : format.label,
            ),
            subtitle: Text(
              [
                if (format.mimeType != null) format.mimeType!,
                if (format.sizeBytes != null)
                  TransferFormat.bytes(format.sizeBytes!),
                if (format.extractAudio) 'From video',
              ].join(' · '),
            ),
            trailing: current != null && format.sameChoice(current)
                ? const Icon(Icons.check)
                : null,
            onTap: () => Navigator.pop(context, format),
          ),
      ];
    }

    return ListView(
      shrinkWrap: true,
      children: [
        ListTile(title: Text(grouped ? 'Save as' : heading)),
        if (grouped && videos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text('Video', style: theme.textTheme.titleSmall),
          ),
        ...tiles(grouped ? videos : formats),
        if (grouped) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text('Audio', style: theme.textTheme.titleSmall),
          ),
          ...tiles(audios),
        ],
      ],
    );
  }
}
