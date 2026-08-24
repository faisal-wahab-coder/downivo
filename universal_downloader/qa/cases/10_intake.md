# Clipboard / Share / QR Test Cases

Maps to `docs/19_Clipboard.md`, `docs/20_Share_Extension.md`, `docs/21_QR_Scanner.md`.

| ID | Case | Expected | Automation |
|----|------|----------|------------|
| IN-001 | Extract URL from text | Primary URL set | existing `content_intake_test.dart` |
| IN-002 | QR direct file → download | `IntakeActionType.download` | existing |
| IN-003 | QR page → browser | `openInBrowser` | existing |
| IN-004 | QR empty / invalid → text | `showText` | `intake_stores_test.dart` |
| IN-005 | Share files only → import | `importFiles` | existing |
| IN-006 | Share text + URL | Download or browser action | `intake_stores_test.dart` |
| IN-007 | Clipboard poll dedup | Second poll null | `intake_stores_test.dart` |
| IN-008 | Clipboard history cap | Max 50 | `intake_stores_test.dart` |
| IN-009 | QR history clear | Empty | `intake_stores_test.dart` |
| IN-010 | Share parser trims text | Trimmed payload | `intake_stores_test.dart` |
