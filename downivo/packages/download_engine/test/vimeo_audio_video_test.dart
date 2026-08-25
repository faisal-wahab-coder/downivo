import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'vimeo_fixtures.dart';

void main() {
  group('Vimeo audio + video', () {
    test('VM-AV-001 progressive MP4 is treated as muxed audio+video', () {
      final config = vimeoPlayerConfig();
      final info = VimeoResolver.parseVideoInfo(config)!;
      expect(info.hasAudio, isTrue);
      expect(VimeoResolver.hasSeparateAudio(config), isFalse);
    });

    test('VM-AV-002 silent video is not claimed to have audio', () {
      final info = VimeoResolver.parseVideoInfo(
        vimeoPlayerConfig(hasAudio: false),
      )!;
      expect(info.hasAudio, isFalse);
    });

    test('VM-AV-003 HLS-only with separate_av is not downloaded', () {
      final config = vimeoHlsOnlyConfig();
      expect(VimeoResolver.parseVideoInfo(config), isNull);
      expect(VimeoResolver.hasSeparateAudio(config), isTrue);
      expect(
        VimeoResolver.restrictionFromConfig(config),
        VimeoRestriction.hlsOnly,
      );
    });

    test('VM-AV-004 selected file is MP4 not HLS playlist', () {
      final info = VimeoResolver.parseVideoInfo(vimeoPlayerConfig())!;
      expect(info.selectedQuality!.url, isNot(contains('.m3u8')));
      expect(info.mimeType, 'video/mp4');
    });

    test('VM-AV-005 duration is preserved from video metadata', () {
      final info = VimeoResolver.parseVideoInfo(
        vimeoPlayerConfig(duration: 184),
      )!;
      expect(info.durationSeconds, 184);
    });
  });
}
