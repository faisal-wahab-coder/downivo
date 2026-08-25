import 'package:browser/browser.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/browser_providers.dart';

Future<void> showBrowserTabsSheet(
  BuildContext context,
  WidgetRef ref, {
  required void Function(int index) onSelect,
  required void Function(int index) onClose,
  required VoidCallback onNewTab,
}) {
  final session = ref.read(browserSessionProvider);

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: UdmSpacing.lg),
              child: Row(
                children: [
                  Text(
                    'Tabs (${session.tabs.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onNewTab();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('New tab'),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: session.tabs.length,
                itemBuilder: (context, index) {
                  final tab = session.tabs[index];
                  final isActive = index == session.activeIndex;
                  return ListTile(
                    selected: isActive,
                    leading: Icon(
                      tab.isHome ? Icons.home_outlined : Icons.public,
                    ),
                    title: Text(tab.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: tab.isHome
                        ? const Text('Start page')
                        : Text(
                            tab.url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                    trailing: session.tabs.length > 1
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              Navigator.pop(context);
                              onClose(index);
                            },
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      onSelect(index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> showBrowserHistorySheet(
  BuildContext context,
  WidgetRef ref, {
  required ValueChanged<String> onOpenUrl,
}) async {
  final store = ref.read(browserStoreProvider);
  final history = ref.read(browserHistoryProvider);

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: UdmSpacing.lg),
              child: Row(
                children: [
                  Text(
                    'History',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  if (history.isNotEmpty)
                    TextButton(
                      onPressed: () async {
                        await store.clearHistory();
                        refreshBrowserData(ref);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Clear all'),
                    ),
                ],
              ),
            ),
            if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.all(UdmSpacing.xl),
                child: Text('No history yet'),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final entry = history[index];
                    return ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(entry.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await store.deleteHistoryItem(entry.id);
                          refreshBrowserData(ref);
                        },
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        onOpenUrl(entry.url);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      );
    },
  );
}

Future<void> showBrowserBookmarksSheet(
  BuildContext context,
  WidgetRef ref, {
  required ValueChanged<String> onOpenUrl,
}) async {
  final store = ref.read(browserStoreProvider);
  final bookmarks = ref.read(browserBookmarksProvider);

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(UdmSpacing.lg),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Bookmarks',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            if (bookmarks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(UdmSpacing.xl),
                child: Text('No bookmarks yet'),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: bookmarks.length,
                  itemBuilder: (context, index) {
                    final bookmark = bookmarks[index];
                    return ListTile(
                      leading: const Icon(Icons.bookmark),
                      title: Text(bookmark.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(bookmark.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await store.removeBookmark(bookmark.id);
                          refreshBrowserData(ref);
                        },
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        onOpenUrl(bookmark.url);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      );
    },
  );
}

Future<DetectedDownload?> showDetectedDownloadsSheet(
  BuildContext context,
  List<DetectedDownload> downloads,
) {
  if (downloads.length == 1) {
    return Future.value(downloads.first);
  }

  return showModalBottomSheet<DetectedDownload>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(UdmSpacing.lg),
              child: Text(
                'Downloadable links (${downloads.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: downloads.length,
                itemBuilder: (context, index) {
                  final item = downloads[index];
                  return ListTile(
                    leading: const Icon(Icons.download),
                    title: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(item.url, maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () => Navigator.pop(context, item),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
