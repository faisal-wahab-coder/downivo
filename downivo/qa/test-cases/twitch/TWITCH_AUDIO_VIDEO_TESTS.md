# Twitch Audio / Video Tests

Automated file: `packages/download_engine/test/twitch_audio_video_test.dart` (5 tests)

| ID | Case |
|----|------|
| TW-AV-001 | Clip MP4 is muxed with audio |
| TW-AV-002 | HLS-only clip is not a silent MP4 download |
| TW-AV-003 | VOD audio_only HLS is not a downloadable quality |
| TW-AV-004 | Resource MIME is video/mp4 |
| TW-AV-005 | HLS URL is never used as a clip resource |

There is no muxer in this engine. Separate HLS audio+video is a platform limitation, not silently dropped audio on an MP4.
