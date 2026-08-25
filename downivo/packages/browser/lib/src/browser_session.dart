import 'package:uuid/uuid.dart';

import 'models/browser_tab.dart';

/// In-memory browser tab session — docs/18 §10
class BrowserSessionState {
  const BrowserSessionState({
    required this.tabs,
    required this.activeIndex,
  });

  final List<BrowserTab> tabs;
  final int activeIndex;

  BrowserTab get activeTab => tabs[activeIndex];

  BrowserSessionState copyWith({
    List<BrowserTab>? tabs,
    int? activeIndex,
  }) {
    return BrowserSessionState(
      tabs: tabs ?? this.tabs,
      activeIndex: activeIndex ?? this.activeIndex,
    );
  }

  factory BrowserSessionState.initial() {
    return BrowserSessionState(
      tabs: [BrowserTab(id: const Uuid().v4(), url: BrowserTab.homeUrl)],
      activeIndex: 0,
    );
  }
}

class BrowserSession {
  BrowserSession({BrowserSessionState? initial})
      : _state = initial ?? BrowserSessionState.initial();

  final _uuid = const Uuid();
  BrowserSessionState _state;

  BrowserSessionState get state => _state;

  void newTab({String url = BrowserTab.homeUrl}) {
    final tabs = [..._state.tabs, BrowserTab(id: _uuid.v4(), url: url)];
    _state = BrowserSessionState(tabs: tabs, activeIndex: tabs.length - 1);
  }

  void closeTab(int index) {
    if (_state.tabs.length <= 1) {
      _state = BrowserSessionState.initial().copyWith(
        tabs: [BrowserTab(id: _uuid.v4(), url: BrowserTab.homeUrl)],
      );
      return;
    }

    final tabs = [..._state.tabs]..removeAt(index);
    var active = _state.activeIndex;
    if (index < active) active -= 1;
    if (active >= tabs.length) active = tabs.length - 1;
    _state = BrowserSessionState(tabs: tabs, activeIndex: active);
  }

  void selectTab(int index) {
    if (index < 0 || index >= _state.tabs.length) return;
    _state = _state.copyWith(activeIndex: index);
  }

  void updateActiveTab(BrowserTab tab) {
    final tabs = [..._state.tabs];
    tabs[_state.activeIndex] = tab;
    _state = _state.copyWith(tabs: tabs);
  }

  void updateTabAt(int index, BrowserTab tab) {
    final tabs = [..._state.tabs];
    tabs[index] = tab;
    _state = _state.copyWith(tabs: tabs);
  }
}
