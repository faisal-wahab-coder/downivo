# Security Policy

## Supported Versions

| Version | Supported |
| ------- | --------- |
| 1.2.x   | Yes — current production (`1.2.0+4`) |
| 1.1.x   | No |
| 1.0.x   | No |
| < 1.0   | No |

Security fixes are applied on the current production line only, unless a maintainer explicitly backports them.

## How to Report a Vulnerability

**Do not** open a public GitHub issue for security vulnerabilities.

Prefer, in order:

1. **[GitHub Security Advisories](https://github.com/faisal-wahab-coder/downivo/security/advisories/new)** — Security tab → Report a vulnerability (enable private reporting on the repository)
2. A private maintainer contact that the owner publishes below

```text
Security contact (configure before public release):
  Use GitHub private vulnerability reporting, or replace this line with an address you monitor
```

Include:

- Description of the issue
- Affected version and platform (Android / Web)
- Steps to reproduce
- Impact (data exposure, crash, privilege, etc.)
- Any suggested fix

You should receive an acknowledgement when a maintainer sees the report. Timing depends on volunteer availability.

## What not to post publicly

Do not include in issues, pull requests, or discussions:

- Passwords, API keys, tokens, cookies, or session material
- Private `google-services.json` contents or signing keystores
- Personal information, private URLs, or downloaded file contents
- Working exploit PoCs for unpatched issues
- Full crash dumps that contain URLs or tokens

## Responsible disclosure

Please allow maintainers time to investigate and ship a fix before publishing details. Do not use this project to attack third-party services, bypass DRM, or access private authenticated content.

## Examples of security issues

In scope:

- Secrets or credentials committed to the repository
- Path traversal or unsafe file writes in `storage` / `FileStore`
- Intent-filter handling that executes unexpected content
- Telemetry that sends URLs, tokens, or file contents despite the sanitizer
- Foreground-service or WebView issues that expose local files
- Dependency vulnerabilities with a realistic exploit path in this app

Out of scope (unless they cause a local vulnerability):

- Third-party site ToS or resolver breakage
- Social platforms changing their HTML/API
- User choosing to download content they are not authorized to access

## Application notes

- There are **no user accounts**. Data stays on device.
- Crashlytics and PostHog are optional and must not receive URLs or tokens (`packages/analytics` privacy sanitizer).
- `key.properties` and `google-services.json` are gitignored; only `*.example` files are committed.
- Android release signing is local. Public CI produces debug-signed AABs only.

See [`documentation/23_Security.md`](documentation/23_Security.md) and [`docs/GIT_HISTORY_SECURITY.md`](docs/GIT_HISTORY_SECURITY.md).
