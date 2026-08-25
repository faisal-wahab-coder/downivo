# 24. Testing

See 11.11.

Minimum replica tests:

1. Database create + v4 migration
2. URL validator
3. Range parser
4. Enqueue persists a row
5. `clearHistory` removes rows, files remain
6. Onboarding copy
7. History semantics
8. Representative resolver tests (YouTube host, WhatsApp private CDN rejection, Telegram hosts)

QA markdown under `downivo/qa/` may be copied if available; not required to compile.

Observability tests (Crashlytics, event properties, URL sanitizer) are specified in [31](31_Observability_Analytics.md) Phase 17 — not required for a V1 replica.
