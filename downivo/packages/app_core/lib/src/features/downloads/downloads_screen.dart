import 'package:analytics/analytics.dart';
import 'package:design_system/design_system.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_types/shared_types.dart';

import '../../providers/analytics_providers.dart';
import '../../providers/download_providers.dart';
import '../../providers/settings_provider.dart';
import 'download_enqueue.dart';
import 'download_task_widgets.dart';
import 'download_wizard_dialog.dart';
import '../search/app_search_screen.dart';

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  static const _collapsedLimit = 10;
  var _showAllCompleted = false;
  var _showAllFailed = false;
  var _filter = _QueueFilter.all;
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(downloadListProvider);

    // Update rolling speed history.
    final currentTotalSpeed = tasks
        .where((t) => t.status == DownloadStatus.downloading)
        .fold<int>(0, (sum, t) => sum + t.speedBytesPerSec);
    _speedHistory.add(currentTotalSpeed);
    if (_speedHistory.length > _maxSpeedHistory) {
      _speedHistory.removeAt(0);
    }

    final queued = tasks
        .where((t) => t.status == DownloadStatus.queued)
        .toList();
    final preparing = tasks
        .where((t) => t.status == DownloadStatus.preparing)
        .toList();
    final downloading = tasks
        .where((t) => t.status == DownloadStatus.downloading)
        .toList();
    final verifying = tasks
        .where((t) => t.status == DownloadStatus.verifying)
        .toList();
    final paused = tasks
        .where((t) => t.status == DownloadStatus.paused)
        .toList();
    final completed = tasks
        .where((t) => t.status == DownloadStatus.completed)
        .toList();
    final failed = tasks
        .where((t) => t.status == DownloadStatus.failed)
        .toList();
    final hasActiveDownloads =
        downloading.isNotEmpty ||
        queued.isNotEmpty ||
        preparing.isNotEmpty ||
        verifying.isNotEmpty;
    final hasPaused = paused.isNotEmpty;

    final wide = MediaQuery.sizeOf(context).width >= UdmBreakpoints.desktop;
    final selected = _selectedId == null
        ? (tasks.isEmpty ? null : tasks.first)
        : tasks.cast<DownloadTask?>().firstWhere(
            (t) => t!.id == _selectedId,
            orElse: () => tasks.isEmpty ? null : tasks.first,
          );

    final list = tasks.isEmpty
        ? EmptyState(
            icon: Icons.download_outlined,
            title: 'No downloads yet',
            subtitle:
                'Paste a URL on Home or tap Add URL to start downloading.',
            actionLabel: 'Add URL',
            onAction: () => _showWizard(context, ref),
          )
        : ListView(
            padding: const EdgeInsets.all(UdmSpacing.lg),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () => _showWizard(context, ref),
                  icon: const Icon(Icons.add_link),
                  label: const Text('Add URL'),
                ),
              ),
              const SizedBox(height: UdmSpacing.lg),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in _QueueFilter.values)
                      Padding(
                        padding: const EdgeInsets.only(right: UdmSpacing.sm),
                        child: FilterChip(
                          label: Text(filter.label),
                          selected: _filter == filter,
                          onSelected: (_) => setState(() => _filter = filter),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: UdmSpacing.lg),
              if (_filter.showDownloading && downloading.isNotEmpty) ...[
                UdmSectionLabel(label: 'Downloading (${downloading.length})'),
                ...downloading.map(
                  (t) => _DownloadTile(
                    task: t,
                    ref: ref,
                    selected: wide && selected?.id == t.id,
                    onSelect: () => setState(() => _selectedId = t.id),
                  ),
                ),
              ],
              if (_filter.showPreparing && preparing.isNotEmpty) ...[
                const SizedBox(height: UdmSpacing.lg),
                UdmSectionLabel(label: 'Finding video (${preparing.length})'),
                ...preparing.map(
                  (t) => _DownloadTile(
                    task: t,
                    ref: ref,
                    selected: wide && selected?.id == t.id,
                    onSelect: () => setState(() => _selectedId = t.id),
                  ),
                ),
              ],
              if (_filter.showQueued && queued.isNotEmpty) ...[
                const SizedBox(height: UdmSpacing.lg),
                UdmSectionLabel(
                  label: 'Queued (${queued.length}) — drag to reorder',
                ),
                _ReorderableQueue(tasks: queued),
              ],
              if (_filter.showPaused && paused.isNotEmpty) ...[
                const SizedBox(height: UdmSpacing.lg),
                UdmSectionLabel(label: 'Paused (${paused.length})'),
                ...paused.map(
                  (t) => _DownloadTile(
                    task: t,
                    ref: ref,
                    selected: wide && selected?.id == t.id,
                    onSelect: () => setState(() => _selectedId = t.id),
                  ),
                ),
              ],
              if (_filter.showVerifying && verifying.isNotEmpty) ...[
                const SizedBox(height: UdmSpacing.lg),
                UdmSectionLabel(label: 'Verifying (${verifying.length})'),
                ...verifying.map(
                  (t) => _DownloadTile(
                    task: t,
                    ref: ref,
                    selected: wide && selected?.id == t.id,
                    onSelect: () => setState(() => _selectedId = t.id),
                  ),
                ),
              ],
              if (_filter.showCompleted && completed.isNotEmpty) ...[
                const SizedBox(height: UdmSpacing.lg),
                UdmSectionLabel(label: 'Completed (${completed.length})'),
                ..._visibleTasks(completed, expanded: _showAllCompleted).map(
                  (t) => _DownloadTile(
                    task: t,
                    ref: ref,
                    selected: wide && selected?.id == t.id,
                    onSelect: () => setState(() => _selectedId = t.id),
                  ),
                ),
                if (completed.length > _collapsedLimit)
                  _ExpandTile(
                    hiddenCount: completed.length - _collapsedLimit,
                    expanded: _showAllCompleted,
                    onToggle: () =>
                        setState(() => _showAllCompleted = !_showAllCompleted),
                  ),
              ],
              if (_filter.showFailed && failed.isNotEmpty) ...[
                const SizedBox(height: UdmSpacing.lg),
                UdmSectionLabel(label: 'Failed (${failed.length})'),
                ..._visibleTasks(failed, expanded: _showAllFailed).map(
                  (t) => _DownloadTile(
                    task: t,
                    ref: ref,
                    selected: wide && selected?.id == t.id,
                    onSelect: () => setState(() => _selectedId = t.id),
                  ),
                ),
                if (failed.length > _collapsedLimit)
                  _ExpandTile(
                    hiddenCount: failed.length - _collapsedLimit,
                    expanded: _showAllFailed,
                    onToggle: () =>
                        setState(() => _showAllFailed = !_showAllFailed),
                  ),
              ],
            ],
          );

    // Aggregate stats for status bar and speed graph.
    final totalSpeed = downloading.fold<int>(
        0, (sum, t) => sum + t.speedBytesPerSec);
    final stuckDownloads =
        downloading.where((t) => t.isStuck).toList();

    final mainContent = wide && selected != null && tasks.isNotEmpty
        ? Row(
            children: [
              Expanded(flex: 3, child: list),
              VerticalDivider(
                width: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              Expanded(
                flex: 2,
                child: _DownloadDetailPane(task: selected, ref: ref),
              ),
            ],
          )
        : list;

    return UdmScaffold(
      title: 'Downloads',
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Search',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const AppSearchScreen(),
              ),
            );
          },
        ),
        if (stuckDownloads.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload stuck (${stuckDownloads.length})',
            onPressed: () {
              final manager = ref.read(downloadManagerProvider);
              manager.reloadAllStuck();
            },
          ),
        IconButton(
          icon: const Icon(Icons.history),
          tooltip: 'Download history',
          onPressed: () => context.push(AppRoutes.downloadHistory),
        ),
        if (hasActiveDownloads)
          IconButton(
            icon: const Icon(Icons.pause_circle_outline),
            tooltip: 'Pause all',
            onPressed: () => pauseAllDownloads(ref),
          ),
        if (hasPaused)
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            tooltip: 'Resume all',
            onPressed: () => resumeAllDownloads(ref),
          ),
      ],
      body: Column(
        children: [
          Expanded(child: mainContent),

          // Segment visualizer for selected downloading task.
          if (selected != null &&
              selected.status == DownloadStatus.downloading &&
              selected.segments.isNotEmpty)
            SegmentVisualizerWidget(
              segments: selected.segments,
              fileName: selected.fileName,
              connectionCount: selected.connectionCount,
              totalBytes: selected.fileSize ?? 0,
              downloadedBytes: selected.bytesReceived,
              speed: selected.speedBytesPerSec,
              etaSeconds: selected.eta.inSeconds,
              isDownloading: true,
            ),

          // Speed graph when downloads are active.
          if (downloading.isNotEmpty)
            SpeedGraphWidget(
              speedHistory: _speedHistory,
              currentSpeed: totalSpeed,
              speedLimitBytesPerSec: 0,
            ),

          // Status bar footer.
          DownloadStatusBar(
            totalItems: tasks.length,
            activeCount: downloading.length,
            totalSpeedBytesPerSec: totalSpeed,
            completedCount: completed.length,
            queuedCount: queued.length,
          ),
        ],
      ),
    );
  }

  // Rolling speed history for the graph.
  final _speedHistory = <int>[];
  static const _maxSpeedHistory = 50;

  List<DownloadTask> _visibleTasks(
    List<DownloadTask> tasks, {
    required bool expanded,
  }) {
    if (expanded || tasks.length <= _collapsedLimit) return tasks;
    return tasks.take(_collapsedLimit).toList();
  }

  Future<void> _showWizard(BuildContext context, WidgetRef ref) async {
    ref.read(analyticsServiceProvider).screen(AnalyticsScreen.urlInput);
    final result = await DownloadWizardDialog.show(
      context,
      initialFormat: ref.read(settingsProvider).preferredFormat,
    );
    if (result == null || !context.mounted) return;

    await enqueueUrlFlow(
      context,
      ref,
      result.url,
      fileName: result.fileName,
      priority: result.priority,
      preferredFormat: result.format,
      goToDownloads: false,
    );
  }
}

enum _QueueFilter { all, active, completed, failed }

extension on _QueueFilter {
  String get label => switch (this) {
    _QueueFilter.all => 'All',
    _QueueFilter.active => 'Active',
    _QueueFilter.completed => 'Completed',
    _QueueFilter.failed => 'Failed',
  };

  bool get showDownloading =>
      this == _QueueFilter.all || this == _QueueFilter.active;
  bool get showPreparing =>
      this == _QueueFilter.all || this == _QueueFilter.active;
  bool get showQueued =>
      this == _QueueFilter.all || this == _QueueFilter.active;
  bool get showPaused =>
      this == _QueueFilter.all || this == _QueueFilter.active;
  bool get showVerifying =>
      this == _QueueFilter.all || this == _QueueFilter.active;
  bool get showCompleted =>
      this == _QueueFilter.all || this == _QueueFilter.completed;
  bool get showFailed =>
      this == _QueueFilter.all || this == _QueueFilter.failed;
}

class _ExpandTile extends StatelessWidget {
  const _ExpandTile({
    required this.hiddenCount,
    required this.expanded,
    required this.onToggle,
  });

  final int hiddenCount;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: onToggle,
        child: Text(expanded ? 'Show less' : 'Show $hiddenCount more'),
      ),
    );
  }
}

class _DownloadTile extends StatelessWidget {
  const _DownloadTile({
    required this.task,
    required this.ref,
    this.selected = false,
    this.onSelect,
  });

  final DownloadTask task;
  final WidgetRef ref;
  final bool selected;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final tokens = ZfileTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: UdmSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(UdmRadius.card),
          border: selected
              ? Border.all(color: tokens.secondary, width: 1.5)
              : null,
        ),
        child: DownloadTaskCard(task: task, ref: ref, onTap: onSelect),
      ),
    );
  }
}

class _DownloadDetailPane extends StatelessWidget {
  const _DownloadDetailPane({required this.task, required this.ref});

  final DownloadTask task;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = ZfileTokens.of(context);

    return ListView(
      padding: const EdgeInsets.all(UdmSpacing.lg),
      children: [
        Text(task.fileName, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: UdmSpacing.sm),
        Text(
          task.url,
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: UdmSpacing.md),
        // Badges row.
        Wrap(
          spacing: UdmSpacing.sm,
          runSpacing: 4,
          children: [
            DownloadStatusBadge(
              status: task.status,
              isStuck: task.isStuck,
              isSlow: task.isSlow,
            ),
            if (task.connectionCount > 1)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tokens.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(UdmRadius.button),
                  border: Border.all(
                      color: tokens.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${task.connectionCount} connections',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: tokens.primary,
                  ),
                ),
              ),
            if (task.reloadCount > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: UdmColors.cautionAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(UdmRadius.button),
                ),
                child: Text(
                  'Reloaded ×${task.reloadCount}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: UdmColors.cautionAmber,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: UdmSpacing.lg),
        DownloadProgressDetails(task: task),
        const SizedBox(height: UdmSpacing.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: DownloadTrailingActions(task: task, ref: ref),
        ),
        // Segment visualizer for multi-connection downloads.
        if (task.segments.isNotEmpty &&
            task.status == DownloadStatus.downloading) ...[
          const SizedBox(height: UdmSpacing.lg),
          SegmentVisualizerWidget(
            segments: task.segments,
            fileName: task.fileName,
            connectionCount: task.connectionCount,
            totalBytes: task.fileSize ?? 0,
            downloadedBytes: task.bytesReceived,
            speed: task.speedBytesPerSec,
            etaSeconds: task.eta.inSeconds,
            isDownloading: true,
          ),
        ],
        if (task.isRemovedFromLibrary) ...[
          const SizedBox(height: UdmSpacing.lg),
          Text(
            'This file was deleted in Files',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (task.filePath != null) ...[
          const SizedBox(height: UdmSpacing.lg),
          Text(task.filePath!, style: Theme.of(context).textTheme.bodySmall),
        ],
        // Checksum info for completed downloads.
        if (task.status == DownloadStatus.completed &&
            task.checksumSha256 != null) ...[
          const SizedBox(height: UdmSpacing.lg),
          Container(
            padding: const EdgeInsets.all(UdmSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? UdmColors.insetWell : UdmColors.paper,
              borderRadius: BorderRadius.circular(UdmRadius.card),
              border: Border.all(
                color: tokens.secondaryDark.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_rounded,
                        size: 14, color: tokens.secondaryDark),
                    const SizedBox(width: 6),
                    Text(
                      'Verified',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tokens.secondaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'SHA-256: ${task.checksumSha256!.substring(0, 16)}…',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: isDark ? UdmColors.fogSteel : UdmColors.slateMute,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ReorderableQueue extends ConsumerWidget {
  const _ReorderableQueue({required this.tasks});

  final List<DownloadTask> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: tasks.length,
      onReorder: (oldIndex, newIndex) async {
        if (newIndex > oldIndex) newIndex -= 1;
        final reordered = List<DownloadTask>.from(tasks);
        final item = reordered.removeAt(oldIndex);
        reordered.insert(newIndex, item);
        await reorderQueue(ref, reordered.map((t) => t.id).toList());
      },
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Padding(
          key: ValueKey(task.id),
          padding: const EdgeInsets.only(bottom: UdmSpacing.sm),
          child: DownloadTaskCard(
            task: task,
            ref: ref,
            leading: ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
          ),
        );
      },
    );
  }
}
