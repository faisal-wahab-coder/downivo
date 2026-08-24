import 'package:content_intake/content_intake.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('IN-004 empty QR shows text', () {
    final action = QrContentResolver().resolveQr('   ');
    expect(action.type, IntakeActionType.showText);
  });

  test('IN-004 invalid QR shows text', () {
    final action = QrContentResolver().resolveQr('not a url at all');
    expect(action.type, IntakeActionType.showText);
    expect(action.text, 'not a url at all');
  });

  test('IN-006 share text with URL prefers download when direct', () {
    final action = QrContentResolver().resolveShare(
      const ShareContentParser().fromText('https://cdn.test/setup.apk'),
    );
    expect(action.type, IntakeActionType.download);
  });

  test('IN-006 share text plus files still resolves URL', () {
    final action = QrContentResolver().resolveShare(
      const ShareContentParser().fromFiles(
        paths: ['/tmp/note.txt'],
        text: 'https://example.com/page',
      ),
    );
    expect(action.type, IntakeActionType.openInBrowser);
  });

  test('IN-007 clipboard poll deduplicates', () async {
    const url = 'https://cdn.test/file.mp4';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') {
        return <String, dynamic>{'text': url};
      }
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    final monitor = ClipboardMonitor();
    final first = await monitor.poll();
    expect(first?.urls, contains(url));
    expect(await monitor.poll(), isNull);
    monitor.reset();
    expect(await monitor.poll(), isNotNull);
  });

  test('clipboard poll swallows paste_fail', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') {
        throw PlatformException(code: 'paste_fail', message: 'Clipboard.getData failed.');
      }
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    expect(await ClipboardMonitor().poll(), isNull);
  });

  test('IN-008 clipboard history caps at 50', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ClipboardHistoryStore(await SharedPreferences.getInstance());
    for (var i = 0; i < 55; i++) {
      await store.add(text: 'item $i', detectedUrl: 'https://x.test/$i');
    }
    expect(store.entries, hasLength(50));
    await store.delete(store.entries.first.id);
    expect(store.entries, hasLength(49));
    await store.clear();
    expect(store.entries, isEmpty);
  });

  test('IN-009 QR history add and clear', () async {
    SharedPreferences.setMockInitialValues({});
    final store = QrHistoryStore(await SharedPreferences.getInstance());
    await store.add(rawValue: 'https://a.test', resolvedUrl: 'https://a.test');
    expect(store.entries, hasLength(1));
    await store.clear();
    expect(store.entries, isEmpty);
  });

  test('IN-010 share parser trims text', () {
    final payload = const ShareContentParser().fromText('  hello  ');
    expect(payload.text, 'hello');
  });

  test('resolveClipboard maps detected content', () {
    final analyzer = ContentAnalyzer();
    final detected = analyzer.analyzeText('https://files.test/app.apk');
    final action = QrContentResolver().resolveClipboard(detected);
    expect(action.type, IntakeActionType.download);
  });
}
