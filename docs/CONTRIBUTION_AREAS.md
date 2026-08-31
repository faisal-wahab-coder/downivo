# Contribution areas

Practical places to help. Only areas that exist in this repo are listed.

## Beginner

- Documentation in `docs/` and `README.md` (keep it accurate)
- Tests for `shared_utils` formatters and small engine helpers (`url_validator`, filename resolver)
- Empty states and copy in `design_system` / `app_core` screens
- Accessibility labels on list rows
- User-visible error strings from `download_error_formatter`
- Manual QA using `downivo/QA_CHECKLIST.md` and filing bugs
- Screenshots for the README (real device captures)

## Intermediate

- Download engine robustness: retries, Range edge cases, crash restore
- Queue UX: reorder, priority, pause-all
- Performance: list virtualization, scan cache, progress throttle
- `media_library` actions and gallery edge cases
- Browser download detection false positives/negatives
- Clipboard / share / QR intake bugs
- Web runner: CORS proxy docs, session file save UX
- Analytics sanitizer coverage (no URL leakage)

## Advanced

- New **ethical** content resolvers (public pages only; fail on auth/DRM/private CDN)
- Android foreground service and notification actions
- Networking / Dio behavior in `download_engine`
- Schema migrations on sqflite v4+
- Plugin or platform-channel work (keep `apps/mobile` thin)
- Promoting a stub package into Melos with a real design — maintainer approval required
- CI: Flutter version pin, optional `format` gate, web build job

## Out of scope unless maintainers agree

- Circumventing DRM, paywalls, or WhatsApp-style private media CDNs
- Collections, Activity Center, Notification Center as product features
- Cloud backup, accounts, iOS as a surprise PR
- Replacing Riverpod or sqflite wholesale
- Adding GetIt, Bloc, Hive, or extra analytics vendors

## How to pick work

1. Search issues
2. Comment that you want to take it
3. Follow [FEATURE_DEVELOPMENT.md](FEATURE_DEVELOPMENT.md)
