# Crash & Recovery Test Cases

Maps to `docs/16_Background_Downloads.md` and download engine recovery.

| ID | Case | Expected | Automation |
|----|------|----------|------------|
| CR-001 | downloading → queued on load | Status reset, progress kept | `crash_recovery_test.dart` |
| CR-002 | preparing / verifying → queued | Same as CR-001 | `crash_recovery_test.dart` |
| CR-003 | paused stays paused | No auto-resume | `crash_recovery_test.dart` |
| CR-004 | Hydrate bytes from partial file | `bytesReceived` = disk size | `crash_recovery_test.dart` |
| CR-005 | Force-stop on device | Interrupted jobs recover queued | Manual — `QA_CHECKLIST.md` |
