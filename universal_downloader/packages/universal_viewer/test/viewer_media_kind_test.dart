import 'package:flutter_test/flutter_test.dart';
import 'package:universal_viewer/universal_viewer.dart';

void main() {
  test('classifies video and audio paths', () {
    expect(viewerKindForMime('video/mp4', 'a.mp4'), ViewerMediaKind.video);
    expect(viewerKindForMime('audio/mpeg', 'a.mp3'), ViewerMediaKind.audio);
    expect(viewerKindForMime(null, 'notes.pdf'), ViewerMediaKind.unsupported);
  });
}
