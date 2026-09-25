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
    expect(find.text('Open with'), findsOneWidget);
    expect(find.text('Show in Files'), findsOneWidget);
    expect(find.text('Save audio'), findsNothing);
    expect(find.text('shot.jpg'), findsWidgets);

    final scrollable = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(
      find.text('Move to folder'),
      80,
      scrollable: scrollable,
    );
    expect(find.text('Move to folder'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Delete'),
      80,
      scrollable: scrollable,
    );
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete file?'), findsOneWidget);
    expect(find.textContaining('shot.jpg'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(await store.exists(imagePath), isFalse);
    expect(find.text('File deleted'), findsOneWidget);
    expect(find.text('Delete file?'), findsNothing);
  });

  testWidgets('Save audio is offered for a video and keeps the video', (
    tester,
  ) async {
    final paths = StoragePaths(rootPath: '/udm');
    final videoPath = '${paths.categoryPath(StorageCategory.videos)}/clip.mp4';
    await store.createDirectory(paths.categoryPath(StorageCategory.videos));
    await store.createDirectory(paths.categoryPath(StorageCategory.audio));
    await store.writeBytes(videoPath, 'not an mp4'.codeUnits);
    final files = await service.listFiles(const LibraryQuery());
    final video = files.firstWhere((file) => file.name == 'clip.mp4');

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
                        file: video,
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
    expect(find.text('Save audio'), findsOneWidget);

    await tester.tap(find.text('Save audio'));
    await tester.pumpAndSettle();
    expect(
      find.text('This video format can\'t be saved as audio yet.'),
      findsOneWidget,
    );
    expect(await store.exists(videoPath), isTrue);
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

  testWidgets('New folder appears inside the current category', (tester) async {
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

    await tester.tap(find.text('New folder'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Trip');
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(find.text('Trip'), findsOneWidget);
    expect(await store.directoryExists('/udm/Images/Trip'), isTrue);
  });

  testWidgets('Long press selects a file for moving', (tester) async {
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

    await tester.longPress(find.text('shot.jpg'));
    await tester.pumpAndSettle();

    expect(find.text('1 selected'), findsOneWidget);
    expect(find.byTooltip('Move to folder'), findsOneWidget);
  });
}
