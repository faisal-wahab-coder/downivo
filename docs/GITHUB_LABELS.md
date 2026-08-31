# GitHub label recommendations

Create these on the GitHub repository (Settings → Labels, or `gh label create`). This document does **not** create labels via API.

| Label | When to use |
| ----- | ----------- |
| `bug` | Something broken in current behavior |
| `feature` | New user-facing capability |
| `enhancement` | Improvement to an existing feature |
| `documentation` | Docs-only (README, `docs/`, `documentation/`) |
| `good first issue` | Small, well-bounded, newcomer-friendly |
| `help wanted` | Maintainers want community help |
| `performance` | Speed, memory, scan/queue jank |
| `security` | Vulnerability or secret handling (no public exploits) |
| `testing` | Tests, CI coverage, QA scripts |
| `refactor` | No intended behavior change |
| `UI/UX` | Layout, theme, accessibility, copy |
| `platform` | Cross-cutting Android/Web |
| `android` | Android-only (manifest, FG service, share, gallery) |
| `ios` | Only if iOS work is explicitly accepted |
| `web` | Flutter Web runner / CORS proxy |
| `priority-high` | Blocks users or a release |
| `priority-medium` | Default |
| `priority-low` | Nice to have |
| `resolver` | Social/media URL resolvers |
| `engine` | `download_engine` queue / Dio |
| `duplicate` | Already tracked |
| `wontfix` | Declined (explain why) |
| `out of scope` | Conflicts with as-built V1 (e.g. sixth tab, cloud sync) |

Suggested colors are optional; use GitHub defaults if unsure.

Do not use `security` on public issues that include exploit steps — use private vulnerability reporting instead.
