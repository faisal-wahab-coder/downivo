import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('kind is inferred from mime when not set', () {
    const video = DiscoveredResource(
      directUrl: 'https://cdn.example/v.mp4',
      fileName: 'v.mp4',
      platform: 'YouTube',
      mimeType: 'video/mp4',
    );
    expect(video.resolvedKind, DiscoveredResourceKind.video);
    expect(DiscoveredResourceKind.fromMime('audio/mpeg'), DiscoveredResourceKind.audio);
    expect(DiscoveredResourceKind.fromMime('image/jpeg'), DiscoveredResourceKind.image);
    expect(
      DiscoveredResourceKind.fromMime('application/pdf'),
      DiscoveredResourceKind.document,
    );
    expect(
      DiscoveredResourceKind.fromMime('image/jpeg', carousel: true),
      DiscoveredResourceKind.carousel,
    );
  });

  test('copyWith preserves optional metadata', () {
    const original = DiscoveredResource(
      directUrl: 'https://cdn.example/v.mp4',
      fileName: 'v.mp4',
      platform: 'YouTube',
      author: 'Ada',
      durationSeconds: 12.5,
      width: 1920,
      height: 1080,
    );
    final updated = original.copyWith(pageUrl: 'https://youtube.com/watch?v=1');
    expect(updated.author, 'Ada');
    expect(updated.durationSeconds, 12.5);
    expect(updated.resolutionLabel, '1920x1080');
    expect(updated.pageUrl, 'https://youtube.com/watch?v=1');
  });
}
