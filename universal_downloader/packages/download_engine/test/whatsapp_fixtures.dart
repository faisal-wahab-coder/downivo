import 'dart:typed_data';

import 'package:dio/dio.dart';

const whatsappPhone = '15555550100';
const whatsappChatUrl = 'https://wa.me/$whatsappPhone';
const whatsappChatTextUrl =
    'https://wa.me/$whatsappPhone?text=Hello%20from%20QA';
const whatsappHomeUrl = 'https://www.whatsapp.com/';
const whatsappWaMeHomeUrl = 'https://wa.me/';
const whatsappChannelId = '0029VaTESTCHANNEL01';
const whatsappChannelUrl =
    'https://www.whatsapp.com/channel/$whatsappChannelId';
const whatsappChannelPostUrl =
    'https://www.whatsapp.com/channel/$whatsappChannelId/1001';
const whatsappInviteCode = 'FIXTUREInviteCodeAB';
const whatsappInviteUrl = 'https://chat.whatsapp.com/$whatsappInviteCode';
const whatsappWebUrl = 'https://web.whatsapp.com/';
const whatsappInvalidWaMeUrl = 'https://wa.me/INVALID';
const whatsappInvalidPathUrl = 'https://www.whatsapp.com/INVALID';
const whatsappImageUrl =
    'https://scontent.xx.fbcdn.net/v/whatsapp_channel_fixture.jpg';
const whatsappImageUrlTwo =
    'https://scontent.xx.fbcdn.net/v/whatsapp_channel_fixture_b.jpg';
const whatsappVideoUrl =
    'https://scontent.xx.fbcdn.net/v/whatsapp_channel_fixture.mp4';
const whatsappThumbUrl =
    'https://scontent.xx.fbcdn.net/v/whatsapp_channel_thumb.jpg';
const whatsappAudioUrl =
    'https://scontent.xx.fbcdn.net/v/whatsapp_audio_fixture.mp3';
const whatsappPdfUrl =
    'https://scontent.xx.fbcdn.net/v/whatsapp_doc_fixture.pdf';
const whatsappPrivateMediaUrl =
    'https://mmg.whatsapp.net/v/t62/encrypted_fixture.enc';

String whatsappChannelHtml({
  String title = 'QA Public Channel',
  String description = 'A public WhatsApp Channel',
  String imageUrl = whatsappImageUrl,
  int width = 1280,
  int height = 720,
}) {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="$title" />
<meta property="og:description" content="$description" />
<meta property="og:image" content="$imageUrl" />
<meta property="og:image:width" content="$width" />
<meta property="og:image:height" content="$height" />
<meta property="og:url" content="$whatsappChannelUrl" />
</head>
<body>
<h1>$title</h1>
<p>$description</p>
</body>
</html>''';
}

String whatsappChannelVideoHtml({
  String title = 'Public Channel video',
  String description = 'A public Channel post',
  String videoUrl = whatsappVideoUrl,
  String thumbUrl = whatsappThumbUrl,
  String duration = '75',
}) {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="$title" />
<meta property="og:description" content="$description" />
<meta property="og:image" content="$thumbUrl" />
<meta property="og:video" content="$videoUrl" />
<meta property="og:video:type" content="video/mp4" />
<meta property="og:video:width" content="1280" />
<meta property="og:video:height" content="720" />
<meta property="og:video:duration" content="$duration" />
</head>
<body><h1>$title</h1></body>
</html>''';
}

String whatsappChannelTextHtml({
  String title = 'QA Public Channel',
  String description = 'Follow this channel in WhatsApp',
}) {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="$title" />
<meta property="og:description" content="$description" />
<meta property="og:image" content="https://static.whatsapp.net/rsrc.php/logo.png" />
</head>
<body><p>Open WhatsApp to follow this channel.</p></body>
</html>''';
}

String whatsappPrivateHtml() {
  return '''
<!DOCTYPE html>
<html>
<head><title>WhatsApp</title></head>
<body><p>This chat is private</p></body>
</html>''';
}

String whatsappAuthHtml() {
  return '''
<!DOCTYPE html>
<html>
<head><title>Log in to WhatsApp</title></head>
<body>
<form id="login-form">Keep your phone connected. Scan the QR code.</form>
</body>
</html>''';
}

String whatsappUnavailableHtml() {
  return '''
<!DOCTYPE html>
<html>
<head><title>WhatsApp</title></head>
<body><p>This content is no longer available</p></body>
</html>''';
}

String whatsappDisappearedHtml() {
  return '''
<!DOCTYPE html>
<html>
<head><title>WhatsApp</title></head>
<body><p>This message has disappeared</p></body>
</html>''';
}

String whatsappLargeChannelHtml(int count) {
  final items = StringBuffer();
  for (var i = 1; i <= count; i++) {
    items.writeln(
      '<meta property="og:image" '
      'content="https://scontent.xx.fbcdn.net/v/channel_$i.jpg" />',
    );
  }
  return '''
<!DOCTYPE html>
<html>
<head>
<meta property="og:title" content="Large channel" />
$items
</head>
<body></body>
</html>''';
}

class WhatsAppMockAdapter implements HttpClientAdapter {
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
