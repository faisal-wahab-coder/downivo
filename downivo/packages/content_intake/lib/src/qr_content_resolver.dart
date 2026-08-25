import 'package:browser/browser.dart';
import 'package:download_engine/download_engine.dart';

import 'content_analyzer.dart';
import 'models/detected_content.dart';
import 'models/intake_action.dart';
import 'models/share_payload.dart';

/// Maps shared or scanned content to app actions — docs/20, docs/21
class QrContentResolver {
  QrContentResolver({
    ContentAnalyzer? analyzer,
    UrlValidator? validator,
  })  : _analyzer = analyzer ?? ContentAnalyzer(),
        _validator = validator ?? UrlValidator();

  final ContentAnalyzer _analyzer;
  final UrlValidator _validator;

  IntakeAction resolveQr(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      return IntakeAction(type: IntakeActionType.showText, text: trimmed);
    }

    final detected = _analyzer.analyzeText(trimmed);
    return _resolveDetected(detected, fallbackText: trimmed);
  }

  IntakeAction resolveShare(SharePayload payload) {
    if (payload.filePaths.isNotEmpty && payload.text == null) {
      return IntakeAction(
        type: IntakeActionType.importFiles,
        filePaths: payload.filePaths,
        label: '${payload.filePaths.length} shared file(s)',
      );
    }

    final detected = _analyzer.analyzeShare(
      text: payload.text,
      filePaths: payload.filePaths,
    );
    return _resolveDetected(detected, fallbackText: payload.text);
  }

  IntakeAction resolveClipboard(DetectedContent content) {
    return _resolveDetected(content, fallbackText: content.rawText);
  }

  IntakeAction _resolveDetected(
    DetectedContent content, {
    String? fallbackText,
  }) {
    if (content.hasFiles && !content.hasUrls) {
      return IntakeAction(
        type: IntakeActionType.importFiles,
        filePaths: content.filePaths,
        label: '${content.filePaths.length} file(s)',
      );
    }

    final url = content.primaryUrl;
    if (url != null) {
      if (DownloadDetector.isDirectDownloadUrl(url)) {
        return IntakeAction(
          type: IntakeActionType.download,
          url: url,
          filePaths: content.filePaths,
          label: _validator.fileNameFromUrl(Uri.parse(url)),
        );
      }

      final parsed = Uri.tryParse(url);
      if (parsed != null && ContentProviderRegistry.canHandle(parsed)) {
        return IntakeAction(
          type: IntakeActionType.download,
          url: url,
          filePaths: content.filePaths,
          label: ContentProviderRegistry.platformLabel(parsed) ?? url,
        );
      }

      final valid = _validator.validate(url);
      if (valid.isValid) {
        return IntakeAction(
          type: IntakeActionType.openInBrowser,
          url: url,
          filePaths: content.filePaths,
          label: url,
        );
      }
    }

    return IntakeAction(
      type: IntakeActionType.showText,
      text: fallbackText ?? content.rawText,
      filePaths: content.filePaths,
    );
  }
}
