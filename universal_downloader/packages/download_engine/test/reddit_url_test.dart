import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reddit URL parsing, classification, normalization, post ID extraction,
/// and platform detection. All tests are offline with no network dependency.
void main() {
  group('Phase 1 — Reddit platform detection', () {
    test('RD-URL-001 www.reddit.com is Reddit', () {
      final uri =
          Uri.parse('https://www.reddit.com/r/pics/comments/abc123/slug/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.reddit);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
      expect(ContentProviderRegistry.platformLabel(uri), 'Reddit');
    });

    test('RD-URL-002 reddit.com (no www) is Reddit', () {
      final uri = Uri.parse('https://reddit.com/r/pics/comments/abc123/slug/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.reddit);
    });

    test('RD-URL-003 old.reddit.com is Reddit', () {
      final uri =
          Uri.parse('https://old.reddit.com/r/pics/comments/abc123/slug/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.reddit);
    });

    test('RD-URL-004 m.reddit.com is Reddit', () {
      final uri = Uri.parse('https://m.reddit.com/r/pics/comments/abc123/slug/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.reddit);
    });

    test('RD-URL-005 np.reddit.com is Reddit', () {
      final uri =
          Uri.parse('https://np.reddit.com/r/pics/comments/abc123/slug/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.reddit);
    });

    test('RD-URL-006 redd.it short URL is Reddit', () {
      final uri = Uri.parse('https://redd.it/abc123');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.reddit);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
    });

    test('RD-URL-007 i.redd.it direct media is Reddit', () {
      final uri = Uri.parse('https://i.redd.it/photo.jpg');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.reddit);
    });

    test('RD-URL-008 v.redd.it direct media is Reddit', () {
      final uri = Uri.parse('https://v.redd.it/abc123/DASH_720.mp4');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.reddit);
    });

    test('RD-URL-009 preview.redd.it is Reddit', () {
      final uri = Uri.parse('https://preview.redd.it/abc.jpg?width=100');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.reddit);
    });

    test('RD-URL-010 non-Reddit host is rejected', () {
      final uri = Uri.parse('https://www.example.com/r/pics/comments/abc/');
      expect(SocialPlatform.fromUri(uri), isNull);
      expect(ContentProviderRegistry.canHandle(uri), isFalse);
    });

    test('RD-URL-011 youtube.com is NOT Reddit', () {
      final uri = Uri.parse('https://www.youtube.com/watch?v=abc');
      expect(SocialPlatform.fromUri(uri), isNot(SocialPlatform.reddit));
    });
  });

  group('Phase 2 — Content type classification', () {
    test('RD-URL-020 home page is HOME', () {
      expect(
        RedditUri.classifyUrl(Uri.parse('https://www.reddit.com/')),
        RedditContentType.home,
      );
      expect(
        RedditResolver.classifyUrl(Uri.parse('https://www.reddit.com/')),
        RedditContentType.home,
      );
    });

    test('RD-URL-021 subreddit URL is SUBREDDIT', () {
      expect(
        RedditUri.classifyUrl(Uri.parse('https://www.reddit.com/r/pics/')),
        RedditContentType.subreddit,
      );
    });

    test('RD-URL-022 canonical post URL is POST', () {
      expect(
        RedditUri.classifyUrl(
          Uri.parse('https://www.reddit.com/r/pics/comments/abc123/a_slug/'),
        ),
        RedditContentType.post,
      );
    });

    test('RD-URL-023 comment URL is COMMENT', () {
      expect(
        RedditUri.classifyUrl(
          Uri.parse(
            'https://www.reddit.com/r/pics/comments/abc123/slug/cmt456/',
          ),
        ),
        RedditContentType.comment,
      );
    });

    test('RD-URL-024 redd.it is SHORT', () {
      expect(
        RedditUri.classifyUrl(Uri.parse('https://redd.it/abc123')),
        RedditContentType.short,
      );
    });

    test('RD-URL-025 share URL is SHARE', () {
      expect(
        RedditUri.classifyUrl(
          Uri.parse('https://www.reddit.com/r/pics/s/AbCdEfG'),
        ),
        RedditContentType.share,
      );
    });

    test('RD-URL-026 i.redd.it is DIRECT_MEDIA', () {
      expect(
        RedditUri.classifyUrl(Uri.parse('https://i.redd.it/x.jpg')),
        RedditContentType.directMedia,
      );
    });

    test('RD-URL-027 user profile is USER', () {
      expect(
        RedditUri.classifyUrl(Uri.parse('https://www.reddit.com/user/spez/')),
        RedditContentType.user,
      );
      expect(
        RedditUri.classifyUrl(Uri.parse('https://www.reddit.com/u/spez/')),
        RedditContentType.user,
      );
    });

    test('RD-URL-028 /r/ with no subreddit is non-content', () {
      expect(
        RedditUri.classifyUrl(Uri.parse('https://www.reddit.com/r/')),
        RedditContentType.nonContent,
      );
    });

    test('RD-URL-029 /gallery/<id> is POST', () {
      expect(
        RedditUri.classifyUrl(
          Uri.parse('https://www.reddit.com/gallery/abc123'),
        ),
        RedditContentType.post,
      );
    });

    test('RD-URL-030 search is SEARCH', () {
      expect(
        RedditUri.classifyUrl(
          Uri.parse('https://www.reddit.com/search/?q=cats'),
        ),
        RedditContentType.search,
      );
    });
  });

  group('Phase 3 — Post ID extraction (slug ignored)', () {
    test('RD-URL-040 extracts post ID from canonical URL', () {
      final uri = Uri.parse(
        'https://www.reddit.com/r/pics/comments/abc123/this_slug_is_ignored/',
      );
      expect(RedditUri.postIdFromUri(uri), 'abc123');
    });

    test('RD-URL-041 extracts post ID without slug', () {
      final uri =
          Uri.parse('https://www.reddit.com/r/pics/comments/abc123/');
      expect(RedditUri.postIdFromUri(uri), 'abc123');
    });

    test('RD-URL-042 extracts post ID from /comments/<id>/', () {
      final uri = Uri.parse('https://www.reddit.com/comments/xyz789/');
      expect(RedditUri.postIdFromUri(uri), 'xyz789');
    });

    test('RD-URL-043 extracts post ID from redd.it', () {
      expect(RedditUri.postIdFromUri(Uri.parse('https://redd.it/abc123')), 'abc123');
    });

    test('RD-URL-044 extracts post ID from comment permalink', () {
      final uri = Uri.parse(
        'https://www.reddit.com/r/pics/comments/abc123/slug/commentid/',
      );
      expect(RedditUri.postIdFromUri(uri), 'abc123');
    });

    test('RD-URL-045 home has no post ID', () {
      expect(
        RedditUri.postIdFromUri(Uri.parse('https://www.reddit.com/')),
        isNull,
      );
    });

    test('RD-URL-046 subreddit has no post ID', () {
      expect(
        RedditUri.postIdFromUri(Uri.parse('https://www.reddit.com/r/pics/')),
        isNull,
      );
    });

    test('RD-URL-047 share URL has no post ID', () {
      expect(
        RedditUri.postIdFromUri(
          Uri.parse('https://www.reddit.com/r/pics/s/AbCdEfG'),
        ),
        isNull,
      );
    });

    test('RD-URL-048 gallery URL extracts post ID', () {
      expect(
        RedditUri.postIdFromUri(
          Uri.parse('https://www.reddit.com/gallery/gal999'),
        ),
        'gal999',
      );
    });
  });

  group('Phase 4 — Subreddit extraction', () {
    test('RD-URL-050 extracts subreddit from post URL', () {
      final uri =
          Uri.parse('https://www.reddit.com/r/AskReddit/comments/abc/slug/');
      expect(RedditUri.subredditFromUri(uri), 'AskReddit');
    });

    test('RD-URL-051 extracts subreddit from subreddit URL', () {
      expect(
        RedditUri.subredditFromUri(Uri.parse('https://www.reddit.com/r/pics/')),
        'pics',
      );
    });

    test('RD-URL-052 home has no subreddit', () {
      expect(
        RedditUri.subredditFromUri(Uri.parse('https://www.reddit.com/')),
        isNull,
      );
    });

    test('RD-URL-053 redd.it has no subreddit', () {
      expect(
        RedditUri.subredditFromUri(Uri.parse('https://redd.it/abc123')),
        isNull,
      );
    });
  });

  group('Phase 5 — URL normalization', () {
    test('RD-URL-060 strips tracking params', () {
      final uri = Uri.parse(
        'https://www.reddit.com/r/pics/comments/abc123/slug/?utm_source=share&utm_medium=web2x&rdt=123',
      );
      final normalized = RedditUri.normalize(uri);
      expect(normalized.queryParameters.containsKey('utm_source'), isFalse);
      expect(normalized.queryParameters.containsKey('rdt'), isFalse);
      expect(RedditUri.postIdFromUri(normalized), 'abc123');
    });

    test('RD-URL-061 canonicalizes old.reddit.com to www', () {
      final uri =
          Uri.parse('https://old.reddit.com/r/pics/comments/abc123/slug/');
      final normalized = RedditUri.normalize(uri);
      expect(normalized.host, 'www.reddit.com');
    });

    test('RD-URL-062 canonicalizes m.reddit.com to www', () {
      final uri =
          Uri.parse('https://m.reddit.com/r/pics/comments/abc123/slug/');
      expect(RedditUri.normalize(uri).host, 'www.reddit.com');
    });

    test('RD-URL-063 drops slug from canonical path', () {
      final uri = Uri.parse(
        'https://www.reddit.com/r/pics/comments/abc123/this_long_slug/',
      );
      final normalized = RedditUri.normalize(uri);
      expect(normalized.path, '/r/pics/comments/abc123/');
      expect(normalized.path, isNot(contains('this_long_slug')));
    });

    test('RD-URL-064 comment URL normalizes to parent post', () {
      final uri = Uri.parse(
        'https://www.reddit.com/r/pics/comments/abc123/slug/cmtid/',
      );
      final normalized = RedditUri.normalize(uri);
      expect(normalized.path, '/r/pics/comments/abc123/');
    });

    test('RD-URL-065 redd.it is left as short URL', () {
      final uri = Uri.parse('https://redd.it/abc123');
      final normalized = RedditUri.normalize(uri);
      expect(normalized.host, 'redd.it');
      expect(RedditUri.postIdFromUri(normalized), 'abc123');
    });

    test('RD-URL-066 SocialUrlUtils uses Reddit normalize', () {
      final uri = Uri.parse(
        'https://old.reddit.com/r/pics/comments/abc123/slug/?utm_source=x',
      );
      final targets = SocialUrlUtils.fetchTargets(uri, SocialPlatform.reddit);
      expect(targets.first.host, 'www.reddit.com');
    });
  });

  group('Phase 6 — JSON endpoint (slug-independent)', () {
    test('RD-URL-070 json endpoint uses post ID not slug', () {
      final uri = Uri.parse(
        'https://www.reddit.com/r/pics/comments/abc123/ignored_slug/',
      );
      expect(
        RedditUri.jsonEndpoint(uri).toString(),
        'https://www.reddit.com/r/pics/comments/abc123.json',
      );
    });

    test('RD-URL-071 redd.it maps to comments JSON', () {
      expect(
        RedditUri.jsonEndpoint(Uri.parse('https://redd.it/abc123')).toString(),
        'https://www.reddit.com/comments/abc123.json',
      );
    });

    test('RD-URL-072 home has no json endpoint', () {
      expect(
        RedditUri.jsonEndpoint(Uri.parse('https://www.reddit.com/')),
        isNull,
      );
    });

    test('RD-URL-073 subreddit has no json endpoint', () {
      expect(
        RedditUri.jsonEndpoint(Uri.parse('https://www.reddit.com/r/pics/')),
        isNull,
      );
    });
  });

  group('Phase 7 — Duplicate identity', () {
    test('RD-URL-080 slug variants share identity', () {
      final a = Uri.parse(
        'https://www.reddit.com/r/pics/comments/abc123/slug_one/',
      );
      final b = Uri.parse(
        'https://www.reddit.com/r/pics/comments/abc123/slug_two/?utm_source=share',
      );
      expect(
        RedditUri.contentIdentity(a),
        RedditUri.contentIdentity(RedditUri.normalize(b)),
      );
      expect(RedditUri.contentIdentity(a), 'reddit:post:abc123');
    });

    test('RD-URL-081 redd.it shares identity with canonical post', () {
      expect(
        RedditUri.contentIdentity(Uri.parse('https://redd.it/abc123')),
        RedditUri.contentIdentity(
          Uri.parse('https://www.reddit.com/r/pics/comments/abc123/slug/'),
        ),
      );
    });

    test('RD-URL-082 different posts have different identities', () {
      expect(
        RedditUri.contentIdentity(
          Uri.parse('https://www.reddit.com/r/pics/comments/aaa/x/'),
        ),
        isNot(
          RedditUri.contentIdentity(
            Uri.parse('https://www.reddit.com/r/pics/comments/bbb/x/'),
          ),
        ),
      );
    });
  });

  group('Phase 8 — Downloadable vs non-downloadable', () {
    test('RD-URL-090 home is not downloadable', () {
      expect(
        RedditUri.isDownloadable(Uri.parse('https://www.reddit.com/')),
        isFalse,
      );
    });

    test('RD-URL-091 subreddit is not downloadable', () {
      expect(
        RedditUri.isDownloadable(Uri.parse('https://www.reddit.com/r/pics/')),
        isFalse,
      );
    });

    test('RD-URL-092 post is downloadable', () {
      expect(
        RedditUri.isDownloadable(
          Uri.parse('https://www.reddit.com/r/pics/comments/abc123/slug/'),
        ),
        isTrue,
      );
    });

    test('RD-URL-093 invalid path is not downloadable', () {
      expect(
        RedditUri.isDownloadable(Uri.parse('https://reddit.com/INVALID')),
        isFalse,
      );
    });
  });

  group('Phase 9 — Fetch targets', () {
    test('RD-URL-100 fetch targets include json endpoint', () {
      final uri =
          Uri.parse('https://www.reddit.com/r/pics/comments/abc123/slug/');
      final targets = SocialUrlUtils.fetchTargets(uri, SocialPlatform.reddit);
      expect(
        targets.any((t) => t.path.endsWith('.json') || t.path.contains('abc123')),
        isTrue,
      );
    });
  });
}
