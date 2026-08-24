# 15. Download Engine

See 11.4, 11.5, 12.10, 12.11.

## User-visible behavior

- Validate http/https
- Social resolve or direct GET
- Queue max 3
- Pause/resume Range
- Cancel, retry (3), pause-all, resume-all
- Progress: percent, bytes, speed, ETA (throttled 250ms)
- Persist every state change
- Restore on startup
- Multi-item selection
- Format/quality preferences
- Filename from headers/URL/user
- Crash recovery + integrity verifying status

## HTTP

Dio. Range parser. Optional extra headers from resolvers. 30s connect / 30m receive.

Flutter Web routes Dio through a loopback CORS proxy (`apps/web/tool/cors_proxy.dart`, default `http://127.0.0.1:8787`) so the same social URL resolvers as Android can send `User-Agent` / `Referer`. Disable with `--dart-define=UD_WEB_PROXY=`.

## Files to create (minimum)

```
lib/download_engine.dart
lib/src/download_manager.dart
lib/src/download_repository.dart
lib/src/download_error_formatter.dart
lib/src/filename_resolver.dart
lib/src/range_response_parser.dart
lib/src/url_validator.dart
lib/src/models/download_task.dart
lib/src/content_providers/  (registry + 16 resolvers + models)
```

`download_engine` is the largest package (~208 Dart files including tests). Tests are part of the replica quality bar.
