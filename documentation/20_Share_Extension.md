# 20. Share Extension

Not an iOS share extension. **Android share target** on `MainActivity`:

- SEND text/plain
- SEND */*
- SEND_MULTIPLE */*
- `launchMode=singleTask`

Plugin: `receive_sharing_intent: 1.8.1`.

IO implementation `share_intake_io.dart`; stub on web. `IntakeActionHandler` routes to download, import files, or show text.
