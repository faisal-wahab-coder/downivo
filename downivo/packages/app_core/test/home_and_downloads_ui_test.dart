import 'package:app_core/src/features/downloads/downloads_screen.dart';
import 'package:app_core/src/features/home/home_screen.dart';
import 'package:app_core/src/providers/download_providers.dart';
import 'package:app_core/src/providers/library_providers.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_types/shared_types.dart';
import 'package:storage/storage.dart';

DownloadTask _task({
  required String id,
  required DownloadStatus status,
  String fileName = 'clip.mp4',
  String? filePath,
}) {
  return DownloadTask(
    id: id,
    url: 'https://example.com/$fileName',
    fileName: fileName,
    filePath: filePath,
    status: status,
    progress: status == DownloadStatus.preparing ? 0 : 0.4,
    createdAt: DateTime(2026, 8, 15),
    updatedAt: DateTime(2026, 8, 15),
  );
}

Widget _app({required List<Override> overrides, required Widget home}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: home),
  );
}

void main() {
  testWidgets('Home puts paste URL first', (tester) async {
    await tester.pumpWidget(
      _app(
        home: const HomeScreen(),
        overrides: [
          downloadListProvider.overrideWith((ref) => []),
          managedStorageStatsProvider.overrideWith((ref) async => (0, 0)),
          categorySummariesProvider.overrideWith((ref) async => []),
          volumeStatsProvider.overrideWith(
            (ref) async =>
                StorageInfo(rootPath: '/', freeBytes: 0, totalBytes: 0),
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('Paste URL'), findsOneWidget);
    expect(find.text('Paste a link to download'), findsOneWidget);
    expect(find.text('Scan QR'), findsOneWidget);
    expect(find.text('Clipboard'), findsOneWidget);
    expect(find.text('Supported sources'), findsOneWidget);
  });

  testWidgets('Downloads lists preparing and verifying tasks', (tester) async {
    await tester.pumpWidget(
      _app(
        home: const DownloadsScreen(),
        overrides: [
          downloadListProvider.overrideWith(
            (ref) => [
              _task(
                id: 'p',
                status: DownloadStatus.preparing,
                fileName: 'prep.bin',
              ),
              _task(
                id: 'v',
                status: DownloadStatus.verifying,
                fileName: 'check.bin',
              ),
            ],
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('prep.bin'), findsOneWidget);
    expect(find.text('check.bin'), findsOneWidget);
    expect(find.textContaining('Finding video'), findsWidgets);
    expect(find.textContaining('Verifying'), findsWidgets);
    expect(find.text('Add URL'), findsOneWidget);
  });

  testWidgets('Queued download shows a Cancel button', (tester) async {
    await tester.pumpWidget(
      _app(
        home: const DownloadsScreen(),
        overrides: [
          downloadListProvider.overrideWith(
            (ref) => [
              _task(
                id: 'q',
                status: DownloadStatus.queued,
                fileName: 'wait.bin',
              ),
            ],
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('wait.bin'), findsOneWidget);
    expect(find.byTooltip('Cancel'), findsOneWidget);
  });

  testWidgets('Completed download opens from the row, not an Open icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        home: const DownloadsScreen(),
        overrides: [
          downloadListProvider.overrideWith(
            (ref) => [
              _task(
                id: 'c',
                status: DownloadStatus.completed,
                fileName: 'done.mp4',
                filePath: '/Videos/done.mp4',
              ),
            ],
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('done.mp4'), findsOneWidget);
    expect(find.byTooltip('Open'), findsNothing);
    expect(find.byTooltip('Share'), findsOneWidget);
  });

  testWidgets('Completed download without a file shows Removed from Files', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        home: const DownloadsScreen(),
        overrides: [
          downloadListProvider.overrideWith(
            (ref) => [
              _task(
                id: 'c',
                status: DownloadStatus.completed,
                fileName: 'gone.mp4',
              ),
            ],
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('gone.mp4'), findsOneWidget);
    expect(find.textContaining('Removed from Files'), findsOneWidget);
    expect(find.byTooltip('Share'), findsNothing);
    expect(find.byTooltip('Open'), findsNothing);
  });
}
