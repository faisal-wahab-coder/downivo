See: `qa/test-reports/PINTEREST_IMPLEMENTATION_AUDIT.md`

Pre-implementation gaps that were closed in this phase:

- Dedicated `PinterestResolver` (was host detection + generic OG only)
- `PinterestUri` classification / pin ID / normalize / `pin.it` / pinimg CDN
- Original-quality images (not 236x/736x thumbnails); correct MIME (PNG/WebP/JPEG)
- Progressive MP4 video; HLS skipped
- Idea Pins via `story_pin_data.pages` + `discoverAll`
- Home/board/profile not scraped as downloads
