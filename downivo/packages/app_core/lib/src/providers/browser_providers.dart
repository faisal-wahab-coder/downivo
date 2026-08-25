import 'package:browser/browser.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_provider.dart';

final browserStoreProvider = Provider<BrowserStore>((ref) {
  return BrowserStore(ref.watch(sharedPreferencesProvider));
});

final browserSessionProvider =
    NotifierProvider<BrowserSessionNotifier, BrowserSessionState>(
  BrowserSessionNotifier.new,
);

class BrowserSessionNotifier extends Notifier<BrowserSessionState> {
  late final BrowserSession _session;

  @override
  BrowserSessionState build() {
    _session = BrowserSession();
    return _session.state;
  }

  void newTab({String url = BrowserTab.homeUrl}) {
    _session.newTab(url: url);
    state = _session.state;
  }

  void closeTab(int index) {
    _session.closeTab(index);
    state = _session.state;
  }

  void selectTab(int index) {
    _session.selectTab(index);
    state = _session.state;
  }

  void updateActiveTab(BrowserTab tab) {
    _session.updateActiveTab(tab);
    state = _session.state;
  }

  void navigateActiveTab(String url) {
    final tab = state.activeTab.copyWith(
      url: url,
      isLoading: !url.startsWith('udm://'),
    );
    _session.updateActiveTab(tab);
    state = _session.state;
  }
}

final browserHistoryProvider = Provider<List<BrowserHistoryEntry>>((ref) {
  ref.watch(browserDataRevisionProvider);
  return ref.watch(browserStoreProvider).history;
});

final browserBookmarksProvider = Provider<List<BrowserBookmark>>((ref) {
  ref.watch(browserDataRevisionProvider);
  return ref.watch(browserStoreProvider).bookmarks;
});

final browserDataRevisionProvider = StateProvider<int>((ref) => 0);

void refreshBrowserData(WidgetRef ref) {
  ref.read(browserDataRevisionProvider.notifier).state++;
}
