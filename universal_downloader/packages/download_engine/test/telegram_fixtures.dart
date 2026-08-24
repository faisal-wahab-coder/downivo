import 'dart:typed_data';

import 'package:dio/dio.dart';

const telegramChannel = 'telegram';
const telegramMessageId = '1001';
const telegramMessageUrl = 'https://t.me/$telegramChannel/$telegramMessageId';
const telegramPreviewUrl = 'https://t.me/s/$telegramChannel/$telegramMessageId';
const telegramChannelUrl = 'https://t.me/$telegramChannel';
const telegramPreviewChannelUrl = 'https://t.me/s/$telegramChannel';
const telegramHomeUrl = 'https://t.me/';
const telegramPhotoUrl = 'https://cdn4.telesco.pe/file/fixture_photo_1001.jpg';
const telegramPhotoUrlTwo =
    'https://cdn4.telesco.pe/file/fixture_photo_1001_b.jpg';
const telegramVideoUrl = 'https://cdn4.telesco.pe/file/fixture_video_1001.mp4';
const telegramGifUrl = 'https://cdn4.telesco.pe/file/fixture_gif_1001.mp4';
const telegramAudioUrl = 'https://cdn4.telesco.pe/file/fixture_audio_1001.mp3';
const telegramVoiceUrl = 'https://cdn4.telesco.pe/file/fixture_voice_1001.oga';
const telegramPdfUrl = 'https://cdn4.telesco.pe/file/fixture_doc_1001.pdf';
const telegramThumbUrl = 'https://cdn4.telesco.pe/file/fixture_thumb_1001.jpg';

String telegramPhotoHtml({
  String title = 'Telegram News',
  String caption = 'A public photo post',
  String author = 'Telegram',
  String imageUrl = telegramPhotoUrl,
  String channel = telegramChannel,
  String messageId = telegramMessageId,
}) {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="$title" />
<meta property="og:description" content="$caption" />
<meta property="og:image" content="$imageUrl" />
<meta property="og:image:width" content="1280" />
<meta property="og:image:height" content="720" />
<meta property="og:url" content="https://t.me/$channel/$messageId" />
</head>
<body>
<div class="tgme_widget_message" data-post="$channel/$messageId">
  <a class="tgme_widget_message_owner_name" href="https://t.me/$channel">
    <span dir="auto">$author</span>
  </a>
  <a class="tgme_widget_message_photo_wrap"
     style="background-image:url('$imageUrl')"
     href="https://t.me/$channel/$messageId"></a>
  <div class="tgme_widget_message_text js-message_text" dir="auto">$caption</div>
</div>
</body>
</html>''';
}

String telegramVideoHtml({
  String title = 'Public Telegram video',
  String caption = 'A public video post',
  String author = 'Telegram',
  String videoUrl = telegramVideoUrl,
  String thumbUrl = telegramThumbUrl,
  String duration = '1:15',
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
<meta property="og:video:width" content="1280" />
<meta property="og:video:height" content="720" />
<meta property="og:video:duration" content="75" />
</head>
<body>
<div class="tgme_widget_message" data-post="$telegramChannel/$telegramMessageId">
  <a class="tgme_widget_message_owner_name" href="https://t.me/$telegramChannel">
    <span dir="auto">$author</span>
  </a>
  <a class="tgme_widget_message_video_player" href="$telegramMessageUrl">
    <i class="tgme_widget_message_video_thumb" style="background-image:url('$thumbUrl')"></i>
    <video src="$videoUrl" class="tgme_widget_message_video" width="1280" height="720"></video>
    <time class="message_video_duration">$duration</time>
  </a>
  <div class="tgme_widget_message_text js-message_text" dir="auto">$caption</div>
</div>
</body>
</html>''';
}

String telegramGifHtml() {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="Animated sticker" />
<meta property="og:video" content="$telegramGifUrl" />
</head>
<body>
<div class="tgme_widget_message" data-post="$telegramChannel/$telegramMessageId">
  <a class="tgme_widget_message_video_player tgme_widget_message_gif_wrap" href="$telegramMessageUrl">
    <video src="$telegramGifUrl" class="tgme_widget_message_video" autoplay loop muted></video>
  </a>
</div>
</body>
</html>''';
}

String telegramDocumentHtml({
  String fileName = 'report.pdf',
  String extra = '1.2 MB, PDF',
  String href = telegramPdfUrl,
}) {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="Document post" />
</head>
<body>
<div class="tgme_widget_message" data-post="$telegramChannel/$telegramMessageId">
  <a class="tgme_widget_message_document_wrap" href="$href">
    <div class="tgme_widget_message_document_title" dir="auto">$fileName</div>
    <div class="tgme_widget_message_document_extra">$extra</div>
  </a>
  <div class="tgme_widget_message_text js-message_text" dir="auto">Quarterly report</div>
</div>
</body>
</html>''';
}

String telegramAudioHtml() {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="Audio post" />
</head>
<body>
<div class="tgme_widget_message" data-post="$telegramChannel/$telegramMessageId">
  <a class="tgme_widget_message_audio" href="$telegramAudioUrl">track.mp3</a>
  <time class="tgme_widget_message_voice_duration">3:20</time>
</div>
</body>
</html>''';
}

String telegramVoiceHtml() {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="Voice message" />
</head>
<body>
<div class="tgme_widget_message" data-post="$telegramChannel/$telegramMessageId">
  <div class="tgme_widget_message_voice" data-voice="$telegramVoiceUrl">
    <time class="tgme_widget_message_voice_duration">0:12</time>
  </div>
</div>
</body>
</html>''';
}

String telegramVoiceAudioSrcHtml() {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="Voice message" />
</head>
<body>
<div class="tgme_widget_message" data-post="$telegramChannel/$telegramMessageId">
  <audio class="tgme_widget_message_voice" src="$telegramVoiceUrl"></audio>
  <time class="tgme_widget_message_voice_duration">0:12</time>
</div>
</body>
</html>''';
}

String telegramVideoSourceHtml() {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="Public Telegram video" />
</head>
<body>
<div class="tgme_widget_message" data-post="$telegramChannel/$telegramMessageId">
  <a class="tgme_widget_message_video_player" href="$telegramMessageUrl">
    <video class="tgme_widget_message_video">
      <source src="$telegramVideoUrl" type="video/mp4" />
    </video>
    <time class="message_video_duration">1:15</time>
  </a>
</div>
</body>
</html>''';
}

String telegramAlbumHtml() {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="Album post" />
<meta property="og:image" content="$telegramPhotoUrl" />
</head>
<body>
<div class="tgme_widget_message" data-post="$telegramChannel/$telegramMessageId">
  <div class="tgme_widget_message_grouped_wrap">
    <div class="tgme_widget_message_grouped">
      <a class="grouped_media_wrap" style="background-image:url('$telegramPhotoUrl')" href="$telegramMessageUrl?single"></a>
      <a class="grouped_media_wrap" style="background-image:url('$telegramPhotoUrlTwo')" href="$telegramMessageUrl?single"></a>
    </div>
  </div>
  <div class="tgme_widget_message_text js-message_text" dir="auto">Two photos</div>
</div>
</body>
</html>''';
}

String telegramTextHtml({String caption = 'Text only public message'}) {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="Telegram" />
<meta property="og:description" content="$caption" />
</head>
<body>
<div class="tgme_widget_message" data-post="$telegramChannel/$telegramMessageId">
  <a class="tgme_widget_message_owner_name" href="https://t.me/$telegramChannel">
    <span dir="auto">Telegram</span>
  </a>
  <div class="tgme_widget_message_text js-message_text" dir="auto">$caption</div>
</div>
</body>
</html>''';
}

String telegramPrivateHtml() {
  return '''
<!DOCTYPE html>
<html>
<head><title>Telegram</title></head>
<body><p>This channel is private</p></body>
</html>''';
}

String telegramAuthHtml() {
  return '''
<!DOCTYPE html>
<html>
<head><title>Log in to Telegram</title></head>
<body>
<form id="login-form">Please log in to Telegram</form>
</body>
</html>''';
}

String telegramUnavailableHtml() {
  return '''
<!DOCTYPE html>
<html>
<head><title>Telegram</title></head>
<body><p>This post is no longer available</p></body>
</html>''';
}

String telegramLargeAlbumHtml(int count) {
  final items = StringBuffer();
  for (var i = 1; i <= count; i++) {
    items.writeln(
      '<a class="grouped_media_wrap" '
      'style="background-image:url(\'https://cdn4.telesco.pe/file/album_$i.jpg\')" '
      'href="$telegramMessageUrl?single"></a>',
    );
  }
  return '''
<!DOCTYPE html>
<html>
<body>
<div class="tgme_widget_message" data-post="$telegramChannel/$telegramMessageId">
  <div class="tgme_widget_message_grouped">$items</div>
</div>
</body>
</html>''';
}

class TelegramMockAdapter implements HttpClientAdapter {
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
