import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// SoundCloud URL parsing, content type classification, URL normalization,
/// artist/track extraction, and security validation.
///
/// All tests are offline unit tests with no network dependency.
void main() {
  // ───────────────────────────────────────────────────────────────────────
  // Phase 1 — Platform detection
  // ───────────────────────────────────────────────────────────────────────

  group('Phase 1 — SoundCloud platform detection', () {
    test('SC-URL-001 soundcloud.com is SoundCloud', () {
      final uri = Uri.parse('https://soundcloud.com/artist/track');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.soundcloud);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
      expect(ContentProviderRegistry.platformLabel(uri), 'SoundCloud');
    });

    test('SC-URL-002 www.soundcloud.com is SoundCloud', () {
      final uri = Uri.parse('https://www.soundcloud.com/artist/track');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.soundcloud);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
    });

    test('SC-URL-003 m.soundcloud.com is SoundCloud', () {
      final uri = Uri.parse('https://m.soundcloud.com/artist/track');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.soundcloud);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
    });

    test('SC-URL-004 snd.sc short URL is SoundCloud', () {
      final uri = Uri.parse('https://snd.sc/abc123');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.soundcloud);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
    });

    test('SC-URL-005 api-v2.soundcloud.com is SoundCloud', () {
      final uri = Uri.parse('https://api-v2.soundcloud.com/tracks/123');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.soundcloud);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
    });

    test('SC-URL-006 non-SoundCloud host is rejected', () {
      final uri = Uri.parse('https://www.example.com/soundcloud/track');
      expect(SocialPlatform.fromUri(uri), isNull);
      expect(ContentProviderRegistry.canHandle(uri), isFalse);
    });

    test('SC-URL-007 youtube.com is NOT SoundCloud', () {
      final uri = Uri.parse('https://www.youtube.com/watch?v=abc');
      expect(SocialPlatform.fromUri(uri), isNot(SocialPlatform.soundcloud));
    });

    test('SC-URL-008 spotify.com is NOT SoundCloud', () {
      final uri = Uri.parse('https://open.spotify.com/track/abc');
      expect(SocialPlatform.fromUri(uri), isNot(SocialPlatform.soundcloud));
    });

    test('SC-URL-009 on.soundcloud.com short link is SoundCloud', () {
      final uri = Uri.parse('https://on.soundcloud.com/AbCdEf');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.soundcloud);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // Phase 2 — Content type classification
  // ───────────────────────────────────────────────────────────────────────

  group('Phase 2 — SoundCloud content type classification', () {
    test('SC-URL-010 home page is classified as HOME', () {
      final uri = Uri.parse('https://soundcloud.com/');
      expect(SoundCloudUri.classifyUrl(uri), SoundCloudContentType.home);
    });

    test('SC-URL-011 track URL is classified as TRACK', () {
      final uri = Uri.parse('https://soundcloud.com/artist/track-name');
      expect(SoundCloudUri.classifyUrl(uri), SoundCloudContentType.track);
    });

    test('SC-URL-012 profile URL is classified as PROFILE', () {
      final uri = Uri.parse('https://soundcloud.com/artist-name');
      expect(SoundCloudUri.classifyUrl(uri), SoundCloudContentType.profile);
    });

    test('SC-URL-013 playlist/set URL is classified as PLAYLIST', () {
      final uri =
          Uri.parse('https://soundcloud.com/artist/sets/playlist-name');
      expect(SoundCloudUri.classifyUrl(uri), SoundCloudContentType.playlist);
    });

    test('SC-URL-014 likes page is non-content', () {
      final uri = Uri.parse('https://soundcloud.com/artist/likes');
      expect(SoundCloudUri.classifyUrl(uri), SoundCloudContentType.nonContent);
    });

    test('SC-URL-015 tracks listing is non-content', () {
      final uri = Uri.parse('https://soundcloud.com/artist/tracks');
      expect(SoundCloudUri.classifyUrl(uri), SoundCloudContentType.nonContent);
    });

    test('SC-URL-016 reposts page is non-content', () {
      final uri = Uri.parse('https://soundcloud.com/artist/reposts');
      expect(SoundCloudUri.classifyUrl(uri), SoundCloudContentType.nonContent);
    });

    test('SC-URL-017 discover system page is non-content', () {
      final uri = Uri.parse('https://soundcloud.com/discover');
      expect(SoundCloudUri.classifyUrl(uri), SoundCloudContentType.nonContent);
    });

    test('SC-URL-018 search system page is non-content', () {
      final uri = Uri.parse('https://soundcloud.com/search');
      expect(SoundCloudUri.classifyUrl(uri), SoundCloudContentType.nonContent);
    });

    test('SC-URL-019 upload system page is non-content', () {
      final uri = Uri.parse('https://soundcloud.com/upload');
      expect(SoundCloudUri.classifyUrl(uri), SoundCloudContentType.nonContent);
    });

    test('SC-URL-020 stream system page is non-content', () {
      final uri = Uri.parse('https://soundcloud.com/stream');
      expect(SoundCloudUri.classifyUrl(uri), SoundCloudContentType.nonContent);
    });

    test('SC-URL-021 artist/sets listing without slug is non-content', () {
      final uri = Uri.parse('https://soundcloud.com/artist/sets');
      expect(SoundCloudUri.classifyUrl(uri), SoundCloudContentType.nonContent);
      expect(SoundCloudUri.isPlaylist(uri), isFalse);
    });

    test('SC-URL-022 /sets/INVALID is not a track', () {
      final uri = Uri.parse('https://soundcloud.com/sets/INVALID');
      expect(SoundCloudUri.classifyUrl(uri), SoundCloudContentType.nonContent);
      expect(SoundCloudUri.isTrack(uri), isFalse);
    });

    test('SC-URL-023 albums listing is non-content', () {
      final uri = Uri.parse('https://soundcloud.com/artist/albums');
      expect(SoundCloudUri.classifyUrl(uri), SoundCloudContentType.nonContent);
    });

    test('SC-URL-024 followers page is non-content', () {
      final uri = Uri.parse('https://soundcloud.com/artist/followers');
      expect(SoundCloudUri.classifyUrl(uri), SoundCloudContentType.nonContent);
    });

    test('SC-URL-025 short URL is classified as shortUrl', () {
      final uri = Uri.parse('https://on.soundcloud.com/AbCdEf');
      expect(SoundCloudUri.classifyUrl(uri), SoundCloudContentType.shortUrl);
      expect(SoundCloudUri.isShortUrl(uri), isTrue);
      expect(SoundCloudUri.isDownloadable(uri), isTrue);
    });

    test('SC-URL-026 album/set URL is a playlist', () {
      final uri = Uri.parse('https://soundcloud.com/artist/sets/album-name');
      expect(SoundCloudUri.classifyUrl(uri), SoundCloudContentType.playlist);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // Phase 3 — Artist/username extraction
  // ───────────────────────────────────────────────────────────────────────

  group('Phase 3 — Artist extraction', () {
    test('SC-URL-030 extracts artist from track URL', () {
      final uri = Uri.parse('https://soundcloud.com/flume/never-be-like-you');
      expect(SoundCloudUri.artistFromUri(uri), 'flume');
    });

    test('SC-URL-031 extracts artist from profile URL', () {
      final uri = Uri.parse('https://soundcloud.com/deadmau5');
      expect(SoundCloudUri.artistFromUri(uri), 'deadmau5');
    });

    test('SC-URL-032 extracts artist from playlist URL', () {
      final uri = Uri.parse('https://soundcloud.com/artist/sets/my-playlist');
      expect(SoundCloudUri.artistFromUri(uri), 'artist');
    });

    test('SC-URL-033 returns null for home page', () {
      final uri = Uri.parse('https://soundcloud.com/');
      expect(SoundCloudUri.artistFromUri(uri), isNull);
    });

    test('SC-URL-034 returns null for system pages', () {
      final uri = Uri.parse('https://soundcloud.com/discover');
      expect(SoundCloudUri.artistFromUri(uri), isNull);
    });

    test('SC-URL-035 artist with hyphens', () {
      final uri = Uri.parse('https://soundcloud.com/the-artist-name/track');
      expect(SoundCloudUri.artistFromUri(uri), 'the-artist-name');
    });

    test('SC-URL-036 artist with numbers', () {
      final uri = Uri.parse('https://soundcloud.com/artist123/track');
      expect(SoundCloudUri.artistFromUri(uri), 'artist123');
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // Phase 4 — Track slug extraction
  // ───────────────────────────────────────────────────────────────────────

  group('Phase 4 — Track slug extraction', () {
    test('SC-URL-040 extracts track slug from standard URL', () {
      final uri = Uri.parse('https://soundcloud.com/flume/never-be-like-you');
      expect(SoundCloudUri.trackSlugFromUri(uri), 'never-be-like-you');
    });

    test('SC-URL-041 returns null for profile URL', () {
      final uri = Uri.parse('https://soundcloud.com/flume');
      expect(SoundCloudUri.trackSlugFromUri(uri), isNull);
    });

    test('SC-URL-042 returns null for playlist URL', () {
      final uri = Uri.parse('https://soundcloud.com/flume/sets/my-set');
      expect(SoundCloudUri.trackSlugFromUri(uri), isNull);
    });

    test('SC-URL-043 track slug with numbers', () {
      final uri = Uri.parse('https://soundcloud.com/artist/track-2024');
      expect(SoundCloudUri.trackSlugFromUri(uri), 'track-2024');
    });

    test('SC-URL-044 complex track slug', () {
      final uri = Uri.parse(
          'https://soundcloud.com/artist/this-is-a-very-long-track-name-remix');
      expect(SoundCloudUri.trackSlugFromUri(uri),
          'this-is-a-very-long-track-name-remix');
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // Phase 5 — Playlist slug extraction
  // ───────────────────────────────────────────────────────────────────────

  group('Phase 5 — Playlist slug extraction', () {
    test('SC-URL-050 extracts playlist slug', () {
      final uri =
          Uri.parse('https://soundcloud.com/artist/sets/chill-vibes-2024');
      expect(SoundCloudUri.playlistSlugFromUri(uri), 'chill-vibes-2024');
    });

    test('SC-URL-051 returns null for non-playlist URL', () {
      final uri = Uri.parse('https://soundcloud.com/artist/track');
      expect(SoundCloudUri.playlistSlugFromUri(uri), isNull);
    });

    test('SC-URL-052 returns null for profile URL', () {
      final uri = Uri.parse('https://soundcloud.com/artist');
      expect(SoundCloudUri.playlistSlugFromUri(uri), isNull);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // Phase 6 — Content type boolean helpers
  // ───────────────────────────────────────────────────────────────────────

  group('Phase 6 — Boolean classification helpers', () {
    test('SC-URL-060 isTrack for track URL', () {
      final uri = Uri.parse('https://soundcloud.com/artist/track');
      expect(SoundCloudUri.isTrack(uri), isTrue);
      expect(SoundCloudUri.isPlaylist(uri), isFalse);
      expect(SoundCloudUri.isProfile(uri), isFalse);
    });

    test('SC-URL-061 isPlaylist for set URL', () {
      final uri = Uri.parse('https://soundcloud.com/artist/sets/playlist');
      expect(SoundCloudUri.isPlaylist(uri), isTrue);
      expect(SoundCloudUri.isTrack(uri), isFalse);
      expect(SoundCloudUri.isProfile(uri), isFalse);
    });

    test('SC-URL-062 isProfile for profile URL', () {
      final uri = Uri.parse('https://soundcloud.com/artist');
      expect(SoundCloudUri.isProfile(uri), isTrue);
      expect(SoundCloudUri.isTrack(uri), isFalse);
      expect(SoundCloudUri.isPlaylist(uri), isFalse);
    });

    test('SC-URL-063 none for home page', () {
      final uri = Uri.parse('https://soundcloud.com/');
      expect(SoundCloudUri.isTrack(uri), isFalse);
      expect(SoundCloudUri.isPlaylist(uri), isFalse);
      expect(SoundCloudUri.isProfile(uri), isFalse);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // Phase 7 — URL normalization
  // ───────────────────────────────────────────────────────────────────────

  group('Phase 7 — URL normalization', () {
    test('SC-URL-070 strips UTM tracking params', () {
      final uri = Uri.parse(
        'https://soundcloud.com/artist/track?utm_source=share&utm_medium=social',
      );
      final normalized = SoundCloudUri.normalize(uri);
      expect(normalized.queryParameters.containsKey('utm_source'), isFalse);
      expect(normalized.queryParameters.containsKey('utm_medium'), isFalse);
    });

    test('SC-URL-071 strips si param', () {
      final uri = Uri.parse(
        'https://soundcloud.com/artist/track?si=abc123',
      );
      final normalized = SoundCloudUri.normalize(uri);
      expect(normalized.queryParameters.containsKey('si'), isFalse);
    });

    test('SC-URL-072 strips in param (tracking)', () {
      final uri = Uri.parse(
        'https://soundcloud.com/artist/track?in=artist/sets/playlist',
      );
      final normalized = SoundCloudUri.normalize(uri);
      expect(normalized.queryParameters.containsKey('in'), isFalse);
    });

    test('SC-URL-073 normalizes host to soundcloud.com', () {
      final uri =
          Uri.parse('https://www.soundcloud.com/artist/track');
      final normalized = SoundCloudUri.normalize(uri);
      expect(normalized.host, 'soundcloud.com');
    });

    test('SC-URL-074 snd.sc short URL is not normalized (requires redirect)', () {
      final uri = Uri.parse('https://snd.sc/abc123');
      final normalized = SoundCloudUri.normalize(uri);
      expect(normalized.host, 'snd.sc');
    });

    test('SC-URL-075 ensures https scheme', () {
      final uri = Uri.parse('http://soundcloud.com/artist/track');
      final normalized = SoundCloudUri.normalize(uri);
      expect(normalized.scheme, 'https');
    });

    test('SC-URL-076 strips fbclid tracking param', () {
      final uri = Uri.parse(
        'https://soundcloud.com/artist/track?fbclid=IwAR123',
      );
      final normalized = SoundCloudUri.normalize(uri);
      expect(normalized.queryParameters.containsKey('fbclid'), isFalse);
    });

    test('SC-URL-077 preserves secret_token', () {
      final uri = Uri.parse(
        'https://soundcloud.com/artist/track?secret_token=s-abc',
      );
      final normalized = SoundCloudUri.normalize(uri);
      expect(normalized.queryParameters['secret_token'], 's-abc');
    });

    test('SC-URL-078 on.soundcloud.com is not rewritten', () {
      final uri = Uri.parse('https://on.soundcloud.com/AbCdEf');
      final normalized = SoundCloudUri.normalize(uri);
      expect(normalized.host, 'on.soundcloud.com');
    });

    test('SC-URL-079 m.soundcloud.com normalizes to soundcloud.com', () {
      final uri = Uri.parse('https://m.soundcloud.com/artist/track');
      final normalized = SoundCloudUri.normalize(uri);
      expect(normalized.host, 'soundcloud.com');
      expect(normalized.path, '/artist/track');
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // Phase 8 — Content identity (deduplication)
  // ───────────────────────────────────────────────────────────────────────

  group('Phase 8 — Content identity', () {
    test('SC-URL-080 same track with/without params has same identity', () {
      final uri1 = Uri.parse('https://soundcloud.com/artist/track');
      final uri2 = Uri.parse(
          'https://soundcloud.com/artist/track?utm_source=twitter');
      expect(
        SoundCloudUri.contentIdentity(SoundCloudUri.normalize(uri1)),
        SoundCloudUri.contentIdentity(SoundCloudUri.normalize(uri2)),
      );
    });

    test('SC-URL-081 different tracks have different identities', () {
      final uri1 = Uri.parse('https://soundcloud.com/artist/track-1');
      final uri2 = Uri.parse('https://soundcloud.com/artist/track-2');
      expect(
        SoundCloudUri.contentIdentity(uri1),
        isNot(SoundCloudUri.contentIdentity(uri2)),
      );
    });

    test('SC-URL-082 track identity format', () {
      final uri = Uri.parse('https://soundcloud.com/flume/never-be-like-you');
      expect(
        SoundCloudUri.contentIdentity(uri),
        'soundcloud:track:flume/never-be-like-you',
      );
    });

    test('SC-URL-083 playlist identity format', () {
      final uri = Uri.parse('https://soundcloud.com/artist/sets/my-playlist');
      expect(
        SoundCloudUri.contentIdentity(uri),
        'soundcloud:playlist:artist/my-playlist',
      );
    });

    test('SC-URL-084 profile identity format', () {
      final uri = Uri.parse('https://soundcloud.com/flume');
      expect(
        SoundCloudUri.contentIdentity(uri),
        'soundcloud:profile:flume',
      );
    });

    test('SC-URL-085 home page has null identity', () {
      final uri = Uri.parse('https://soundcloud.com/');
      expect(SoundCloudUri.contentIdentity(uri), isNull);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // Phase 9 — Security validation
  // ───────────────────────────────────────────────────────────────────────

  group('Phase 9 — Security validation', () {
    test('SC-URL-090 javascript: URL is not SoundCloud', () {
      final uri = Uri.parse('javascript:alert(1)');
      expect(SocialPlatform.fromUri(uri), isNull);
      expect(ContentProviderRegistry.canHandle(uri), isFalse);
    });

    test('SC-URL-091 file: URL is not SoundCloud', () {
      final uri = Uri.parse('file:///etc/passwd');
      expect(SocialPlatform.fromUri(uri), isNull);
      expect(ContentProviderRegistry.canHandle(uri), isFalse);
    });

    test('SC-URL-092 localhost is not SoundCloud', () {
      final uri = Uri.parse('http://localhost/soundcloud');
      expect(SocialPlatform.fromUri(uri), isNull);
      expect(ContentProviderRegistry.canHandle(uri), isFalse);
    });

    test('SC-URL-093 127.0.0.1 is not SoundCloud', () {
      final uri = Uri.parse('http://127.0.0.1:8080/soundcloud');
      expect(SocialPlatform.fromUri(uri), isNull);
      expect(ContentProviderRegistry.canHandle(uri), isFalse);
    });

    test('SC-URL-094 private IP is not SoundCloud', () {
      final uri = Uri.parse('http://192.168.1.1/soundcloud');
      expect(SocialPlatform.fromUri(uri), isNull);
      expect(ContentProviderRegistry.canHandle(uri), isFalse);
    });

    test('SC-URL-095 path traversal in track slug is resolved by URI parser', () {
      // Dart's Uri.parse resolves .. segments, preventing path traversal.
      final uri = Uri.parse(
          'https://soundcloud.com/artist/../../../../etc/passwd');
      // The URI parser normalizes the path, so no actual traversal occurs.
      // The slug returned is just the last resolved segment.
      final slug = SoundCloudUri.trackSlugFromUri(uri);
      expect(slug, isNotNull);
      expect(slug!.contains('..'), isFalse);
    });

    test('SC-URL-096 very long URL does not crash', () {
      final longPath = 'a' * 5000;
      final uri = Uri.parse('https://soundcloud.com/artist/$longPath');
      expect(() => SoundCloudUri.classifyUrl(uri), returnsNormally);
      expect(SoundCloudUri.isTrack(uri), isTrue);
    });

    test('SC-URL-097 empty path is home', () {
      final uri = Uri.parse('https://soundcloud.com');
      expect(SoundCloudUri.classifyUrl(uri), SoundCloudContentType.home);
    });

    test('SC-URL-098 encoded track URL still classifies as track', () {
      final uri = Uri.parse(
        'https://soundcloud.com/artist/track%2Dname',
      );
      expect(SoundCloudUri.classifyUrl(uri), SoundCloudContentType.track);
      expect(SoundCloudUri.trackSlugFromUri(uri), 'track-name');
    });

    test('SC-URL-099 example.com audio is not SoundCloud', () {
      final uri = Uri.parse('https://example.com/audio.mp3');
      expect(SocialPlatform.fromUri(uri), isNull);
    });
  });
}
