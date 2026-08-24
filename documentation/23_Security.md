# 23. Security

- No accounts, no cloud
- Permissions minimized (internet, notifications, camera, FG service, wake lock)
- Clipboard opt-in
- Do not fetch WhatsApp private media CDNs
- Do not break DRM
- Release R8/ProGuard
- `key.properties` gitignored; ship `key.properties.example`
- WebView is for browsing + detection, not a generic file-exfil tool
