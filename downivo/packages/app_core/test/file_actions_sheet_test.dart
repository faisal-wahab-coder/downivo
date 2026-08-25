import 'package:app_core/src/features/files/file_actions_sheet.dart';
import 'package:app_core/src/features/files/files_screen.dart';
import 'package:app_core/src/providers/library_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_library/media_library.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storage/storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MediaLibraryService service;
  late MemoryFileStore store;
  late String imagePath;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    store = MemoryFileStore();
    final paths = StoragePaths(rootPath: '/udm');
    imagePath = '${paths.categoryPath(StorageCategory.images)}/shot.jpg';
    await store.createDirectory(paths.categoryPath(StorageCategory.images));
    await store.writeBytes(imagePath, List<int>.filled(16, 1));
    service = MediaLibraryService(
      paths: paths,
      favorites: FavoritesStore(prefs),
      fileStore: store,
    );
  });

  testWidgets('Delete in the action sheet confirms then removes the file', (
    tester,
  ) async {
    final files = await service.listFiles(const LibraryQuery());
    expect(files, isNotEmpty);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [mediaLibraryServiceProvider.overrideWith((ref) => service)],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return TextButton(
                      onPressed: () => showFileActionsSheet(
                        context: context,
                        ref: ref,
                        file: files.first,
                        onChanged: () async {},
                      ),
                      child: const Text('Open sheet'),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('shot.jpg'), findsWidgets);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete file?'), findsOneWidget);
    expect(find.text('shot.jpg'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(await store.exists(imagePath), isFalse);
    expect(find.text('File deleted'), findsOneWidget);
    expect(find.text('Delete file?'), findsNothing);
  });

  testWidgets('Files list shows a delete button next to more actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mediaLibraryServiceProvider.overrideWith((ref) => service),
          libraryLocationProvider.overrideWith(
            (ref) =>
                const LibraryFolderLocation(category: StorageCategory.images),
          ),
          pendingImportsProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: FilesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('shot.jpg'), findsOneWidget);
    expect(find.byTooltip('Delete'), findsOneWidget);
    expect(find.byTooltip('More actions'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete file?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(await store.exists(imagePath), isFalse);
  });
}
