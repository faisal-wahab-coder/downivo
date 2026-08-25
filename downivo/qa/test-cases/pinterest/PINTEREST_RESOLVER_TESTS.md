# Pinterest Resolver Tests

## Test File
`packages/download_engine/test/pinterest_resolver_test.dart`

## Coverage

| ID | Case |
|----|------|
| PT-RES-001 | `__PWS_DATA__` image pin |
| PT-RES-002 | Home empty |
| PT-RES-003 | Board empty (no bulk) |
| PT-RES-004 | Profile empty |
| PT-RES-005 | `pin.it` redirect |
| PT-RES-006 | Pidgets fallback |
| PT-RES-007 | oEmbed fallback upgrades thumbnail |
| PT-RES-008 | Empty HTML |
| PT-RES-009 | parseHtmlResources |
| PT-RES-010 | Registry discover |
| PT-RES-011 | Registry does not scrape home |
| PT-RES-012 | Unicode title filename |
| PT-RES-013 | Download headers include Pinterest referer |

Fixtures: `test/pinterest_fixtures.dart`
