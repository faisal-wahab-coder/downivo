import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_library/media_library.dart';
import 'package:shared_types/shared_types.dart';
import 'package:udm_search/search.dart';

import '../../providers/download_providers.dart';
import '../../providers/library_providers.dart';
import '../../providers/settings_provider.dart';
import '../files/file_detail_screen.dart';
import '../files/image_gallery_screen.dart';

class AppSearchScreen extends ConsumerStatefulWidget {
  const AppSearchScreen({super.key});

  @override
  ConsumerState<AppSearchScreen> createState() => _AppSearchScreenState();
}

class _AppSearchScreenState extends ConsumerState<AppSearchScreen> {
  final _controller = TextEditingController();
  var _hits = const <SearchHit>[];
  var _hasQuery = false;

  RecentSearches get _recent =>
      RecentSearches(ref.read(sharedPreferencesProvider));

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run(String raw) async {
    final query = raw.trim();
    setState(() => _hasQuery = query.isNotEmpty);
    if (query.isEmpty) {
      setState(() => _hits = const []);
      return;
    }
    final files = await ref
        .read(mediaLibraryServiceProvider)
        .listFiles(const LibraryQuery());
    final downloads = ref.read(downloadListProvider);
    final hits = const AppSearchService().search(
      query: query,
      files: files,
      downloads: downloads,
    );
    await _recent.add(query);
    if (!mounted) return;
    setState(() => _hits = hits);
  }

  @override
  Widget build(BuildContext context) {
    final recents = _recent.read();
    return UdmScaffold(
      title: 'Search',
      body: ListView(
        padding: const EdgeInsets.all(UdmSpacing.lg),
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search downloads and files',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _controller.clear();
                        _run('');
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
            onChanged: _run,
            onSubmitted: _run,
          ),
          const SizedBox(height: UdmSpacing.lg),
          if (!_hasQuery) ...[
            Row(
              children: [
                const UdmSectionLabel(label: 'Recent'),
                const Spacer(),
                if (recents.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      await _recent.clear();
                      setState(() {});
                    },
                    child: const Text('Clear'),
                  ),
              ],
            ),
            if (recents.isEmpty)
              const EmptyState(
                icon: Icons.search,
                title: 'Search your library',
                subtitle: 'Find downloads and files by name or platform.',
              )
            else
              Wrap(
                spacing: 8,
                children: [
                  for (final item in recents)
                    ActionChip(
                      label: Text(item),
                      onPressed: () {
                        _controller.text = item;
                        _run(item);
                      },
                    ),
                ],
              ),
          ] else if (_hits.isEmpty)
            const EmptyState(
              icon: Icons.search_off,
              title: 'No results found',
              subtitle: 'Try a different name, platform, or file type.',
            )
          else
            for (final hit in _hits)
              ListTile(
                leading: Icon(
                  hit.kind == SearchHitKind.file
                      ? Icons.insert_drive_file_outlined
                      : Icons.download_outlined,
                ),
                title: Text(hit.title),
                subtitle: Text(hit.subtitle ?? hit.kind.name),
                onTap: () async {
                  if (hit.kind == SearchHitKind.file && hit.path != null) {
                    final service = ref.read(mediaLibraryServiceProvider);
                    final file = await service.fileAt(hit.path!);
                    if (!context.mounted) return;
                    if (file != null && file.isGalleryImage) {
                      final matches = await service.listFiles(
                        LibraryQuery(search: _controller.text.trim()),
                      );
                      if (!context.mounted) return;
                      await openImageGallery(
                        context,
                        images: matches,
                        initial: file,
                      );
                      return;
                    }
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) =>
                            FileDetailScreen(filePath: hit.path!),
                      ),
                    );
                  } else {
                    context.go(AppRoutes.downloads);
                  }
                },
              ),
        ],
      ),
    );
  }
}
