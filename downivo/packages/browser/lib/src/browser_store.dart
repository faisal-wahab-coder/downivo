import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'models/browser_bookmark.dart';
import 'models/browser_history_entry.dart';

/// Persists browser history and bookmarks locally.
class BrowserStore {
  BrowserStore(this._prefs);

  static const _historyKey = 'browser_history';
  static const _bookmarksKey = 'browser_bookmarks';
  static const _maxHistory = 200;

  final SharedPreferences _prefs;
  final _uuid = const Uuid();

  List<BrowserHistoryEntry> get history {
    final raw = _prefs.getString(_historyKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => BrowserHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.visitedAt.compareTo(a.visitedAt));
    } on Object {
      return [];
    }
  }

  List<BrowserBookmark> get bookmarks {
    final raw = _prefs.getString(_bookmarksKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => BrowserBookmark.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.title.compareTo(b.title));
    } on Object {
      return [];
    }
  }

  Future<void> addHistory({required String url, required String title}) async {
    if (url.startsWith('udm://')) return;

    final entries = history
        .where((entry) => entry.url != url)
        .take(_maxHistory - 1)
        .toList();

    entries.insert(
      0,
      BrowserHistoryEntry(
        id: _uuid.v4(),
        url: url,
        title: title.isEmpty ? url : title,
        visitedAt: DateTime.now(),
      ),
    );

    await _prefs.setString(
      _historyKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> deleteHistoryItem(String id) async {
    final kept = history.where((e) => e.id != id).toList();
    await _prefs.setString(
      _historyKey,
      jsonEncode(kept.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> clearHistory() async {
    await _prefs.remove(_historyKey);
  }

  bool isBookmarked(String url) => bookmarks.any((b) => b.url == url);

  Future<void> toggleBookmark({
    required String url,
    required String title,
  }) async {
    final current = bookmarks;
    if (current.any((b) => b.url == url)) {
      final kept = current.where((b) => b.url != url).toList();
      await _prefs.setString(
        _bookmarksKey,
        jsonEncode(kept.map((e) => e.toJson()).toList()),
      );
      return;
    }

    current.add(
      BrowserBookmark(
        id: _uuid.v4(),
        url: url,
        title: title.isEmpty ? url : title,
        createdAt: DateTime.now(),
      ),
    );
    await _prefs.setString(
      _bookmarksKey,
      jsonEncode(current.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> removeBookmark(String id) async {
    final kept = bookmarks.where((b) => b.id != id).toList();
    await _prefs.setString(
      _bookmarksKey,
      jsonEncode(kept.map((e) => e.toJson()).toList()),
    );
  }
}
