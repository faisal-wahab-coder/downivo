import 'package:flutter/material.dart';

/// Video or audio for one resolved video. Null means the user cancelled.
enum SaveAsChoice { video, audio }

Future<SaveAsChoice?> showSaveAsPrompt(
  BuildContext context, {
  required bool audioSelected,
}) {
  return showDialog<SaveAsChoice>(
    context: context,
    builder: (context) => _SaveAsDialog(audioSelected: audioSelected),
  );
}

class _SaveAsDialog extends StatefulWidget {
  const _SaveAsDialog({required this.audioSelected});

  final bool audioSelected;

  @override
  State<_SaveAsDialog> createState() => _SaveAsDialogState();
}

class _SaveAsDialogState extends State<_SaveAsDialog> {
  late String _value = widget.audioSelected ? 'audio' : 'video';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save as'),
      content: DropdownButtonFormField<String>(
        initialValue: _value,
        decoration: const InputDecoration(labelText: 'Format'),
        items: const [
          DropdownMenuItem(value: 'video', child: Text('Video')),
          DropdownMenuItem(value: 'audio', child: Text('Audio')),
        ],
        onChanged: (value) {
          if (value == null) return;
          setState(() => _value = value);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _value == 'audio' ? SaveAsChoice.audio : SaveAsChoice.video,
          ),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
