import 'dart:typed_data';

import 'package:dio/dio.dart';

const snapchatUsername = 'fixtureuser';
const snapchatSpotlightId = 'W7_FIXTURE_SPOTLIGHT_AAAAAQ';
const snapchatStoryId = 'STORY_FIXTURE_ID_AAAA';
const snapchatShareCode = 'FxShare1';
const snapchatProfileId = 'PROFILE_FIXTURE_AAAA';
const snapchatSnapId = 'SNAP_FIXTURE_ID_AAAA';

const snapchatHomeUrl = 'https://www.snapchat.com/';
const snapchatProfileUrl = 'https://www.snapchat.com/@$snapchatUsername';
const snapchatAddUrl = 'https://www.snapchat.com/add/$snapchatUsername';
const snapchatPProfileUrl = 'https://www.snapchat.com/p/$snapchatProfileId';
const snapchatSpotlightUrl =
    'https://www.snapchat.com/spotlight/$snapchatSpotlightId';
const snapchatProfileSpotlightUrl =
    'https://www.snapchat.com/@$snapchatUsername/spotlight/$snapchatSpotlightId';
const snapchatSpotlightFeedUrl = 'https://www.snapchat.com/spotlight';
const snapchatStoryUrl = 'https://story.snapchat.com/s/$snapchatUsername';
const snapchatSavedStoryUrl =
    'https://www.snapchat.com/p/$snapchatProfileId/highlights/$snapchatStoryId';
const snapchatShareUrl = 'https://t.snapchat.com/$snapchatShareCode';
const snapchatMobileShareUrl =
    'https://www.snapchat.com/t/$snapchatShareCode';
const snapchatEmbedUrl =
    'https://www.snapchat.com/embed/$snapchatSpotlightId';
const snapchatSnapUrl = 'https://www.snapchat.com/snap/$snapchatSnapId';
const snapchatLoginUrl = 'https://www.snapchat.com/login';
const snapchatChatUrl = 'https://www.snapchat.com/chat';
const snapchatMemoriesUrl = 'https://www.snapchat.com/memories';

const snapchatVideoUrl =
    'https://cf-st.sc-cdn.net/d/fixture_spotlight_video.mp4';
const snapchatBoltVideoUrl =
    'https://bolt-gcdn.sc-cdn.net/x/D1Hpl1dPzWmGIfKIyQAfp.27.IRZXSOY?mo=fixture&uc=46';
const snapchatPhotoUrl = 'https://cf-st.sc-cdn.net/d/fixture_snap_photo.jpg';
const snapchatPhotoUrlTwo =
    'https://cf-st.sc-cdn.net/d/fixture_snap_photo_b.jpg';
const snapchatThumbUrl = 'https://cf-st.sc-cdn.net/d/fixture_thumb.jpg';
const snapchatHlsUrl = 'https://cf-st.sc-cdn.net/d/fixture_stream.m3u8';

String snapchatPhotoHtml({
  String title = 'Public Snap',
  String caption = 'A public Snapchat photo',
  String author = 'Fixture User',
  String imageUrl = snapchatPhotoUrl,
  String username = snapchatUsername,
}) {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="$title" />
<meta property="og:description" content="$caption" />
<meta property="og:image" content="$imageUrl" />
<meta property="og:image:width" content="1080" />
<meta property="og:image:height" content="1920" />
<meta property="og:url" content="https://www.snapchat.com/@$username" />
</head>
<body>
<img src="$imageUrl" alt="$title" />
<script>{"creatorName":"$author","displayName":"$author"}</script>
</body>
</html>''';
}

String snapchatVideoHtml({
  String title = 'Public Spotlight',
  String caption = 'A public Spotlight video',
  String author = 'Fixture User',
  String videoUrl = snapchatVideoUrl,
  String thumbUrl = snapchatThumbUrl,
  String duration = '12.5',
}) {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="$title" />
<meta property="og:description" content="$caption" />
<meta property="og:image" content="$thumbUrl" />
<meta property="og:video" content="$videoUrl" />
<meta property="og:video:type" content="video/mp4" />
<meta property="og:video:width" content="1080" />
<meta property="og:video:height" content="1920" />
<meta property="og:video:duration" content="$duration" />
</head>
<body>
<video src="$videoUrl" width="1080" height="1920"></video>
<script>{"creatorName":"$author","contentUrl":"$videoUrl","duration":"$duration"}</script>
</body>
</html>''';
}

String snapchatBoltVideoHtml({
  String title = 'Public Spotlight',
  String videoUrl = snapchatBoltVideoUrl,
  String thumbUrl = 'https://story.snapchat.com/p/fixture/preview.jpg',
}) {
  final escaped = videoUrl.replaceAll('&', '&amp;');
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="$title" />
<meta property="og:video" content="$escaped" />
<meta property="og:video:secure_url" content="$escaped" />
<meta property="og:video:type" content="video/mp4" />
<meta property="og:video:width" content="1080" />
<meta property="og:video:height" content="1920" />
<meta property="og:image" content="$thumbUrl" />
</head>
<body></body>
</html>''';
}

String snapchatSpotlightRelatedHtml() {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="Public Spotlight" />
<meta property="og:video" content="${snapchatBoltVideoUrl.replaceAll('&', '&amp;')}" />
<meta property="og:video:type" content="video/mp4" />
<meta property="og:image" content="https://story.snapchat.com/p/fixture/preview.jpg" />
</head>
<body>
<script>
{"contentUrl":"$snapchatBoltVideoUrl"}
{"contentUrl":"https://bolt-gcdn.sc-cdn.net/1/relatedSpotlightA.27.IRZXSOY?mo=a&uc=46"}
{"mediaUrl":"https://bolt-gcdn.sc-cdn.net/u/relatedSpotlightB.27.IRZXSOY?mo=b&uc=46"}
{"contentUrl":"https://cf-st.sc-cdn.net/d/relatedSpotlightC.27.IRZXSOY?mo=c&uc=46"}
</script>
</body>
</html>''';
}

String snapchatVideoSourceHtml() {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="Public Spotlight" />
</head>
<body>
<video>
  <source src="$snapchatVideoUrl" type="video/mp4" />
</video>
</body>
</html>''';
}

String snapchatStoryHtml() {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="Public Story" />
<meta property="og:description" content="Two public snaps" />
<meta property="og:image" content="$snapchatThumbUrl" />
</head>
<body>
<script>
{"snapMediaUrl":"$snapchatPhotoUrl","mediaUrl":"$snapchatPhotoUrlTwo"}
</script>
</body>
</html>''';
}

String snapchatProfileHtml({
  String title = 'Fixture User (@fixtureuser) on Snapchat',
  String description = 'Public Snapchat profile',
}) {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="$title" />
<meta property="og:description" content="$description" />
<meta property="og:image" content="$snapchatThumbUrl" />
</head>
<body>
<h1>Fixture User</h1>
</body>
</html>''';
}

String snapchatPrivateHtml() {
  return '''
<!DOCTYPE html>
<html>
<head><title>Snapchat</title></head>
<body><p>This story is private. Only friends can view this content.</p></body>
</html>''';
}

String snapchatAuthHtml() {
  return '''
<!DOCTYPE html>
<html>
<head><title>Log in to Snapchat</title></head>
<body>
<form>Log in to Snapchat to continue</form>
</body>
</html>''';
}

String snapchatUnavailableHtml() {
  return '''
<!DOCTYPE html>
<html>
<head><title>Snapchat</title></head>
<body><p>This spotlight is no longer available</p></body>
</html>''';
}

String snapchatExpiredHtml() {
  return '''
<!DOCTYPE html>
<html>
<head><title>Snapchat</title></head>
<body><p>This snap has expired</p></body>
</html>''';
}

String snapchatHlsHtml() {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="HLS Spotlight" />
<meta property="og:video" content="$snapchatHlsUrl" />
<meta property="og:image" content="$snapchatThumbUrl" />
</head>
<body></body>
</html>''';
}

String snapchatLargeStoryHtml(int count) {
  final items = StringBuffer();
  for (var i = 1; i <= count; i++) {
    items.writeln(
      '"contentUrl":"https://cf-st.sc-cdn.net/d/story_snap_$i.jpg"',
    );
  }
  return '''
<!DOCTYPE html>
<html>
<body>
<script>{$items}</script>
</body>
</html>''';
}

class SnapchatMockAdapter implements HttpClientAdapter {
  static String htmlResponse = '';
  static int htmlStatus = 200;
  static bool throwError = false;
  static DioExceptionType exceptionType = DioExceptionType.connectionError;

  static void reset() {
    htmlResponse = '';
    htmlStatus = 200;
    throwError = false;
    exceptionType = DioExceptionType.connectionError;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (throwError) {
      throw DioException(requestOptions: options, type: exceptionType);
    }

    if (htmlStatus >= 400) {
      throw DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: htmlStatus,
          data: htmlResponse,
        ),
        type: DioExceptionType.badResponse,
      );
    }

    return ResponseBody.fromString(
      htmlResponse,
      htmlStatus,
      headers: {
        Headers.contentTypeHeader: ['text/html; charset=utf-8'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
