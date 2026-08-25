import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'firebase_bootstrap.dart';
import 'privacy_sanitizer.dart';

class CrashlyticsAdapter {
  CrashlyticsAdapter({PrivacySanitizer sanitizer = const PrivacySanitizer()})
    : _sanitizer = sanitizer;

  final PrivacySanitizer _sanitizer;
  var _enabled = false;

  Future<void> attach({required bool collectionEnabled}) async {
    if (!FirebaseBootstrap.available) return;
    _enabled = collectionEnabled && !kDebugMode;
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        _enabled,
      );
    } on Object {
      _enabled = false;
    }
  }

  Future<void> setCollectionEnabled(bool enabled) async {
    _enabled = enabled && FirebaseBootstrap.available && !kDebugMode;
    if (!FirebaseBootstrap.available) return;
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        _enabled,
      );
    } on Object {
      // Ignore adapter failures; logging still works locally.
    }
  }

  Future<void> setKeys(Map<String, String> keys) async {
    if (!_enabled) return;
    for (final entry in keys.entries) {
      try {
        await FirebaseCrashlytics.instance.setCustomKey(
          entry.key,
          _sanitizer.sanitizeMessage(entry.value),
        );
      } on Object {
        // Best-effort context.
      }
    }
  }

  Future<void> log(String message) async {
    if (!_enabled) return;
    try {
      await FirebaseCrashlytics.instance.log(
        _sanitizer.sanitizeMessage(message),
      );
    } on Object {
      // Best-effort breadcrumb.
    }
  }

  Future<void> recordError(
    Object error,
    StackTrace stack, {
    bool fatal = false,
    String? reason,
  }) async {
    if (!FirebaseBootstrap.available) return;
    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        fatal: fatal,
        reason: reason == null ? null : _sanitizer.sanitizeMessage(reason),
      );
    } on Object {
      // Swallow so error handlers cannot recurse.
    }
  }

  Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = true,
  }) async {
    if (!FirebaseBootstrap.available) return;
    try {
      if (fatal) {
        await FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      } else {
        await FirebaseCrashlytics.instance.recordFlutterError(details);
      }
    } on Object {
      // Swallow.
    }
  }
}
