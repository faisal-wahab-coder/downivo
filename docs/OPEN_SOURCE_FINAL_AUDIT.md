# Open-source final audit

Completed after local preparation and `bash scripts/ci.sh`. Public destination: [github.com/faisal-wahab-coder/downivo](https://github.com/faisal-wahab-coder/downivo).

## Open Source Readiness

```text
Security:        7/10
Documentation:   9/10
Architecture:    8/10
Testing:         8/10
CI/CD:           8/10
Contribution:    9/10
Maintainability: 8/10
Overall:         8/10
```

Security is not 10 because a Firebase Android config blob remains in **Git history** even though the live file is untracked. Rotate or restrict that API key after the first push.

## Files Created

- `LICENSE`
- `README.md`
- `CONTRIBUTING.md`
- `CODE_OF_CONDUCT.md`
- `SECURITY.md`
- `CHANGELOG.md`
- `.env.example`
- `.github/ISSUE_TEMPLATE/bug_report.md`
- `.github/ISSUE_TEMPLATE/feature_request.md`
- `.github/ISSUE_TEMPLATE/config.yml`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `docs/README.md`
- `docs/OPEN_SOURCE_AUDIT.md`
- `docs/ARCHITECTURE.md`
- `docs/DEVELOPMENT.md`
- `docs/FEATURE_DEVELOPMENT.md`
- `docs/ROADMAP.md`
- `docs/CONTRIBUTION_AREAS.md`
- `docs/DEPENDENCY_AUDIT.md`
- `docs/GITHUB_LABELS.md`
- `docs/PROJECT_GOVERNANCE.md`
- `docs/GIT_HISTORY_SECURITY.md`
- `docs/PUBLIC_RELEASE_CHECKLIST.md`
- `docs/OPEN_SOURCE_FINAL_AUDIT.md`

## Files Modified

- `.gitignore`
- `downivo/.gitignore`
- `downivo/scripts/ci.sh`
- `downivo/melos.yaml`
- `downivo/CHANGELOG.md`
- `downivo/README.md`
- `downivo/RELEASE.md`
- `downivo/apps/mobile/android/app/google-services.json.example`
- `downivo/packages/search/analysis_options.yaml`
- `downivo/packages/universal_viewer/analysis_options.yaml`
- `.github/workflows/flutter-ci.yml`
- `.github/workflows/release.yml`

## Files Untracked (kept locally)

- `downivo/apps/mobile/android/app/google-services.json` — gitignored; still on disk for local Firebase. **Still in Git history.**

## Files That Require Manual Review

- Firebase key rotation / API restrictions (Google Cloud Console)
- Whether commit author emails should stay public
- Whether `.agents/` and `.cursor/` Stitch skills should remain in the public tree
- `SECURITY.md` / `CODE_OF_CONDUCT.md` if you want a contact besides GitHub advisories
- Play signing (`key.properties`) stays local — never commit

## Security Issues

- Firebase `google-services.json` was in git and is still in history (see [GIT_HISTORY_SECURITY.md](GIT_HISTORY_SECURITY.md))
- No live `.env`, keystore, or PostHog key in the working tree
- Changelog/release notes no longer point at a private previous host

## Git History Issues

- Six commits; Firebase file blob still reachable
- Author email uses a workplace domain
- History was **not** rewritten

## Build/Test Results

Ran locally on 31 August 2026:

- Flutter **3.47.1** (stable), Dart **3.13.1**
- `bash scripts/ci.sh` from `downivo/` — **exit 0**, “All CI checks passed.”
- Analyze uses `--no-fatal-infos --no-fatal-warnings` so pre-existing `download_engine` warnings do not fail CI
- Unit/widget tests passed for engine, library, analytics, `app_core`, `apps/mobile`, `apps/web`, and other Melos members in `scripts/ci.sh`
- Full Android release AAB was **not** rebuilt in this pass (CI job on `main` will do a debug-signed AAB)

## Remaining Work

```text
P0 — Must fix before treating the repo as fully public-safe
  Rotate or restrict the Firebase Android API key
  Enable GitHub private vulnerability reporting on the new repo

P1 — Should do soon after push
  Confirm Actions ran on GitHub
  Create recommended labels (docs/GITHUB_LABELS.md)
  Add real README screenshots
  Pin a Flutter version in CI once you freeze a known-good SDK

P2 — Recommended
  Tighten analyze (remove --no-fatal-warnings after cleaning download_engine)
  Unify Flutter min SDK across packages
  Decide fate of empty stub packages and Cursor/Stitch trees

P3 — Future
  iOS, desktop, telemetry rollout with a privacy policy
  Format gate in CI
  Web build job
```
