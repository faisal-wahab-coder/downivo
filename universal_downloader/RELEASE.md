# Production Release Guide

Universal Downloader **1.2.0** — What's new dialog, gallery, and social URL resolvers.

## Prerequisites

- Flutter 3.x stable
- Android SDK (API 29+)
- Java 17
- [Melos](https://melos.invertase.dev/) (`dart pub global activate melos`)

## Verify before release

From `universal_downloader/`:

```bash
bash scripts/ci.sh
```

Or with Melos (optional): `melos bootstrap && melos run analyze && melos run test`

Complete the manual checklist in [`QA_CHECKLIST.md`](QA_CHECKLIST.md) on a physical device.

## Versioning

- **Version name** — `pubspec.yaml` → `version: MAJOR.MINOR.PATCH+BUILD`
- **Version code** — the number after `+` (must increment for each Play Store upload)
- Current production: `1.2.0+4`

## Signing (Google Play)

1. Create an upload keystore (once):

   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Copy `apps/mobile/android/key.properties.example` → `apps/mobile/android/key.properties`

3. Fill in passwords and keystore path. **Never commit** `key.properties` or `*.jks`.

4. CI builds without `key.properties` use debug signing for artifacts only. Production Play uploads require your upload key locally or via GitHub Actions secrets.

## Build commands

From `universal_downloader/apps/mobile`:

```bash
# Android App Bundle (Play Store)
flutter build appbundle --release

# APK (side-load / internal testing)
flutter build apk --release
```

Outputs:

- AAB: `build/app/outputs/bundle/release/app-release.aab`
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- ProGuard mapping: `build/app/outputs/mapping/release/mapping.txt` (upload to Play Console)

## CI/CD

- **Remote** — [Bitbucket `app_ideas/downloader`](https://bitbucket.org/app_ideas/downloader)
- **Pull requests** — `.github/workflows/flutter-ci.yml` runs analyze + test (GitHub; optional on Bitbucket)
- **Main branch** — also builds release AAB artifact
- **Tags `v*`** — `.github/workflows/release.yml` runs full validation and uploads AAB + mapping

Create a release:

```bash
git tag v1.2.0
git push origin v1.2.0
```

## Google Play checklist

- [ ] Upload AAB to Production (or staged rollout)
- [ ] Upload ProGuard mapping file
- [ ] Store listing, screenshots, content rating
- [ ] Privacy policy URL (if required for permissions)
- [ ] Declare foreground service (`dataSync`) and notification usage

## Post-release

- Monitor crash reports in Play Console
- Track download success rate and startup metrics (Settings → Performance)
- File hotfixes on `hotfix/*` branches per `docs/11_Technical_Architecture/11.12_CI_CD.md`
