# Development

Commands below are taken from this repository (`downivo/scripts/ci.sh`, `melos.yaml`, app READMEs, `RELEASE.md`).

## Development environment

| Tool | Constraint |
| ---- | ---------- |
| Dart SDK | `^3.10.0` |
| Flutter | `>=3.44.0` for `apps/mobile` and `job_manager`; other packages allow `>=3.24.0` or `>=3.38.0`. Use a single recent stable SDK that satisfies **3.44+**. |
| Android SDK | `minSdk 29`, `compileSdk 37` in `apps/mobile/android/app/build.gradle.kts` |
| Java | 17 |
| Melos | `^8.2.2` (optional; `dev_dependencies` on the workspace pubspec) |

IDE: any Dart-capable editor. `.vscode/` is gitignored.

Cursor/Stitch files under `.cursor/` and `.agents/` are **optional maintainer tooling**. They are not required to build the app.

## Installation

```bash
git clone https://github.com/faisal-wahab-coder/downivo.git
cd downivo/apps/mobile
flutter pub get
```

Workspace-wide (optional):

```bash
cd downivo
dart pub global activate melos
melos bootstrap
```

## Environment variables

The apps do **not** load `.env` at runtime. See [`.env.example`](../.env.example).

| Variable | How it is used |
| -------- | ---------------- |
| `POSTHOG_API_KEY` | `--dart-define=POSTHOG_API_KEY=` |
| `POSTHOG_HOST` | `--dart-define=POSTHOG_HOST=` (default `https://us.i.posthog.com`) |
| `UD_WEB_PROXY_PORT` | `apps/web/tool/cors_proxy.dart` |
| Firebase | File `apps/mobile/android/app/google-services.json` (gitignored). Copy from `google-services.json.example` then replace with a real Firebase download. |
| Signing | `apps/mobile/android/key.properties` from `key.properties.example` |

Without Firebase/PostHog the app still runs; analytics adapters no-op.

## Running locally

**Android**

```bash
cd downivo/apps/mobile
flutter run
```

**Web**

```bash
cd downivo/apps/web
dart run tool/cors_proxy.dart    # terminal 1
flutter pub get
flutter run -d chrome            # terminal 2
```

`./run_chrome.sh` in `apps/web` starts both if present. Disable the proxy with `--dart-define=UD_WEB_PROXY=` (direct file URLs only).

## Debugging

- Flutter DevTools / Observatory as usual (`flutter run` then `d`)
- Download queue: watch `DownloadManager.tasksStream` via the Downloads tab
- Performance numbers: Settings → Performance
- Android foreground service: system notification while downloads run
- Crashlytics debug: Settings includes a test-crash control when Firebase is configured (`packages/analytics` README)

Do not log full download URLs in new code. Use `AppLogger` in `analytics`.

## Testing

From `downivo/`:

```bash
bash scripts/ci.sh
```

That script runs `flutter pub get`, `flutter analyze --no-fatal-infos`, and `flutter test` for each package listed in `scripts/ci.sh`.

Per package:

```bash
cd downivo/packages/download_engine
flutter test
```

Melos:

```bash
cd downivo
melos run test
melos run qa          # bash qa/runner/qa_runner.sh — local QA runner
```

Manual device QA: [`downivo/QA_CHECKLIST.md`](../downivo/QA_CHECKLIST.md) and `downivo/qa/`.

## Linting

```bash
cd downivo
bash scripts/ci.sh    # includes analyze
# or
melos run analyze
# or
cd apps/mobile && flutter analyze --no-fatal-infos
```

Lint rules: `package:flutter_lints/flutter.yaml` via each package `analysis_options.yaml`.

## Formatting

```bash
cd downivo
melos run format      # dart format . in each package
```

There is no `dart format` CI gate yet.

## Building

Sideload APK for a phone (from `downivo/`):

```bash
bash scripts/build_release_apk.sh --open
```

Or `melos run build:apk`. `--fat` builds all ABIs; `--aab` also builds a Play bundle.

From `downivo/apps/mobile`:

```bash
flutter build apk --release
flutter build appbundle --release
```

Outputs (under `apps/mobile/build/`):

- APK: `app/outputs/flutter-apk/app-release.apk`
- AAB: `app/outputs/bundle/release/app-release.aab`
- Mapping: `app/outputs/mapping/release/mapping.txt`

CI on `main` builds a **debug-signed** AAB when `key.properties` is missing. Play Store uploads require a real upload keystore locally or via secrets you add later — do not commit them.

Web: `flutter build web` from `apps/web` (not currently a CI job).

Release engineering: [`downivo/RELEASE.md`](../downivo/RELEASE.md).

## Troubleshooting

| Problem | What to check |
| ------- | ------------- |
| `sdk` / Flutter constraint errors | Need Dart 3.10+ and Flutter 3.44+ for mobile |
| Android Gradle / KGP | `shared_preferences_android` and `webview_flutter_android` are pinned in `apps/mobile` `dependency_overrides` |
| Firebase plugin apply fails | Missing `google-services.json` should **skip** plugins (`build.gradle.kts` checks `exists()`). Do not commit a live file. |
| Web social URLs fail | Start `cors_proxy.dart`; it binds loopback only |
| Tests need sqflite | Packages use `sqflite_common_ffi` in tests |
| Empty stub packages | Not in Melos — ignore unless you are promoting one |
| `documentation/` vs `docs/` | `documentation/` = product specs; `docs/` = OSS contributor guides |

## Platform-specific development

**Android** — permissions in `AndroidManifest.xml` (internet, notifications, camera, FG service, wake lock, write external storage maxSdk 29). Share target via SEND intent-filters. Application label `Downivo`.

**Web** — no camera QR, share intake, or foreground service. Session files until Save to disk. `web/sqlite3.wasm` is required and tracked.

**iOS** — not a V1 target. Do not assume iOS plugins work.

## Common problems

- Adding a sixth tab breaks IA and onboarding assumptions
- Putting UI in `navigation/tab_screens.dart` — live screens belong in `app_core`
- Replacing sqflite with Drift because ADR-002 said so — **do not**; the as-built database is sqflite
- Sending URLs to Crashlytics/PostHog — forbidden
- Committing `*.jks` or `key.properties` — forbidden
