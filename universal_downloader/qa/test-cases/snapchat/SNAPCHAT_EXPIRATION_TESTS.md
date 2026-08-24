# Snapchat Expiration Tests

Automated file: `packages/download_engine/test/snapchat_expiration_test.dart` (4 tests)

Expired or disappeared public content must fail closed. Do not recover it through unauthorized methods.

| ID | Case |
|----|------|
| SC-EXP-001 | Expired HTML → EXPIRED |
| SC-EXP-002 | User message contains “expired” |
| SC-EXP-003 | Expired HTML is not downloaded |
| SC-EXP-004 | Expired HTML yields no media items |
