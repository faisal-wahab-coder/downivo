# Vimeo Resolver Tests

## Test File
`packages/download_engine/test/vimeo_resolver_test.dart`

## Coverage

| ID | Case |
|----|------|
| VM-RES-001 | Player config → progressive MP4 |
| VM-RES-002 | Home returns empty |
| VM-RES-003 | Profile returns empty |
| VM-RES-004 | INVALID returns empty |
| VM-RES-005 | Player URL resolves same video |
| VM-RES-006 | HTML `playerConfig` fallback |
| VM-RES-007 | Empty config returns null |
| VM-RES-008 | Registry discover |
| VM-RES-009 | Registry does not scrape home |
| VM-RES-010 | Download headers include Referer |
| VM-RES-011 | discoverAll is a single item |
| VM-RES-012 | Channel video URL |
| VM-RES-013 | Empty title falls back to video ID |

Uses `VimeoMockAdapter`. No live network.
