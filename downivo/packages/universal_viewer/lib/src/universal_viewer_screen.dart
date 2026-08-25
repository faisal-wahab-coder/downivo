import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'player_factory_stub.dart'
    if (dart.library.io) 'player_factory_io.dart';
import 'viewer_media_kind.dart';

class UniversalViewerScreen extends StatefulWidget {
  const UniversalViewerScreen({
    super.key,
    required this.path,
    required this.title,
    this.mimeType,
  });

  final String path;
  final String title;
  final String? mimeType;

  static bool canPlay(String path, String? mimeType) =>
      viewerKindForMime(mimeType, path) != ViewerMediaKind.unsupported;

  @override
  State<UniversalViewerScreen> createState() => _UniversalViewerScreenState();
}

class _UniversalViewerScreenState extends State<UniversalViewerScreen> {
  VideoPlayerController? _controller;
  var _speed = 1.0;

  @override
  void initState() {
    super.initState();
    final controller = createLocalVideoController(widget.path);
    _controller = controller;
    if (controller == null) return;
    controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      controller.play();
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final kind = viewerKindForMime(widget.mimeType, widget.path);
    return UdmScaffold(
      title: widget.title,
      actions: [
        PopupMenuButton<double>(
          tooltip: 'Playback speed',
          onSelected: (value) {
            setState(() => _speed = value);
            controller?.setPlaybackSpeed(value);
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 0.5, child: Text('0.5x')),
            PopupMenuItem(value: 1, child: Text('1x')),
            PopupMenuItem(value: 1.5, child: Text('1.5x')),
            PopupMenuItem(value: 2, child: Text('2x')),
          ],
        ),
      ],
      body: controller == null
          ? const Center(
              child: Text('In-app playback is not available on this platform.'),
            )
          : !controller.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: kind == ViewerMediaKind.audio
                        ? Icon(
                            Icons.audiotrack,
                            size: 96,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : AspectRatio(
                            aspectRatio: controller.value.aspectRatio == 0
                                ? 16 / 9
                                : controller.value.aspectRatio,
                            child: VideoPlayer(controller),
                          ),
                  ),
                ),
                VideoProgressIndicator(controller, allowScrubbing: true),
                Row(
                  children: [
                    IconButton(
                      tooltip: controller.value.isPlaying ? 'Pause' : 'Play',
                      onPressed: () {
                        setState(() {
                          controller.value.isPlaying
                              ? controller.pause()
                              : controller.play();
                        });
                      },
                      icon: Icon(
                        controller.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Mute',
                      onPressed: () {
                        final muted = controller.value.volume == 0;
                        controller.setVolume(muted ? 1 : 0);
                        setState(() {});
                      },
                      icon: Icon(
                        controller.value.volume == 0
                            ? Icons.volume_off
                            : Icons.volume_up,
                      ),
                    ),
                    Text('${_speed}x'),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Fullscreen',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => Scaffold(
                              backgroundColor: Colors.black,
                              body: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Center(
                                  child: AspectRatio(
                                    aspectRatio:
                                        controller.value.aspectRatio == 0
                                            ? 16 / 9
                                            : controller.value.aspectRatio,
                                    child: VideoPlayer(controller),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.fullscreen),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
