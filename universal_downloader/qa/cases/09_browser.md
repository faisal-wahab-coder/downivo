# Browser Test Cases

Maps to `docs/18_Browser.md`.

| ID | Case | Expected | Automation |
|----|------|----------|------------|
| BR-001 | Bare domain → https | `https://example.com` | existing `browser_test.dart` |
| BR-002 | Spaced input → search | Google search URL | existing |
| BR-003 | Direct file URL detected | true | existing |
| BR-004 | Social CDN hosts detected | googlevideo, tiktokcdn, fbcdn, etc. | `browser_session_test.dart` |
| BR-005 | New tab becomes active | `activeIndex` last | `browser_session_test.dart` |
| BR-006 | Close last tab | Replaced with home tab | `browser_session_test.dart` |
| BR-007 | History ignores `udm://` | Not stored | `browser_session_test.dart` |
| BR-008 | Bookmark toggle | Add then remove | `browser_session_test.dart` |
| BR-009 | History cap | Newest 200 kept | `browser_session_test.dart` |
