# analytics

Crash monitoring, product events, structured logging, and Remote Config for Downivo.

V1 had an empty stub. This package is now a Melos member. See `documentation/31_Observability_Analytics.md`.

## What ships in the app

- `AnalyticsService` — only API UI/engine should call
- `AppLogger` — structured logs, URLs/tokens stripped
- Firebase Crashlytics (when `google-services.json` is present)
- PostHog (when `POSTHOG_API_KEY` is passed)
- Firebase Remote Config + Performance traces
- Privacy sanitizer + Settings opt-out

Without Firebase/PostHog keys the app still runs; adapters no-op.

## Firebase (Crashlytics, Performance, Remote Config)

1. Create a Firebase project and an Android app with applicationId `com.pm.downivo`.
2. Download `google-services.json` into `apps/mobile/android/app/`.
3. Gradle applies Google Services + Crashlytics plugins only if that file exists.
4. Release builds send crashes. Debug builds keep collection off (use Settings → Send test crash).

## PostHog

Pass at run/build time:

```
flutter run --dart-define=POSTHOG_API_KEY=phc_... --dart-define=POSTHOG_HOST=https://us.i.posthog.com
```

## Remote Config keys

| Key | Default |
|-----|---------|
| `maintenance_mode` | false |
| `max_concurrent_downloads` | 3 |
| `default_quality` | (empty) |
| `{platform}_resolver_enabled` | true |

## Dashboards and alerts

Configure in the Firebase and PostHog consoles (not in the app):

- Crash-free users/sessions, ANRs
- Funnel: app_opened → url_pasted → platform_detected → resolve_* → download_* → download_opened
- Breakdown by `platform`, `error_category`, Android version
- Alerts: crash rate, download failure rate, resolver failure by platform

Never send full URLs, tokens, cookies, or file contents.
