# 23. Security

- No accounts, no cloud sync. Planned Crashlytics + PostHog (see [31](31_Observability_Analytics.md)) is crash/product telemetry only — not user accounts or backup
- Telemetry must not include URLs, tokens, cookies, or file contents; consent/privacy policy required before production rollout
- Permissions minimized (internet, notifications, camera, FG service, wake lock)
- Clipboard opt-in
- Do not fetch WhatsApp private media CDNs
- Do not break DRM
- Release R8/ProGuard
- `key.properties` gitignored; ship `key.properties.example`
- WebView is for browsing + detection, not a generic file-exfil tool
