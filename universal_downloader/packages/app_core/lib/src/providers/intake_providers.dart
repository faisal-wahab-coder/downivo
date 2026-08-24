import 'package:content_intake/content_intake.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';

final clipboardMonitorProvider = Provider<ClipboardMonitor>((ref) {
  return ClipboardMonitor();
});

final clipboardHistoryStoreProvider = Provider<ClipboardHistoryStore>((ref) {
  return ClipboardHistoryStore(ref.watch(sharedPreferencesProvider));
});

final qrHistoryStoreProvider = Provider<QrHistoryStore>((ref) {
  return QrHistoryStore(ref.watch(sharedPreferencesProvider));
});

final contentAnalyzerProvider = Provider<ContentAnalyzer>((ref) {
  return ContentAnalyzer();
});

final qrContentResolverProvider = Provider<QrContentResolver>((ref) {
  return QrContentResolver();
});

final shareContentParserProvider = Provider<ShareContentParser>((ref) {
  return const ShareContentParser();
});

final clipboardHistoryProvider = Provider<List<ClipboardEntry>>((ref) {
  ref.watch(intakeDataRevisionProvider);
  return ref.watch(clipboardHistoryStoreProvider).entries;
});

final qrHistoryProvider = Provider<List<QrScanEntry>>((ref) {
  ref.watch(intakeDataRevisionProvider);
  return ref.watch(qrHistoryStoreProvider).entries;
});

final intakeDataRevisionProvider = StateProvider<int>((ref) => 0);

final pendingBrowserUrlProvider = StateProvider<String?>((ref) => null);

void refreshIntakeData(WidgetRef ref) {
  ref.read(intakeDataRevisionProvider.notifier).state++;
}
