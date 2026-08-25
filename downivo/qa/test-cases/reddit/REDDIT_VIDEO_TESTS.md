# Reddit Video Tests

## Test File
`packages/download_engine/test/reddit_video_test.dart`

## Coverage

- DASH `fallback_url` MP4 extraction
- HLS/DASH playlists are not used as download URLs
- Thumbnail, duration, width, height via `RedditPostInfo`
- Separate audio stream identification (`DASH_audio.mp4`)
- `is_gif` reddit_video keeps `video/mp4` (not renamed to `.gif`)

Muxing video+audio into one file is a documented platform limitation (no muxer in the engine).
