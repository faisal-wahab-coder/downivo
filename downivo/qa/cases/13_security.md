# Security Test Cases

Maps to `docs/23_Security.md` and `docs/24_Testing.md` §19.

| ID | Case | Expected | Automation |
|----|------|----------|------------|
| SEC-001 | Reject `file://` | Invalid URL | `security_test.dart` |
| SEC-002 | Reject `javascript:` | Invalid URL | `security_test.dart` |
| SEC-003 | Reject `ftp://` | Invalid URL | `security_test.dart` |
| SEC-004 | Reject empty / whitespace | Invalid URL | `security_test.dart` |
| SEC-005 | Sanitize `../` filename | Basename only, no separators | `security_test.dart` |
| SEC-006 | Disposition path traversal | Sanitized download name | `security_test.dart` |
| SEC-007 | HTML response rejected | ArgumentError / failed download | `security_test.dart` + DL-009 |
| SEC-008 | `udm://` not stored in history | Privacy for internal pages | BR-007 |

Open gap (not changed in this pass): `UrlValidator` does not block private/link-local IPs. Localhost is required by the QA server.
