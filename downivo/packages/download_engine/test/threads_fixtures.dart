import 'dart:typed_data';

import 'package:dio/dio.dart';

const threadsUsername = 'fixtureuser';
const threadsDisplayName = 'Fixture User';
const threadsAuthorId = '17841400000000000';
const threadsPostId = 'C8n0YxRPqkD';
const threadsQuotedPostId = 'C7quotedPost1';
const threadsRepostedPostId = 'C6repostOrig1';
const threadsShareCode = 'xmtShare1';

const threadsHomeUrl = 'https://www.threads.net/';
const threadsHomeComUrl = 'https://www.threads.com/';
const threadsProfileUrl = 'https://www.threads.net/@$threadsUsername';
const threadsProfileComUrl = 'https://www.threads.com/@$threadsUsername';
const threadsPostUrl =
    'https://www.threads.net/@$threadsUsername/post/$threadsPostId';
const threadsPostComUrl =
    'https://www.threads.com/@$threadsUsername/post/$threadsPostId';
const threadsShortPostUrl = 'https://www.threads.net/t/$threadsPostId';
const threadsEmbedUrl =
    'https://www.threads.net/@$threadsUsername/post/$threadsPostId/embed';
const threadsBareEmbedUrl = 'https://www.threads.net/post/$threadsPostId/embed/';
const threadsShareUrl =
    'https://www.threads.net/@$threadsUsername/post/$threadsPostId?xmt=$threadsShareCode';
const threadsTrackedUrl =
    'https://www.threads.net/@$threadsUsername/post/$threadsPostId?utm_source=share&fbclid=abc&hl=en';
const threadsLoginUrl = 'https://www.threads.net/login';
const threadsInvalidPathUrl = 'https://www.threads.net/INVALID';
const threadsInvalidPostUrl = 'https://www.threads.net/@INVALID/post/INVALID';

const threadsImageUrl =
    'https://scontent.cdninstagram.com/v/t51.29350-15/fixture_threads_image.jpg';
const threadsImageUrlTwo =
    'https://scontent.cdninstagram.com/v/t51.29350-15/fixture_threads_image_b.jpg';
const threadsImageUrlThree =
    'https://scontent-iad3-1.cdninstagram.com/v/t51.29350-15/fixture_threads_image_c.jpg';
const threadsFnaImageUrl =
    'https://instagram.fruh2-1.fna.fbcdn.net/v/t51.2885-15/fixture_threads_image.jpg';
const threadsFnaVideoUrl =
    'https://instagram.fruh2-1.fna.fbcdn.net/o1/v/t16/fixture_threads_video.mp4';
const threadsStaticCdnUrl =
    'https://static.cdninstagram.com/rsrc.php/v3/fixture_logo.png';
const threadsVideoUrl =
    'https://scontent.cdninstagram.com/o1/v/t16/f2/m69/fixture_threads_video.mp4';
const threadsThumbUrl =
    'https://scontent.cdninstagram.com/v/t51.29350-15/fixture_threads_thumb.jpg';
const threadsProfilePicUrl =
    'https://scontent.cdninstagram.com/v/t51.2885-19/fixture_avatar.jpg';
const threadsHlsUrl =
    'https://scontent.cdninstagram.com/o1/v/t16/f2/m69/fixture_threads.m3u8';

String threadsImageHtml({
  String title = 'Fixture User on Threads',
  String caption = 'A public Threads image',
  String author = threadsDisplayName,
  String username = threadsUsername,
  String imageUrl = threadsImageUrl,
  String postId = threadsPostId,
  int width = 1080,
  int height = 1350,
}) {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="$title" />
<meta property="og:description" content="$caption" />
<meta property="og:image" content="$imageUrl" />
<meta property="og:image:width" content="$width" />
<meta property="og:image:height" content="$height" />
<meta property="og:url" content="https://www.threads.net/@$username/post/$postId" />
</head>
<body>
<script>
{"username":"$username","full_name":"$author","pk":"$threadsAuthorId","code":"$postId","text":"$caption","image_versions2":{"candidates":[{"url":"$imageUrl","width":$width,"height":$height}]},"taken_at":1710000000}
</script>
</body>
</html>''';
}

String threadsVideoHtml({
  String title = 'Fixture User on Threads',
  String caption = 'A public Threads video',
  String author = threadsDisplayName,
  String username = threadsUsername,
  String videoUrl = threadsVideoUrl,
  String thumbUrl = threadsThumbUrl,
  String duration = '12.5',
  int width = 1080,
  int height = 1920,
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
<meta property="og:video:width" content="$width" />
<meta property="og:video:height" content="$height" />
<meta property="og:video:duration" content="$duration" />
<meta property="og:url" content="https://www.threads.net/@$username/post/$threadsPostId" />
</head>
<body>
<script>
{"username":"$username","full_name":"$author","pk":"$threadsAuthorId","code":"$threadsPostId","text":"$caption","video_versions":[{"url":"$videoUrl","width":$width,"height":$height}],"video_duration":$duration}
</script>
</body>
</html>''';
}

String threadsTextHtml({
  String caption = 'Just a public text post',
  String username = threadsUsername,
}) {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="Fixture User on Threads" />
<meta property="og:description" content="$caption" />
<meta property="og:url" content="https://www.threads.net/@$username/post/$threadsPostId" />
</head>
<body>
<script>
{"username":"$username","full_name":"$threadsDisplayName","pk":"$threadsAuthorId","code":"$threadsPostId","text":"$caption","text_post_app_info":{}}
</script>
</body>
</html>''';
}

String threadsCarouselHtml() {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="Fixture User on Threads" />
<meta property="og:description" content="Three public images" />
<meta property="og:image" content="$threadsImageUrl" />
</head>
<body>
<script>
{"username":"$threadsUsername","full_name":"$threadsDisplayName","code":"$threadsPostId","text":"Three public images","carousel_media":[{"image_versions2":{"candidates":[{"url":"$threadsImageUrl","width":1080,"height":1080}]}},{"image_versions2":{"candidates":[{"url":"$threadsImageUrlTwo","width":1080,"height":1350}]}},{"image_versions2":{"candidates":[{"url":"$threadsImageUrlThree","width":1080,"height":1920}]}}]}
</script>
</body>
</html>''';
}

String threadsMultiMediaHtml() {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="Fixture User on Threads" />
<meta property="og:description" content="Image and video" />
<meta property="og:image" content="$threadsThumbUrl" />
</head>
<body>
<script>
{"username":"$threadsUsername","code":"$threadsPostId","text":"Image and video","carousel_media":[{"image_versions2":{"candidates":[{"url":"$threadsImageUrl","width":1080,"height":1080}]}},{"video_versions":[{"url":"$threadsVideoUrl","width":1080,"height":1920}]}]}
</script>
</body>
</html>''';
}

String threadsQuoteHtml() {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="Fixture User on Threads" />
<meta property="og:description" content="Quoting another post" />
<meta property="og:image" content="$threadsImageUrl" />
</head>
<body>
<script>
{"username":"$threadsUsername","full_name":"$threadsDisplayName","code":"$threadsPostId","text":"Quoting another post","text_post_app_info":{"share_info":{"quoted_post":{"code":"$threadsQuotedPostId","image_versions2":{"candidates":[{"url":"$threadsImageUrl","width":1080,"height":1080}]}}}}}
</script>
</body>
</html>''';
}

String threadsRepostHtml() {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="Fixture User on Threads" />
<meta property="og:description" content="Reposted this" />
<meta property="og:image" content="$threadsImageUrl" />
</head>
<body>
<script>
{"username":"$threadsUsername","code":"$threadsPostId","text":"Reposted this","is_repost":true,"text_post_app_info":{"share_info":{"reposted_post":{"code":"$threadsRepostedPostId","image_versions2":{"candidates":[{"url":"$threadsImageUrl","width":1080,"height":1080}]}}}}}
</script>
</body>
</html>''';
}

String threadsProfileHtml({
  String title = 'Fixture User (@fixtureuser) on Threads',
  String description = 'Public Threads profile',
}) {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="$title" />
<meta property="og:description" content="$description" />
<meta property="og:image" content="$threadsProfilePicUrl" />
</head>
<body>
<script>{"username":"$threadsUsername","full_name":"$threadsDisplayName","biography":"$description"}</script>
</body>
</html>''';
}

String threadsPrivateHtml() {
  return '''
<!DOCTYPE html>
<html>
<head><title>Threads</title></head>
<body><p>This profile is private. Only approved followers can see this content.</p></body>
</html>''';
}

String threadsAuthHtml() {
  return '''
<!DOCTYPE html>
<html>
<head><title>Log in to Threads</title></head>
<body>
<form>Log in to Threads to continue</form>
</body>
</html>''';
}

/// Public post HTML that still includes Threads chrome ("Log in" + a JS
/// module whose name contains "password"). That is not a login wall.
String threadsPublicHtmlWithLoginChrome({
  String imageUrl = threadsImageUrl,
  String postId = threadsPostId,
}) {
  return '''
<!DOCTYPE html>
<html>
<head>
<title>Log in</title>
<meta property="og:image" content="$imageUrl" />
<meta property="og:description" content="A public Threads image" />
</head>
<body>
<button>Log in</button>
<script>
{"code":"$postId","image_versions2":{"candidates":[{"url":"$imageUrl","width":1080,"height":1350}]},"__module":"SecuredActionChallengePasswordDialog.react"}
</script>
</body>
</html>''';
}

String threadsUnicodeEscapedUrl(String url) => url
    .replaceAll('/', r'\u002F')
    .replaceAll('&', r'\u0026')
    .replaceAll('%', r'\u0025');

String threadsUnicodeImageHtml({
  String imageUrl = threadsFnaImageUrl,
  String postId = threadsPostId,
}) {
  final escaped = threadsUnicodeEscapedUrl(imageUrl);
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:description" content="Unicode image" />
</head>
<body>
<script>
{"code":"$postId","image_versions2":{"candidates":[{"url":"$escaped","width":1080,"height":1350}]},"video_versions":null,"media_type":1}
</script>
</body>
</html>''';
}

String threadsUnicodeVideoHtml({
  String videoUrl = threadsFnaVideoUrl,
  String postId = threadsPostId,
}) {
  final escaped = threadsUnicodeEscapedUrl(videoUrl);
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:description" content="Unicode video" />
</head>
<body>
<script>
{"code":"$postId","video_versions":[{"type":101,"url":"$escaped","width":640,"height":640}],"image_versions2":{"candidates":[{"url":"${threadsUnicodeEscapedUrl(threadsFnaImageUrl)}","width":640,"height":640}]}}
</script>
</body>
</html>''';
}

/// Live Threads video posts set `carousel_media` to null and still include a
/// poster in `image_versions2`. `media_type` 2 is video.
String threadsVideoWithNullCarouselHtml({
  String videoUrl = threadsFnaVideoUrl,
  String posterUrl = threadsFnaImageUrl,
  String postId = threadsPostId,
}) {
  final escapedVideo = videoUrl.replaceAll('/', r'\/');
  final escapedPoster = posterUrl.replaceAll('/', r'\/');
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:image" content="$posterUrl" />
<meta property="og:description" content="A public Threads video" />
</head>
<body>
<script>
{"carousel_media":null,"code":"$postId","image_versions2":{"candidates":[{"height":640,"url":"$escapedPoster","width":640}]},"media_type":2,"has_audio":true,"video_versions":[{"type":101,"url":"$escapedVideo","width":640,"height":640}]}
</script>
</body>
</html>''';
}

String threadsImageWithNullCarouselHtml({
  String imageUrl = threadsImageUrl,
  String postId = threadsPostId,
}) {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:image" content="$imageUrl" />
<meta property="og:description" content="A public Threads image" />
</head>
<body>
<script>
{"carousel_media":null,"code":"$postId","image_versions2":{"candidates":[{"url":"$imageUrl","width":1080,"height":1350}]},"video_versions":null,"media_type":1}
</script>
</body>
</html>''';
}

String threadsFeedWithOtherPostHtml({
  String targetPostId = threadsPostId,
  String otherPostId = 'OTHERPOST1',
  String targetUrl = threadsImageUrl,
  String otherUrl = threadsImageUrlTwo,
}) {
  return '''
<!DOCTYPE html>
<html>
<body>
<script>
{"code":"$otherPostId","carousel_media":[{"image_versions2":{"candidates":[{"url":"$otherUrl","width":1080,"height":1080}]}}]}
{"code":"$targetPostId","image_versions2":{"candidates":[{"url":"$targetUrl","width":1080,"height":1350}]}}
</script>
</body>
</html>''';
}

String threadsUnavailableHtml() {
  return '''
<!DOCTYPE html>
<html>
<head><title>Threads</title></head>
<body><p>Sorry, this page isn't available. The link you followed may be broken.</p></body>
</html>''';
}

String threadsHlsHtml() {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="HLS Threads" />
<meta property="og:video" content="$threadsHlsUrl" />
<meta property="og:image" content="$threadsThumbUrl" />
</head>
<body></body>
</html>''';
}

String threadsLargeCarouselHtml(int count) {
  final items = StringBuffer();
  for (var i = 1; i <= count; i++) {
    if (i > 1) items.write(',');
    items.write(
      '{"image_versions2":{"candidates":[{"url":"https://scontent.cdninstagram.com/v/t51.29350-15/carousel_$i.jpg","width":1080,"height":1080}]}}',
    );
  }
  return '''
<!DOCTYPE html>
<html>
<body>
<script>{"carousel_media":[$items]}</script>
</body>
</html>''';
}

/// Empty `candidates` stub for the post, then a later object with the file.
/// Live Threads pages do this: the first record is `media_type` 19 with
/// `"candidates":[]`, and the JPEG or MP4 is on a later copy of the same code.
String threadsStubThenImageHtml({
  String imageUrl = threadsImageUrl,
  String postId = threadsPostId,
}) {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:description" content="A public Threads image" />
</head>
<body>
<script>
{"code":"$postId","media_type":19,"image_versions2":{"candidates":[]},"video_versions":null,"carousel_media":null,"text":"caption"}
{"code":"OTHERPOST1","image_versions2":{"candidates":[{"url":"$threadsImageUrlTwo","width":1080,"height":1080}]}}
{"code":"$postId","media_type":1,"carousel_media":null,"video_versions":null,"image_versions2":{"candidates":[{"url":"$imageUrl","width":1080,"height":1350}]}}
</script>
</body>
</html>''';
}

String threadsMediaLessShellHtml() {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:description" content="A public Threads image" />
<title>Threads</title>
</head>
<body></body>
</html>''';
}

class ThreadsMockAdapter implements HttpClientAdapter {
  static String htmlResponse = '';
  static Map<String, String> htmlByPathContains = {};
  static int htmlStatus = 200;
  static bool throwError = false;
  static DioExceptionType exceptionType = DioExceptionType.connectionError;

  static void reset() {
    htmlResponse = '';
    htmlByPathContains = {};
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

    var body = htmlResponse;
    final url = options.uri.toString();
    for (final entry in htmlByPathContains.entries) {
      if (url.contains(entry.key)) {
        body = entry.value;
        break;
      }
    }

    return ResponseBody.fromString(
      body,
      htmlStatus,
      headers: {
        Headers.contentTypeHeader: ['text/html; charset=utf-8'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
