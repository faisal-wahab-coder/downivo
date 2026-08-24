import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/download_providers.dart';
import 'download_task_widgets.dart';

class DownloadHistoryScreen extends ConsumerWidget {
  const DownloadHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(downloadHistoryProvider);

    return UdmScaffold(
      title: 'Download history',
      actions: [
        if (history.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear history',
            onPressed: () => _confirmClearHistory(context, ref),
          ),
      ],
      body: history.isEmpty
          ? const EmptyState(
              icon: Icons.history,
              title: 'No download history',
              subtitle:
                  'Completed, failed, and cancelled downloads will appear here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(UdmSpacing.lg),
              itemCount: history.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: UdmSpacing.sm),
              itemBuilder: (context, index) {
                final task = history[index];
                return DownloadTaskCard(task: task, ref: ref);
              },
            ),
    );
  }

  Future<void> _confirmClearHistory(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear download history?'),
        content: const Text(
          'History entries will be removed. Downloaded files on your device are not deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear history'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final removed = await clearDownloadHistory(ref);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            removed > 0
                ? 'Cleared $removed ${removed == 1 ? 'entry' : 'entries'}'
                : 'History already empty',
          ),
        ),
      );
    }
  }
}
