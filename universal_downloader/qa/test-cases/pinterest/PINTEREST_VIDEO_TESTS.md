# Pinterest Video Tests

## Test File
`packages/download_engine/test/pinterest_video_test.dart`

| ID | Case |
|----|------|
| PT-VID-001 | 720p MP4 preferred over HLS and 480p |
| PT-VID-002 | HLS-only → no download (not thumbnail) |
| PT-VID-003 | Thumbnail from images.orig |
| PT-VID-004 | Duration / width / height on pin info |
| PT-VID-005 | Muxed MP4 has no separate audio stream |
| PT-VID-006 | HLS-only reports separate-audio limitation |
| PT-VID-007 | discoverAll single video |
| PT-VID-008 | OpenGraph video fallback |
