import 'package:app_core/src/features/intake/intake_prompt_sheet.dart';
import 'package:content_intake/content_intake.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Download detected sheet opens the wizard after confirm', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: _IntakeHost()),
      ),
    );

    await tester.tap(find.text('Show sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Download detected'), findsOneWidget);
    expect(find.text('YouTube'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Download'));
    await tester.pumpAndSettle();

    expect(find.text('Download detected'), findsNothing);
    expect(find.text('New download'), findsOneWidget);
    expect(find.text('https://youtu.be/kfKP4o-bXzM'), findsOneWidget);
  });
}

class _IntakeHost extends ConsumerWidget {
  const _IntakeHost();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: TextButton(
        onPressed: () => showIntakeActionSheet(
          context,
          ref,
          IntakeAction(
            type: IntakeActionType.download,
            url: 'https://youtu.be/kfKP4o-bXzM',
            label: 'YouTube',
          ),
        ),
        child: const Text('Show sheet'),
      ),
    );
  }
}
