import 'dart:io';

import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Public page URLs used to exercise live social discovery.
///
/// These are well-known public posts plus links previously used in this app.
const liveSocialLinks = <({String platform, String url})>[
  (
    platform: 'YouTube',
    url: 'https://www.youtube.com/watch?v=jNQXAC9IVRw',
  ),
  (
    platform: 'YouTube',
    url: 'https://youtu.be/jNQXAC9IVRw',
  ),
  (
    platform: 'YouTube',
    url: 'https://www.youtube.com/watch?v=aqz-KE-bpKQ',
  ),
  (
    platform: 'YouTube',
    url:
        'https://www.youtube.com/watch?v=kfKP4o-bXzM&list=RDkfKP4o-bXzM&start_radio=1',
  ),
  (
    platform: 'YouTube',
    url: 'https://youtu.be/kfKP4o-bXzM?si=nN64wHnbgwRE8HcB',
  ),
  (
    platform: 'TikTok',
    url: 'https://www.tiktok.com/@bnsmrh404/video/7643276616088440071',
  ),
  (
    platform: 'TikTok',
    url: 'https://www.tiktok.com/@twice_tiktok_official/video/7334344147525963015',
  ),
  (
    platform: 'TikTok',
    url:
        'https://www.tiktok.com/@hshs63690/video/7673099286178958610?is_from_webapp=1&sender_device=pc',
  ),
  (
    platform: 'Instagram',
    url:
        'https://www.instagram.com/reel/Db9-utOhI9_/?utm_source=ig_web_copy_link',
  ),
  (
    platform: 'Instagram',
    url: 'https://www.instagram.com/p/Dbn-XJhk0_-/',
  ),
  (
    platform: 'X (Twitter)',
    url: 'https://x.com/WesRoth/status/2013693268190437410',
  ),
  (
    platform: 'X (Twitter)',
    url: 'https://twitter.com/Remotion/status/2013626968386765291',
  ),
  (
    platform: 'Facebook',
    url: 'https://www.facebook.com/facebook/videos/10153231379926749/',
  ),
  (
    platform: 'Facebook',
    url: 'https://www.facebook.com/reel/1067805301884603',
  ),
  (
    platform: 'Reddit',
    url: 'https://www.reddit.com/r/videos/comments/6rrwyj/that_small_heart_attack/',
  ),
  (
    platform: 'Reddit',
    url:
        'https://www.reddit.com/r/funny/comments/d8qo81/baby_crocodiles_sound_like_theyre_shooting_laser/',
  ),
  (
    platform: 'Pinterest',
    url: 'https://www.pinterest.com/pin/580547278694592554/',
  ),
  (
    platform: 'LinkedIn',
    url: 'https://www.linkedin.com/posts/linkedin_activity-7046513282177392640-abcd',
  ),
  (
    platform: 'Threads',
    url: 'https://www.threads.net/@instagram/post/C8n0YxRPqkD',
  ),
];

void main() {
  final enabled = Platform.environment['SOCIAL_LIVE_TEST'] == '1';

  test('detects every supported social host pattern', () {
    final samples = <String, String>{
      'YouTube watch': 'https://www.youtube.com/watch?v=jNQXAC9IVRw',
      'YouTube shortlink': 'https://youtu.be/jNQXAC9IVRw',
      'YouTube Shorts': 'https://www.youtube.com/shorts/jNQXAC9IVRw',
      'YouTube embed': 'https://www.youtube.com/embed/jNQXAC9IVRw',
      'TikTok video':
          'https://www.tiktok.com/@bnsmrh404/video/7643276616088440071',
      'TikTok shortlink': 'https://vm.tiktok.com/ZMabcdef/',
      'Instagram reel': 'https://www.instagram.com/reel/Db9-utOhI9_/',
      'Instagram post': 'https://www.instagram.com/p/Dbn-XJhk0_-/',
      'X status': 'https://x.com/user/status/2013693268190437410',
      'Twitter status': 'https://twitter.com/user/status/2013693268190437410',
      'Facebook watch': 'https://www.facebook.com/watch/?v=1',
      'Facebook reel': 'https://www.facebook.com/reel/123',
      'fb.watch': 'https://fb.watch/abc123/',
      'Reddit comments':
          'https://www.reddit.com/r/videos/comments/abc/title/',
      'redd.it': 'https://v.redd.it/abc123',
      'Pinterest pin': 'https://www.pinterest.com/pin/123/',
      'pin.it': 'https://pin.it/abc',
      'LinkedIn post':
          'https://www.linkedin.com/posts/linkedin_activity-7046513282177392640-abcd',
      'LinkedIn short': 'https://lnkd.in/abc123',
      'Threads': 'https://www.threads.net/@user/post/AbC123/',
      'Threads.com': 'https://www.threads.com/@user/post/AbC123/',
    };

    for (final entry in samples.entries) {
      final uri = Uri.parse(entry.value);
      expect(
        ContentProviderRegistry.canHandle(uri),
        isTrue,
        reason: '${entry.key} should be recognized: ${entry.value}',
      );
    }
  });

  test(
    'resolves public social video pages through ContentProviderRegistry',
    () async {
      final registry = ContentProviderRegistry();
      final rows = <String>[];
      var resolved = 0;

      for (final item in liveSocialLinks) {
        final uri = Uri.parse(item.url);
        final detected = ContentProviderRegistry.canHandle(uri);
        final label = ContentProviderRegistry.platformLabel(uri) ?? 'unknown';

        if (!detected) {
          rows.add(
            '${item.platform}\t${item.url}\tNO\t$label\t-\tnot recognized',
          );
          continue;
        }

        try {
          final result = await registry
              .discover(uri)
              .timeout(const Duration(seconds: 35));
          if (result == null) {
            rows.add(
              '${item.platform}\t${item.url}\tYES\t$label\t-\tno media found',
            );
            continue;
          }
          resolved++;
          final host = Uri.tryParse(result.directUrl)?.host ?? 'unknown-host';
          rows.add(
            '${item.platform}\t${item.url}\tYES\t${result.platform}\t'
            '${result.fileName}\thost=$host mime=${result.mimeType ?? '-'}',
          );
        } catch (error) {
          final message = error.toString().split('\n').first;
          rows.add(
            '${item.platform}\t${item.url}\tYES\t$label\t-\tERROR $message',
          );
        }
      }

      // ignore: avoid_print
      print('SOCIAL_LIVE_RESULTS');
      for (final row in rows) {
        // ignore: avoid_print
        print(row);
      }
      // ignore: avoid_print
      print('SOCIAL_LIVE_RESOLVED=$resolved/${liveSocialLinks.length}');

      expect(resolved, greaterThan(0));
    },
    skip: enabled ? false : 'Set SOCIAL_LIVE_TEST=1 to run live discovery',
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
