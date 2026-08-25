import 'models/share_payload.dart';

/// Normalizes share payloads from platform channels.
class ShareContentParser {
  const ShareContentParser();

  SharePayload fromText(String? text) {
    return SharePayload(
      text: text?.trim(),
      filePaths: const [],
      mimeTypes: const [],
    );
  }

  SharePayload fromFiles({
    required List<String> paths,
    List<String> mimeTypes = const [],
    String? text,
  }) {
    return SharePayload(
      text: text?.trim(),
      filePaths: paths,
      mimeTypes: mimeTypes,
    );
  }
}
