import 'package:download_engine/download_engine.dart';
import 'package:flutter/material.dart';
import 'package:shared_types/shared_types.dart';

/// Pre-download confirmation — URL, filename, priority, and format.
class DownloadWizardDialog extends StatefulWidget {
  const DownloadWizardDialog({
    super.key,
    this.initialUrl,
    this.initialFormat,
  });

  final String? initialUrl;

  /// Settings format. Audio preselects Audio; anything else preselects Video.
  final String? initialFormat;

  static Future<DownloadWizardResult?> show(
    BuildContext context, {
    String? initialUrl,
    String? initialFormat,
  }) {
    return showDialog<DownloadWizardResult>(
      context: context,
      builder: (context) => DownloadWizardDialog(
        initialUrl: initialUrl,
        initialFormat: initialFormat,
      ),
    );
  }

  @override
  State<DownloadWizardDialog> createState() => _DownloadWizardDialogState();
}

class DownloadWizardResult {
  const DownloadWizardResult({
    required this.url,
    required this.fileName,
    required this.priority,
    required this.format,
  });

  final String url;
  final String? fileName;
  final DownloadPriority priority;

  /// Null means Video for this download. Audio is `audio`.
  final String? format;
}

class _DownloadWizardDialogState extends State<DownloadWizardDialog> {
  final _urlController = TextEditingController();
  final _fileNameController = TextEditingController();
  DownloadPriority _priority = DownloadPriority.normal;
  String? _format;

  @override
  void initState() {
    super.initState();
    _format = _normalizeFormat(widget.initialFormat);
    if (widget.initialUrl != null) {
      _urlController.text = widget.initialUrl!;
      _fileNameController.text = UrlValidator().fileNameFromUrl(
        Uri.parse(widget.initialUrl!),
      );
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _fileNameController.dispose();
    super.dispose();
  }

  void _submit() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    Navigator.pop(
      context,
      DownloadWizardResult(
        url: url,
        fileName: _fileNameController.text.trim().isEmpty
            ? null
            : _fileNameController.text.trim(),
        priority: _priority,
        format: _format,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New download'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://example.com/file.zip',
              ),
              keyboardType: TextInputType.url,
              autofocus: widget.initialUrl == null,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fileNameController,
              decoration: const InputDecoration(
                labelText: 'File name (optional)',
                hintText: 'Leave empty to detect from server',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<DownloadPriority>(
              value: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: DownloadPriority.values
                  .map(
                    (priority) => DropdownMenuItem(
                      value: priority,
                      child: Text(_priorityLabel(priority)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _priority = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _format == 'audio' ? 'audio' : 'video',
              decoration: const InputDecoration(labelText: 'Format'),
              items: const [
                DropdownMenuItem(value: 'video', child: Text('Video')),
                DropdownMenuItem(value: 'audio', child: Text('Audio')),
              ],
              onChanged: (value) {
                setState(() => _format = value == 'audio' ? 'audio' : null);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Download')),
      ],
    );
  }

  static String? _normalizeFormat(String? format) {
    return format == 'audio' ? 'audio' : null;
  }

  String _priorityLabel(DownloadPriority priority) => switch (priority) {
    DownloadPriority.low => 'Low',
    DownloadPriority.normal => 'Normal',
    DownloadPriority.high => 'High',
    DownloadPriority.urgent => 'Urgent',
  };
}
