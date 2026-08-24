See: `qa/test-reports/LINKEDIN_IMPLEMENTATION_AUDIT.md`

Pre-implementation gaps that were closed in this phase:

- Dedicated `LinkedInResolver` (was host detection + generic `og:video` only)
- `LinkedInUri` classification / activity ID / normalize / `lnkd.in` / licdn CDN
- Progressive MP4 video; HLS and player `og:video` skipped
- Highest exposed DMS images; logos and profile photos skipped
- Multi-image `discoverAll` with order and unique filenames
- Document PDF when publicly exposed
- Home / feed / profile / company / article not scraped as downloads
