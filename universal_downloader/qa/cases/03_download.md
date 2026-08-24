# Download Test Cases

Maps to `docs/15_Download_Engine.md` and `docs/24_Testing.md` §12.

| ID | Case | Expected | Automation |
|----|------|----------|------------|
| DL-001 | Enqueue valid HTTP URL | Task persisted as queued | `download_lifecycle_test.dart` |
| DL-002 | Enqueue invalid URL | `ArgumentError` | `download_lifecycle_test.dart` |
| DL-003 | Complete small file | Status completed, bytes match | `download_lifecycle_test.dart` |
| DL-004 | Honor Content-Disposition | Saved name from header | `download_lifecycle_test.dart` |
| DL-005 | Follow 302 redirect | File downloaded from target | `download_lifecycle_test.dart` |
| DL-006 | Pause then resume with Range | File complete and identical | `download_lifecycle_test.dart` |
| DL-007 | Cancel in-flight download | Task removed, partial file deleted | `download_lifecycle_test.dart` |
| DL-008 | HTTP 404 with no retries | Status failed, 404 message | `download_lifecycle_test.dart` |
| DL-009 | HTML Content-Type | Status failed, page-not-file message | `download_lifecycle_test.dart` |
| DL-010 | Size mismatch vs Content-Length | Failed (client abort or integrity) | `download_lifecycle_test.dart` |
| DL-011 | maxConcurrent = 1 | Second task stays queued | `download_lifecycle_test.dart` |
| DL-012 | Reorder queued tasks | Queue order persisted | `download_lifecycle_test.dart` |
| DL-013 | MIME routes to category folder | `.mp4` under Videos | `download_lifecycle_test.dart` |
| DL-014 | clearHistory | Finished rows gone, files kept | existing integration test |
