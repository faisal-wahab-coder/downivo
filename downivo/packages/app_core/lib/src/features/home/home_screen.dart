import 'dart:async';

import 'package:analytics/analytics.dart';
import 'package:design_system/design_system.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_library/media_library.dart';
import 'package:shared_types/shared_types.dart';
import 'package:shared_utils/shared_utils.dart';
import 'package:storage/storage.dart';

import '../../providers/analytics_providers.dart';
import '../../providers/download_providers.dart';
import '../../providers/library_providers.dart';
import '../downloads/download_enqueue.dart';
import '../downloads/download_task_widgets.dart';
import '../downloads/format_picker_sheet.dart';
import '../downloads/media_preview_card.dart';
import '../files/open_managed_media.dart';
import '../intake/clipboard_history_screen.dart';
import '../intake/qr_navigation.dart';
import '../search/app_search_screen.dart';
import 'storage_dashboard.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _urlController = TextEditingController();
  final _urlFocus = FocusNode();
  Timer? _resolveDebounce;
  var _resolving = false;
  var _urlFocused = false;
  var _unsupported = false;
  String? _errorText;
  SocialPlatform? _platform;
  List<DiscoveredResource> _resources = const [];
  MediaFormat? _selectedFormat;

  @override
  void initState() {
    super.initState();
    _urlFocus.addListener(() {
      setState(() => _urlFocused = _urlFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _resolveDebounce?.cancel();
    _urlFocus.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _onUrlChanged(String value) {
    _resolveDebounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _errorText = null;
        _resources = const [];
        _platform = null;
        _resolving = false;
        _unsupported = false;
        _selectedFormat = null;
      });
      return;
    }
    final validation = UrlValidator().validate(value);
    final looksComplete = trimmed.contains('://') || trimmed.contains('.');
    if (!validation.isValid) {
      setState(() {
        _errorText = looksComplete ? validation.errorMessage : null;
        _platform = null;
        _resources = const [];
        _resolving = false;
        _unsupported = false;
        _selectedFormat = null;
      });
      return;
    }
    final canHandle = ContentProviderRegistry.canHandle(validation.uri!);
    setState(() {
      _errorText = null;
      _unsupported = !canHandle;
      _platform = SocialPlatform.fromUri(validation.uri!);
      _resources = const [];
      _selectedFormat = null;
    });
    if (!canHandle) return;
    _resolveDebounce = Timer(const Duration(milliseconds: 450), () {
      unawaited(_resolve(value.trim()));
    });
  }

  Future<void> _resolve(String url) async {
    setState(() {
      _resolving = true;
      _errorText = null;
    });
    try {
      final resources = await discoverAllResources(ref, url);
      if (!mounted || _urlController.text.trim() != url) return;
      setState(() {
        _resources = resources;
        _resolving = false;
        _selectedFormat = resources.isEmpty
            ? null
            : resources.first.recommendedFormat ??
                  (resources.first.formats.isEmpty
                      ? null
                      : resources.first.formats.first);
        if (resources.isEmpty) {
          final uri = Uri.tryParse(url);
          if (uri != null &&
              SocialPlatform.fromUri(uri) == SocialPlatform.soundcloud) {
            final kind = SoundCloudUri.classifyUrl(uri);
            _errorText = switch (kind) {
              SoundCloudContentType.profile =>
                'This is a SoundCloud profile, not a track or playlist. '
                    'Paste a track link or a playlist link (…/sets/…).',
              SoundCloudContentType.home =>
                'This is the SoundCloud home page, not a downloadable track.',
              SoundCloudContentType.nonContent =>
                'This SoundCloud page is not a downloadable track or playlist.',
              _ => 'Could not resolve this SoundCloud link.',
            };
          } else {
            _errorText = 'Could not resolve this link.';
          }
        }
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _resolving = false;
        _resources = const [];
        _selectedFormat = null;
        _errorText = DownloadErrorFormatter.fromObject(error);
      });
    }
  }

  Future<void> _paste() async {
    try {
      ref.read(analyticsServiceProvider).track(AnalyticsEvent.pasteButtonClicked);
      ref.read(analyticsServiceProvider).setLastAction('PasteUrl');
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();
      if (text == null || text.isEmpty) return;
      _urlController.text = text;
      _onUrlChanged(text);
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Clipboard access was blocked. Paste with Ctrl+V or ⌘V, '
            'or allow clipboard permission for this site.',
          ),
        ),
      );
    }
  }

  Future<void> _submit([String? raw]) async {
    final url = (raw ?? _urlController.text).trim();
    final validation = UrlValidator().validate(url);
    if (!validation.isValid) {
      setState(() => _errorText = validation.errorMessage ?? 'Invalid URL');
      return;
    }
    await enqueueUrlFlow(
      context,
      ref,
      validation.uri!.toString(),
      goToDownloads: true,
      formatOverride: _selectedFormat,
      resolvedResources: _resources.isEmpty ? null : _resources,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(downloadListProvider);
    final storageStats = ref.watch(managedStorageStatsProvider);
    final summaries = ref.watch(categorySummariesProvider);
    final volume = ref.watch(volumeStatsProvider);
    final wide = MediaQuery.sizeOf(context).width >= UdmBreakpoints.desktop;

    final active = tasks.where((t) => t.isActive).take(3).toList();
    final recentCompleted = tasks
        .where((t) => t.status == DownloadStatus.completed)
        .take(5)
        .toList();

    final preview = _resources.isNotEmpty ? _resources.first : null;

    final urlBlock = _UrlHero(
      controller: _urlController,
      focusNode: _urlFocus,
      focused: _urlFocused,
      resolving: _resolving,
      errorText: _errorText,
      unsupported: _unsupported,
      platform: _platform,
      preview: preview,
      extraCount: _resources.length > 1 ? _resources.length - 1 : 0,
      selectedFormat: _selectedFormat,
      onChanged: _onUrlChanged,
      onPaste: _paste,
      onSubmitted: _submit,
      onDownloadPreview: () => _submit(),
      onFormatSelected: preview != null && preview.formats.length > 1
          ? (picked) {
              setState(() => _selectedFormat = picked);
              ref.read(analyticsServiceProvider).track(
                AnalyticsEvent.qualityChanged,
                {AnalyticsProp.quality: picked.label},
              );
              ref.read(analyticsServiceProvider).track(
                AnalyticsEvent.formatChanged,
                {AnalyticsProp.format: picked.mimeType},
              );
            }
          : null,
      onMoreOptions: preview != null && preview.formats.length > 1
          ? () async {
              final picked = await FormatPickerSheet.show(
                context,
                formats: preview.formats,
                selected: _selectedFormat,
                selectedUrl: _selectedFormat?.url ?? preview.directUrl,
              );
              if (picked != null && mounted) {
                setState(() => _selectedFormat = picked);
                ref.read(analyticsServiceProvider).track(
                  AnalyticsEvent.qualityChanged,
                  {AnalyticsProp.quality: picked.label},
                );
                ref.read(analyticsServiceProvider).track(
                  AnalyticsEvent.formatChanged,
                  {AnalyticsProp.format: picked.mimeType},
                );
              }
            }
          : null,
      onScanQr: qrScannerAvailable ? () => openQrScanner(context) : null,
      onClipboard: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => const ClipboardHistoryScreen(),
          ),
        );
      },
      onBrowser: () => context.go(AppRoutes.browser),
      onSearch: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => const AppSearchScreen(),
          ),
        );
      },
    );

    final activityColumn = [
      if (active.isNotEmpty) ...[
        UdmSectionLabel(label: 'Active'),
        ...active.map(
          (task) => Padding(
            padding: const EdgeInsets.only(bottom: UdmSpacing.sm),
            child: DownloadTaskCard(task: task, ref: ref),
          ),
        ),
        const SizedBox(height: UdmSpacing.lg),
      ],
      if (recentCompleted.isNotEmpty) ...[
        UdmSectionLabel(
          label: 'Recent',
          trailing: TextButton(
            onPressed: () => context.push(AppRoutes.downloadHistory),
            child: const Text('View all'),
          ),
        ),
        ...recentCompleted.map(
          (task) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              task.isRemovedFromLibrary
                  ? Icons.delete_outline
                  : Icons.check_circle_outline,
              color: task.isRemovedFromLibrary
                  ? UdmColors.cautionAmber
                  : UdmColors.successMoss,
            ),
            title: Text(
              task.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              task.isRemovedFromLibrary
                  ? 'Removed from Files'
                  : task.fileSize != null
                  ? TransferFormat.bytes(task.fileSize!)
                  : 'Completed',
            ),
            onTap: () {
              if (task.hasManagedFile) {
                openManagedMedia(
                  context,
                  ref,
                  path: task.filePath!,
                  title: task.title?.trim().isNotEmpty == true
                      ? task.title!
                      : task.fileName,
                  mimeType: task.mimeType,
                );
              } else if (task.isRemovedFromLibrary) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('This file was deleted in Files'),
                  ),
                );
              }
            },
          ),
        ),
        const SizedBox(height: UdmSpacing.lg),
      ],
    ];

    final metaColumn = [
      _StorageOverview(
        stats: storageStats,
        summaries: summaries,
        volume: volume,
        onOpenFiles: () => context.go(AppRoutes.files),
      ),
      const SizedBox(height: UdmSpacing.xxl),
      const UdmSectionLabel(label: 'Supported sources'),
      Wrap(
        spacing: UdmSpacing.sm,
        runSpacing: UdmSpacing.sm,
        children: [
          for (final platform in SocialPlatform.values)
            PlatformBadge(label: platform.label),
        ],
      ),
    ];

    return UdmScaffold(
      title: AppIdentity.displayName,
      actions: [
        IconButton(
          tooltip: 'Search downloads and files',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const AppSearchScreen(),
              ),
            );
          },
          icon: const Icon(Icons.search),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(UdmSpacing.lg),
        children: [
          urlBlock,
          const SizedBox(height: UdmSpacing.xxl),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: activityColumn,
                  ),
                ),
                const SizedBox(width: UdmSpacing.xxl),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: metaColumn,
                  ),
                ),
              ],
            )
          else ...[
            ...activityColumn,
            ...metaColumn,
          ],
        ],
      ),
    );
  }
}

class _UrlHero extends StatelessWidget {
  const _UrlHero({
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.resolving,
    required this.errorText,
    required this.unsupported,
    required this.platform,
    required this.preview,
    required this.extraCount,
    required this.selectedFormat,
    required this.onChanged,
    required this.onPaste,
    required this.onSubmitted,
    required this.onDownloadPreview,
    required this.onMoreOptions,
    required this.onFormatSelected,
    required this.onScanQr,
    required this.onClipboard,
    required this.onBrowser,
    required this.onSearch,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final bool resolving;
  final String? errorText;
  final bool unsupported;
  final SocialPlatform? platform;
  final DiscoveredResource? preview;
  final int extraCount;
  final MediaFormat? selectedFormat;
  final ValueChanged<String> onChanged;
  final VoidCallback onPaste;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onDownloadPreview;
  final VoidCallback? onMoreOptions;
  final ValueChanged<MediaFormat>? onFormatSelected;
  final VoidCallback? onScanQr;
  final VoidCallback onClipboard;
  final VoidCallback onBrowser;
  final VoidCallback onSearch;

  String? get _helperText {
    if (errorText != null || resolving) return null;
    final raw = controller.text.trim();
    if (raw.isEmpty) {
      return focused
          ? 'Paste or type a link to download'
          : 'Paste a link to download';
    }
    if (unsupported) {
      return 'No extractor for this site. We can still save a direct file.';
    }
    if (platform != null && preview == null) {
      return 'Detected ${platform!.label}';
    }
    return 'Paste a link to download';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const UdmSectionLabel(label: 'Paste URL'),
        UrlInputField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          onPaste: onPaste,
          isResolving: resolving,
          errorText: errorText,
          helperText: _helperText,
        ),
        if (platform != null && preview == null && errorText == null) ...[
          const SizedBox(height: UdmSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: PlatformBadge(label: platform!.label),
          ),
        ],
        const SizedBox(height: UdmSpacing.md),
        Wrap(
          spacing: UdmSpacing.sm,
          children: [
            if (onScanQr != null)
              TextButton.icon(
                onPressed: onScanQr,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan QR'),
              ),
            TextButton.icon(
              onPressed: onClipboard,
              icon: const Icon(Icons.content_paste_outlined),
              label: const Text('Clipboard'),
            ),
            TextButton.icon(
              onPressed: onBrowser,
              icon: const Icon(Icons.language),
              label: const Text('Browser'),
            ),
            TextButton.icon(
              onPressed: onSearch,
              icon: const Icon(Icons.search),
              label: const Text('Search'),
            ),
          ],
        ),
        if (preview != null) ...[
          const SizedBox(height: UdmSpacing.md),
          MediaPreviewCard(
            resource: preview!,
            extraCount: extraCount,
            selectedFormat: selectedFormat,
            onDownload: onDownloadPreview,
            onMoreOptions: onMoreOptions,
            onFormatSelected: onFormatSelected,
          ),
        ],
      ],
    );
  }
}

class _StorageOverview extends StatelessWidget {
  const _StorageOverview({
    required this.stats,
    required this.summaries,
    required this.volume,
    required this.onOpenFiles,
  });

  final AsyncValue<(int, int)> stats;
  final AsyncValue<List<CategorySummary>> summaries;
  final AsyncValue<StorageInfo> volume;
  final VoidCallback onOpenFiles;

  @override
  Widget build(BuildContext context) {
    return StorageDashboard(
      managedStats: stats,
      summaries: summaries,
      volume: volume,
      onOpenFiles: onOpenFiles,
    );
  }
}
