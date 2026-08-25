import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigation/navigation.dart';

void main() {
  testWidgets('wide viewport shows desktop rail', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(1280, 800)),
          child: MainShell(
            currentIndex: 0,
            onDestinationSelected: (_) {},
            child: const Text('content'),
          ),
        ),
      ),
    );

    expect(find.text('DV'), findsOneWidget);
    expect(find.text('HOME'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('narrow viewport shows bottom navigation', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: MainShell(
            currentIndex: 0,
            onDestinationSelected: (_) {},
            child: const Text('content'),
          ),
        ),
      ),
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('DV'), findsNothing);
  });

  testWidgets('back on a non-home tab returns to Home', (tester) async {
    var index = 2;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: StatefulBuilder(
            builder: (context, setState) {
              return MainShell(
                currentIndex: index,
                onDestinationSelected: (value) {
                  setState(() => index = value);
                },
                child: const Text('content'),
              );
            },
          ),
        ),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(index, 0);
    expect(find.text('Exit Downivo?'), findsNothing);
  });

  testWidgets('back on Home shows exit confirmation', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: MainShell(
            currentIndex: 0,
            onDestinationSelected: (_) {},
            child: const Text('content'),
          ),
        ),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Exit Downivo?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Exit Downivo?'), findsNothing);
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('back on Home shows exit even if the root navigator can pop', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MediaQuery(
                      data: const MediaQueryData(size: Size(390, 844)),
                      child: MainShell(
                        currentIndex: 0,
                        onDestinationSelected: (_) {},
                        child: const Text('content'),
                      ),
                    ),
                  ),
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Exit Downivo?'), findsOneWidget);
    expect(find.text('content'), findsOneWidget);
  });
}
