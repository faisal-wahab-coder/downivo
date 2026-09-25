import 'package:app_core/src/features/files/file_detail_screen.dart';
import 'package:app_core/src/features/files/files_screen.dart';
import 'package:app_core/src/features/files/image_gallery_screen.dart';
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
  late String shotPath;
  late String otherPath;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    store = MemoryFileStore();
    final paths = StoragePaths(rootPath: '/udm');
    shotPath = '${paths.categoryPath(StorageCategory.images)}/shot.jpg';
    otherPath = '${paths.categoryPath(StorageCategory.images)}/other.jpg';
    await store.createDirectory(paths.categoryPath(StorageCategory.images));
    await store.writeBytes(shotPath, List<int>.filled(16, 1));
    await store.writeBytes(otherPath, List<int>.filled(16, 2));
    service = MediaLibraryService(
      paths: paths,
      favorites: FavoritesStore(prefs),
      fileStore: store,
    );
  });

  Future<void> _pumpFiles(WidgetTester tester) async {
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
  }

  testWidgets('tap image opens gallery and keeps tile more actions', (
    tester,
  ) async {
    await _pumpFiles(tester);

    expect(find.byTooltip('More actions'), findsWidgets);
    expect(find.byType(ImageGalleryScreen), findsNothing);

    await tester.tap(find.text('other.jpg'));
    await tester.pumpAndSettle();

    expect(find.byType(ImageGalleryScreen), findsOneWidget);
    expect(find.byTooltip('File details'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'More actions'), findsOneWidget);
    expect(find.text('File details'), findsNothing);
    expect(find.text('Open file'), findsNothing);
  });

  testWidgets('gallery swipes between folder images', (tester) async {
    await _pumpFiles(tester);

    await tester.tap(find.text('other.jpg'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 2'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('2 / 2'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('shot.jpg')),
      findsOneWidget,
    );
  });

  testWidgets('gallery 3-dot opens file details', (tester) async {
    await _pumpFiles(tester);

    await tester.tap(find.text('other.jpg'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('File details'));
    await tester.pumpAndSettle();

    expect(find.byType(FileDetailScreen), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Open file'), findsNothing);
    expect(find.text('Save to Gallery'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'More actions'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Delete'), findsNothing);
  });

  testWidgets('gallery more actions opens the sheet for the current image', (
    tester,
  ) async {
    await _pumpFiles(tester);

    await tester.tap(find.text('other.jpg'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'More actions'));
    await tester.pumpAndSettle();

    expect(find.text('Share'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Delete'),
      80,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Delete'), findsOneWidget);
  });
}
