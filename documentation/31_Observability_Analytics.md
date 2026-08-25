# 31. Observability & Analytics

**Status:** Implemented in `packages/analytics` (Melos). Sinks stay silent until Firebase/PostHog keys are present.  
**As-built:** Crashlytics + PostHog adapters, `AppLogger`, funnel events, Remote Config defaults, Settings opt-out. Requires `google-services.json` and `POSTHOG_API_KEY` for live data.  
**Source of truth:** this file. Architecture sketches live in [12.23](12_System_Design/12.23_Analytics_Architecture.md) and [12.24](12_System_Design/12.24_Logging_Framework.md).

---

# 1. Objective

The application is functionally complete (M1–M9). Before major new product features, add crash monitoring, error tracking, user-interaction analytics, download analytics, and product insights.

The system must answer:

| Question |
|----------|
| How are users interacting with the application? |
| Which platforms are used most? |
| Which URLs fail to resolve? (platform + error category only — never the URL) |
| Which downloads fail? |
| Where do users abandon the download flow? |
| Which screens/features are actually being used? |
| Which devices / Android versions cause problems? |
| Which crashes and errors should be fixed first? |
| Which new features should be prioritized based on real usage? |

Implement incrementally using the phases and sprints below.

**Principle:** Observe → Measure → Analyze → Prioritize → Build → Measure again.

---

# 2. Recommended technology stack

| Area | Tool | Purpose |
|------|------|---------|
| Crash monitoring | Firebase Crashlytics | Flutter + native Android crashes |
| Product analytics | PostHog | User events, funnels, retention |
| Performance (later) | Firebase Performance / Sentry Performance | Slow operations |
| Remote configuration (later) | Firebase Remote Config | Safely enable/disable features |
| Internal abstraction | Custom `AnalyticsService` | Prevent vendor lock-in |
| Logging | Custom structured `AppLogger` | Debugging and diagnostics |

**Initial recommendation:** Firebase Crashlytics + PostHog + custom `AnalyticsService`.

Do **not** integrate multiple analytics providers for the same purpose. Do **not** send product events through Crashlytics or crash reports through PostHog.

Local `packages/performance` (startup ms, TTL/LRU caches, `ThrottleGate`) stays. Remote performance monitoring is additive; it does not replace that package.

---

# 3. Privacy rules (mandatory)

Downivo processes URLs that users provide. **Never send complete user URLs to analytics platforms.**

## Do not track

- Full URL
- Query parameters
- Authentication tokens
- Cookies
- Access tokens
- Personal information
- Downloaded file contents
- Private Telegram URLs
- Private social-media URLs
- File names that may contain personal information
- Keyboard input
- Every tap or every scroll

## Instead track

```json
{
  "platform": "youtube",
  "media_type": "video",
  "resolution": "1080p"
}
```

Use anonymized identifiers where required (PostHog distinct id / session id — not device advertising IDs unless legally reviewed).

Existing product rules still apply: no WhatsApp private media CDNs, no DRM circumvention, on-device metadata for downloads. Telemetry is a **new outbound channel** and must be documented in the privacy policy with consent/controls where applicable.

---

# 4. As-built mapping (Flutter app)

Wire events to existing code. Do not invent parallel screens or platform enums.

## 4.1 Platforms

Analytics `platform` values vs `SocialPlatform`:

| Analytics value | As-built |
|-----------------|----------|
| `youtube` | `SocialPlatform.youtube` |
| `youtube_shorts` | **Not a separate enum.** Detect Shorts from path (`/shorts/`) at emit time; otherwise `youtube` |
| `tiktok` | `SocialPlatform.tiktok` |
| `instagram` | `SocialPlatform.instagram` |
| `facebook` | `SocialPlatform.facebook` |
| `x` | `SocialPlatform.twitter` (label is already “X (Twitter)”) |
| `reddit` | `SocialPlatform.reddit` |
| `pinterest` | `SocialPlatform.pinterest` |
| `linkedin` | `SocialPlatform.linkedin` |
| `threads` | `SocialPlatform.threads` |
| `soundcloud` | `SocialPlatform.soundcloud` |
| `vimeo` | `SocialPlatform.vimeo` |
| `twitch` | `SocialPlatform.twitch` |
| `telegram` | `SocialPlatform.telegram` |
| `snapchat` | `SocialPlatform.snapchat` |
| `whatsapp` | `SocialPlatform.whatsapp` |
| `dailymotion` | `SocialPlatform.dailymotion` |
| `direct_url` | Resolver miss / generic HTTP file (`fromUri` returned `null` and download proceeds) |
| `unknown` | Could not classify and did not start a direct download |

Emit analytics keys as the left column (`x`, not `twitter`). Keep `SocialPlatform` unchanged unless a dedicated Shorts resolver is added later.

## 4.2 Screens

| Analytics `screen` | As-built surface |
|--------------------|------------------|
| `home` | `HomeScreen` (`/home`) |
| `url_input` | `DownloadWizardDialog` |
| `resolution` | Resolve step inside wizard / `DownloadManager` prepare |
| `media_selection` | `MediaSelectionSheet`, `FormatPickerSheet` |
| `downloads` | `DownloadsScreen` (`/downloads`) |
| `download_details` | `FileDetailScreen` (and completed-tile detail if used) |
| `settings` | `SettingsScreen` (`/settings`) |
| `history` | `DownloadHistoryScreen` (`/downloads/history`) |

Also present, optional later (not required for the first milestone): `browser`, `files`, `search`, `qr_scanner`, `clipboard_history`, `onboarding`.

## 4.3 Download lifecycle

`DownloadStatus`: `queued`, `preparing`, `downloading`, `paused`, `completed`, `failed`, `cancelled`, `verifying`.

Map to events: started (leave queued → downloading/preparing), paused, resumed, completed, failed, cancelled.

`DownloadManager.maxConcurrent` is **3** (constructor default). Remote Config may override this later; default remains 3.

## 4.4 Package placement

Promote `downivo/packages/analytics` from a stub to a Melos member.

Suggested contents (names may vary):

- `AnalyticsService` — single write API used by `app_core` and `download_engine`
- Crashlytics adapter (Android + Flutter)
- PostHog adapter
- `AppLogger` (or a sibling `logging` module if analytics should stay event-only)
- Privacy sanitizer (strip URLs, tokens, query strings before any sink)

`app_core` emits UI/lifecycle events. `download_engine` / resolvers emit resolve and download events with `downloadId`, `platform`, `media_type`, `error_category` — never the URL.

Web runner: Crashlytics is Android-primary. PostHog may run on web if keys and privacy review allow; otherwise no-op adapters.

---

# 5. Phase 1 — Crash monitoring

**Goal:** Understand when and why the application crashes.

## Tasks

- Add Firebase Crashlytics
- Configure Android Crashlytics
- Configure Flutter error reporting
- Capture uncaught Dart exceptions
- Capture Flutter framework errors (`FlutterError.onError`)
- Capture native Android crashes
- Capture fatal crashes
- Capture non-fatal exceptions
- Enable crash reporting for **release** builds (debug optional / off by default)
- Verify with a controlled test crash
- Verify events appear in the Firebase dashboard

## Crash context

Every important error should include useful context, for example:

| Key | Example |
|-----|---------|
| Screen | `downloads` |
| Action | `StartDownload` |
| Platform | `youtube` |
| MediaType | `video` |
| AppVersion | `1.2.0` |
| AndroidVersion | `15` |

## Custom Crashlytics keys

`app_version`, `build_number`, `platform`, `media_type`, `download_state`, `network_type`, `screen`, `last_action`

Do not put URLs or tokens in custom keys.

## Success

The team can answer: *What crashed, how often, on which devices, and during which operation?*

---

# 6. Phase 2 — Structured application logging

**Goal:** Consistent logs that help diagnose failures.

## Tasks

- Centralized `AppLogger`
- Log levels
- Structured logging
- Correlation / download IDs
- Never log sensitive URLs or authentication information
- Resolver, downloader, storage, permission, and network logs

## Levels

`DEBUG` · `INFO` · `WARNING` · `ERROR` · `FATAL`

## Example

```
INFO  Download started  downloadId=83921  platform=youtube  mediaType=video
```

Never:

```
Downloading https://some-private-url...
```

## Success

A developer can investigate a failed download without reproducing the problem immediately.

Release builds: do not print secrets; prefer Crashlytics non-fatals + sanitized breadcrumbs over verbose device logs.

---

# 7. Phase 3 — Product analytics

**Goal:** Understand what users actually do.

All analytics events go through `AnalyticsService`. UI and engine must not call PostHog (or any vendor) directly.

## Basic events

`app_opened`

`url_pasted`  
`platform_detected`

`resolve_started`  
`resolve_success`  
`resolve_failed`

`download_started`  
`download_paused`  
`download_resumed`  
`download_completed`  
`download_failed`  
`download_cancelled`

## Additional events

`download_deleted`  
`download_opened`  
`download_shared`

`settings_opened`  
`permission_requested`  
`permission_granted`  
`permission_denied`

`storage_warning`

Properties on download/resolve events: `platform`, `media_type`, and other **non-PII** fields from later phases. Never `url`.

---

# 8. Phase 4 — Platform analytics

**Goal:** Which supported platforms are actually used.

Track `platform` using the values in §4.1.

Example:

```json
{
  "event": "platform_detected",
  "platform": "youtube",
  "media_type": "video"
}
```

## Dashboard

Platform distribution report, for example:

| Platform | Share (example) |
|----------|-----------------|
| YouTube | 50% |
| TikTok | 20% |
| Instagram | 10% |
| Facebook | 7% |
| Reddit | 5% |
| Pinterest | 3% |
| Other | 5% |

## Success

Engineering effort can follow real usage, not guesses.

---

# 9. Phase 5 — Download funnel

**Goal:** Where users fail or abandon download.

```
App Open
  → URL Pasted
  → Platform Detected
  → Resolution Started
  → Resolution Successful
  → Media Selected
  → Download Started
  → Download Completed
  → File Opened / Shared
```

## Conversion (example)

```
10,000 URLs submitted
     → 9,200 resolved
     → 8,700 downloads started
     → 7,900 downloads completed
```

## Metrics

- Resolution success rate
- Download start rate
- Download completion rate
- Download failure rate

## Success

Identify the exact abandon step.

**First production milestone = Phases 1–5.** After they are live, collect **2–4 weeks** of real usage before deciding the next feature roadmap.

---

# 10. Phase 6 — Download performance analytics

**Goal:** Performance and reliability of downloads.

Track: `download_duration`, `file_size` (bucketed), `download_speed`, `download_status`, `retry_count`, `network_type`, `media_type`, `platform`.

## Metrics

Average download duration, average download speed, average file size (from buckets or internal-only exact size), download success rate, download failure rate, retry rate.

## File size buckets

Do not send exact sizes when unnecessary:

`< 10 MB` · `10–50 MB` · `50–100 MB` · `100–500 MB` · `500 MB–1 GB` · `> 1 GB`

---

# 11. Phase 7 — Resolver analytics

**Goal:** Which resolvers are reliable and which need work.

Events: `resolve_started`, `resolve_success`, `resolve_failed`

Properties: `platform`, `media_type`, `resolver_version`, `error_category`

## Error categories (normalized — never raw exception text that may include URLs)

`invalid_url`  
`unsupported_platform`  
`private_content`  
`content_not_found`  
`rate_limited`  
`network_error`  
`timeout`  
`resolver_error`  
`media_unavailable`  
`unknown_error`

Example insight: YouTube 96% resolve success, TikTok 81%, Instagram 72%, Facebook 64% → focus order is obvious.

---

# 12. Phase 8 — User interaction analytics

**Goal:** How users navigate the application.

Screens: see §4.2.

## Events

`screen_viewed`

`paste_button_clicked`  
`download_button_clicked`  
`quality_changed`  
`format_changed`

`pause_clicked`  
`resume_clicked`  
`cancel_clicked`

`share_clicked`  
`open_file_clicked`  
`delete_clicked`

Track only interactions that help product decisions.

---

# 13. Phase 9 — User journey and session analysis

**Goal:** Real user journeys (PostHog session replay is **not** required; event sequences are enough).

Success example: Home → Paste URL → YouTube detected → Resolution successful → 1080p selected → Download started → Download completed → Share.

Failure example: Home → Paste URL → TikTok detected → Resolution failed → User exits.

Use this to separate UX problems from technical failures.

---

# 14. Phase 10 — Performance monitoring

**Goal:** Detect slow screens and operations before users report them.

Monitor: app startup, Home screen load, URL parsing, resolver duration, media selection load, download initialization, database queries, file-system operations, large-file processing.

Local `PerformanceManager.recordStartup` already records startup ms on-device. Remote traces should reuse the same operations.

## Example targets (adjust from production)

| Operation | Target |
|-----------|--------|
| App startup | < 2 s |
| URL detection | < 500 ms |
| Resolver | < 5 s where practical |
| UI interaction | < 100 ms |

---

# 15. Phase 11 — Device and environment analytics

**Goal:** Device-specific problems.

Track: Android version, device manufacturer, device model, app version, build number, CPU architecture, network type.

Example: Samsung Android 15 download failure 2% vs Xiaomi Android 14 18% → a concrete engineering target.

Minimize fingerprinting: prefer aggregated Crashlytics/PostHog device fields over a custom exhaustive hardware dump.

---

# 16. Phase 12 — Remote configuration

**Goal:** Change important behavior without a new store release.

Use Remote Config for: feature flags, resolver enable/disable, download limits, maximum concurrent downloads, default quality, experimental features, maintenance mode.

Example keys:

```
youtube_resolver_enabled = true
tiktok_resolver_enabled = true
max_concurrent_downloads = 3
```

**Constraint:** Remote configuration is a safe fallback while a fix is developed. It must **not** permanently hide serious bugs.

Engine default remains `maxConcurrent: 3` if Remote Config is unavailable (offline / first launch).

---

# 17. Phase 13 — Analytics dashboard

Central dashboard sections:

### Application health

Crash-free users, crash-free sessions, ANRs, fatal crashes, non-fatal errors.

### Usage

DAU, WAU, MAU, sessions, downloads/user.

### Downloader

Downloads started / completed / failed, completion rate, average download duration.

### Platforms

YouTube, TikTok, Instagram, Facebook, X, Reddit, Pinterest, LinkedIn, Threads, SoundCloud, Vimeo, Twitch, Telegram, Snapchat, WhatsApp, Dailymotion (plus `direct_url` / `unknown` / `youtube_shorts` as implemented).

### Resolver

Resolution success rate, resolution failure rate, top resolver errors (`error_category`).

---

# 18. Phase 14 — Automated alerts

**Goal:** Know about serious problems before users report them.

Alert on: crash rate increases, ANR rate increases, download failure rate increases, resolver failure increases, specific platform failure increases, specific Android version failure increases.

Example: Instagram resolver failures 8% → 31% on app version 1.4.0 → investigate.

---

# 19. Phase 15 — Product decision framework

Do not add features from requests or assumptions alone.

Score: **Usage + Failure rate + User impact + Business value + Engineering cost**.

| Feature | Usage | Failure | Impact | Priority |
|---------|-------|---------|--------|----------|
| YouTube improvements | High | Medium | High | P0 |
| TikTok improvements | High | High | High | P0 |
| Download queue | Medium | Low | High | P1 |
| Video editor | Low | N/A | Medium | P3 |
| Themes | Low | N/A | Low | P4 |

This prevents unnecessary feature development.

---

# 20. Phase 16 — Privacy and data review

Before production rollout:

- [ ] Review all analytics events
- [ ] Remove complete URLs
- [ ] Remove authentication information
- [ ] Remove cookies
- [ ] Remove personal data
- [ ] Review device information
- [ ] Review analytics retention
- [ ] Document collected data (this file + privacy policy)
- [ ] Add/update privacy policy if required
- [ ] Verify analytics providers' privacy settings
- [ ] Provide required consent/controls where applicable
- [ ] Keep Firebase / PostHog keys out of git (use `google-services.json` / dart-define / CI secrets; never commit production secrets)

---

# 21. Phase 17 — Testing

Before production analytics:

### Crash testing

- [ ] Controlled Flutter crash
- [ ] Native Android crash
- [ ] Non-fatal exception
- [ ] Crashlytics receives all events

### Analytics testing

- [ ] `app_opened`
- [ ] URL detection (`url_pasted` / `platform_detected`)
- [ ] Resolver success
- [ ] Resolver failure
- [ ] Download start / completion / failure / cancellation
- [ ] Event properties (no URL, valid `platform` / `error_category`)

### Privacy testing

- [ ] URL is not sent
- [ ] Tokens are not sent
- [ ] Cookies are not sent
- [ ] Personal information is not sent

Unit-test the sanitizer with URLs that contain tokens and query strings.

---

# 22. Recommended implementation order

Do **not** implement everything simultaneously.

| Sprint | Scope |
|--------|--------|
| **1 Foundation** | Crashlytics, `AnalyticsService`, `AppLogger`, error handling |
| **2 Core analytics** | App lifecycle, URL submission, platform detection, resolver success/failure, download start/completion/failure |
| **3 Product analytics** | Funnels, platform statistics, download statistics, screen usage, user journeys |
| **4 Performance** | Resolver / download / startup performance, device analysis, ANR monitoring |
| **5 Operations** | Dashboards, alerts, Remote Config, feature flags |
| **6 Data-driven product** | Collect, analyze, identify bottlenecks, prioritize, A/B test important changes, release, measure |

Sprints 1–2 plus funnel wiring cover Phases 1–5 (first milestone).

---

# 23. Final architecture

```
                    Flutter Application
                           │
                           ▼
                  ┌─────────────────┐
                  │ AnalyticsService│
                  └────────┬────────┘
                           │
             ┌─────────────┼─────────────┐
             ▼             ▼             ▼
        Crashlytics      PostHog       Logger
             │             │             │
             ▼             ▼             ▼
          Crashes        Events         Logs
          ANRs           Funnels        Errors
          Errors         Sessions        Debug
             │             │             │
             └─────────────┼─────────────┘
                           ▼
                    Analytics Dashboard
                           │
                           ▼
                    Product Decisions
                           │
                           ▼
                    New Features
                           │
                           ▼
                     Measure Again
```

Adapters behind `AnalyticsService` are replaceable. Call sites stay vendor-free.

---

# 24. Success definition

Observability is successful when the team can answer these **without** asking users to reproduce the problem:

- How many users are actively using the application?
- How many downloads are performed?
- Which platforms are most popular?
- Which platforms have the highest failure rate?
- Where are users abandoning the download flow?
- Which devices have the most crashes?
- Which Android versions have problems?
- What is the download success rate?
- What is the average download performance?
- Which features are actually being used?
- What are the top application crashes?
- What should we build next based on actual user behavior?

---

# 25. First milestone (gate for new features)

Before adding any major new Downivo feature, complete:

1. Phase 1 — Crash monitoring  
2. Phase 2 — Structured logging  
3. Phase 3 — Product analytics  
4. Phase 4 — Platform analytics  
5. Phase 5 — Download funnel  

Once live in production, collect **2–4 weeks** of real usage data and use that data for the next feature roadmap.
