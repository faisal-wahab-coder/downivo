import 'package:download_engine/download_engine.dart';
import 'package:flutter/material.dart';
import 'package:shared_types/shared_types.dart';

/// Pre-download confirmation — URL, filename, and priority.
class DownloadWizardDialog extends StatefulWidget {
  const DownloadWizardDialog({super.key, this.initialUrl});

  final String? initialUrl;

  static Future<DownloadWizardResult?> show(
    BuildContext context, {
    String? initialUrl,
  }) {
    return showDialog<DownloadWizardResult>(
      context: context,
      builder: (context) => DownloadWizardDialog(initialUrl: initialUrl),
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
  });

  final String url;
  final String? fileName;
  final DownloadPriority priority;
}

class _DownloadWizardDialogState extends State<DownloadWizardDialog> {
  final _urlController = TextEditingController();
  final _fileNameController = TextEditingController();
  DownloadPriority _priority = DownloadPriority.normal;

  @override
  void initState() {
    super.initState();
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

  String _priorityLabel(DownloadPriority priority) => switch (priority) {
    DownloadPriority.low => 'Low',
    DownloadPriority.normal => 'Normal',
    DownloadPriority.high => 'High',
    DownloadPriority.urgent => 'Urgent',
  };
}
