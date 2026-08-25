# Downivo Web

Flutter Web host for the same Clean Architecture packages as Android.

Social and site URLs need a local reverse proxy (browsers cannot set
`User-Agent` and most origins block CORS). Start the proxy, then Chrome:

```bash
cd downivo/apps/web
dart run tool/cors_proxy.dart
```

In a second terminal:

```bash
cd downivo/apps/web
flutter pub get
flutter run -d chrome
```

Or use `./run_chrome.sh` to start both.

`web/sqlite3.wasm` is required for SQLite in the browser.

Disable the proxy with `--dart-define=UD_WEB_PROXY=` (direct file URLs only).

Browser limits:

- Downloads run only while the tab is open
- Files stay in this session until you use Save to disk in Files
