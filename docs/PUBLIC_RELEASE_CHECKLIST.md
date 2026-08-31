# Public release checklist

Owner checklist before making the repository public. Items in **Security** that mention rotation cannot be finished by documentation alone.

## Security

- [ ] No API keys in the **working tree** (Firebase file untracked; confirm `git status` and `git grep`)
- [ ] Firebase Android API key **rotated or restricted** (see [GIT_HISTORY_SECURITY.md](GIT_HISTORY_SECURITY.md))
- [ ] No passwords
- [ ] No tokens (PostHog only via local dart-define)
- [ ] No private certificates / keystores (`*.jks`, `key.properties`)
- [ ] No private or previous-host URLs in current files
- [ ] No personal or company information you are unwilling to publish (commit emails, `com.pm.downivo` if you want to change it — changing applicationId is a breaking Play identity change)
- [ ] Decide whether to rewrite Git history before the first public push
- [ ] Enable GitHub **private vulnerability reporting**
- [ ] Fill the contact placeholders in `SECURITY.md` and `CODE_OF_CONDUCT.md` if you do not want GitHub-only reporting

## Documentation

- [ ] README
- [ ] CONTRIBUTING
- [ ] CODE_OF_CONDUCT
- [ ] SECURITY
- [ ] ARCHITECTURE (`docs/ARCHITECTURE.md`)
- [ ] DEVELOPMENT
- [ ] ROADMAP
- [ ] LICENSE (MIT)
- [ ] Optional: add real screenshots to README

## GitHub

- [ ] Issue templates
- [ ] PR template
- [ ] CI workflows
- [ ] License
- [ ] Labels ([GITHUB_LABELS.md](GITHUB_LABELS.md))
- [ ] Discussions (enable in repo settings if you want them)
- [ ] GitHub Projects (optional)
- [ ] Topics e.g. `flutter`, `android`, `download-manager`, `dart`
- [ ] Description: Flutter download manager (Downivo)
- [ ] Default branch (`main` vs `dev`) documented in the GitHub UI

## Code

- [ ] `bash scripts/ci.sh` passes locally
- [ ] Lint (`flutter analyze`) passes in CI
- [ ] Build works (`flutter build apk` or `appbundle` as needed)
- [ ] Dependencies reviewed ([DEPENDENCY_AUDIT.md](DEPENDENCY_AUDIT.md))
- [ ] No unnecessary generated files (`build/`, `.dart_tool/` gitignored)
- [ ] `google-services.json` not tracked

## Release

- [ ] Repository name finalized
- [ ] Repository description finalized
- [ ] Topics configured
- [ ] Default branch configured
- [ ] Initial GitHub release prepared (tag `v1.2.0` or current)
- [ ] Play Store / sideload process still uses local signing ([`downivo/RELEASE.md`](../downivo/RELEASE.md))

## After the first public push

- [ ] Confirm Actions ran on the default branch
- [ ] Create labels
- [ ] Open a few `good first issue` tickets from [ROADMAP.md](ROADMAP.md)
- [ ] Watch the first issues for leaked secrets in reports
