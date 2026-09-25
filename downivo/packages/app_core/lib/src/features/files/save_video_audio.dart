import 'package:download_engine/download_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_library/media_library.dart';
import 'package:storage/storage.dart';

import '../../providers/library_providers.dart';

/// Copies a video's soundtrack into Audio and leaves the video in place.
Future<void> saveVideoAsAudio({
  required BuildContext context,
  required WidgetRef ref,
  required LibraryFile file,
  required Future<void> Function() onChanged,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(const SnackBar(content: Text('Saving audio…')));
  final service = ref.read(mediaLibraryServiceProvider);

  try {
    final length = await service.fileLength(file.path);
    final result = await Mp4AudioExtractor.extractRead(
      length: length,
      read: (offset, count) => service.readFileAt(file.path, offset, count),
    );
    switch (result) {
      case Mp4AudioUnchanged():
        _show(
          messenger,
          'This video format can\'t be saved as audio yet.',
        );
      case Mp4AudioFailed(:final message):
        _show(messenger, message);
      case Mp4AudioReady(:final bytes):
        final saved = await service.addGeneratedFile(
          fileName: FileNameResolver.replaceExtension(file.name, 'audio/mp4'),
          bytes: bytes,
          category: StorageCategory.audio,
          mimeType: 'audio/mp4',
        );
        await onChanged();
        _show(messenger, 'Saved audio as ${saved.name}');
    }
  } on OutOfMemoryError {
    _show(messenger, 'This video is too large to save as audio.');
  } on Object {
    _show(messenger, 'Could not save audio from this video.');
  }
}

void _show(ScaffoldMessengerState messenger, String message) {
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(content: Text(message)));
}
