# Vimeo Video Tests

## Test File
`packages/download_engine/test/vimeo_video_test.dart`

## Coverage

| ID | Case |
|----|------|
| VM-VID-001 | Highest progressive MP4 over HLS |
| VM-VID-002 | HLS-only is not downloadable |
| VM-VID-003 | Player URL same media URL |
| VM-VID-004 | Dimensions match selected file |
| VM-VID-005 | og:video player URL is not media |
| VM-VID-006 | og:video direct MP4 fallback |

Do not treat `player.vimeo.com/video/{id}` as a file URL.
