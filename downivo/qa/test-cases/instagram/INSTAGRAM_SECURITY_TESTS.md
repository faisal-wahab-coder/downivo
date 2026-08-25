# Instagram Security Tests

## Test File
`packages/download_engine/test/instagram_error_test.dart` (Phase 18 section)
`packages/download_engine/test/instagram_url_test.dart` (Phase 18 section)

## Coverage

| Phase | Description | Tests |
|-------|-------------|-------|
| 18 | Unsafe protocol rejection (javascript:, file:, data:) | IG-SEC-001 to IG-SEC-005 |
| 18 | Localhost/private IP rejection | IG-SEC-004, IG-SEC-005 |
| 18 | Long URL handling | IG-SEC-006 |
| 18 | video_url protocol validation | IG-SEC-006 to IG-SEC-008 |

## Security Model

1. **Platform detection** (`SocialPlatform.fromUri`) — rejects non-Instagram hosts
2. **URL validation** (`UrlValidator.validate`) — rejects non-HTTP schemes
3. **Video URL validation** (`_bestVideoUrl`) — requires `startsWith('http')`
4. **Image URL validation** (`_bestImageUrl`) — requires `startsWith('http')`
5. **Filename sanitization** (`FileNameResolver.sanitize`) — prevents path traversal
6. **Redirect following** — controlled by Dio with validateStatus bounds

## Verified Rejections

- `javascript:` URLs → not recognized as any platform
- `file:` URLs → not recognized, not used as media source
- `data:` URLs → not recognized
- `localhost` → not recognized
- `192.168.x.x` → not recognized
- Non-HTTP video_url in payloads → resolver returns null
- Non-HTTP image_url in payloads → resolver returns null
