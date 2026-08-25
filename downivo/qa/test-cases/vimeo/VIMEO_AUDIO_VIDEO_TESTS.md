# Vimeo Audio / Video Tests

## Test File
`packages/download_engine/test/vimeo_audio_video_test.dart`

## Coverage

| ID | Case |
|----|------|
| VM-AV-001 | Progressive MP4 is muxed |
| VM-AV-002 | Silent (`has_audio=false`) is not claimed to have audio |
| VM-AV-003 | HLS `separate_av` is not downloaded |
| VM-AV-004 | Selected file is MP4 |
| VM-AV-005 | Duration preserved |

There is no muxer in this engine. Separate HLS audio+video is a platform limitation, not silently dropped audio on an MP4.
