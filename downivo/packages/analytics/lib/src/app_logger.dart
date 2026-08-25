import 'package:flutter/foundation.dart';

import 'privacy_sanitizer.dart';

enum LogLevel { debug, info, warning, error, fatal }

/// Structured logger. Never log URLs, tokens, or cookies.
class AppLogger {
  AppLogger({
    PrivacySanitizer sanitizer = const PrivacySanitizer(),
    void Function(LogLevel level, String line)? sink,
  }) : _sanitizer = sanitizer,
       _sink = sink;

  final PrivacySanitizer _sanitizer;
  final void Function(LogLevel level, String line)? _sink;

  void debug(String message, {Map<String, Object?>? fields}) =>
      log(LogLevel.debug, message, fields: fields);

  void info(String message, {Map<String, Object?>? fields}) =>
      log(LogLevel.info, message, fields: fields);

  void warning(String message, {Map<String, Object?>? fields}) =>
      log(LogLevel.warning, message, fields: fields);

  void error(String message, {Map<String, Object?>? fields}) =>
      log(LogLevel.error, message, fields: fields);

  void fatal(String message, {Map<String, Object?>? fields}) =>
      log(LogLevel.fatal, message, fields: fields);

  void log(
    LogLevel level,
    String message, {
    Map<String, Object?>? fields,
  }) {
    final safeMessage = _sanitizer.sanitizeMessage(message);
    final safeFields = _sanitizer.sanitize(fields);
    final buffer = StringBuffer('${level.name.toUpperCase()}  $safeMessage');
    for (final entry in safeFields.entries) {
      buffer.write('  ${entry.key}=${entry.value}');
    }
    final line = buffer.toString();
    final custom = _sink;
    if (custom != null) {
      custom(level, line);
      return;
    }
    debugPrint(line);
  }
}
