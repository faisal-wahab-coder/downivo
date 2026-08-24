# M9 Production Release — Manual QA Checklist

Per NFR-496. Complete on a physical Android device (API 29+) before shipping **v1.1.0** to Google Play.

Automated suites and the download fixture server live in `qa/`. Run `bash qa/runner/qa_runner.sh` before this device pass.

## Onboarding & shell

- [ ] Fresh install shows onboarding; completing it lands on Home with bottom navigation
- [ ] All five tabs navigate correctly (Home, Downloads, Browser, Files, Settings)
- [ ] Dark mode toggle in Settings applies immediately

## Downloads

- [ ] Add URL wizard validates invalid URLs and accepts valid HTTP/HTTPS links
- [ ] Download queues, shows progress, and completes (or fails gracefully offline)
- [ ] Pause / resume / cancel / retry work on active and failed items
- [ ] Reorder queued downloads via drag handle
- [ ] Download history screen lists completed, failed, and cancelled entries
- [ ] Clear history removes records only — files remain in Files tab



## Browser

- [ ] Address bar navigation, back/forward, refresh, and tabs work
- [ ] Detected download links open the download wizard



## Files

- [ ] Category folders, breadcrumbs, search, and filters behave correctly
- [ ] Open, share, rename, move, delete actions work on sample files
- [ ] Import banner appears for unsorted files and import succeeds



## Intake

- [ ] Copy a URL — clipboard prompt appears (when enabled in Settings)
- [ ] QR scanner reads a URL and offers download / browser actions
- [ ] Share a link from another app into Universal Downloader



## Background & recovery

- [ ] Foreground notification shows during active download
- [ ] Force-stop and relaunch — interrupted downloads recover to queued



## Accessibility

- [ ] TalkBack reads screen titles and icon button tooltips
- [ ] Touch targets are comfortably tappable (48dp minimum)



## Performance

- [ ] Cold start completes within acceptable time (see Settings → Performance)
- [ ] Large file lists scroll smoothly without jank



## Sign-off


| Role        | Name | Date | Pass |
| ----------- | ---- | ---- | ---- |
| QA          |      |      |      |
| Engineering |      |      |      |


