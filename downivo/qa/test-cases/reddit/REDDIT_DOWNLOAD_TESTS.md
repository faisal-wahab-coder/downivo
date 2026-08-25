# Reddit Download Tests

## Test File
`packages/download_engine/test/reddit_download_test.dart`

## Coverage

Shared Download Engine state machine:

QUEUED → PREPARING → DOWNLOADING → VERIFYING → COMPLETED

Also pause/resume, cancel, fail/retry, independent gallery item states, MIME→extension mapping.
