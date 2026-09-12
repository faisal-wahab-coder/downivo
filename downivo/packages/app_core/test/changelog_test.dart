import 'package:app_core/src/changelog/app_changelog.dart';
import 'package:app_core/src/changelog/changelog_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('unreadChangelogEntries', () {
    test('shows latest only when nothing has been seen yet', () {
      final unread = unreadChangelogEntries(null);
      expect(unread, hasLength(1));
      expect(unread.first.version, latestChangelogVersion);
    });

    test('is empty when the latest version was already seen', () {
      expect(unreadChangelogEntries(latestChangelogVersion), isEmpty);
    });

    test('returns every entry newer than the last seen version', () {
      final unread = unreadChangelogEntries('1.0.0');
      expect(unread.map((e) => e.version), ['1.3.0', '1.2.0', '1.1.0']);
    });

    test('shows latest only when the stored version is unknown', () {
      final unread = unreadChangelogEntries('0.9.0');
      expect(unread, hasLength(1));
      expect(unread.first.version, latestChangelogVersion);
    });
  });

  testWidgets('changelog dialog lists highlights and closes', (tester) async {
    const entry = ChangelogEntry(
      version: '9.9.9',
      highlights: ['New gallery save', 'Faster downloads'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => showChangelogDialog(
                context,
                entries: const [entry],
              ),
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text("What's new in 9.9.9"), findsOneWidget);
    expect(find.text('New gallery save'), findsOneWidget);
    expect(find.text('Faster downloads'), findsOneWidget);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text("What's new in 9.9.9"), findsNothing);
  });

  testWidgets('changelog dialog groups multiple versions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => showChangelogDialog(
                context,
                entries: const [
                  ChangelogEntry(
                    version: '1.2.0',
                    highlights: ['Feature A'],
                  ),
                  ChangelogEntry(
                    version: '1.1.0',
                    highlights: ['Feature B'],
                  ),
                ],
              ),
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text("What's new"), findsOneWidget);
    expect(find.text('Version 1.2.0'), findsOneWidget);
    expect(find.text('Version 1.1.0'), findsOneWidget);
    expect(find.text('Feature A'), findsOneWidget);
    expect(find.text('Feature B'), findsOneWidget);
  });
}
