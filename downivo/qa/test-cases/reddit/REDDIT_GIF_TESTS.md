# Reddit GIF Tests

## Test File
`packages/download_engine/test/reddit_gif_test.dart`

## Coverage

Actual media type is inspected:

- GIF source → `image/gif` + `.gif` (not renamed to MP4)
- MP4-only animated media → `video/mp4` + `.mp4`
- `reddit_video.is_gif` → `video/mp4`
- Gallery `AnimatedImage` with `image/gif` stays GIF
