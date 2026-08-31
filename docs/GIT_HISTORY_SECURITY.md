# Git history security

This file explains history issues discovered during open-source preparation. **History was not rewritten.** Do that yourself only if you intend a public GitHub repo and you accept that anyone who already cloned the old history still has the old objects.

Public destination: [github.com/faisal-wahab-coder/downivo](https://github.com/faisal-wahab-coder/downivo).

## Current history (at audit)

Six commits on `dev` / `main`, all authored **Faisal Wahab**. Dates in August 2026.

The previous `origin` remote was a private host. Changelog and release notes in the working tree no longer point at that host.

## Sensitive information in history

### 1. Firebase `google-services.json`

The file `downivo/apps/mobile/android/app/google-services.json` was committed (commit that added project documentation). It includes a Firebase project id, numeric project number, Android `mobilesdk_app_id`, and an Android API key.

**After preparation:** the file is **untracked** and gitignored. A local copy may remain on your machine for Crashlytics. The **blob remains in Git history**.

**Before the first public `git push`:**

1. In Google Cloud Console / Firebase: **restrict** the Android API key to the app (`com.pm.downivo`) and consider **rotating** it (download a new `google-services.json`).
2. Decide whether to **purge the file from history** (recommended if the repo will be public and the key cannot be treated as a restricted client key):

```bash
# Example only — you run this. Rewrites all commits.
git filter-repo --path downivo/apps/mobile/android/app/google-services.json --invert-paths
```

`git filter-repo` is the current Git recommendation. Alternatives: BFG Repo-Cleaner. Anyone with an old clone must re-clone after a rewrite.

3. If you already pushed the file to **any** remote, rotate the key even if you rewrite afterward.

Do not paste the old key into issues or this repo.

### 2. Author email

Commits use a workplace email domain. That is visible on every commit. Options:

- Leave it (simple; identifies you as the author)
- Rewrite `GIT_AUTHOR_EMAIL` / `GIT_COMMITTER_EMAIL` for all commits **before** the first public push if you do not want that address public
- Use a GitHub-provided noreply address for **future** commits (`git config` locally — this preparation does not change git config)

### 3. Previous remote URLs

Older commits of `CHANGELOG.md` and `RELEASE.md` may still contain the previous private-host compare URLs inside Git history, even though the current files do not.

### 4. Large or generated files

Tracked `downivo/apps/web/web/sqlite3.wasm` is **required** for Flutter Web SQLite — keep it. Branding PNGs are reasonable. No multi-hundred-MB blobs were found in `git rev-list` top objects.

`.agents/` and `.cursor/` design skills are large in *file count* but not huge binaries. They are not secrets; you may still choose to drop them from a public repo in a later PR if you want a slimmer tree.

## What was not done

- No `git push --force`
- No `filter-branch` / `filter-repo`
- No amendment of existing commits

## Recommended order if you want a clean public history

1. Rotate Firebase credentials
2. Confirm `.gitignore` excludes `google-services.json`
3. Optionally filter-repo the Firebase file and author emails
4. Create [github.com/faisal-wahab-coder/downivo](https://github.com/faisal-wahab-coder/downivo)
5. Point `origin` at that repository and push once
6. Tag `v1.2.0` (or current version) from the cleaned tree

If you skip history rewrite, still rotate the Firebase key and rely on API restrictions.
