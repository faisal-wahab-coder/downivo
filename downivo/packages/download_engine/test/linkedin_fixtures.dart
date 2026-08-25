import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

const linkedinActivityId = '7046513282177392640';
const linkedinPostUrl =
    'https://www.linkedin.com/posts/linkedin_activity-$linkedinActivityId-abcd';
const linkedinFeedUrl =
    'https://www.linkedin.com/feed/update/urn:li:activity:$linkedinActivityId/';
const linkedinImageUrl =
    'https://media.licdn.com/dms/image/v2/D4E22AQFtestfeed/feedshare-shrink_2048_1536/0/1710000000000?e=2147483647&v=beta&t=abc';
const linkedinImageUrlSmall =
    'https://media.licdn.com/dms/image/v2/D4E22AQFtestfeed/feedshare-shrink_800_800/0/1710000000000?e=2147483647&v=beta&t=abc';
const linkedinImageUrlTwo =
    'https://media.licdn.com/dms/image/v2/D4E22AQFsecondimg/feedshare-shrink_2048_1536/0/1710000000001?e=2147483647&v=beta&t=def';
const linkedinVideoMp4 =
    'https://dms.licdn.com/playlist/vid/v2/D4E10AQFvideo/mp4-720p-30fps-crf28/video.mp4?e=2147483647&v=beta&t=xyz';
const linkedinVideoMp4Sd =
    'https://dms.licdn.com/playlist/vid/v2/D4E10AQFvideo/mp4-360p-30fps-crf28/video.mp4?e=2147483647&v=beta&t=xyz';
const linkedinVideoMp4Path =
    'https://dms.licdn.com/playlist/vid/v2/D4E10AQFvideo/mp4-720p-30fp-crf28/B4DZVIDEO/0/1?e=2147483647&v=beta&t=abc';
const linkedinVideoThumb =
    'https://dms.licdn.com/playlist/vid/v2/D4E10AQFvideo/thumbnail-with-play-button-overlay-high/B4DZTHUMB/0/1?e=2147483647&v=beta&t=abc';
const linkedinCommentImage =
    'https://media.licdn.com/dms/image/v2/D4D2CAQHtest/comment-image-shrink_8192_1280/0/1?e=2147483647&v=beta&t=abc';
const linkedinArticleCover =
    'https://media.licdn.com/dms/image/v2/D4D12AQEtest/article-cover_image-shrink_720_1280/0/1?e=2147483647&v=beta&t=abc';
const linkedinHls =
    'https://dms.licdn.com/playlist/vid/v2/D4E10AQFvideo/hls/master.m3u8?e=2147483647';
const linkedinPdfUrl =
    'https://media.licdn.com/dms/document/media/v2/D4E1FAQfslides/slides.pdf';
const linkedinLogo =
    'https://static.licdn.com/aero-v1/sc/h/al2o9zrvru7aqj8e1x2rzsrca';

String linkedinImagePostHtml({
  String title = 'Public LinkedIn photo | Ada Lovelace | 12 comments',
  String description = 'A public image post',
  String author = 'Ada Lovelace',
  String imageUrl = linkedinImageUrl,
  String? extraImageUrl,
}) {
  final extra = extraImageUrl == null
      ? ''
      : '<meta property="og:image" content="$extraImageUrl" />'
          '"originalUrl":"$extraImageUrl"';
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="$title" />
<meta property="og:description" content="$description" />
<meta property="og:image" content="$imageUrl" />
<meta property="og:url" content="$linkedinPostUrl" />
<meta name="author" content="$author" />
</head>
<body>
<script type="application/json">
{"authorName":"$author","originalUrl":"$imageUrl"$extra}
</script>
<img src="$imageUrl" />
${extraImageUrl == null ? '' : '<img src="$extraImageUrl" />'}
</body>
</html>''';
}

String linkedinMultiImageHtml() {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="Carousel post" />
<meta property="og:image" content="$linkedinImageUrl" />
</head>
<body>
<script>
{"images":[
  {"originalUrl":"$linkedinImageUrl"},
  {"originalUrl":"$linkedinImageUrlTwo"}
]}
</script>
<img src="$linkedinImageUrl" />
<img src="$linkedinImageUrlSmall" />
<img src="$linkedinImageUrlTwo" />
</body>
</html>''';
}

String linkedinVideoPostHtml({
  bool include720 = true,
  bool include360 = true,
  bool includeHls = true,
  String title = 'Public LinkedIn video',
  String author = 'Ada Lovelace',
  double durationMs = 12500,
}) {
  final streams = <Map<String, dynamic>>[];
  if (include360) {
    streams.add({
      'width': 640,
      'height': 360,
      'bitRate': 400000,
      'streamingLocations': [
        {'url': linkedinVideoMp4Sd},
      ],
    });
  }
  if (include720) {
    streams.add({
      'width': 1280,
      'height': 720,
      'bitRate': 1500000,
      'streamingLocations': [
        {'url': linkedinVideoMp4},
      ],
    });
  }
  final hls = includeHls
      ? '"adaptiveStreams":[{"streamingLocations":[{"url":"$linkedinHls"}]}]'
      : '';
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="$title" />
<meta property="og:description" content="A public video" />
<meta property="og:image" content="$linkedinImageUrl" />
<meta property="og:video" content="$linkedinFeedUrl" />
<meta property="og:video:type" content="text/html" />
<meta name="author" content="$author" />
</head>
<body>
<script type="application/ld+json">
{"@type":"VideoObject","name":"$title","duration":"PT12.5S","thumbnailUrl":"$linkedinImageUrl"}
</script>
<script>
{"authorName":"$author","durationInMilliseconds":$durationMs,
"progressiveStreams":${jsonEncode(streams)}
${hls.isEmpty ? '' : ',$hls'}}
</script>
</body>
</html>''';
}

String linkedinHlsOnlyVideoHtml() {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="HLS only" />
<meta property="og:video" content="$linkedinFeedUrl" />
<meta property="og:video:type" content="text/html" />
<meta property="og:image" content="$linkedinImageUrl" />
</head>
<body>
<script>
{"progressiveStreams":[],
"adaptiveStreams":[{"streamingLocations":[{"url":"$linkedinHls"}]}]}
</script>
</body>
</html>''';
}

String linkedinDocumentHtml({
  String title = 'Slide deck',
  String pdfUrl = linkedinPdfUrl,
}) {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="$title" />
</head>
<body>
<script>
{"transcribedDocumentUrl":"$pdfUrl","fileName":"slides.pdf"}
</script>
</body>
</html>''';
}

String linkedinTextPostHtml() {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="Just a thought | Ada | LinkedIn" />
<meta property="og:description" content="Text only" />
<meta property="og:image" content="$linkedinLogo" />
</head>
<body><p>Text only public post</p></body>
</html>''';
}

String linkedinAuthWallHtml() {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="Sign in | LinkedIn" />
<link rel="canonical" href="https://www.linkedin.com/authwall" />
</head>
<body>
<a href="/uas/login">Sign in</a>
</body>
</html>''';
}

String linkedinArticleHtml() {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="An article" />
<meta property="og:type" content="article" />
</head>
<body><article>Long form</article></body>
</html>''';
}

String linkedinDirectOgImageHtml() {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="OG image" />
<meta property="og:image" content="$linkedinImageUrl" />
</head>
<body></body>
</html>''';
}

/// Public embed-style HTML: progressive file is a `mp4-720p` path (no `.mp4`),
/// plus unrelated comment/article images that must not be downloaded.
String linkedinEmbedProgressivePathHtml() {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="Public LinkedIn video" />
<meta property="og:image" content="$linkedinVideoThumb" />
<meta property="og:type" content="article" />
</head>
<body>
<script>
{"type":"video/mp4","src":"$linkedinVideoMp4Path&quot;","width":1280}
</script>
<img src="$linkedinCommentImage" />
<img src="$linkedinArticleCover" />
</body>
</html>''';
}

String linkedinVideoPageWithCommentImagesOnlyHtml() {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="Video post" />
<meta property="og:image" content="$linkedinVideoThumb" />
</head>
<body>
<img src="$linkedinCommentImage" />
<img src="$linkedinArticleCover" />
</body>
</html>''';
}

class LinkedInMockAdapter implements HttpClientAdapter {
  static String htmlResponse = '';
  static int htmlStatus = 200;
  static bool throwError = false;
  static DioExceptionType exceptionType = DioExceptionType.connectionError;
  static String? redirectLocation;

  static void reset() {
    htmlResponse = '';
    htmlStatus = 200;
    throwError = false;
    exceptionType = DioExceptionType.connectionError;
    redirectLocation = null;
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

    final host = options.uri.host.toLowerCase();
    if (redirectLocation != null &&
        (host == 'lnkd.in' || host.endsWith('.lnkd.in'))) {
      return ResponseBody.fromString(
        '',
        302,
        headers: {
          'location': [redirectLocation!],
        },
      );
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
