import 'package:app_core/src/features/downloads/download_history_screen.dart';
import 'package:app_core/src/providers/download_providers.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_types/shared_types.dart';

DownloadTask _completedTask() {
  return DownloadTask(
    id: '1',
    url: 'https://example.com/a.zip',
    fileName: 'a.zip',
    status: DownloadStatus.completed,
    progress: 1,
    fileSize: 4096,
    createdAt: DateTime(2026, 8, 15),
    updatedAt: DateTime(2026, 8, 15),
  );
}

void main() {
  testWidgets('lists finished downloads with accessibility labels', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadHistoryProvider.overrideWith((ref) => [_completedTask()]),
        ],
        child: const MaterialApp(home: DownloadHistoryScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('a.zip'), findsOneWidget);
    expect(find.textContaining('Completed'), findsWidgets);
    expect(find.bySemanticsLabel('a.zip, Completed'), findsOneWidget);
    expect(find.text('Download history'), findsOneWidget);
  });

  testWidgets('shows empty state when history is empty', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadHistoryProvider.overrideWith((ref) => []),
        ],
        child: const MaterialApp(home: DownloadHistoryScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('No download history'), findsOneWidget);
    expect(find.byTooltip('Clear history'), findsNothing);
  });
}
