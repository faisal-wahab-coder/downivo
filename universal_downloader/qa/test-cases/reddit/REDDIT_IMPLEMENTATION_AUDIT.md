See: `qa/test-reports/REDDIT_IMPLEMENTATION_AUDIT.md`

Pre-implementation gaps that were closed in this phase:

- Images, GIFs, galleries, mixed MIME
- `discoverAll` wiring
- `RedditUri` classification / post ID / normalize / `redd.it` JSON endpoint
- Home/subreddit not scraped as downloads
- Audio stream identification (muxing is a documented platform limitation)
