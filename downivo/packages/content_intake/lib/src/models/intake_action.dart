/// Action to take after analyzing shared or scanned content.
enum IntakeActionType {
  download,
  openInBrowser,
  showText,
  importFiles,
}

class IntakeAction {
  const IntakeAction({
    required this.type,
    this.url,
    this.text,
    this.filePaths = const [],
    this.label,
  });

  final IntakeActionType type;
  final String? url;
  final String? text;
  final List<String> filePaths;
  final String? label;
}
