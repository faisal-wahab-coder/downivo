import 'dart:async';

import 'package:content_intake/content_intake.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'share_intake.dart';

class IoShareIntake implements ShareIntake {
  StreamSubscription<List<SharedMediaFile>>? _subscription;

  @override
  Future<void> start(ShareMediaHandler onMedia) async {
    final sharing = ReceiveSharingIntent.instance;
    final initialMedia = await sharing.getInitialMedia();
    if (initialMedia.isNotEmpty) {
      await onMedia(_payloadFromSharedMedia(initialMedia));
    }
    _subscription = sharing.getMediaStream().listen((media) {
      unawaited(onMedia(_payloadFromSharedMedia(media)));
    });
  }

  @override
  Future<void> reset() => ReceiveSharingIntent.instance.reset();

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
  }

  SharePayload _payloadFromSharedMedia(List<SharedMediaFile> media) {
    final texts = <String>[];
    final paths = <String>[];
    final mimeTypes = <String>[];

    for (final item in media) {
      switch (item.type) {
        case SharedMediaType.text:
        case SharedMediaType.url:
          if (item.path.trim().isNotEmpty) texts.add(item.path.trim());
          if (item.message != null && item.message!.trim().isNotEmpty) {
            texts.add(item.message!.trim());
          }
        case SharedMediaType.image:
        case SharedMediaType.video:
        case SharedMediaType.file:
          if (item.path.isNotEmpty) paths.add(item.path);
          if (item.mimeType != null) mimeTypes.add(item.mimeType!);
      }
    }

    return SharePayload(
      text: texts.isEmpty ? null : texts.join('\n'),
      filePaths: paths,
      mimeTypes: mimeTypes,
    );
  }
}

ShareIntake createPlatformShareIntake() => IoShareIntake();
