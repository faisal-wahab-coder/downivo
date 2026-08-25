import 'package:content_intake/content_intake.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/intake_providers.dart';
import 'intake_action_handler.dart';

class ClipboardHistoryScreen extends ConsumerWidget {
  const ClipboardHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(clipboardHistoryProvider);
    final store = ref.read(clipboardHistoryStoreProvider);

    return UdmScaffold(
      title: 'Clipboard history',
      actions: [
        if (history.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear history',
            onPressed: () async {
              await store.clear();
              refreshIntakeData(ref);
            },
          ),
      ],
      body: history.isEmpty
          ? const EmptyState(
              icon: Icons.content_paste_outlined,
              title: 'No clipboard history',
              subtitle: 'Copied download links appear here when detected.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(UdmSpacing.lg),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final entry = history[index];
                return Card(
                  child: ListTile(
                    title: Text(
                      entry.detectedUrl ?? entry.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(entry.capturedAt.toLocal().toString()),
                    trailing: entry.detectedUrl != null
                        ? const Icon(Icons.download_outlined)
                        : null,
                    onTap: entry.detectedUrl == null
                        ? null
                        : () => IntakeActionHandler.handle(
                              context,
                              ref,
                              IntakeAction(
                                type: IntakeActionType.download,
                                url: entry.detectedUrl,
                              ),
                            ),
                  ),
                );
              },
            ),
    );
  }
}
