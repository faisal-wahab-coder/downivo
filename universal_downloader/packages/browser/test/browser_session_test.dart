import 'package:browser/browser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('BR-004 detects social CDN hosts', () {
    const hosts = [
      'https://r1---sn-abc.googlevideo.com/videoplayback',
      'https://v16.tiktokcdn.com/aweme.mp4',
      'https://scontent.xx.fbcdn.net/v.mp4',
      'https://scontent.cdninstagram.com/v.mp4',
      'https://video.twimg.com/ext_tw_video/1.mp4',
      'https://v.redd.it/abc',
      'https://i.pinimg.com/originals/a.jpg',
    ];
    for (final url in hosts) {
      expect(DownloadDetector.isSocialCdnUrl(Uri.parse(url)), isTrue, reason: url);
      expect(DownloadDetector.isDirectDownloadUrl(url), isTrue, reason: url);
    }
  });

  test('BR-005 new tab becomes active', () {
    final session = BrowserSession();
    session.newTab(url: 'https://example.com');
    expect(session.state.activeIndex, 1);
    expect(session.state.activeTab.url, 'https://example.com');
  });

  test('BR-006 closing the last tab replaces it with home', () {
    final session = BrowserSession();
    session.closeTab(0);
    expect(session.state.tabs, hasLength(1));
    expect(session.state.activeTab.isHome, isTrue);
  });

  test('selectTab and updateActiveTab', () {
    final session = BrowserSession();
    session.newTab(url: 'https://a.test');
    session.selectTab(0);
    session.updateActiveTab(session.state.activeTab.copyWith(title: 'Home'));
    expect(session.state.tabs.first.title, 'Home');
    expect(session.state.activeIndex, 0);
  });

  test('BR-007 history ignores udm:// pages', () async {
    SharedPreferences.setMockInitialValues({});
    final store = BrowserStore(await SharedPreferences.getInstance());
    await store.addHistory(url: BrowserTab.homeUrl, title: 'Home');
    expect(store.history, isEmpty);
  });

  test('BR-008 bookmark toggle add and remove', () async {
    SharedPreferences.setMockInitialValues({});
    final store = BrowserStore(await SharedPreferences.getInstance());
    await store.toggleBookmark(url: 'https://example.com', title: 'Example');
    expect(store.isBookmarked('https://example.com'), isTrue);
    await store.toggleBookmark(url: 'https://example.com', title: 'Example');
    expect(store.isBookmarked('https://example.com'), isFalse);
  });

  test('BR-009 history keeps the newest 200 entries', () async {
    SharedPreferences.setMockInitialValues({});
    final store = BrowserStore(await SharedPreferences.getInstance());
    for (var i = 0; i < 205; i++) {
      await store.addHistory(url: 'https://example.com/p$i', title: 'p$i');
    }
    expect(store.history, hasLength(200));
    expect(store.history.first.url, 'https://example.com/p204');
  });

  test('history delete and clear', () async {
    SharedPreferences.setMockInitialValues({});
    final store = BrowserStore(await SharedPreferences.getInstance());
    await store.addHistory(url: 'https://a.test', title: 'A');
    await store.deleteHistoryItem(store.history.single.id);
    expect(store.history, isEmpty);
    await store.addHistory(url: 'https://b.test', title: 'B');
    await store.clearHistory();
    expect(store.history, isEmpty);
  });
}
