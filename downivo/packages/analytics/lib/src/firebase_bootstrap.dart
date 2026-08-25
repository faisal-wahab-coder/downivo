import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Initializes Firebase when `google-services.json` / default options exist.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool _attempted = false;
  static bool available = false;

  static Future<bool> ensureInitialized() async {
    if (_attempted) return available;
    _attempted = true;
    if (kIsWeb) {
      available = false;
      return false;
    }
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      available = true;
    } on Object {
      available = false;
    }
    return available;
  }
}
