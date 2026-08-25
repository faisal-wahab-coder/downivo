import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_library/media_library.dart';

import '../../providers/library_providers.dart';
import 'file_actions_sheet.dart';
import 'file_detail_screen.dart';
import 'file_image_stub.dart' if (dart.library.io) 'file_image_io.dart';

Future<void> openImageGallery(
  BuildContext context, {
  required List<LibraryFile> images,
  required LibraryFile initial,
}) {
  final list = [
    for (final file in images)
      if (file.isGalleryImage) file,
  ];
  if (!list.any((file) => file.path == initial.path)) {
    list.insert(0, initial);
  }
  final index = list.indexWhere((file) => file.path == initial.path);
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) =>
          ImageGalleryScreen(images: list, initialIndex: index < 0 ? 0 : index),
    ),
  );
}

class ImageGalleryScreen extends ConsumerStatefulWidget {
  const ImageGalleryScreen({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  final List<LibraryFile> images;
  final int initialIndex;

  @override
  ConsumerState<ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends ConsumerState<ImageGalleryScreen> {
  late final PageController _pageController;
  late int _index;
  var _pagingLocked = false;
  final _transforms = <int, TransformationController>{};

  @override
  void initState() {
    super.initState();
    _index = widget.images.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, widget.images.length - 1);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _transforms.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TransformationController _controllerFor(int index) {
    return _transforms.putIfAbsent(index, () {
      final controller = TransformationController();
      controller.addListener(() => _onScaleChanged(index));
      return controller;
    });
  }

  void _onScaleChanged(int index) {
    if (!mounted || index != _index) return;
    final locked = _controllerFor(index).value.getMaxScaleOnAxis() > 1.05;
    if (locked != _pagingLocked) {
      setState(() => _pagingLocked = locked);
    }
  }

  void _openDetails() {
    if (widget.images.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            FileDetailScreen(filePath: widget.images[_index].path),
      ),
    );
  }

  Future<void> _openActions() async {
    if (widget.images.isEmpty) return;
    final file = widget.images[_index];
    await showFileActionsSheet(
      context: context,
      ref: ref,
      file: file,
      onChanged: () async => invalidateLibrary(ref),
      onDeleted: () {
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return const UdmScaffold(
        title: 'Image',
        body: EmptyState(
          icon: Icons.broken_image_outlined,
          title: 'No image to show',
        ),
      );
    }

    final file = widget.images[_index];
    return UdmScaffold(
      title: file.name,
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          tooltip: 'File details',
          onPressed: _openDetails,
        ),
      ],
      body: ColoredBox(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              physics: _pagingLocked
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              itemCount: widget.images.length,
              onPageChanged: (index) {
                _transforms[_index]?.value = Matrix4.identity();
                setState(() {
                  _index = index;
                  _pagingLocked = false;
                });
              },
              itemBuilder: (context, index) {
                return _ZoomableLibraryImage(
                  file: widget.images[index],
                  controller: _controllerFor(index),
                );
              },
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(UdmSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.images.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: UdmSpacing.md),
                          child: Text(
                            '${_index + 1} / ${widget.images.length}',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: Colors.white70),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _openActions,
                          icon: const Icon(Icons.tune),
                          label: const Text('More actions'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomableLibraryImage extends StatelessWidget {
  const _ZoomableLibraryImage({required this.file, required this.controller});

  final LibraryFile file;
  final TransformationController controller;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    const fallback = Icon(
      Icons.broken_image_outlined,
      size: 96,
      color: Colors.white54,
    );
    final image = libraryFileImage(
      file,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      cacheWidth: (size.width * dpr).round().clamp(256, 4096),
      errorFallback: fallback,
    );

    return InteractiveViewer(
      transformationController: controller,
      minScale: 1,
      maxScale: 5,
      child: SizedBox.expand(child: image ?? const Center(child: fallback)),
    );
  }
}
