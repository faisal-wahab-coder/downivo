/// Payload received from the system share sheet.
class SharePayload {
  const SharePayload({
    required this.text,
    required this.filePaths,
    required this.mimeTypes,
  });

  final String? text;
  final List<String> filePaths;
  final List<String> mimeTypes;

  bool get isEmpty =>
      (text == null || text!.trim().isEmpty) && filePaths.isEmpty;
}
