# Snapchat Profile Tests

Automated file: `packages/download_engine/test/snapchat_profile_test.dart` (5 tests)

A public profile is a container. Do **not** download the profile itself.

| ID | Case |
|----|------|
| SC-PROF-001 | `/@{user}` is PUBLIC_PROFILE, not downloadable |
| SC-PROF-002 | `/add/{user}` shares identity with `/@{user}` |
| SC-PROF-003 | Registry does not auto-download a profile |
| SC-PROF-004 | Public HTML metadata (name, description) |
| SC-PROF-005 | User error explains profile is not media |
