# Notifications / Permissions Test Cases

Maps to `docs/12.21` and notification flows.

| ID | Case | Expected | Automation |
|----|------|----------|------------|
| NP-001 | Dispatch pause action | Handler receives `pause` + task id | `notification_actions_test.dart` |
| NP-002 | Dispatch cancel action | Handler receives `cancel` | `notification_actions_test.dart` |
| NP-003 | Missing action id | Handler not called | `notification_actions_test.dart` |
| NP-004 | Progress before init | No-op, no throw | `notification_actions_test.dart` |
| NP-005 | Clipboard always granted | `isGranted` / `request` true | `permission_service_test.dart` |
| NP-006 | Permission metadata | Titles and optional flags | `permission_service_test.dart` |
