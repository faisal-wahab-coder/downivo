import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SocialPlatform', () {
    test('detects major social hosts', () {
      expect(
        SocialPlatform.fromUri(
          Uri.parse('https://www.youtube.com/watch?v=abc'),
        ),
        SocialPlatform.youtube,
      );
      expect(
        SocialPlatform.fromUri(
          Uri.parse('https://www.tiktok.com/@user/video/123'),
        ),
        SocialPlatform.tiktok,
      );
      expect(
        SocialPlatform.fromUri(
          Uri.parse('https://www.instagram.com/reel/abc123/'),
        ),
        SocialPlatform.instagram,
      );
      expect(
        SocialPlatform.fromUri(Uri.parse('https://x.com/user/status/1')),
        SocialPlatform.twitter,
      );
      expect(
        SocialPlatform.fromUri(Uri.parse('https://www.facebook.com/watch/?v=1')),
        SocialPlatform.facebook,
      );
      expect(
        SocialPlatform.fromUri(
          Uri.parse('https://www.reddit.com/r/test/comments/abc/post/'),
        ),
        SocialPlatform.reddit,
      );
      expect(
        SocialPlatform.fromUri(Uri.parse('https://vimeo.com/76979871')),
        SocialPlatform.vimeo,
      );
      expect(
        SocialPlatform.fromUri(
          Uri.parse('https://player.vimeo.com/video/76979871'),
        ),
        SocialPlatform.vimeo,
      );
      expect(
        SocialPlatform.fromUri(Uri.parse('https://www.twitch.tv/videos/123')),
        SocialPlatform.twitch,
      );
      expect(
        SocialPlatform.fromUri(
          Uri.parse('https://clips.twitch.tv/AwkwardHelplessSalamanderSwiftRage'),
        ),
        SocialPlatform.twitch,
      );
      expect(
        SocialPlatform.fromUri(
          Uri.parse(
            'https://www.linkedin.com/posts/linkedin_activity-7046513282177392640-abcd',
          ),
        ),
        SocialPlatform.linkedin,
      );
      expect(
        SocialPlatform.fromUri(Uri.parse('https://lnkd.in/abc123')),
        SocialPlatform.linkedin,
      );
      expect(
        SocialPlatform.fromUri(Uri.parse('https://t.me/telegram/1')),
        SocialPlatform.telegram,
      );
      expect(
        SocialPlatform.fromUri(Uri.parse('tg://resolve?domain=telegram&post=1')),
        SocialPlatform.telegram,
      );
      expect(
        SocialPlatform.fromUri(
          Uri.parse('https://www.snapchat.com/spotlight/abc'),
        ),
        SocialPlatform.snapchat,
      );
      expect(
        SocialPlatform.fromUri(Uri.parse('https://t.snapchat.com/abc123')),
        SocialPlatform.snapchat,
      );
      expect(
        SocialPlatform.fromUri(Uri.parse('https://wa.me/15555550100')),
        SocialPlatform.whatsapp,
      );
      expect(
        SocialPlatform.fromUri(Uri.parse('https://chat.whatsapp.com/AbCdEfGhIj')),
        SocialPlatform.whatsapp,
      );
    });
  });

  group('MediaExtractor', () {
    test('extracts TikTok playAddr with mp4 filename', () {
      const html = '''
        <html><head>
          <meta property="og:title" content="Sample clip" />
          <script>{"playAddr":"https://v16.tiktokcdn.com/a/video.mp4?token=1"}</script>
        </head></html>
      ''';
      final result = MediaExtractor.extract(
        pageUrl: Uri.parse('https://www.tiktok.com/@user/video/123'),
        html: html,
        platform: SocialPlatform.tiktok,
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('tiktokcdn.com'));
      expect(result.fileName, endsWith('.mp4'));
    });

    test('extracts Instagram og:video', () {
      const html = '''
        <meta property="og:title" content="Reel" />
        <meta property="og:video" content="https://cdn.instagram.com/o1/v/reel.mp4" />
      ''';
      final result = MediaExtractor.extract(
        pageUrl: Uri.parse('https://www.instagram.com/reel/xyz/'),
        html: html,
        platform: SocialPlatform.instagram,
      );
      expect(result?.directUrl, contains('reel.mp4'));
      expect(result?.fileName, 'reel.mp4');
    });

    test('extracts Twitter video URL', () {
      const html = '''
        <meta property="og:title" content="Tweet video" />
        https://video.twimg.com/ext_tw_video/1/pu/vid/720x1280/abc/KX.mp4
      ''';
      final result = MediaExtractor.extract(
        pageUrl: Uri.parse('https://x.com/user/status/999'),
        html: html,
        platform: SocialPlatform.twitter,
      );
      expect(result?.directUrl, contains('video.twimg.com'));
      expect(result?.fileName, endsWith('.mp4'));
    });

    test('extracts YouTube progressive stream URL', () {
      const html = '''
        <script>
        var ytInitialPlayerResponse = {"streamingData":{"formats":[{"url":"https://rr1---sn.example.googlevideo.com/videoplayback?id=abc","mimeType":"video/mp4"}]}};
        </script>
      ''';
      final result = MediaExtractor.extract(
        pageUrl: Uri.parse('https://www.youtube.com/watch?v=abc'),
        html: html,
        platform: SocialPlatform.youtube,
      );
      expect(result?.directUrl, contains('googlevideo.com'));
      expect(result?.fileName, endsWith('.mp4'));
    });
  });

  group('FileNameResolver', () {
    test('parses quoted content-disposition filename', () {
      expect(
        FileNameResolver.parseContentDisposition(
          'attachment; filename="report.pdf"',
        ),
        'report.pdf',
      );
    });

    test('adds extension from content-type when missing', () {
      final name = FileNameResolver.resolve(
        uri: Uri.parse('https://cdn.example.com/assets/clip'),
        contentDisposition: 'attachment; filename="clip"',
        contentType: 'video/mp4',
      );
      expect(name, 'clip.mp4');
    });

    test('rejects HTML responses for direct downloads', () {
      expect(
        () => FileNameResolver.resolve(
          uri: Uri.parse('https://example.com/page'),
          contentType: 'text/html; charset=utf-8',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('UrlValidator', () {
    final validator = UrlValidator();

    test('accepts social page URLs for provider resolution', () {
      expect(
        validator.validate('https://www.youtube.com/watch?v=abc').isValid,
        isTrue,
      );
      expect(
        validator.validate(
          'https://www.tiktok.com/@bnsmrh404/video/7643276616088440071',
        ).isValid,
        isTrue,
      );
      expect(
        validator.validate('https://www.instagram.com/reel/abc/').isValid,
        isTrue,
      );
    });

    test('derives filename from path', () {
      final name = validator.fileNameFromUrl(
        Uri.parse('https://example.com/path/video.mp4'),
      );
      expect(name, 'video.mp4');
    });
  });

  group('ContentProviderRegistry', () {
    test('canHandle detects supported hosts', () {
      expect(
        ContentProviderRegistry.canHandle(
          Uri.parse('https://vm.tiktok.com/abc/'),
        ),
        isTrue,
      );
      expect(
        ContentProviderRegistry.canHandle(
          Uri.parse('https://example.com/file.zip'),
        ),
        isFalse,
      );
    });
  });

  group('InstagramGraphqlResolver', () {
    test('extracts shortcode from reel URLs with query params', () {
      final url = Uri.parse(
        'https://www.instagram.com/reel/Db9-utOhI9_/?utm_source=ig_web_copy_link',
      );
      expect(InstagramGraphqlResolver.shortcodeFromUri(url), 'Db9-utOhI9_');
      expect(
        InstagramGraphqlResolver.canonicalPageUrl(url, 'Db9-utOhI9_').toString(),
        'https://www.instagram.com/reel/Db9-utOhI9_/',
      );
    });

    test('parses graphql video_versions payload', () {
      final payload = {
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [
              {
                'video_versions': [
                  {
                    'width': 720,
                    'url': 'https://instagram.cdn.example/o1/v/reel.mp4?token=1',
                  },
                  {
                    'width': 1080,
                    'url': 'https://instagram.cdn.example/o1/v/reel_hd.mp4?token=2',
                  },
                ],
                'caption': {'text': 'Kolu ka gud part2'},
              },
            ],
          },
        },
      };

      final pageUrl = Uri.parse('https://www.instagram.com/reel/Db9-utOhI9_/');
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: pageUrl,
        shortcode: 'Db9-utOhI9_',
        payload: payload,
      );

      expect(result, isNotNull);
      expect(result!.directUrl, contains('reel_hd.mp4'));
      expect(result.fileName, 'reel_hd.mp4');
      expect(result.mimeType, 'video/mp4');
    });
  });

  group('TikTokResolver', () {
    test('extracts downloadAddr from mobile HTML', () {
      const html =
          '{"downloadAddr":"https://v16.tiktokcdn.com/a/video.mp4?token=1"}';
      expect(TikTokResolver.videoIdFromUri(
        Uri.parse('https://www.tiktok.com/@user/video/7643276616088440071'),
      ), '7643276616088440071');
      expect(
        TikTokResolver.extractFromHtmlForTest(html),
        contains('tiktokcdn.com'),
      );
    });

    test('parses video id from webapp share query params', () {
      expect(
        TikTokResolver.videoIdFromUri(
          Uri.parse(
            'https://www.tiktok.com/@hshs63690/video/7673099286178958610?is_from_webapp=1&sender_device=pc',
          ),
        ),
        '7673099286178958610',
      );
    });

    test('ignores static webarch CDN assets', () {
      const html =
          'https://sf-i18n-resources.tiktokcdn.com/obj/tiktok-webarch-solution-i18n-us';
      expect(TikTokResolver.extractFromHtmlForTest(html), isNull);
    });

    test('keeps unicode-escaped playAddr video URLs', () {
      const html =
          '"playAddr":"https:\\u002F\\u002Fv16-webapp-prime.tiktok.com\\u002Fvideo\\u002Ftos\\u002Falisg\\u002Fclip\\u002F?a=1988&mime_type=video_mp4"';
      final url = TikTokResolver.extractFromHtmlForTest(html);
      expect(url, contains('v16-webapp-prime.tiktok.com'));
      expect(url, contains('/video/tos/'));
      expect(url, isNot(contains(r'\u002F')));
    });
  });

  group('YouTubeResolver', () {
    test('extracts googlevideo URL from watch page HTML', () {
      const html =
          'https://rr5---sn.test.googlevideo.com/videoplayback%3Fexpire%3D1%26itag%3D18%26source%3Dyt';
      final url = YouTubeResolver.extractFromHtmlForTest(html);
      expect(url, contains('googlevideo.com'));
      expect(url, contains('itag=18'));
    });

    test('ignores SABR streamingUrl that cannot be downloaded as MP4', () {
      const html =
          '"streamingUrl":"https://rr7---sn.test.googlevideo.com/videoplayback?expire=1\\u0026sabr=1\\u0026sig=abc"';
      expect(YouTubeResolver.extractFromHtmlForTest(html), isNull);
    });

    test('keeps unicode-escaped query params on mix/radio watch URLs', () {
      const html =
          '"streamingUrl":"https://rr7---sn-15po3n5-g0is.googlevideo.com/videoplayback?expire=1\\u0026itag=18\\u0026source=youtube\\u0026id=abc"';
      final url = YouTubeResolver.extractFromHtmlForTest(html);
      expect(url, contains('googlevideo.com'));
      expect(url, contains('itag=18'));
      expect(url, contains('source=youtube'));
      expect(url, isNot(contains(r'\u0026')));
    });

    test('parses video id from youtu.be share links', () {
      expect(
        YouTubeResolver.videoIdFromUri(
          Uri.parse('https://youtu.be/kfKP4o-bXzM?si=nN64wHnbgwRE8HcB'),
        ),
        'kfKP4o-bXzM',
      );
      expect(
        YouTubeResolver.videoIdFromUri(
          Uri.parse('https://www.youtu.be/kfKP4o-bXzM?si=abc'),
        ),
        'kfKP4o-bXzM',
      );
      expect(
        SocialPlatform.fromUri(
          Uri.parse('https://youtu.be/kfKP4o-bXzM?si=nN64wHnbgwRE8HcB'),
        ),
        SocialPlatform.youtube,
      );
    });

    test('parses video id from mix/radio watch URL', () {
      expect(
        YouTubeResolver.videoIdFromUri(
          Uri.parse(
            'https://www.youtube.com/watch?v=kfKP4o-bXzM&list=RDkfKP4o-bXzM&start_radio=1',
          ),
        ),
        'kfKP4o-bXzM',
      );
    });

    test('parses video id from shorts URL', () {
      expect(
        YouTubeResolver.videoIdFromUri(
          Uri.parse('https://www.youtube.com/shorts/abc123XYZ'),
        ),
        'abc123XYZ',
      );
    });
  });

  group('TwitterResolver', () {
    test('builds syndication token', () {
      expect(TwitterResolver.syndicationToken('20'), isNotEmpty);
    });

    test('parses video variants from syndication payload', () {
      final result = TwitterResolver.parseSyndicationPayload(
        tweetId: '1',
        payload: {
          'text': 'Video tweet',
          'video': {
            'variants': [
              {'url': 'https://video.twimg.com/a.mp4', 'content_type': 'video/mp4', 'bitrate': 100},
              {'url': 'https://video.twimg.com/b.mp4', 'content_type': 'video/mp4', 'bitrate': 500},
            ],
          },
        },
      );
      expect(result?.directUrl, contains('b.mp4'));
    });
  });

  group('RedditResolver', () {
    test('parses fallback_url from post JSON', () {
      final result = RedditResolver.parsePostJson(
        pageUrl: Uri.parse('https://www.reddit.com/r/videos/comments/abc/test/'),
        payload: [
          {
            'data': {
              'children': [
                {
                  'data': {
                    'title': 'Clip',
                    'secure_media': {
                      'reddit_video': {
                        'fallback_url': 'https://v.redd.it/abc123/DASH_720.mp4',
                      },
                    },
                  },
                },
              ],
            },
          },
        ],
      );
      expect(result?.directUrl, contains('v.redd.it'));
      expect(result?.fileName, isNotEmpty);
    });
  });
}
