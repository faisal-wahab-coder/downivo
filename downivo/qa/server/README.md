# Download test server

Local HTTP fixture used by automated download tests and manual QA.

Automated tests start this server in-process and inject a real `HttpClient` into Dio. Flutter's `TestWidgetsFlutterBinding` otherwise stubs every request as HTTP 400.

```bash
dart run qa/server/bin/serve.dart --port 8765
```

| Path | Behavior |
|------|----------|
| `/health` | 200 `ok` |
| `/files/sample.bin` | 64 KiB binary, Range-aware |
| `/files/small.txt` | Small text |
| `/files/video.mp4` | `video/mp4` |
| `/slow/sample.bin` | Chunked with delay |
| `/no-range/sample.bin` | Ignores Range, always 200 |
| `/redirect/sample.bin` | 302 → `/files/sample.bin` |
| `/status/{code}` | Exact status |
| `/headers/disposition` | `filename="report.pdf"` |
| `/headers/utf8-name` | `filename*=UTF-8''café.bin` |
| `/headers/html` | `text/html` |
| `/mismatch/file.bin` | Content-Length 100, 10-byte body |
