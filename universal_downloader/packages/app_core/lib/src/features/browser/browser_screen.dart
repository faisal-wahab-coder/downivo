import 'dart:convert';

import 'package:browser/browser.dart';
import 'package:design_system/design_system.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../providers/browser_providers.dart';
import '../../providers/download_providers.dart';
import '../downloads/download_wizard_dialog.dart';
import '../downloads/media_selection_sheet.dart';
import 'browser_home.dart';
import 'browser_sheets.dart';

class BrowserScreen extends ConsumerStatefulWidget {
  const BrowserScreen({super.key});

  @override
  ConsumerState<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends ConsumerState<BrowserScreen> {
  final _addressController = TextEditingController();
  final _controllers = <String, WebViewController>{};
  List<DetectedDownload> _pageDownloads = const [];

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(browserSessionProvider);
    final tab = session.activeTab;
    final store = ref.watch(browserStoreProvider);
    final bookmarked = !tab.isHome && store.isBookmarked(tab.url);

    if (_addressController.text != BrowserUrlUtils.displayUrl(tab.url)) {
      _addressController.text = BrowserUrlUtils.displayUrl(tab.url);
    }

    return UdmScaffold(
      title: tab.isHome ? 'Browser' : tab.title,
      actions: [
        if (_pageDownloads.isNotEmpty)
          IconButton(
            icon: Badge(
              label: Text('${_pageDownloads.length}'),
              child: const Icon(Icons.download_outlined),
            ),
            tooltip: 'Downloads on page',
            onPressed: () => _pickPageDownload(context),
          ),
        if (!tab.isHome)
          IconButton(
            icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_border),
            tooltip: bookmarked ? 'Remove bookmark' : 'Add bookmark',
            onPressed: () async {
              await store.toggleBookmark(url: tab.url, title: tab.title);
              refreshBrowserData(ref);
            },
          ),
        IconButton(
          icon: const Icon(Icons.history),
          tooltip: 'History',
          onPressed: () => showBrowserHistorySheet(
            context,
            ref,
            onOpenUrl: (url) => _navigateTo(url, fromUser: true),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.bookmarks_outlined),
          tooltip: 'Bookmarks',
          onPressed: () => showBrowserBookmarksSheet(
            context,
            ref,
            onOpenUrl: (url) => _navigateTo(url, fromUser: true),
          ),
        ),
        IconButton(
          icon: Badge(
            label: Text('${session.tabs.length}'),
            isLabelVisible: session.tabs.length > 1,
            child: const Icon(Icons.tab),
          ),
          tooltip: 'Tabs',
          onPressed: () => showBrowserTabsSheet(
            context,
            ref,
            onSelect: _selectTab,
            onClose: _closeTab,
            onNewTab: () => ref.read(browserSessionProvider.notifier).newTab(),
          ),
        ),
      ],
      body: Column(
        children: [
          _BrowserToolbar(
            addressController: _addressController,
            canGoBack: tab.canGoBack,
            canGoForward: tab.canGoForward,
            isLoading: tab.isLoading,
            onSubmit: (value) => _navigateTo(
              BrowserUrlUtils.normalizeInput(value),
              fromUser: true,
            ),
            onBack: () => _controllerFor(tab)?.goBack(),
            onForward: () => _controllerFor(tab)?.goForward(),
            onRefresh: () => tab.isHome
                ? setState(() => _pageDownloads = const [])
                : _controllerFor(tab)?.reload(),
            onHome: () => _navigateTo(BrowserTab.homeUrl, fromUser: true),
          ),
          Expanded(
            child: tab.isHome
                ? BrowserHome(
                    onQuickLink: (url) => _navigateTo(url, fromUser: true),
                    onSearch: (query) => _navigateTo(
                      BrowserUrlUtils.normalizeInput(query),
                      fromUser: true,
                    ),
                  )
                : _buildWebView(tab),
          ),
        ],
      ),
    );
  }

  WebViewController? _controllerFor(BrowserTab tab) => _controllers[tab.id];

  Widget _buildWebView(BrowserTab tab) {
    final controller = _controllers[tab.id];
    if (controller == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_controllers.containsKey(tab.id)) return;
        _ensureController(tab);
        setState(() {});
      });
      return const Center(child: CircularProgressIndicator());
    }

    return _BrowserWebView(
      key: ValueKey(tab.id),
      tab: tab,
      controller: controller,
    );
  }

  WebViewController _ensureController(BrowserTab tab) {
    final existing = _controllers[tab.id];
    if (existing != null) return existing;

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);

    controller
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final detected = DownloadDetector.fromNavigationUrl(request.url);
            if (detected != null) {
              _offerDownload(detected);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (url) {
            ref.read(browserSessionProvider.notifier).updateActiveTab(
                  tab.copyWith(isLoading: true, url: url),
                );
          },
          onPageFinished: (url) async {
            final title = await controller.getTitle() ?? url;
            ref.read(browserSessionProvider.notifier).updateActiveTab(
                  tab.copyWith(
                    url: url,
                    title: title,
                    isLoading: false,
                  ),
                );
            await ref.read(browserStoreProvider).addHistory(
                  url: url,
                  title: title,
                );
            refreshBrowserData(ref);
            if (!kIsWeb) {
              await _scanPageLinks(controller, tab);
            }
          },
          onUrlChange: (change) async {
            if (change.url == null) return;
            final canBack = await controller.canGoBack();
            final canForward = await controller.canGoForward();
            ref.read(browserSessionProvider.notifier).updateActiveTab(
                  ref.read(browserSessionProvider).activeTab.copyWith(
                        url: change.url!,
                        canGoBack: canBack,
                        canGoForward: canForward,
                      ),
                );
          },
        ),
      );

    if (!kIsWeb) {
      controller.addJavaScriptChannel(
        'UdmDownloadLinks',
        onMessageReceived: (message) {
          try {
            final urls = (jsonDecode(message.message) as List<dynamic>)
                .map((e) => e.toString())
                .toList();
            final detected = DownloadDetector.fromLinkUrls(urls);
            if (mounted) {
              setState(() => _pageDownloads = detected);
            }
          } on Object {
            // Ignore malformed JS payloads.
          }
        },
      );
    }

    if (!tab.isHome) {
      controller.loadRequest(Uri.parse(tab.url));
    }

    _controllers[tab.id] = controller;
    return controller;
  }

  Future<void> _scanPageLinks(WebViewController controller, BrowserTab tab) async {
    if (tab.id != ref.read(browserSessionProvider).activeTab.id) return;

    await controller.runJavaScript('''
      (function() {
        var links = [];
        document.querySelectorAll('a[href]').forEach(function(a) {
          if (a.href) links.push(a.href);
        });
        document.querySelectorAll('video[src], video source[src]').forEach(function(node) {
          var src = node.src || node.getAttribute('src');
          if (src) links.push(src);
        });
        document.querySelectorAll('meta[property="og:video"], meta[property="og:video:url"]').forEach(function(node) {
          var content = node.getAttribute('content');
          if (content) links.push(content);
        });
        UdmDownloadLinks.postMessage(JSON.stringify(links));
      })();
    ''');
  }

  Future<void> _navigateTo(String url, {required bool fromUser}) async {
    final detected = DownloadDetector.fromNavigationUrl(url);
    if (detected != null) {
      await _offerDownload(detected);
      return;
    }

    setState(() => _pageDownloads = const []);
    ref.read(browserSessionProvider.notifier).navigateActiveTab(url);

    if (url.startsWith('udm://')) return;

    final tab = ref.read(browserSessionProvider).activeTab;
    final controller = _ensureController(tab);
    await controller.loadRequest(Uri.parse(url));
  }

  Future<void> _offerDownload(DetectedDownload detected) async {
    final result = await DownloadWizardDialog.show(
      context,
      initialUrl: detected.url,
    );
    if (result == null || !mounted) return;

    try {
      // Check for multi-item content (carousel).
      final uri = Uri.tryParse(result.url);
      if (uri != null && ContentProviderRegistry.canHandle(uri)) {
        final resources = await discoverAllResources(ref, result.url);
        if (resources.length > 1 && mounted) {
          final selected = await MediaSelectionSheet.show(
            context,
            resources: resources,
            url: result.url,
          );
          if (selected == null || selected.isEmpty || !mounted) return;
          await enqueueMultipleDownloads(
            ref,
            selected,
            priority: result.priority,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${selected.length} downloads queued'),
              ),
            );
          }
          return;
        }
      }

      await enqueueDownload(
        ref,
        result.url,
        fileName: result.fileName,
        priority: result.priority,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Queued ${detected.label}')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      final message = error is ArgumentError
          ? (error.message?.toString() ?? 'Invalid URL')
          : error.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _pickPageDownload(BuildContext context) async {
    final picked = await showDetectedDownloadsSheet(context, _pageDownloads);
    if (picked != null) await _offerDownload(picked);
  }

  void _selectTab(int index) {
    setState(() => _pageDownloads = const []);
    ref.read(browserSessionProvider.notifier).selectTab(index);
  }

  void _closeTab(int index) {
    final session = ref.read(browserSessionProvider);
    final tabId = session.tabs[index].id;
    _controllers.remove(tabId);
    setState(() => _pageDownloads = const []);
    ref.read(browserSessionProvider.notifier).closeTab(index);
  }
}

class _BrowserToolbar extends StatelessWidget {
  const _BrowserToolbar({
    required this.addressController,
    required this.canGoBack,
    required this.canGoForward,
    required this.isLoading,
    required this.onSubmit,
    required this.onBack,
    required this.onForward,
    required this.onRefresh,
    required this.onHome,
  });

  final TextEditingController addressController;
  final bool canGoBack;
  final bool canGoForward;
  final bool isLoading;
  final ValueChanged<String> onSubmit;
  final VoidCallback? onBack;
  final VoidCallback? onForward;
  final VoidCallback? onRefresh;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(UdmSpacing.sm),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: canGoBack ? onBack : null,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: canGoForward ? onForward : null,
                ),
                IconButton(
                  icon: Icon(isLoading ? Icons.close : Icons.refresh),
                  onPressed: onRefresh,
                ),
                IconButton(
                  icon: const Icon(Icons.home_outlined),
                  onPressed: onHome,
                ),
              ],
            ),
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                hintText: 'Search or enter URL',
                isDense: true,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => onSubmit(addressController.text),
                ),
              ),
              textInputAction: TextInputAction.go,
              onSubmitted: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class _BrowserWebView extends StatelessWidget {
  const _BrowserWebView({
    super.key,
    required this.tab,
    required this.controller,
  });

  final BrowserTab tab;
  final WebViewController controller;

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: controller);
  }
}
