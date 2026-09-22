# Project governance

Lightweight process so the project stays reviewable without a bureaucracy layer.

## Feature decisions

- User-visible features start as a GitHub issue.
- Maintainers decide using the as-built architecture and [ROADMAP.md](ROADMAP.md).
- Large or controversial ideas (new platforms, new analytics vendors, schema rewrites) need an issue discussion **before** a PR.
- Older `documentation/` UX chapters for unbuilt modules are **not** automatic approval to build them.

## Pull request review

- Contributors open PRs against **`dev` only**. Direct pushes to `dev` and `main` are blocked.
- At least one maintainer review before merge when more than one person has access.
- Solo-maintainer repos may self-merge after CI is green; still wait for CI.
- Checks: `scripts/ci.sh` (GitHub Actions), no secrets, architecture boundaries, tests for logic changes.
- Drive-by reformats of unrelated files should be asked to revert.
- Releases: maintainer PR from `dev` into `main`, then tag.

## Issues

- Use the bug and feature templates.
- Close duplicates with a link.
- `good first issue` should include a file hint and acceptance criteria.
- If a report includes secrets, edit/redact and rotate credentials; do not leave keys in the thread.

## Breaking changes

- Discuss on an issue first.
- Examples: sqflite schema that cannot migrate, changing `applicationId`, dropping a resolver, raising minSdk.
- Document in `CHANGELOG.md` under Unreleased / a new version.
- Prefer a minor version for features and a patch for fixes (`1.4.0+6` uses the `+` build number for Play).

## Releases

- Version lives in `downivo/apps/mobile/pubspec.yaml` (and `apps/web` should stay aligned).
- Tag `vMAJOR.MINOR.PATCH` after CI is green.
- GitHub Actions `release.yml` builds artifacts; creating the GitHub Release notes is a maintainer step.
- Play Store signing stays off public CI unless the owner later adds encrypted secrets.

Details: [`downivo/RELEASE.md`](../downivo/RELEASE.md).

## Becoming a regular contributor

There is no formal election. People who submit quality PRs, review others, and respect [CODE_OF_CONDUCT.md](../CODE_OF_CONDUCT.md) may be asked to help triage issues. Write access is at the owner's discretion.

## License

Contributions are accepted under the [MIT License](../LICENSE). Do not add files under a conflicting license without an issue.
