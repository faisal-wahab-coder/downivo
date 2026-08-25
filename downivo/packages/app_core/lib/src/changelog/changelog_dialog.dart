import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import 'app_changelog.dart';

Future<void> showChangelogDialog(
  BuildContext context, {
  List<ChangelogEntry>? entries,
}) {
  final toShow = entries ?? changelogEntries;
  if (toShow.isEmpty) return Future.value();

  return showDialog<void>(
    context: context,
    builder: (context) => ChangelogDialog(entries: toShow),
  );
}

class ChangelogDialog extends StatelessWidget {
  const ChangelogDialog({super.key, required this.entries});

  final List<ChangelogEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = entries.length == 1
        ? "What's new in ${entries.first.version}"
        : "What's new";
    final maxHeight = MediaQuery.sizeOf(context).height * 0.5;

    return AlertDialog(
      title: Text(title),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                if (entries.length > 1) ...[
                  if (i > 0) const SizedBox(height: UdmSpacing.lg),
                  Text(
                    'Version ${entries[i].version}',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: UdmSpacing.sm),
                ],
                for (final highlight in entries[i].highlights)
                  Padding(
                    padding: const EdgeInsets.only(bottom: UdmSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('•  ', style: theme.textTheme.bodyMedium),
                        Expanded(
                          child: Text(
                            highlight,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it'),
        ),
      ],
    );
  }
}
