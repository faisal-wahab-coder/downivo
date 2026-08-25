# Reddit Security Tests

## Test File
`packages/download_engine/test/reddit_security_test.dart`

## Coverage

`javascript:`, `file:`, `data:` rejected; localhost / 127.0.0.1 / private IPs are not Reddit; path traversal, slash/colon/quotes, Arabic, emoji, long titles sanitized; encoded post URLs still extract ID.
