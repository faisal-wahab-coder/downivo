import 'package:app_core/app_core.dart';
import 'package:app_core/src/providers/library_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:storage/storage.dart';

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async => '/tmp/udm_test';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  PathProviderPlatform.instance = _FakePathProvider();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<ProviderContainer> testContainer() async {
    final root = await bootstrap();
    final container = ProviderContainer(
      parent: root,
      overrides: [
        volumeStatsProvider.overrideWith(
          (ref) async => StorageInfo(
            rootPath: '/tmp/udm_test',
            freeBytes: 0,
            totalBytes: 0,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  testWidgets('shows onboarding welcome step', (tester) async {
    final container = await testContainer();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const UniversalDownloaderApp(),
      ),
    );

    await tester.pump();

    expect(find.text('Welcome to Universal Downloader'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('opens home shell when onboarding already complete', (tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_complete': true,
      'storage_root_path': '/tmp/udm_test/Downloads/Universal Downloader',
    });

    final container = await testContainer();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const UniversalDownloaderApp(),
      ),
    );

    await tester.pump();

    expect(find.text('Get started'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
