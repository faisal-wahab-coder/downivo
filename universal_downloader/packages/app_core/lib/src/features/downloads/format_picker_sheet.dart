import 'package:download_engine/download_engine.dart';
import 'package:flutter/material.dart';
import 'package:shared_utils/shared_utils.dart';

class FormatPickerSheet extends StatelessWidget {
  const FormatPickerSheet({super.key, required this.formats, this.selectedUrl});

  final List<MediaFormat> formats;
  final String? selectedUrl;

  static Future<MediaFormat?> show(
    BuildContext context, {
    required List<MediaFormat> formats,
    String? selectedUrl,
  }) {
    return showModalBottomSheet<MediaFormat>(
      context: context,
      showDragHandle: true,
      builder: (context) =>
          FormatPickerSheet(formats: formats, selectedUrl: selectedUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        const ListTile(title: Text('Quality')),
        for (final format in formats)
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
              ].join(' · '),
            ),
            trailing:
                (selectedUrl ??
                        formats
                            .where((f) => f.isRecommended)
                            .firstOrNull
                            ?.url ??
                        formats.first.url) ==
                    format.url
                ? const Icon(Icons.check)
                : null,
            onTap: () => Navigator.pop(context, format),
          ),
      ],
    );
  }
}
