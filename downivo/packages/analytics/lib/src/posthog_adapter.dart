import 'package:posthog_flutter/posthog_flutter.dart';

import 'privacy_sanitizer.dart';

class PosthogAdapter {
  PosthogAdapter({PrivacySanitizer sanitizer = const PrivacySanitizer()})
    : _sanitizer = sanitizer;

  final PrivacySanitizer _sanitizer;
  var _ready = false;
  var _enabled = false;

  bool get isReady => _ready;

  Future<void> setup({
    required String apiKey,
    required String host,
    required bool enabled,
  }) async {
    _enabled = enabled;
    if (apiKey.isEmpty) return;
    try {
      final config = PostHogConfig(apiKey);
      config.host = host;
      config.captureApplicationLifecycleEvents = true;
      await Posthog().setup(config);
      _ready = true;
      if (!enabled) {
        await Posthog().disable();
      }
    } on Object {
      _ready = false;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    if (!_ready) return;
    try {
      if (enabled) {
        await Posthog().enable();
      } else {
        await Posthog().disable();
      }
    } on Object {
      // Keep local flag.
    }
  }

  Future<void> capture(
    String event,
    Map<String, Object> properties,
  ) async {
    if (!_ready || !_enabled) return;
    try {
      await Posthog().capture(
        eventName: event,
        properties: _sanitizer.sanitize(properties),
      );
    } on Object {
      // Drop the event rather than crash the app.
    }
  }

  Future<void> screen(String name, Map<String, Object> properties) async {
    if (!_ready || !_enabled) return;
    try {
      await Posthog().screen(
        screenName: name,
        properties: _sanitizer.sanitize(properties),
      );
    } on Object {
      // Drop.
    }
  }
}
